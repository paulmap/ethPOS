import 'package:hive/hive.dart';

part 'serial_unit.g.dart';

/// A tracked physical unit: serial/IMEI plus its warranty window.
/// Created when stock is received, consumed (and dated) when sold.
@HiveType(typeId: 21)
class SerialUnit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  final String serial;

  /// null while still in stock.
  @HiveField(3)
  final DateTime? soldAt;

  @HiveField(4)
  final String? saleId;

  @HiveField(5)
  final String? customerId;

  /// Set at point of sale from the product's warranty months.
  @HiveField(6)
  final DateTime? warrantyEnds;

  @HiveField(7)
  final String? binId;

  SerialUnit({
    required this.id,
    required this.productId,
    required this.serial,
    this.soldAt,
    this.saleId,
    this.customerId,
    this.warrantyEnds,
    this.binId,
  });

  bool get inStock => soldAt == null;

  bool get underWarranty =>
      warrantyEnds != null && warrantyEnds!.isAfter(DateTime.now());

  int get daysOfWarrantyLeft => warrantyEnds == null
      ? 0
      : warrantyEnds!.difference(DateTime.now()).inDays;

  SerialUnit copyWith({
    DateTime? soldAt,
    String? saleId,
    String? customerId,
    DateTime? warrantyEnds,
    String? binId,
  }) =>
      SerialUnit(
        id: id,
        productId: productId,
        serial: serial,
        soldAt: soldAt ?? this.soldAt,
        saleId: saleId ?? this.saleId,
        customerId: customerId ?? this.customerId,
        warrantyEnds: warrantyEnds ?? this.warrantyEnds,
        binId: binId ?? this.binId,
      );
}
