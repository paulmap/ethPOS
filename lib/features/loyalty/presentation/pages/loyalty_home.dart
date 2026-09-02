import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loyalty_provider.dart';
import 'add_customer_page.dart';
import 'customer_profile_page.dart';

class LoyaltyHome extends StatefulWidget {
  const LoyaltyHome({super.key});

  @override
  State<LoyaltyHome> createState() => _LoyaltyHomeState();
}

class _LoyaltyHomeState extends State<LoyaltyHome> {
  String _searchQuery = '';

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
          if (provider.customers.isEmpty) {
            return const Center(child: Text('No customers registered yet.'));
          }

          final customers = provider.searchCustomers(_searchQuery);

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
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              if (customers.isEmpty)
                const Expanded(child: Center(child: Text('No customers match your search.')))
              else
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
