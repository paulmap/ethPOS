import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/widgets/common/custom_button.dart';
import '../../../../core/widgets/common/custom_text_field.dart';
import '../providers/inventory_provider.dart';

class EditProductPage extends StatefulWidget {
  final LocalProduct? product;
  final String? initialBarcode;

  const EditProductPage({super.key, this.product, this.initialBarcode});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _barcodeController;
  late String _selectedCurrency;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _minStockController;
  late TextEditingController _reorderLevelController;
  late TextEditingController _costPriceController;
  late TextEditingController _markupController;
  late TextEditingController _storeAreaController;
  late TextEditingController _aisleController;
  late TextEditingController _binShelfController;
  late TextEditingController _compatibleTagsController;

  final List<String> _currencies = ['USD', 'ZWL', 'ZAR', 'BP'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.currentStock.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? widget.initialBarcode ?? '');
    _selectedCurrency = widget.product?.currency ?? 'USD';
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _minStockController = TextEditingController(text: widget.product?.minStockHolding?.toString() ?? '0');
    _reorderLevelController = TextEditingController(text: widget.product?.reorderLevel?.toString() ?? '5');
    _costPriceController = TextEditingController(text: widget.product?.costPrice?.toString() ?? '0.0');
    _markupController = TextEditingController(text: widget.product?.markup?.toString() ?? '0.0');
    _storeAreaController = TextEditingController(text: widget.product?.storeArea ?? '');
    _aisleController = TextEditingController(text: widget.product?.aisle ?? '');
    _binShelfController = TextEditingController(text: widget.product?.binShelf ?? '');
    _compatibleTagsController = TextEditingController(text: widget.product?.compatibleTags?.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _minStockController.dispose();
    _reorderLevelController.dispose();
    _costPriceController.dispose();
    _markupController.dispose();
    _storeAreaController.dispose();
    _aisleController.dispose();
    _binShelfController.dispose();
    _compatibleTagsController.dispose();
    super.dispose();
  }

  String? _emptyToNull(String text) => text.isEmpty ? null : text;

  List<String>? _parseTags(String text) {
    final tags = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return tags.isEmpty ? null : tags;
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InventoryProvider>();
      final isEditing = widget.product != null;

      final updatedProduct = LocalProduct(
        id: isEditing ? widget.product!.id : const Uuid().v4(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        currentStock: int.parse(_stockController.text),
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        sku: _skuController.text,
        category: _categoryController.text,
        description: _descriptionController.text,
        minStockHolding: int.tryParse(_minStockController.text),
        reorderLevel: int.tryParse(_reorderLevelController.text),
        costPrice: double.tryParse(_costPriceController.text),
        markup: double.tryParse(_markupController.text),
        storeArea: isEditing ? widget.product!.storeArea : _emptyToNull(_storeAreaController.text),
        aisle: isEditing ? widget.product!.aisle : _emptyToNull(_aisleController.text),
        binShelf: isEditing ? widget.product!.binShelf : _emptyToNull(_binShelfController.text),
        compatibleTags: _parseTags(_compatibleTagsController.text),
        currency: _selectedCurrency,
        lastUpdated: DateTime.now(),
        isDiscontinued: widget.product?.isDiscontinued ?? false,
      );

      if (isEditing) {
        await provider.updateProduct(updatedProduct);
      } else {
        await provider.addProduct(updatedProduct);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Product updated' : 'Product added')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Product Name',
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Price',
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null,
                      readOnly: isEditing,
                      helperText: isEditing ? 'Change from Price List (Admin PIN)' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                      child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: isEditing ? null : (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Current Stock',
                controller: _stockController,
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v!) == null ? 'Invalid' : null,
                readOnly: isEditing,
                helperText: isEditing ? 'Adjust via New Stock (Receive)' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Barcode (Optional)',
                controller: _barcodeController,
              ),
              const SizedBox(height: 16),
              if (isEditing)
                CustomTextField(
                  label: 'Location',
                  controller: TextEditingController(text: widget.product!.locationCode),
                  readOnly: true,
                  helperText: 'Move via Transfer Location (Stock page)',
                )
              else ...[
                const Text('Location (Optional)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Store/Area',
                        controller: _storeAreaController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Aisle',
                        controller: _aisleController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Bin/Shelf',
                        controller: _binShelfController,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Compatibility Tags (Optional — e.g. iPhone 12, iPhone 13)',
                controller: _compatibleTagsController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'SKU',
                controller: _skuController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Category',
                controller: _categoryController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Min Stock',
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Reorder Level',
                      controller: _reorderLevelController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Cost Price',
                      controller: _costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: isEditing,
                      helperText: isEditing ? 'Set via New Stock (Receive)' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Markup %',
                      controller: _markupController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: isEditing,
                      helperText: isEditing ? 'Change from Price List (Admin PIN)' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Product',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
