import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/models/local_supplier.dart';
import '../providers/supplier_provider.dart';

class SupplierHome extends StatelessWidget {
  const SupplierHome({super.key});

  void _showSupplierDialog(BuildContext context, [LocalSupplier? existingSupplier]) {
    final nameController = TextEditingController(text: existingSupplier?.name);
    final contactController = TextEditingController(text: existingSupplier?.contactPerson);
    final phoneController = TextEditingController(text: existingSupplier?.phoneNumber);
    final emailController = TextEditingController(text: existingSupplier?.email);
    final addressController = TextEditingController(text: existingSupplier?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingSupplier == null ? 'Add New Supplier' : 'Edit Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Business Name')),
              TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact Person')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final supplier = LocalSupplier(
                  id: existingSupplier?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  contactPerson: contactController.text,
                  phoneNumber: phoneController.text,
                  email: emailController.text,
                  address: addressController.text,
                );
                
                if (existingSupplier == null) {
                  context.read<SupplierProvider>().addSupplier(supplier);
                } else {
                  context.read<SupplierProvider>().updateSupplier(supplier);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, child) {
          final suppliers = provider.suppliers;
          if (suppliers.isEmpty) {
            return const Center(child: Text('No suppliers found.\nTap + to add one.', textAlign: TextAlign.center));
          }
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(supplier.name[0])),
                title: Text(supplier.name),
                subtitle: Text(supplier.contactPerson ?? 'No contact person'),
                trailing: Text(supplier.phoneNumber ?? ''),
                onTap: () => _showSupplierDialog(context, supplier),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
