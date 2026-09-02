/// Mirrors the shape of a product as synced from the Flutter app's
/// `LocalProduct` (see lib/core/storage/models/local_product.dart). Only
/// the fields the assistant actually needs are kept.
class ProductDto {
  final String id;
  final String name;
  final String? barcode;
  final double price;
  final String currency;
  final int currentStock;
  final String category;
  final String description;
  final String locationCode;
  final List<String> compatibleTags;

  ProductDto({
    required this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.currency,
    required this.currentStock,
    required this.category,
    required this.description,
    required this.locationCode,
    required this.compatibleTags,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      locationCode: json['locationCode'] as String? ?? 'Unassigned',
      compatibleTags: (json['compatibleTags'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'price': price,
        'currency': currency,
        'currentStock': currentStock,
        'category': category,
        'description': description,
        'locationCode': locationCode,
        'compatibleTags': compatibleTags,
      };

  /// Lowercased searchable text used by retrieval scoring.
  String get searchBlob =>
      '$name $category $description ${compatibleTags.join(' ')} $id'.toLowerCase();
}
