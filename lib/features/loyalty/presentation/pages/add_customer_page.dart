import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/models/local_customer.dart';
import '../../../../core/widgets/common/custom_button.dart';
import '../../../../core/widgets/common/custom_text_field.dart';
import '../providers/loyalty_provider.dart';

class AddCustomerPage extends StatefulWidget {
  final LocalCustomer? existingCustomer;
  const AddCustomerPage({super.key, this.existingCustomer});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _outstandingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      _nameController.text = widget.existingCustomer!.name;
      _phoneController.text = widget.existingCustomer!.phoneNumber;
      _creditLimitController.text = widget.existingCustomer!.creditLimit?.toString() ?? '';
      _birthdayController.text = widget.existingCustomer!.birthday ?? '';
      _outstandingController.text = widget.existingCustomer!.totalOutstanding?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _creditLimitController.dispose();
    _birthdayController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final loyaltyProvider = context.read<LoyaltyProvider>();
      
      if (widget.existingCustomer == null) {
        final existing = loyaltyProvider.findCustomerByPhone(_phoneController.text);
        if (existing != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer with this phone number already exists: ${existing.name}')),
          );
          return;
        }
      }

      final customer = widget.existingCustomer?.copyWith(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        creditLimit: double.tryParse(_creditLimitController.text),
        birthday: _birthdayController.text.isEmpty ? null : _birthdayController.text,
        totalOutstanding: double.tryParse(_outstandingController.text),
      ) ?? LocalCustomer(
        id: const Uuid().v4(),
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        createdAt: DateTime.now(),
        points: 0,
        creditLimit: double.tryParse(_creditLimitController.text),
        birthday: _birthdayController.text.isEmpty ? null : _birthdayController.text,
        totalOutstanding: double.tryParse(_outstandingController.text),
      );

      if (widget.existingCustomer == null) {
        await loyaltyProvider.updateCustomer(customer); // updateCustomer handles both put and refresh
      } else {
        await loyaltyProvider.updateCustomer(customer);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingCustomer == null ? 'Customer added successfully!' : 'Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCustomer == null ? 'Register Customer' : 'Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Customer Name*',
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number*',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Birthday (e.g. 12 May)',
                controller: _birthdayController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Credit Limit',
                controller: _creditLimitController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Total Outstanding',
                controller: _outstandingController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: widget.existingCustomer == null ? 'Register Customer' : 'Update Profile',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
