import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

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
                  subtitle: Text('SKU: ${p.effectiveSku} | Code: ${p.effectiveProductCode}'),
                  trailing: Column(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
