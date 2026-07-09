import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../../../../core/storage/models/local_product.dart';

class PriceListPage extends StatefulWidget {
  const PriceListPage({super.key});

  @override
  State<PriceListPage> createState() => _PriceListPageState();
}

class _PriceListPageState extends State<PriceListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price List')),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final products = provider.products;
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tax: ${p.effectiveTaxCategory}'),
                    Text('Cost: ${p.effectiveCurrency} ${p.effectiveCostPrice.toStringAsFixed(2)}'),
                    Text('Markup: ${p.effectiveMarkup.toStringAsFixed(1)}%'),
                  ],
                ),
                trailing: Text(
                  '${p.effectiveCurrency} ${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                ),
                onTap: () => _viewPricing(context, p),
              );
            },
          );
        },
      ),
    );
  }

  void _viewPricing(BuildContext context, LocalProduct product) {
    showDialog(
      context: context,
      builder: (ctx) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Admin Access Required'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please enter the Admin PIN to edit pricing.'),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final inventory = context.read<InventoryProvider>();
                final expectedPin = inventory.settings.adminPin ?? '1234';
                
                if (pinController.text == expectedPin) {
                  Navigator.pop(ctx);
                  _showEditPricingDialog(context, product, inventory);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid PIN')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPricingDialog(BuildContext context, LocalProduct product, InventoryProvider inventory) {
    final costPrice = product.effectiveCostPrice;
    
    // Use controllers to format two decimal places
    final markupController = TextEditingController(text: product.effectiveMarkup.toStringAsFixed(2));
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updatePriceFromMarkup(String val) {
              final m = double.tryParse(val) ?? 0.0;
              final newPrice = costPrice + (costPrice * (m / 100));
              priceController.text = newPrice.toStringAsFixed(2);
            }

            void updateMarkupFromPrice(String val) {
              final p = double.tryParse(val) ?? 0.0;
              if (costPrice > 0) {
                final m = ((p - costPrice) / costPrice) * 100;
                markupController.text = m.toStringAsFixed(2);
              } else {
                markupController.text = '100.00';
              }
            }

            return AlertDialog(
              title: Text('Edit Pricing: ${product.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyField('Tax Category', product.effectiveTaxCategory),
                    _buildReadOnlyField('Cost Price', '${product.effectiveCurrency} ${costPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: markupController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Markup (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      onChanged: updatePriceFromMarkup,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Price (${product.effectiveCurrency})',
                        border: const OutlineInputBorder(),
                        prefixText: '${product.effectiveCurrency} ',
                      ),
                      onChanged: updateMarkupFromPrice,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final newMarkup = double.tryParse(markupController.text) ?? product.effectiveMarkup;
                    final newPrice = double.tryParse(priceController.text) ?? product.price;

                    final updatedProduct = product.copyWith(
                      markup: newMarkup,
                      price: newPrice,
                      lastUpdated: DateTime.now(),
                    );

                    inventory.updateProduct(updatedProduct);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} pricing updated!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }
}
