import 'package:flutter/material.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';
import 'new_product_page.dart';
import 'new_stock_page.dart';
import 'price_list_page.dart';
import 'stock_status_page.dart';

class InventoryHome extends StatelessWidget {
  const InventoryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return PosScaffold(
      title: 'Inventory',
      subtitle: 'Manage products and stock',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Tile(
                label: 'New Product',
                icon: Icons.add_box_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewProductPage())),
              ),
              const SizedBox(height: 12),
              _Tile(
                label: 'New Stock',
                icon: Icons.inventory,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewStockPage())),
              ),
              const SizedBox(height: 12),
              _Tile(
                label: 'Price List',
                icon: Icons.list_alt,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceListPage())),
              ),
              const SizedBox(height: 12),
              _Tile(
                label: 'Stock Status',
                icon: Icons.bar_chart,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockStatusPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.ink),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
