import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../storage/models/local_product.dart';
import '../../../features/analytics/presentation/pages/reports_page.dart';
import '../../../features/assistant/presentation/pages/ai_actions_log_page.dart';
import '../../../features/inventory/presentation/pages/inventory_home.dart';
import '../../../features/inventory/presentation/pages/price_list_page.dart';
import '../../../features/inventory/presentation/pages/stock_ledger_page.dart';
import '../../../features/inventory/presentation/pages/stock_status_page.dart';
import '../../../features/sales/presentation/pages/cash_up_page.dart';
import '../../../features/sales/presentation/pages/checkout_page.dart';
import '../../../features/purchases/presentation/pages/purchase_home.dart';
import '../../../features/sales/presentation/pages/receipts_page.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import 'auth_gate.dart';

/// Every route name the redesigned screens push. Keep this the single source:
/// a tile that navigates to a name missing from here throws, which is what a
/// half-wired route table looks like from the shop floor.
Map<String, WidgetBuilder> posRoutes() => {
      '/home': (_) => const AuthGate(),
      '/scan': (_) => const CheckoutPage(),
      '/cart': (_) => const CheckoutPage(),
      '/stock': (_) => StockLedgerPage(
            products: Hive.box<LocalProduct>('products_box'),
          ),
      '/stock-status': (_) => const StockStatusPage(),
      '/inventory': (_) => const InventoryHome(),
      '/prices': (_) => const PriceListPage(),
      '/receipts': (_) => const ReceiptsPage(),
      '/reports': (_) => const ReportsPage(),
      '/purchases': (_) => const PurchaseHome(),
      '/cash-up': (_) => const CashUpPage(
            expectedCash: 0,
            mobileMoneyTotal: 0,
            cardTotal: 0,
          ),
      '/ai-log': (_) => const AiActionsLogPage(),
      '/settings': (_) => const SettingsPage(),
    };
