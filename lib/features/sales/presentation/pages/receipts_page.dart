import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/models/local_sale.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';
import 'sale_receipt_page.dart';

/// Receipts, newest first, grouped by day. A reprint is one tap: the counter
/// question is almost always "can I have that again", not "search my sales".
class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<LocalSale>('sales_box');

    return PosScaffold(
      title: 'Receipts',
      child: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<LocalSale> sales, _) {
          final all = sales.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No sales on this device yet.',
                  style: TextStyle(fontSize: 14, color: AppColors.mutedLight),
                ),
              ),
            );
          }

          final days = <String, List<LocalSale>>{};
          for (final sale in all) {
            days.putIfAbsent(_dayKey(sale.timestamp), () => []).add(sale);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
            children: [
              for (final entry in days.entries) ...[
                Eyebrow(entry.key.toUpperCase()),
                StackedList(
                  children: [
                    for (final sale in entry.value)
                      _ReceiptRow(sale: sale),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _dayKey(DateTime at) {
    final now = DateTime.now();
    final sameDay = at.year == now.year && at.month == now.month;
    if (sameDay && at.day == now.day) return 'Today';
    if (sameDay && at.day == now.day - 1) return 'Yesterday';
    return '${at.day.toString().padLeft(2, '0')}/'
        '${at.month.toString().padLeft(2, '0')}/${at.year}';
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.sale});

  final LocalSale sale;

  @override
  Widget build(BuildContext context) {
    final units = sale.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final time = '${sale.timestamp.hour.toString().padLeft(2, '0')}:'
        '${sale.timestamp.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleReceiptPage(sale: sale)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.receiptNumber ?? sale.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$time  ·  $units item${units == 1 ? '' : 's'}'
                  '${sale.paymentCurrency == null ? '' : '  ·  ${sale.paymentCurrency}'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Money(sale.totalAmount, size: 15),
        ],
      ),
    );
  }
}
