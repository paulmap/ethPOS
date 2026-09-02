import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../core/storage/models/ai_action.dart';
import '../../../../core/storage/models/stock_bin.dart';

/// Multi-bin stock: one product, several locations, each with its own quantity.
///
/// `LocalProduct.currentStock` remains the total that sales deduct from. Bins
/// explain where that total sits, and are drawn down in pick order so the
/// counter drawer empties before the storeroom.
class BinService extends ChangeNotifier {
  BinService({required this.bins, required this.actionLog});

  final Box<StockBin> bins;
  final Box<AiAction> actionLog;

  List<StockBin> forProduct(String productId) {
    final list = bins.values.where((b) => b.productId == productId).toList()
      ..sort((a, b) => a.pickOrder.compareTo(b.pickOrder));
    return list;
  }

  int totalFor(String productId) =>
      forProduct(productId).fold(0, (sum, b) => sum + b.quantity);

  List<StockBin> inArea(String area) => bins.values
      .where((b) => b.area.toLowerCase() == area.toLowerCase())
      .toList()
    ..sort((a, b) => a.bin.compareTo(b.bin));

  Map<String, int> areaSummary() {
    final out = <String, int>{};
    for (final b in bins.values) {
      out[b.area] = (out[b.area] ?? 0) + b.quantity;
    }
    return out;
  }

  Future<StockBin> upsert({
    required String productId,
    required String area,
    required String bin,
    required int quantity,
    int? pickOrder,
  }) async {
    final existing = bins.values.firstWhere(
      (b) =>
          b.productId == productId &&
          b.area.toLowerCase() == area.toLowerCase() &&
          b.bin.toLowerCase() == bin.toLowerCase(),
      orElse: () => StockBin(
        id: '',
        productId: productId,
        area: area,
        bin: bin,
        quantity: 0,
        lastUpdated: DateTime.now(),
      ),
    );

    final record = existing.id.isEmpty
        ? StockBin(
            id: 'bin-${DateTime.now().microsecondsSinceEpoch}',
            productId: productId,
            area: area,
            bin: bin,
            quantity: quantity,
            pickOrder: pickOrder ?? _defaultPickOrder(area),
            lastUpdated: DateTime.now(),
          )
        : existing.copyWith(quantity: quantity, pickOrder: pickOrder);

    await bins.put(record.id, record);
    notifyListeners();
    return record;
  }

  /// Draw [quantity] down across bins in pick order. Returns the bins touched,
  /// so a receipt or a serial can record where the unit actually came from.
  Future<List<StockBin>> pick(String productId, int quantity) async {
    var remaining = quantity;
    final touched = <StockBin>[];
    for (final bin in forProduct(productId)) {
      if (remaining <= 0) break;
      final take = remaining < bin.quantity ? remaining : bin.quantity;
      if (take <= 0) continue;
      final updated = bin.copyWith(quantity: bin.quantity - take);
      await bins.put(updated.id, updated);
      touched.add(updated);
      remaining -= take;
    }
    notifyListeners();
    return touched;
  }

  /// Return stock to a bin, e.g. a voided sale.
  Future<void> putBack(String binId, int quantity) async {
    final bin = bins.get(binId);
    if (bin == null) return;
    await bins.put(binId, bin.copyWith(quantity: bin.quantity + quantity));
    notifyListeners();
  }

  /// Move stock between two bins, logging it as an AI action when the model
  /// suggested it so the supervisor can undo it.
  Future<bool> move({
    required String fromBinId,
    required String toBinId,
    required int quantity,
    bool aiInitiated = false,
    String? approvedBy,
  }) async {
    final from = bins.get(fromBinId);
    final to = bins.get(toBinId);
    if (from == null || to == null || from.quantity < quantity) return false;

    await bins.put(fromBinId, from.copyWith(quantity: from.quantity - quantity));
    await bins.put(toBinId, to.copyWith(quantity: to.quantity + quantity));

    if (aiInitiated) {
      final action = AiAction(
        id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
        kind: AiActionKind.moveStock,
        summary: 'Moved $quantity from ${from.code} to ${to.code}',
        detail: approvedBy == null
            ? 'Suggested and applied.'
            : 'Approved by $approvedBy at the counter.',
        at: DateTime.now(),
        undoPayload:
            '{"fromBinId":"$fromBinId","toBinId":"$toBinId","quantity":$quantity}',
        approvedBy: approvedBy,
      );
      await actionLog.put(action.id, action);
    }

    notifyListeners();
    return true;
  }

  static int _defaultPickOrder(String area) {
    final a = area.toLowerCase();
    if (a.startsWith('counter')) return 10;
    if (a.startsWith('display')) return 20;
    if (a.startsWith('store')) return 30;
    return 100;
  }
}
