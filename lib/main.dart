import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/bootstrap.dart';
import 'core/themes/app_theme.dart';
import 'core/storage/models/local_product.dart';
import 'core/storage/models/local_sale.dart';
import 'core/storage/models/local_customer.dart';
import 'core/storage/models/local_supplier.dart';
import 'core/storage/models/local_purchase.dart';
import 'core/storage/models/app_settings.dart';
import 'core/widgets/pos/auth_gate.dart';
import 'core/widgets/pos/pos_routes.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/sales/presentation/providers/sales_provider.dart';
import 'features/loyalty/presentation/providers/loyalty_provider.dart';
import 'features/suppliers/presentation/providers/supplier_provider.dart';
import 'features/purchases/presentation/providers/purchase_provider.dart';
import 'features/assistant/presentation/providers/ai_assistant_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Existing adapters
  Hive.registerAdapter(LocalProductAdapter());
  Hive.registerAdapter(LocalSaleItemAdapter());
  Hive.registerAdapter(LocalSaleAdapter());
  Hive.registerAdapter(LocalCustomerAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(LocalSupplierAdapter());
  Hive.registerAdapter(LocalPurchaseItemAdapter());
  Hive.registerAdapter(LocalPurchaseAdapter());

  // Existing boxes
  await Hive.openBox<LocalProduct>('products_box');
  await Hive.openBox<LocalSale>('sales_box');
  await Hive.openBox<LocalCustomer>('customers_box');
  await Hive.openBox<AppSettings>('settings_box');
  await Hive.openBox<LocalSupplier>('suppliers_box');
  await Hive.openBox<LocalPurchase>('purchases_box');

  // New: bins, serials, extras, shifts, AI action log
  await PosBootstrap.openNewBoxes();
  await PosBootstrap.migrateLegacyLocations();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
        ...PosBootstrap.newProviders(),
      ],
      child: const EthPosApp(),
    ),
  );
}

class EthPosApp extends StatelessWidget {
  const EthPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ethPOS',
      theme: AppTheme.lightTheme,
      // Sign-in gate, not the till: HomePage is only reached once a staff
      // member has entered their PIN.
      home: const AuthGate(),
      routes: posRoutes(),
    );
  }
}
