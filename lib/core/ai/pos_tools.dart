import 'dart:convert';

import 'package:hive/hive.dart';

import '../storage/models/ai_action.dart';
import '../storage/models/local_product.dart';
import '../storage/models/local_sale.dart';
import '../storage/models/product_extras.dart';
import '../storage/models/serial_unit.dart';
import '../storage/models/stock_bin.dart';

/// Does the answer expose money the assistant may not see?
enum ToolScope { open, supervisorOnly }

class ToolResult {
  final String name;

  /// Structured rows the answer sheet renders as evidence chips.
  final List<Map<String, dynamic>> rows;

  /// A short factual summary the model turns into prose.
  final String facts;

  /// The query, shown behind the supervisor's "show the query" expander.
  final String query;
  final ToolScope scope;

  const ToolResult({
    required this.name,
    required this.rows,
    required this.facts,
    required this.query,
    this.scope = ToolScope.open,
  });

  Map<String, dynamic> toJson() =>
      {'tool': name, 'facts': facts, 'rows': rows};
}

/// The model never touches Hive directly. It picks a tool by name, we run the
/// query here, and only the result goes back into the prompt. That keeps the
/// numbers correct even when a 2B model reasons poorly, and gives the
/// supervisor an auditable query string.
class PosTools {
  PosTools({
    required this.products,
    required this.bins,
    required this.sales,
    required this.serials,
    required this.extras,
  });

  final Box<LocalProduct> products;
  final Box<StockBin> bins;
  final Box<LocalSale> sales;
  final Box<SerialUnit> serials;
  final Box<ProductExtras> extras;

  static const catalogue = <String, String>{
    'find_product':
        'Locate stock by name, SKU or barcode. Returns bins and quantities.',
    'whats_in_bin': 'List what should be sitting in a given bin.',
    'reorder_now':
        'Lines that run out soonest, with days of cover from recent sales.',
    'dead_stock': 'Lines with no sale in a given number of days.',
    'takings': 'Sales totals for a period. Supervisor only.',
    'margin_by_product': 'Margin per line. Supervisor only.',
    'warranty_lookup': 'Whether a serial number is still under warranty.',
    'basket_suggestions':
        'Products often bought with the items already in the cart.',
    'customer_history': 'What a customer has bought before.',
  };

  List<StockBin> _binsFor(String productId) {
    final list = bins.values.where((b) => b.productId == productId).toList()
      ..sort((a, b) => a.pickOrder.compareTo(b.pickOrder));
    return list;
  }

  /// Units sold per day over [days], used for days-of-cover.
  double _velocity(String productId, {int days = 28}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    var units = 0;
    for (final sale in sales.values) {
      if (sale.timestamp.isBefore(cutoff)) continue;
      for (final item in sale.items) {
        if (item.productId == productId) units += item.quantity;
      }
    }
    return units / days;
  }

