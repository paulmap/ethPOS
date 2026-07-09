import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/storage/models/app_settings.dart';

class InventoryProvider extends ChangeNotifier {
  final Box<LocalProduct> _productsBox;
  final Box<AppSettings> _settingsBox;
  
  InventoryProvider() 
    : _productsBox = Hive.box<LocalProduct>('products_box'),
      _settingsBox = Hive.box<AppSettings>('settings_box');
  
  List<LocalProduct> get products => _productsBox.values.where((p) => !(p.isDiscontinued ?? false)).toList();
  List<LocalProduct> get allProducts => _productsBox.values.toList();
  
  AppSettings get settings => _settingsBox.get('current_settings') ?? AppSettings();
  
  Future<void> updateSettings(AppSettings newSettings) async {
    await _settingsBox.put('current_settings', newSettings);
    notifyListeners();
  }
  
  List<LocalProduct> get lowStockItems => _productsBox.values
      .where((p) => p.currentStock < 5)
      .toList();
      
  Future<void> addProduct(LocalProduct product) async {
    await _productsBox.put(product.id, product);
    notifyListeners();
  }
  
  Future<void> updateStock(String id, int quantityAdded) async {
    final product = _productsBox.get(id);
    if (product != null) {
      final updated = product.copyWith(
        currentStock: product.currentStock + quantityAdded,
        lastUpdated: DateTime.now(),
      );
      await _productsBox.put(id, updated);
      notifyListeners();
    }
  }

  Future<void> updateProduct(LocalProduct product) async {
    await _productsBox.put(product.id, product);
    notifyListeners();
  }

  Future<void> discontinueProduct(String id) async {
    final product = _productsBox.get(id);
    if (product != null) {
      await _productsBox.put(id, product.copyWith(isDiscontinued: true));
      notifyListeners();
    }
  }

  double getExchangeRate(String currency) {
    return settings.exchangeRates[currency] ?? 1.0;
  }

  double convertToUSD(double amount, String fromCurrency) {
    // Exchange rates are relative to USD (1 USD = X Currency)
    final rate = getExchangeRate(fromCurrency);
    return amount / rate;
  }

  double convertToCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    final usdAmount = convertToUSD(amount, fromCurrency);
    final targetRate = getExchangeRate(toCurrency);
    return usdAmount * targetRate;
  }
}
