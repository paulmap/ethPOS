import 'package:hive/hive.dart';

part 'stock_bin.g.dart';

/// One physical location holding a quantity of one product.
///
/// Deliberately a SEPARATE box rather than fields on [LocalProduct]: typeId 0
/// keeps its existing shape, so no risky Hive migration. A product's total on
/// hand is the sum of its bins; `LocalProduct.currentStock` stays as the
/// authoritative total that sales deduct from, and bins explain WHERE it is.
@HiveType(typeId: 20)
class StockBin extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  /// Display, Storeroom, Counter drawer, Yard…
  @HiveField(2)
  final String area;

  /// Bin/shelf/drawer identifier within the area, e.g. "B12", "D2".
  @HiveField(3)
  final String bin;

  @HiveField(4)
  final int quantity;

  /// Bins are picked from in ascending [pickOrder]; the counter drawer first.
  @HiveField(5)
  final int pickOrder;

  @HiveField(6)
  final DateTime lastUpdated;

  StockBin({
    required this.id,
    required this.productId,
    required this.area,
    required this.bin,
    required this.quantity,
    required this.lastUpdated,
    int? pickOrder,
  }) : pickOrder = pickOrder ?? 100;

  StockBin copyWith({
    String? area,
    String? bin,
    int? quantity,
    int? pickOrder,
    DateTime? lastUpdated,
  }) =>
      StockBin(
        id: id,
        productId: productId,
        area: area ?? this.area,
        bin: bin ?? this.bin,
        quantity: quantity ?? this.quantity,
        pickOrder: pickOrder ?? this.pickOrder,
        lastUpdated: lastUpdated ?? DateTime.now(),
      );

  /// Short code used in the ledger and on cart lines, e.g. "STR·B12".
  String get code => '${_areaAbbrev(area)}·$bin';

  String get label => '$area $bin';

  static String _areaAbbrev(String area) {
    final a = area.trim().toLowerCase();
    if (a.startsWith('display')) return 'DIS';
    if (a.startsWith('store')) return 'STR';
    if (a.startsWith('counter')) return 'CTR';
    if (a.startsWith('yard')) return 'YRD';
    return area.length <= 3
        ? area.toUpperCase()
        : area.substring(0, 3).toUpperCase();
  }
}
