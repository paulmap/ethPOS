import 'package:hive/hive.dart';

part 'local_product.g.dart';

@HiveType(typeId: 0)
class LocalProduct extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? barcode;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final int currentStock;

  @HiveField(5)
  final DateTime lastUpdated;

  @HiveField(6)
  final String? currency;

  @HiveField(7)
  final bool? isDiscontinued;

  @HiveField(8)
  final String? productCode;

  @HiveField(9)
  final String? sku;

  @HiveField(10)
  final String? category;

  @HiveField(11)
  final String? description;

  @HiveField(12)
  final String? taxCategory;

  @HiveField(13)
  final int? minStockHolding;

  @HiveField(14)
  final int? reorderLevel;

  @HiveField(15)
  final double? costPrice;

  @HiveField(16)
  final double? markup;

  LocalProduct({
    required this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.currentStock,
    required this.lastUpdated,
    this.productCode,
    this.sku,
    this.category,
    this.description,
    this.taxCategory,
    this.minStockHolding,
    this.reorderLevel,
    this.costPrice,
    this.markup,
    String? currency,
    bool? isDiscontinued,
  })  : currency = currency ?? 'USD',
        isDiscontinued = isDiscontinued ?? false;

  LocalProduct copyWith({
    String? name,
    String? barcode,
    double? price,
    int? currentStock,
    DateTime? lastUpdated,
    String? productCode,
    String? sku,
    String? category,
    String? description,
    String? taxCategory,
    int? minStockHolding,
    int? reorderLevel,
    double? costPrice,
    double? markup,
    String? currency,
    bool? isDiscontinued,
  }) {
    return LocalProduct(
      id: id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      currentStock: currentStock ?? this.currentStock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      productCode: productCode ?? this.productCode,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      description: description ?? this.description,
      taxCategory: taxCategory ?? this.taxCategory,
      minStockHolding: minStockHolding ?? this.minStockHolding,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      costPrice: costPrice ?? this.costPrice,
      markup: markup ?? this.markup,
      currency: currency ?? this.currency,
      isDiscontinued: isDiscontinued ?? this.isDiscontinued,
    );
  }

  // Getter for non-nullable access in UI
  String get effectiveCurrency => currency ?? 'USD';
  bool get effectiveIsDiscontinued => isDiscontinued ?? false;
  String get effectiveProductCode => productCode ?? barcode ?? 'N/A';
  String get effectiveSku => sku ?? 'N/A';
  String get effectiveCategory => category ?? 'General';
  String get effectiveDescription => description ?? name;
  String get effectiveTaxCategory => taxCategory ?? 'None';
  int get effectiveMinStock => minStockHolding ?? 0;
  int get effectiveReorderLevel => reorderLevel ?? 5;
  double get effectiveCostPrice => costPrice ?? 0.0;
  double get effectiveMarkup => markup ?? 0.0;
}
