import 'package:flutter/material.dart';
import '../../../../core/storage/models/local_customer.dart';
import 'add_customer_page.dart';
import 'customer_history_page.dart';

class CustomerProfilePage extends StatelessWidget {
  final LocalCustomer customer;

  const CustomerProfilePage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer profile'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('ADD TO RECEIPT', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar and Name
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              child: Text(
                customer.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              customer.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Details List
            _buildDetailTile(Icons.phone, customer.phoneNumber),
            _buildDetailTile(Icons.qr_code, customer.id.substring(0, 12).toUpperCase()),
            const Divider(),
            _buildDetailTile(Icons.star, '${customer.points}', subtitle: 'Points'),
            _buildDetailTile(Icons.speed, customer.creditLimit?.toStringAsFixed(2) ?? 'N/A', subtitle: 'Credit limit'),
            _buildDetailTile(Icons.cake, customer.birthday ?? '-', subtitle: 'Birthday'),
            _buildDetailTile(Icons.currency_yen, customer.totalOutstanding?.toStringAsFixed(2) ?? '0.00', subtitle: 'Total outstanding'),
            
            const SizedBox(height: 20),
            
            // Actions
            _buildActionLink('MORE INFO', () {}),
            _buildActionLink('EDIT PROFILE', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerPage(existingCustomer: customer),
                ),
              );
            }),
            _buildActionLink('REDEEM POINTS', () {}),
            _buildActionLink('GENERATE NFC', () {}),
            _buildActionLink('VIEW PURCHASE HISTORY', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerHistoryPage(customer: customer),
                ),
              );
            }),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      dense: true,
    );
  }

  Widget _buildActionLink(String label, VoidCallback onTap) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.indigo,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
