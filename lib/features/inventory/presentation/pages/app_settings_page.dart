import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/storage/models/app_settings.dart';
import '../../../../core/widgets/common/custom_button.dart';
import '../providers/inventory_provider.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late String _baseCurrency;
  late Map<String, TextEditingController> _rateControllers;
  final List<String> _currencies = ['USD', 'ZWL', 'ZAR', 'BP'];

  @override
  void initState() {
    super.initState();
    final settings = context.read<InventoryProvider>().settings;
    _baseCurrency = settings.baseCurrency;
    _rateControllers = {};
    for (final curr in _currencies) {
      _rateControllers[curr] = TextEditingController(
        text: settings.exchangeRates[curr]?.toString() ?? '1.0',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() async {
    final rates = <String, double>{};
    for (final curr in _currencies) {
      rates[curr] = double.tryParse(_rateControllers[curr]!.text) ?? 1.0;
    }

    final newSettings = AppSettings(
      baseCurrency: _baseCurrency,
      exchangeRates: rates,
    );

    await context.read<InventoryProvider>().updateSettings(newSettings);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loyalty Base Currency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'All loyalty points will be calculated based on this currency.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _baseCurrency,
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _baseCurrency = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            const Text(
              'Exchange Rates (Relative to USD)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Enter many units per 1 USD (e.g., 2500 ZWL = 1 USD)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._currencies.map((curr) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Text(curr, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                      child: TextField(
                        controller: _rateControllers[curr],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Save Settings',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
