import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/widgets/common/scanner/barcode_scanner_widget.dart';

class NewProductPage extends StatefulWidget {
  const NewProductPage({super.key});

  @override
  State<NewProductPage> createState() => _NewProductPageState();
}

class _NewProductPageState extends State<NewProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _upcController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _compatibleTagsController = TextEditingController();

  List<String>? _parseTags(String text) {
    final tags = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return tags.isEmpty ? null : tags;
  }

  Future<void> _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scannerCtx) => BarcodeScannerWidget(
          onDetect: (code) {
            _upcController.text = code;
            Navigator.pop(scannerCtx);
          },
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = LocalProduct(
        id: const Uuid().v4(),
        name: _nameController.text,
        sku: _skuController.text,
        category: _categoryController.text,
        description: _descriptionController.text,
        price: 0.0,
        currentStock: 0,
        barcode: _upcController.text.isNotEmpty ? _upcController.text : _skuController.text,
        compatibleTags: _parseTags(_compatibleTagsController.text),
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
              _buildTextField('Product Description / Name', _nameController, Icons.description),
              _buildTextField('SKU', _skuController, Icons.inventory_2),
              _buildTextField('Category', _categoryController, Icons.category),
              _buildTextField(
                'UPC Barcode (Optional)',
                _upcController,
                Icons.qr_code_scanner,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Scan barcode',
                  onPressed: _scanBarcode,
                ),
              ),
              _buildTextField('Long Description (Optional)', _descriptionController, Icons.info_outline, maxLines: 3),
              _buildTextField(
                'Compatibility Tags (Optional — e.g. iPhone 12, iPhone 13)',
                _compatibleTagsController,
                Icons.link,
                required: false,
              ),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, Widget? suffixIcon, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: required ? (value) => value == null || value.isEmpty ? 'Field required' : null : null,
      ),
    );
  }
}
