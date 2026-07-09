import 'package:flutter/material.dart';
import 'new_product_page.dart';
import 'new_stock_page.dart';
import 'price_list_page.dart';
import 'stock_status_page.dart';

class InventoryHome extends StatelessWidget {
  const InventoryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildInventoryCard(
              context,
              'New Product',
              Icons.add_box_outlined,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewProductPage())),
            ),
            _buildInventoryCard(
              context,
              'New Stock',
              Icons.inventory,
              Colors.green,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewStockPage())),
            ),
            _buildInventoryCard(
              context,
              'Price List',
              Icons.list_alt,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceListPage())),
            ),
            _buildInventoryCard(
              context,
              'Stock',
              Icons.bar_chart,
              Colors.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockStatusPage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
