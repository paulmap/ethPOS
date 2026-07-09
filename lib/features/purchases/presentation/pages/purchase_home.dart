import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/models/local_purchase.dart';
import '../../../../core/storage/models/local_supplier.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../suppliers/presentation/providers/supplier_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../providers/purchase_provider.dart';

class PurchaseHome extends StatelessWidget {
  const PurchaseHome({super.key});

  void _showAddPurchaseDialog(BuildContext context) {
    final suppliers = context.read<SupplierProvider>().suppliers;
    final products = context.read<InventoryProvider>().products;
    
    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a supplier first.')));
      return;
    }
    
    String? selectedSupplierId = suppliers.first.id;
    List<LocalPurchaseItem> selectedItems = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Record New Purchase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedSupplierId,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => setModalState(() => selectedSupplierId = val),
              ),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
              ...selectedItems.map((item) => ListTile(
                title: Text(item.productName),
                subtitle: Text('Qty: ${item.quantity} @ ${item.costPrice}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setModalState(() => selectedItems.remove(item)),
                ),
              )),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddItemDialog(context, products, (newItem) {
                    setModalState(() => selectedItems.add(newItem));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedItems.isEmpty ? null : () {
                      final total = selectedItems.fold<double>(0, (sum, item) => sum + (item.costPrice * item.quantity));
                      final purchase = LocalPurchase(
                        id: const Uuid().v4(),
                        supplierId: selectedSupplierId!,
                        items: selectedItems,
                        totalAmount: total,
                        timestamp: DateTime.now(),
                      );
                      context.read<PurchaseProvider>().addPurchase(purchase, context.read<InventoryProvider>());
                      Navigator.pop(context);
                    },
                    child: const Text('Complete Purchase'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, List<LocalProduct> products, Function(LocalPurchaseItem) onAdd) {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No products available.')));
      return;
    }
    
    LocalProduct? selectedProduct = products.first;
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController(text: products.first.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item to Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<LocalProduct>(
              initialValue: selectedProduct,
              decoration: const InputDecoration(labelText: 'Product'),
              items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (val) {
                selectedProduct = val;
                costController.text = val?.price.toString() ?? '0';
              },
            ),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: costController, decoration: const InputDecoration(labelText: 'Cost Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 0;
              final cost = double.tryParse(costController.text) ?? 0;
              if (selectedProduct != null && qty > 0) {
                onAdd(LocalPurchaseItem(
                  productId: selectedProduct!.id,
                  productName: selectedProduct!.name,
                  quantity: qty,
                  costPrice: cost,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          final purchases = provider.purchases;
          if (purchases.isEmpty) {
            return const Center(child: Text('No purchases recorded.\nTap + to record one.', textAlign: TextAlign.center));
          }
          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              final supplier = context.read<SupplierProvider>().suppliers.firstWhere((s) => s.id == purchase.supplierId, orElse: () => LocalSupplier(id: '?', name: 'Unknown'));
              
              return ExpansionTile(
                title: Text('Purchase #${purchase.purchaseNumber ?? purchase.id.substring(0, 8)}'),
                subtitle: Text('${supplier.name} • ${DateFormat('yyyy-MM-dd HH:mm').format(purchase.timestamp)}'),
                trailing: Text('\$${purchase.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                children: purchase.items.map((item) => ListTile(
                  title: Text(item.productName),
                  subtitle: Text('Qty: ${item.quantity}'),
                  trailing: Text('\$${(item.costPrice * item.quantity).toStringAsFixed(2)}'),
                )).toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPurchaseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
