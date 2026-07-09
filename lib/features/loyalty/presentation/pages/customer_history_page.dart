import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/models/local_customer.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../sales/presentation/pages/sale_receipt_page.dart';

class CustomerHistoryPage extends StatelessWidget {
  final LocalCustomer customer;

  const CustomerHistoryPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${customer.name}\'s History'),
      ),
      body: Consumer<SalesProvider>(
        builder: (context, provider, child) {
          final customerSales = provider.recentSales
              .where((sale) => sale.customerId == customer.id)
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (customerSales.isEmpty) {
            return const Center(
              child: Text('No purchase history found for this customer.'),
            );
          }

          return ListView.builder(
            itemCount: customerSales.length,
            itemBuilder: (context, index) {
              final sale = customerSales[index];
              return ListTile(
                title: Text('Sale #${sale.receiptNumber ?? sale.id.substring(0, 8)}'),
                subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp)),
                trailing: Text(
                  'USD ${sale.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SaleReceiptPage(sale: sale),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