  ToolResult findProduct(String term) {
    final q = term.trim().toLowerCase();
    final matches = products.values.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase() == q) ||
          (p.barcode == q) ||
          (p.productCode?.toLowerCase() == q);
    }).take(6);

    final rows = matches.map((p) {
      final b = _binsFor(p.id);
      return {
        'productId': p.id,
        'name': p.name,
        'price': p.price,
        'onHand': p.currentStock,
        'bins': b.map((x) => {'code': x.code, 'qty': x.quantity}).toList(),
      };
    }).toList();

    final facts = rows.isEmpty
        ? 'No product matches "$term".'
        : rows
            .map((r) =>
                '${r['name']}: ${r['onHand']} on hand, in ${(r['bins'] as List).map((b) => '${b['code']} (${b['qty']})').join(', ')}')
            .join('; ');

    return ToolResult(
      name: 'find_product',
      rows: rows,
      facts: facts,
      query: 'products where name/sku/barcode ~ "$term" join stock_bins',
    );
  }

  ToolResult whatsInBin(String area, String bin) {
    final matches = bins.values.where((b) =>
        b.bin.toLowerCase() == bin.toLowerCase() &&
        b.area.toLowerCase().startsWith(area.toLowerCase().substring(0, 3)));

    final rows = matches.map((b) {
      final p = products.get(b.productId);
      return {
        'productId': b.productId,
        'name': p?.name ?? 'Unknown product',
        'qty': b.quantity,
        'code': b.code,
      };
    }).toList();

    return ToolResult(
      name: 'whats_in_bin',
      rows: rows,
      facts: rows.isEmpty
          ? 'Nothing is assigned to $area $bin.'
          : rows.map((r) => '${r['name']} × ${r['qty']}').join('; '),
      query: 'stock_bins where area="$area" and bin="$bin"',
    );
  }

  ToolResult reorderNow({int horizonDays = 14}) {
    final rows = <Map<String, dynamic>>[];
    for (final p in products.values) {
      if (p.effectiveIsDiscontinued) continue;
      final perDay = _velocity(p.id);
      if (perDay <= 0) continue;
      final cover = p.currentStock / perDay;
      if (cover > horizonDays) continue;
      rows.add({
        'productId': p.id,
        'name': p.name,
        'onHand': p.currentStock,
        'daysCover': cover.round(),
        'perWeek': (perDay * 7).round(),
        'bins': _binsFor(p.id).map((b) => b.code).toList(),
      });
    }
    rows.sort((a, b) =>
        (a['daysCover'] as int).compareTo(b['daysCover'] as int));
    final top = rows.take(6).toList();

    return ToolResult(
      name: 'reorder_now',
      rows: top,
      facts: top.isEmpty
          ? 'Nothing runs out within $horizonDays days.'
          : top
              .map((r) =>
                  '${r['name']}: ${r['onHand']} left, ${r['daysCover']} days of cover, sells ${r['perWeek']}/week')
              .join('; '),
      query:
          'for each product: stock / (units sold last 28d / 28) <= $horizonDays days',
    );
  }

  ToolResult deadStock({int days = 60}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final sold = <String>{};
    for (final sale in sales.values) {
      if (sale.timestamp.isBefore(cutoff)) continue;
      for (final item in sale.items) {
        sold.add(item.productId);
      }
    }
    final rows = products.values
        .where((p) => !sold.contains(p.id) && p.currentStock > 0)
        .map((p) => {
              'productId': p.id,
              'name': p.name,
              'onHand': p.currentStock,
              'tiedUp': p.effectiveCostPrice * p.currentStock,
              'bins': _binsFor(p.id).map((b) => b.code).toList(),
            })
        .toList()
      ..sort((a, b) =>
          (b['tiedUp'] as double).compareTo(a['tiedUp'] as double));

    final total = rows.fold<double>(
        0, (sum, r) => sum + (r['tiedUp'] as double));

    return ToolResult(
      name: 'dead_stock',
      rows: rows.take(8).toList(),
      // Cost values are money: supervisor only.
      facts:
          '${rows.length} lines have not sold in $days days, tying up \$${total.toStringAsFixed(0)}.',
      query: 'products with no sale line in the last $days days and stock > 0',
      scope: ToolScope.supervisorOnly,
    );
  }

  ToolResult takings({required DateTime from, required DateTime to}) {
    var total = 0.0;
    var count = 0;
    for (final sale in sales.values) {
      if (sale.timestamp.isBefore(from) || sale.timestamp.isAfter(to)) continue;
      total += sale.totalAmount;
      count++;
    }
    return ToolResult(
      name: 'takings',
      rows: [
        {
          'total': total,
          'sales': count,
          'average': count == 0 ? 0 : total / count,
        }
      ],
      facts:
          'Takings \$${total.toStringAsFixed(2)} across $count sales; average basket \$${(count == 0 ? 0 : total / count).toStringAsFixed(2)}.',
      query:
          'sum(sales.total) where timestamp between ${from.toIso8601String()} and ${to.toIso8601String()}',
      scope: ToolScope.supervisorOnly,
    );
  }

  ToolResult marginByProduct({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final revenue = <String, double>{};
    final cost = <String, double>{};
    final units = <String, int>{};

    for (final sale in sales.values) {
      if (sale.timestamp.isBefore(cutoff)) continue;
      for (final item in sale.items) {
        final p = products.get(item.productId);
        if (p == null) continue;
        revenue[p.id] = (revenue[p.id] ?? 0) + item.unitPrice * item.quantity;
        cost[p.id] =
            (cost[p.id] ?? 0) + p.effectiveCostPrice * item.quantity;
        units[p.id] = (units[p.id] ?? 0) + item.quantity;
      }
    }

    final rows = revenue.keys.map((id) {
      final rev = revenue[id]!;
      final c = cost[id] ?? 0;
      return {
        'productId': id,
        'name': products.get(id)?.name ?? id,
        'sold': units[id] ?? 0,
        'revenue': rev,
        'marginPct': rev == 0 ? 0 : ((rev - c) / rev * 100).round(),
      };
    }).toList()
      ..sort((a, b) =>
          (b['marginPct'] as int).compareTo(a['marginPct'] as int));

    return ToolResult(
      name: 'margin_by_product',
      rows: rows.take(8).toList(),
      facts: rows.isEmpty
          ? 'No sales in the last $days days.'
          : rows
              .take(5)
              .map((r) => '${r['name']}: ${r['marginPct']}% on ${r['sold']} sold')
              .join('; '),
      query:
          '(revenue - cost) / revenue per product over the last $days days',
      scope: ToolScope.supervisorOnly,
    );
  }

  ToolResult warrantyLookup(String serial) {
    final unit = serials.values.firstWhere(
      (s) => s.serial.toLowerCase() == serial.trim().toLowerCase(),
      orElse: () => SerialUnit(id: '', productId: '', serial: ''),
    );
    if (unit.id.isEmpty) {
      return ToolResult(
        name: 'warranty_lookup',
        rows: const [],
        facts: 'No unit with serial $serial has been sold from here.',
        query: 'serial_units where serial="$serial"',
      );
    }
    final p = products.get(unit.productId);
    return ToolResult(
      name: 'warranty_lookup',
      rows: [
        {
          'serial': unit.serial,
          'name': p?.name ?? 'Unknown product',
          'soldAt': unit.soldAt?.toIso8601String(),
          'warrantyEnds': unit.warrantyEnds?.toIso8601String(),
          'covered': unit.underWarranty,
          'daysLeft': unit.daysOfWarrantyLeft,
        }
      ],
      facts: unit.underWarranty
          ? '${p?.name ?? 'That unit'} is covered for another ${unit.daysOfWarrantyLeft} days.'
          : '${p?.name ?? 'That unit'} is out of warranty.',
      query: 'serial_units where serial="$serial"',
    );
  }

  /// Co-occurrence over past sales, filtered to what is actually in stock.
  ToolResult basketSuggestions(List<String> cartProductIds, {int limit = 3}) {
    if (cartProductIds.isEmpty) {
      return const ToolResult(
        name: 'basket_suggestions',
        rows: [],
        facts: 'Cart is empty.',
        query: 'n/a',
      );
    }
    final together = <String, int>{};
    final baskets = <String, int>{};

    for (final sale in sales.values) {
      final ids = sale.items.map((i) => i.productId).toSet();
      final overlap = ids.intersection(cartProductIds.toSet());
      if (overlap.isEmpty) continue;
      for (final id in overlap) {
        baskets[id] = (baskets[id] ?? 0) + 1;
      }
      for (final id in ids.difference(cartProductIds.toSet())) {
        together[id] = (together[id] ?? 0) + 1;
      }
    }

    final rows = together.entries
        .map((e) {
          final p = products.get(e.key);
          if (p == null || p.currentStock <= 0) return null;
          final anchor = baskets.values.isEmpty
              ? 0
              : baskets.values.reduce((a, b) => a > b ? a : b);
          return {
            'productId': p.id,
            'name': p.name,
            'price': p.price,
            'onHand': p.currentStock,
            'together': e.value,
            'outOf': anchor,
            'bins': _binsFor(p.id).map((b) => b.code).toList(),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => (b['together'] as int).compareTo(a['together'] as int));

    final top = rows.take(limit).toList();
    return ToolResult(
      name: 'basket_suggestions',
      rows: top,
      facts: top.isEmpty
          ? 'Nothing is reliably bought with these items.'
          : top
              .map((r) =>
                  '${r['name']} appears in ${r['together']} of ${r['outOf']} similar baskets, ${r['onHand']} in stock')
              .join('; '),
      query:
          'co-occurrence of products with ${cartProductIds.length} cart item(s), filtered to stock > 0',
    );
  }

  ToolResult customerHistory(String customerId, {int limit = 8}) {
    final theirs = sales.values
        .where((s) => s.customerId == customerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final rows = theirs
        .take(limit)
        .map((s) => {
              'saleId': s.id,
              'at': s.timestamp.toIso8601String(),
              'items': s.items
                  .map((i) => products.get(i.productId)?.name ?? i.productId)
                  .toList(),
            })
        .toList();

    return ToolResult(
      name: 'customer_history',
      rows: rows,
      facts: rows.isEmpty
          ? 'No previous purchases on record.'
          : 'Last visit ${theirs.first.timestamp.toIso8601String().substring(0, 10)}, ${theirs.length} purchases on record.',
      query: 'sales where customerId="$customerId" order by timestamp desc',
    );
  }

  /// Deterministic autonomous action: recompute a reorder point from velocity.
  /// Returns the [AiAction] to log, with the old value kept for undo.
  AiAction? proposeReorderPoint(LocalProduct product) {
    final perWeek = _velocity(product.id) * 7;
    if (perWeek <= 0) return null;
    final suggested = (perWeek * 2).ceil();
    if (suggested == product.effectiveReorderLevel) return null;
    return AiAction(
      id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
      kind: AiActionKind.setReorderPoint,
      summary: 'Reorder point set to $suggested',
      detail:
          '${product.name} — was ${product.effectiveReorderLevel}. Sells about ${perWeek.round()} a week.',
      at: DateTime.now(),
      undoPayload: jsonEncode({
        'productId': product.id,
        'previousReorderLevel': product.effectiveReorderLevel,
      }),
    );
  }
}
