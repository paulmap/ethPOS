import 'package:hive/hive.dart';

part 'local_purchase.g.dart';

@HiveType(typeId: 6)
class LocalPurchaseItem {
  @HiveField(0)
  final String productId;
  
  @HiveField(1)
  final String productName;
  
  @HiveField(2)
  final int quantity;
  
  @HiveField(3)
  final double costPrice;

  LocalPurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
  });
}

@HiveType(typeId: 7)
class LocalPurchase extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String supplierId;
  
  @HiveField(2)
  final List<LocalPurchaseItem> items;
  
  @HiveField(3)
  final double totalAmount;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final String status; // Pending, Received, Cancelled
  
  @HiveField(6)
  final String? purchaseNumber;

  LocalPurchase({
    required this.id,
    required this.supplierId,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.status = 'Received',
    this.purchaseNumber,
  });

  LocalPurchase copyWith({
    String? id,
    String? supplierId,
    List<LocalPurchaseItem>? items,
    double? totalAmount,
    DateTime? timestamp,
    String? status,
    String? purchaseNumber,
  }) {
    return LocalPurchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
    );
  }
}
