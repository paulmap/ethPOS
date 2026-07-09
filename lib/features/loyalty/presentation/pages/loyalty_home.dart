import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loyalty_provider.dart';
import 'add_customer_page.dart';
import 'customer_profile_page.dart';

class LoyaltyHome extends StatelessWidget {
  const LoyaltyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomerPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<LoyaltyProvider>(
        builder: (context, provider, child) {
          final customers = provider.customers;
          
          if (customers.isEmpty) {
            return const Center(child: Text('No customers registered yet.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Customers',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Search logic handled by provider or local state
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(customer.name),
                      subtitle: Text(customer.maskedPhoneNumber),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${customer.points} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerProfilePage(customer: customer),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
