import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../../../../core/storage/models/local_product.dart';

class NewProductPage extends StatefulWidget {
  const NewProductPage({super.key});

  @override
  State<NewProductPage> createState() => _NewProductPageState();
}

class _NewProductPageState extends State<NewProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _upcController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = LocalProduct(
        id: const Uuid().v4(),
        name: _nameController.text,
        productCode: _productCodeController.text,
        sku: _skuController.text,
        category: _categoryController.text,
        description: _descriptionController.text,
        price: 0.0,
        currentStock: 0,
        barcode: _upcController.text.isNotEmpty ? _upcController.text : _productCodeController.text,
        lastUpdated: DateTime.now(),
      );
      
      context.read<InventoryProvider>().addProduct(product);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('Product Code', _productCodeController, Icons.tag),
              _buildTextField('Product Description / Name', _nameController, Icons.description),
              _buildTextField('SKU', _skuController, Icons.inventory_2),
              _buildTextField('Category', _categoryController, Icons.category),
              _buildTextField('UPC Barcode (Optional)', _upcController, Icons.qr_code_scanner),
              _buildTextField('Long Description (Optional)', _descriptionController, Icons.info_outline, maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Text('Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
      ),
    );
  }
}
