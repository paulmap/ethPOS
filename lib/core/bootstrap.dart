import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'ai/ai_provider.dart';
import 'ai/pos_tools.dart';
import 'session/session_provider.dart';
import 'storage/models/ai_action.dart';
import 'storage/models/local_product.dart';
import 'storage/models/local_sale.dart';
import 'storage/models/product_extras.dart';
import 'storage/models/serial_unit.dart';
import 'storage/models/shift_record.dart';
import 'storage/models/stock_bin.dart';
import '../features/inventory/presentation/providers/bin_service.dart';

/// New boxes and providers introduced by the redesign. Call [openNewBoxes]
/// after your existing Hive.initFlutter + adapter registration in main(), then
/// spread [newProviders] into the existing MultiProvider.
class PosBootstrap {
  static const staff = <Staff>[
    Staff(id: 'paul', name: 'Paul M.', role: StaffRole.assistant, pin: '1111'),
    Staff(id: 'owner', name: 'Supervisor', role: StaffRole.supervisor, pin: '0000'),
  ];

  static Future<void> openNewBoxes() async {
    Hive
      ..registerAdapter(StockBinAdapter())
      ..registerAdapter(SerialUnitAdapter())
      ..registerAdapter(ProductExtrasAdapter())
      ..registerAdapter(ShiftRecordAdapter())
      ..registerAdapter(AiActionKindAdapter())
      ..registerAdapter(AiActionAdapter());

    await Future.wait([
      Hive.openBox<StockBin>('stock_bins_box'),
      Hive.openBox<SerialUnit>('serials_box'),
      Hive.openBox<ProductExtras>('product_extras_box'),
      Hive.openBox<ShiftRecord>('shifts_box'),
      Hive.openBox<AiAction>('ai_actions_box'),
    ]);
  }

  /// Backfills bins from the old single-location fields on LocalProduct, so an
  /// existing install keeps its locations. Safe to call on every launch: it
  /// only writes when a product has no bin yet.
  static Future<int> migrateLegacyLocations() async {
    final products = Hive.box<LocalProduct>('products_box');
    final bins = Hive.box<StockBin>('stock_bins_box');
    var created = 0;

    for (final product in products.values) {
      final has = bins.values.any((b) => b.productId == product.id);
      if (has || !product.hasLocation) continue;

      final area = (product.storeArea?.isNotEmpty ?? false)
          ? product.storeArea!
          : 'Storeroom';
      final bin = [product.aisle, product.binShelf]
          .where((s) => s != null && s.isNotEmpty)
          .join('-');

      final record = StockBin(
        id: 'bin-legacy-${product.id}',
        productId: product.id,
        area: area,
        bin: bin.isEmpty ? 'B1' : bin,
        quantity: product.currentStock,
        lastUpdated: DateTime.now(),
      );
      await bins.put(record.id, record);
      created++;
    }
    return created;
  }

  static List<SingleChildWidget> newProviders() {
    final products = Hive.box<LocalProduct>('products_box');
    final bins = Hive.box<StockBin>('stock_bins_box');
    final sales = Hive.box<LocalSale>('sales_box');
    final serials = Hive.box<SerialUnit>('serials_box');
    final extras = Hive.box<ProductExtras>('product_extras_box');
    final shifts = Hive.box<ShiftRecord>('shifts_box');
    final actions = Hive.box<AiAction>('ai_actions_box');

    final session = SessionProvider(shifts: shifts, staff: staff);
    final tools = PosTools(
      products: products,
      bins: bins,
      sales: sales,
      serials: serials,
      extras: extras,
    );

    return [
      ChangeNotifierProvider<SessionProvider>.value(value: session),
      ChangeNotifierProvider<BinService>(
        create: (_) => BinService(bins: bins, actionLog: actions),
      ),
      ChangeNotifierProvider<AiProvider>(
        create: (_) {
          final ai = AiProvider(
            tools: tools,
            session: session,
            actionLog: actions,
            products: products,
          );
          // Fire and forget: reads device RAM, picks a tier, loads the model if
          // it has already been downloaded. The till never waits on this.
          getApplicationSupportDirectory().then(
            (dir) => ai.initialise(modelDirectory: '${dir.path}/models'),
          );
          return ai;
        },
      ),
    ];
  }
}
