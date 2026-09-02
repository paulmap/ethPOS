import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/models/local_product.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';
import '../providers/bin_service.dart';
import 'product_detail_page.dart';

/// Management screens go dense on purpose: density signals which mode you are
/// in. Nine lines on screen, bins collapsed to "+n more", low stock tinted.
class StockLedgerPage extends StatefulWidget {
  const StockLedgerPage({super.key, required this.products});

  final Box<LocalProduct> products;

  @override
  State<StockLedgerPage> createState() => _StockLedgerPageState();
}

enum _Filter { all, low, storeroom, dead }

class _StockLedgerPageState extends State<StockLedgerPage> {
  String _term = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinService>();
    final rows = _rows(bins);

    return PosScaffold(
      title: 'Stock status',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: TextField(
              onChanged: (v) => setState(() => _term = v),
              decoration: const InputDecoration(
                hintText: 'Name, SKU or bin code',
                prefixIcon: Icon(Icons.search, size: 17),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 42, minHeight: 20),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: _Pill(
                      label: switch (f) {
                        _Filter.all => 'All',
                        _Filter.low => 'Low',
                        _Filter.storeroom => 'Storeroom',
                        _Filter.dead => 'Dead',
                      },
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const _LedgerHeader(),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _LedgerRow(
                          product: rows[i],
                          binCodes: bins
                              .forProduct(rows[i].id)
                              .map((b) => b.code)
                              .toList(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(product: rows[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<LocalProduct> _rows(BinService bins) {
    final q = _term.trim().toLowerCase();
    return widget.products.values.where((p) {
      if (q.isNotEmpty) {
        final inBin = bins
            .forProduct(p.id)
            .any((b) => b.code.toLowerCase().contains(q));
        final match = p.name.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.contains(q) ?? false) ||
            inBin;
        if (!match) return false;
      }
      return switch (_filter) {
        _Filter.all => true,
        _Filter.low => p.currentStock <= p.effectiveReorderLevel,
        _Filter.storeroom => bins
            .forProduct(p.id)
            .any((b) => b.area.toLowerCase().startsWith('store')),
        _Filter.dead => p.currentStock > 0 &&
            DateTime.now().difference(p.lastUpdated).inDays > 60,
      };
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      letterSpacing: 0.7,
      color: AppColors.mutedLight,
    );
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      child: Row(
        children: const [
          Expanded(child: Text('ITEM', style: style)),
          SizedBox(width: 70, child: Text('BINS', style: style)),
          SizedBox(
            width: 44,
            child: Text('QTY', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.product,
    required this.binCodes,
    required this.onTap,
  });

  final LocalProduct product;
  final List<String> binCodes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final low = product.currentStock <= product.effectiveReorderLevel;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: low ? AppColors.warningTint : null,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(color: AppColors.divider)),
          color: low ? AppColors.warningTint : AppColors.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.effectiveSku} · \$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                binCodes.isEmpty
                    ? 'Unassigned'
                    : binCodes.length == 1
                        ? binCodes.first
                        : '${binCodes.first}\n+${binCodes.length - 1} more',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${product.currentStock}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: low ? AppColors.warning : AppColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.hairlineStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
