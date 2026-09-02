import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/storage/models/local_product.dart';
import '../providers/inventory_provider.dart';
import 'edit_product_page.dart';

class StockStatusPage extends StatelessWidget {
  const StockStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Status')),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final products = provider.products;
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = products[index];
              final isLowStock = p.currentStock <= p.effectiveReorderLevel;

              return Card(
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SKU: ${p.effectiveSku} | Code: ${p.effectiveProductCode} | Loc: ${p.locationCode}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProductPage(product: p)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Stock: ${p.currentStock}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.red : Colors.green[700],
                              fontSize: 16,
                            ),
                          ),
                          if (isLowStock)
                            const Text('LOW STOCK', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProductPage(product: p)),
                            );
                          } else if (value == 'transfer') {
                            _showTransferDialog(context, provider, p);
                          } else if (value == 'discontinue') {
                            _confirmDiscontinue(context, provider, p);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'transfer', child: Text('Transfer Location')),
                          PopupMenuItem(value: 'discontinue', child: Text('Discontinue')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTransferDialog(BuildContext context, InventoryProvider provider, LocalProduct product) {
    final storeAreaController = TextEditingController(text: product.storeArea);
    final aisleController = TextEditingController(text: product.aisle);
    final binShelfController = TextEditingController(text: product.binShelf);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Transfer Location: ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: ${product.locationCode}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: storeAreaController,
                decoration: const InputDecoration(labelText: 'Store/Area', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aisleController,
                decoration: const InputDecoration(labelText: 'Aisle', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: binShelfController,
                decoration: const InputDecoration(labelText: 'Bin/Shelf', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Note: copyWith falls back to the old value on null, so pass
              // empty strings (not null) here to allow clearing a segment —
              // locationCode already filters out empty segments for display.
              final updated = product.copyWith(
                storeArea: storeAreaController.text,
                aisle: aisleController.text,
                binShelf: binShelfController.text,
                lastUpdated: DateTime.now(),
              );
              provider.updateProduct(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} moved to ${updated.locationCode}')),
              );
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  void _confirmDiscontinue(BuildContext context, InventoryProvider provider, LocalProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discontinue Product'),
        content: Text(
          '${product.name} will be hidden from sales and stock lists but kept for sales history. This cannot be undone from here.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.discontinueProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} discontinued')),
              );
            },
            child: const Text('Discontinue'),
          ),
        ],
      ),
    );
  }
}
