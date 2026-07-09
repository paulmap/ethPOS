import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/models/local_purchase.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';

class PurchaseProvider extends ChangeNotifier {
  final Box<LocalPurchase> _purchaseBox = Hive.box<LocalPurchase>('purchases_box');
  final Box<LocalProduct> _productBox = Hive.box<LocalProduct>('products_box');

  List<LocalPurchase> get purchases => _purchaseBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  Future<void> addPurchase(LocalPurchase purchase, InventoryProvider inventory) async {
    final settings = inventory.settings;
    final int nextPONo = settings.effectivePoStartNumber;
    final String poNumber = '${settings.effectivePoPrefix}${nextPONo.toString().padLeft(6, '0')}';

    final updatedPurchase = LocalPurchase(
      id: purchase.id,
      supplierId: purchase.supplierId,
      items: purchase.items,
      totalAmount: purchase.totalAmount,
      timestamp: purchase.timestamp,
      status: purchase.status,
      purchaseNumber: poNumber,
    );

    await _purchaseBox.put(updatedPurchase.id, updatedPurchase);
    
    // Increment PO Number in Settings
    await inventory.updateSettings(settings.copyWith(
      poStartNumber: nextPONo + 1,
    ));
    
    // Update stock for each item in the purchase
    if (purchase.status == 'Received') {
      for (final item in purchase.items) {
        final product = _productBox.get(item.productId);
        if (product != null) {
          final updated = product.copyWith(
            currentStock: product.currentStock + item.quantity,
            lastUpdated: DateTime.now(),
          );
          await _productBox.put(updated.id, updated);
        }
      }
    }
    
    notifyListeners();
  }

  Future<void> updatePurchaseStatus(String id, String status) async {
    final purchase = _purchaseBox.get(id);
    if (purchase != null) {
      final oldStatus = purchase.status;
      final updated = purchase.copyWith(
        status: status,
      );
      await _purchaseBox.put(id, updated);
      
      // If status changed to Received, update stock
      if (oldStatus != 'Received' && status == 'Received') {
        for (final item in purchase.items) {
          final product = _productBox.get(item.productId);
          if (product != null) {
            final updatedProd = product.copyWith(
              currentStock: product.currentStock + item.quantity,
              lastUpdated: DateTime.now(),
            );
            await _productBox.put(updatedProd.id, updatedProd);
          }
        }
      }
    }
    notifyListeners();
  }
}
