import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/storage/models/local_sale.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../loyalty/presentation/providers/loyalty_provider.dart';

class SalesProvider extends ChangeNotifier {
  final Box<LocalProduct> _productsBox = Hive.box<LocalProduct>('products_box');
  final Box<LocalSale> _salesBox = Hive.box<LocalSale>('sales_box');
  
  final List<LocalSaleItem> _cart = [];
  String? _selectedCustomerId;
  int _pointsToRedeem = 0;

  List<LocalSaleItem> get cart => _cart;
  String? get selectedCustomerId => _selectedCustomerId;
  int get pointsToRedeem => _pointsToRedeem;

  void addToCart(LocalProduct product, int quantity) {
    final index = _cart.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final existing = _cart[index];
      _cart[index] = LocalSaleItem(
        productId: product.id,
        productName: product.name,
        quantity: existing.quantity + quantity,
        unitPrice: product.price,
        currency: product.currency,
      );
    } else {
      _cart.add(LocalSaleItem(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.price,
        currency: product.currency,
      ));
    }
    notifyListeners();
  }
  
  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }
  
  void clearCart() {
    _cart.clear();
    _selectedCustomerId = null;
    _pointsToRedeem = 0;
    notifyListeners();
  }

  void setSelectedCustomer(String? customerId) {
    _selectedCustomerId = customerId;
    _pointsToRedeem = 0;
    notifyListeners();
  }

  // Alias for compatibility
  void selectCustomer(String? customerId) => setSelectedCustomer(customerId);

  void setPointsToRedeem(int points) {
    _pointsToRedeem = points;
    notifyListeners();
  }

  double getCartTotalInBase(InventoryProvider inventory) {
    double total = 0;
    for (final item in _cart) {
      total += inventory.convertToCurrency(
        item.unitPrice * item.quantity, 
        item.currency ?? 'USD', 
        inventory.settings.baseCurrency
      );
    }
    return total;
  }

  // Alias for compatibility
  double convertAmount(double amount, String from, String to, InventoryProvider inv) {
    return inv.convertToCurrency(amount, from, to);
  }

  Future<LocalSale?> processSale({
    required InventoryProvider inventory,
    required LoyaltyProvider loyalty,
    required String paymentCurrency,
    required double tenderedAmount,
    required double change,
    required bool changeConvertedToPoints,
    String? customerPO,
  }) async {
    if (_cart.isEmpty) return null;
    
    final baseCurrency = inventory.settings.baseCurrency;
    final settings = inventory.settings;
    
    // Generate Receipt Number
    final int nextReceiptNo = settings.effectiveReceiptStartNumber;
    final String receiptNumber = '${settings.effectiveReceiptPrefix}${nextReceiptNo.toString().padLeft(6, '0')}';

    // Calculate total in USD for points (1 USD = 100 points)
    double totalInUSD = 0;
    for (final item in _cart) {
      totalInUSD += inventory.convertToUSD(item.unitPrice * item.quantity, item.currency ?? 'USD');
    }
    final pointsAwarded = (totalInUSD * 100).floor();
    
    // Deduct stock
    for (final item in _cart) {
      final product = _productsBox.get(item.productId);
      if (product != null) {
        final updated = product.copyWith(
          currentStock: product.currentStock - item.quantity,
          lastUpdated: DateTime.now(),
        );
        await _productsBox.put(updated.id, updated);
      }
    }
    
    // Update Loyalty
    if (_selectedCustomerId != null) {
      if (_pointsToRedeem > 0) {
        await loyalty.redeemPoints(_selectedCustomerId!, _pointsToRedeem);
      }
      await loyalty.addPoints(_selectedCustomerId!, pointsAwarded);
      
      if (changeConvertedToPoints && change > 0) {
        final changeInUSD = inventory.convertToUSD(change, paymentCurrency);
        final extraPoints = (changeInUSD * 100).floor();
        if (extraPoints > 0) {
          await loyalty.addPoints(_selectedCustomerId!, extraPoints);
        }
      }
    }
    
    final totalInBase = getCartTotalInBase(inventory);
    final discountInUSD = _pointsToRedeem / 100.0;
    final discountInBase = inventory.convertToCurrency(discountInUSD, 'USD', baseCurrency);
    final finalTotalInBase = totalInBase - discountInBase;

    // Save sale record
    final sale = LocalSale(
      id: const Uuid().v4(),
      items: List.from(_cart),
      totalAmount: finalTotalInBase,
      timestamp: DateTime.now(),
      customerId: _selectedCustomerId,
      pointsAwarded: pointsAwarded,
      pointsRedeemed: _pointsToRedeem,
      paymentCurrency: paymentCurrency,
      tenderedAmount: tenderedAmount,
      change: change,
      changeConvertedToPoints: changeConvertedToPoints,
      customerPO: customerPO,
      receiptNumber: receiptNumber,
    );
    await _salesBox.put(sale.id, sale);
    
    // Increment Receipt Number in Settings
    await inventory.updateSettings(settings.copyWith(
      receiptStartNumber: nextReceiptNo + 1,
    ));

    clearCart();
    return sale;
  }
  
  List<LocalSale> get recentSales => _salesBox.values.toList()..sort((a,b) => b.timestamp.compareTo(a.timestamp));
}
