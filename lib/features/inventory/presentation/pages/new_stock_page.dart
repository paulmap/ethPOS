import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../../../suppliers/presentation/providers/supplier_provider.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/storage/models/local_supplier.dart';
import 'package:intl/intl.dart';

class NewStockPage extends StatefulWidget {
  const NewStockPage({super.key});

  @override
  State<NewStockPage> createState() => _NewStockPageState();
}

class _NewStockPageState extends State<NewStockPage> {
  final _formKey = GlobalKey<FormState>();
  LocalProduct? _selectedProduct;
  LocalSupplier? _selectedSupplier;
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _poController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _minStockController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'ZWL', 'ZAR', 'BP'];

  void _saveStock() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final updatedProduct = _selectedProduct!.copyWith(
        currentStock: _selectedProduct!.currentStock + (int.tryParse(_quantityController.text) ?? 0),
        costPrice: double.tryParse(_costController.text),
        minStockHolding: int.tryParse(_minStockController.text),
        reorderLevel: int.tryParse(_reorderLevelController.text),
        lastUpdated: DateTime.now(),
      );
      
      context.read<InventoryProvider>().updateProduct(updatedProduct);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock received successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Stock (Receive)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductSelector(),
              const SizedBox(height: 16),
              _buildSupplierSelector(),
              const SizedBox(height: 16),
              _buildTextField('Date', _dateController, Icons.calendar_today, readOnly: true, onTap: () => _selectDate(context)),
              _buildTextField('Purchase Order #', _poController, Icons.receipt),
              _buildTextField('Quantity Received', _quantityController, Icons.add_shopping_cart, keyboardType: TextInputType.number),
              Row(
                children: [
                   Expanded(
                     flex: 2,
                     child: _buildTextField('Cost Price', _costController, Icons.payments, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Padding(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: DropdownButtonFormField<String>(
                         initialValue: _selectedCurrency,
                         decoration: InputDecoration(
                           labelText: 'Curr',
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                         ),
                         items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                         onChanged: (val) => setState(() => _selectedCurrency = val!),
                       ),
                     ),
                   ),
                ],
              ),
              _buildTextField('Minimum Stock Holding', _minStockController, Icons.warning_amber, keyboardType: TextInputType.number),
              _buildTextField('Reorder Level', _reorderLevelController, Icons.reorder, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveStock,
                  child: const Text('Receive Stock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<LocalProduct>(
          initialValue: _selectedProduct,
          decoration: InputDecoration(
            labelText: 'Select Product',
            prefixIcon: const Icon(Icons.inventory_2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          isExpanded: true,
          items: provider.products.map((p) => DropdownMenuItem(
            value: p,
            child: Text(p.name),
          )).toList(),
          onChanged: (val) {
             setState(() {
               _selectedProduct = val;
               if (val != null) {
                 _costController.text = val.effectiveCostPrice.toString();
                 _minStockController.text = val.effectiveMinStock.toString();
                 _reorderLevelController.text = val.effectiveReorderLevel.toString();
               }
             });
          },
          validator: (val) => val == null ? 'Select a product' : null,
        );
      },
    );
  }

  Widget _buildSupplierSelector() {
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<LocalSupplier>(
          initialValue: _selectedSupplier,
          decoration: InputDecoration(
            labelText: 'Select Supplier',
            prefixIcon: const Icon(Icons.local_shipping),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: provider.suppliers.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.name),
          )).toList(),
          onChanged: (val) => setState(() => _selectedSupplier = val),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
}
