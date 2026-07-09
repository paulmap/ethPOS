import 'package:hive/hive.dart';

part 'local_sale.g.dart';

@HiveType(typeId: 1)
class LocalSaleItem {
  @HiveField(0)
  final String productId;
  
  @HiveField(1)
  final String productName;
  
  @HiveField(2)
  final int quantity;
  
  @HiveField(3)
  final double unitPrice;

  @HiveField(4)
  final String? currency;

  LocalSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.currency = 'USD',
  });
}

@HiveType(typeId: 2)
class LocalSale extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final List<LocalSaleItem> items;
  
  @HiveField(2)
  final double totalAmount;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4, defaultValue: false)
  final bool? isSynced;

  @HiveField(5)
  final String? customerId;

  @HiveField(6)
  final int? pointsAwarded;

  @HiveField(7)
  final int? pointsRedeemed;

  @HiveField(8)
  final String? paymentCurrency;

  @HiveField(9)
  final double? tenderedAmount;

  @HiveField(10)
  final double? change;

  @HiveField(11)
  final bool? changeConvertedToPoints;

  @HiveField(12)
  final String? customerPO;

  @HiveField(13)
  final String? receiptNumber;

  LocalSale({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.isSynced = false,
    this.customerId,
    this.pointsAwarded,
    this.pointsRedeemed,
    this.paymentCurrency,
    this.tenderedAmount,
    this.change,
    this.changeConvertedToPoints,
    this.customerPO,
    this.receiptNumber,
  });
}
