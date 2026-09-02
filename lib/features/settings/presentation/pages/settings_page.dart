import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  
  // Sequence Settings
  late TextEditingController _rcptPrefixController;
  late TextEditingController _rcptStartController;
  late TextEditingController _invPrefixController;
  late TextEditingController _invStartController;
  late TextEditingController _poPrefixController;
  late TextEditingController _poStartController;
  
  // General UI
  late TextEditingController _taglineController;
  late List<String> _taxCategories;
  final TextEditingController _newTaxCategoryController = TextEditingController();
  late TextEditingController _minPointsForRedemptionController;

  // AI Assistant
  late TextEditingController _assistantBaseUrlController;
  late TextEditingController _assistantApiKeyController;
  late bool _assistantEnabled;

  @override
  void initState() {
    super.initState();
    final settings = context.read<InventoryProvider>().settings;
    _businessNameController = TextEditingController(text: settings.effectiveBusinessName);
    _cityController = TextEditingController(text: settings.effectiveCity);
    _countryController = TextEditingController(text: settings.effectiveCountry);
    _emailController = TextEditingController(text: settings.effectiveEmail);
    _contactController = TextEditingController(text: settings.effectiveContactNumber);
    
    _rcptPrefixController = TextEditingController(text: settings.effectiveReceiptPrefix);
    _rcptStartController = TextEditingController(text: settings.effectiveReceiptStartNumber.toString());
    _invPrefixController = TextEditingController(text: settings.effectiveInvoicePrefix);
    _invStartController = TextEditingController(text: settings.effectiveInvoiceStartNumber.toString());
    _poPrefixController = TextEditingController(text: settings.effectivePoPrefix);
    _poStartController = TextEditingController(text: settings.effectivePoStartNumber.toString());
    
    _taglineController = TextEditingController(text: settings.effectiveReceiptTagline);
    _taxCategories = List.from(settings.effectiveTaxCategories);
    _minPointsForRedemptionController = TextEditingController(text: settings.effectiveMinPointsForRedemption.toString());
    _assistantBaseUrlController = TextEditingController(text: settings.effectiveAssistantBaseUrl);
    _assistantApiKeyController = TextEditingController(text: settings.effectiveAssistantApiKey);
    _assistantEnabled = settings.effectiveAssistantEnabled;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _rcptPrefixController.dispose();
    _rcptStartController.dispose();
    _invPrefixController.dispose();
    _invStartController.dispose();
    _poPrefixController.dispose();
    _poStartController.dispose();
    _taglineController.dispose();
    _newTaxCategoryController.dispose();
    _minPointsForRedemptionController.dispose();
    _assistantBaseUrlController.dispose();
    _assistantApiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InventoryProvider>();
      final updatedSettings = provider.settings.copyWith(
        businessName: _businessNameController.text,
        city: _cityController.text,
        country: _countryController.text,
        email: _emailController.text,
        contactNumber: _contactController.text,
        receiptPrefix: _rcptPrefixController.text,
        receiptStartNumber: int.tryParse(_rcptStartController.text) ?? 1,
        invoicePrefix: _invPrefixController.text,
        invoiceStartNumber: int.tryParse(_invStartController.text) ?? 1,
        poPrefix: _poPrefixController.text,
        poStartNumber: int.tryParse(_poStartController.text) ?? 1,
        receiptTagline: _taglineController.text,
        taxCategories: _taxCategories,
        minPointsForRedemption: int.tryParse(_minPointsForRedemptionController.text) ?? 100,
        assistantBaseUrl: _assistantBaseUrlController.text,
        assistantApiKey: _assistantApiKeyController.text,
        assistantEnabled: _assistantEnabled,
      );
      provider.updateSettings(updatedSettings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  void _generateApiKey() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    setState(() => _assistantApiKeyController.text = base64Url.encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Company Information'),
              const SizedBox(height: 10),
              _buildTextField('Business Name', _businessNameController, Icons.business),
              _buildTextField('City', _cityController, Icons.location_city),
              _buildTextField('Country', _countryController, Icons.public),
              _buildTextField('Email Address', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextField('Contact Number', _contactController, Icons.phone, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 20),
              _buildSectionHeader('Sequence Settings'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField('Receipt Prefix', _rcptPrefixController, Icons.tag)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Start No.', _rcptStartController, Icons.format_list_numbered, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField('Invoice Prefix', _invPrefixController, Icons.description)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Start No.', _invStartController, Icons.format_list_numbered, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField('PO Prefix', _poPrefixController, Icons.shopping_cart)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Start No.', _poStartController, Icons.format_list_numbered, keyboardType: TextInputType.number)),
                ],
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('Receipt Settings'),
              const SizedBox(height: 10),
              _buildTextField('Receipt Tagline', _taglineController, Icons.message),
              
              const SizedBox(height: 20),
              _buildSectionHeader('Tax Categories'),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _taxCategories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_taxCategories[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _taxCategories.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTaxCategoryController,
                      decoration: const InputDecoration(
                        hintText: 'New Tax Category (e.g. VAT 15%)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                    onPressed: () {
                      if (_newTaxCategoryController.text.isNotEmpty) {
                        setState(() {
                          _taxCategories.add(_newTaxCategoryController.text);
                          _newTaxCategoryController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              _buildSectionHeader('Loyalty Program'),
              const SizedBox(height: 10),
              _buildTextField(
                'Minimum Points to Redeem',
                _minPointsForRedemptionController,
                Icons.card_giftcard,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('AI Assistant'),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable AI Assistant'),
                subtitle: const Text('Requires a self-hosted backend URL and API key'),
                value: _assistantEnabled,
                onChanged: (v) => setState(() => _assistantEnabled = v),
              ),
              _buildTextField(
                'Backend URL',
                _assistantBaseUrlController,
                Icons.dns,
                keyboardType: TextInputType.url,
                required: false,
              ),
              _buildTextField(
                'API Key',
                _assistantApiKeyController,
                Icons.vpn_key,
                required: false,
                suffixIcon: TextButton(
                  onPressed: _generateApiKey,
                  child: const Text('Generate'),
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = true,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        keyboardType: keyboardType,
        validator: required ? (value) => value == null || value.isEmpty ? 'Field cannot be empty' : null : null,
      ),
    );
  }
}
