# Runbook — getting the redesign onto your phone

Written against your actual repo: \`ethpos\`, Dart SDK ^3.11.0, and the
\`main.dart\` you have today. Every dependency you need is already in
\`pubspec.yaml\` except the font.

Work through this in order. Steps 1–6 get it compiling; step 7 puts it on the
device; step 8 is the AI model, which is optional at first — the app answers
questions correctly without it.

---

## 0. Before you touch anything

\`\`\`bash
cd ~/path/to/ethPOS
git status                       # make sure you're clean
git checkout -b redesign
\`\`\`

If you are not using git, copy the whole folder somewhere safe. Step 3 changes
\`main.dart\`, and step 2 regenerates files.

---

## 1. Copy the files in

Unzip the download. Inside it, \`lib/\` mirrors your own \`lib/\`, so the
paths already line up:

\`\`\`bash
cp -R ~/Downloads/flutter/lib/. ./lib/
\`\`\`

This **overwrites two files**:

- \`lib/core/themes/colors.dart\`
- \`lib/core/themes/app_theme.dart\`

Both are intentional — that is the new paper/ink/AI-blue look. Everything else
is new files, nothing else of yours is touched.

Sanity check:

\`\`\`bash
ls lib/core/ai lib/core/session lib/core/widgets/pos
\`\`\`

You should see \`ai_provider.dart\`, \`session_provider.dart\`,
\`command_bar.dart\` and friends.

---

## 2. Add the font, then generate the Hive adapters

**Font.** Download Archivo from Google Fonts, and put three files in
\`assets/fonts/\`: \`Archivo-Regular.ttf\`, \`Archivo-Medium.ttf\`,
\`Archivo-SemiBold.ttf\`.

Then in \`pubspec.yaml\`, under the existing \`flutter:\` section (right
after your \`assets:\` list, at the same indent as \`assets:\`) add:

\`\`\`yaml
  fonts:
    - family: Archivo
      fonts:
        - asset: assets/fonts/Archivo-Regular.ttf
        - asset: assets/fonts/Archivo-Medium.ttf
          weight: 500
        - asset: assets/fonts/Archivo-SemiBold.ttf
          weight: 600

Skipping the font is fine for a first run — open
\`lib/core/themes/app_theme.dart\` and change
\`const String kFontFamily = 'Archivo';\` to \`= '';\`, and it falls back
to the platform sans.

**Adapters.** Five new Hive models need their \`.g.dart\` files:

\`\`\`bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
\`\`\`

This takes a minute or two. When it finishes you should have five new files
beside the models:

\`\`\`bash
ls lib/core/storage/models/*.g.dart
# ... stock_bin.g.dart serial_unit.g.dart product_extras.g.dart
#     shift_record.g.dart ai_action.g.dart
\`\`\`

If build_runner errors with a typeId clash, open the model it names and change
its \`@HiveType(typeId: …)\` to a free number, then rerun. The new models
claim 20–25; your existing ones use 0–8.

---

## 3. Replace main.dart

Your current \`main.dart\` opens six boxes and registers six providers. Here
it is with the new pieces folded in — replace the whole file:

\`\`\`dart
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
import 'core/widgets/pos/home_page.dart';
import 'features/assistant/presentation/pages/ai_actions_log_page.dart';
import 'features/inventory/presentation/pages/stock_ledger_page.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/sales/presentation/pages/cash_up_page.dart';
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

  // Backfills bins from your existing storeArea/aisle/binShelf fields.
  // Safe to leave in permanently: it only writes where a product has no bin.
  final migrated = await PosBootstrap.migrateLegacyLocations();
  debugPrint('Backfilled \$migrated stock bins');

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
      child: const VendorVaultApp(),
    ),
  );
}

class VendorVaultApp extends StatelessWidget {
  const VendorVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ethPOS',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
      routes: {
        '/home': (_) => const HomePage(),
        '/stock': (_) => StockLedgerPage(
              products: Hive.box<LocalProduct>('products_box'),
            ),
        '/cash-up': (_) => const CashUpPage(
              expectedCash: 0,
              mobileMoneyTotal: 0,
              cardTotal: 0,
            ),
        '/ai-log': (_) => const AiActionsLogPage(),
      },
    );
  }
}
\`\`\`

Two notes on this file:

- \`home:\` now points at the new \`HomePage\`, not \`MainHomeView\`.
  Your old shell is untouched — if you want to get back to it while you
  transition, add \`'/old': (_) => const MainHomeView(),\` to \`routes\`.
- You now have two AI providers: your existing \`AiAssistantProvider\` and the
  new \`AiProvider\`. That is fine while you migrate. Once the new one is
  doing the work, delete the old one and its chat page.

The \`/inventory\`, \`/scan\`, \`/receipts\`, \`/reports\`,
\`/scanner\` and \`/product/edit\` routes are referenced by the new
screens but not defined yet — point them at your existing pages, or leave them
and expect a "route not found" if you tap those tiles. Quickest fix:

\`\`\`dart
'/inventory': (_) => const InventoryHome(),   // your existing page
'/scan': (_) => const CheckoutPage(),          // your existing page
\`\`\`

---

## 4. Set your real staff PINs

Open \`lib/core/bootstrap.dart\`. At the top:

\`\`\`dart
static const staff = <Staff>[
  Staff(id: 'tendai', name: 'Tendai M.', role: StaffRole.assistant, pin: '1234'),
  Staff(id: 'owner', name: 'Supervisor', role: StaffRole.supervisor, pin: '9012'),
];
\`\`\`

Change the names and PINs to yours. **These are plain text** — fine for a proof
of concept on your own device, not fine for a real shop. Hash them before anyone
else uses it.

Remember the supervisor PIN: it is what reveals takings, margin and the insight
feed when you tap the padlock.

---

## 5. Make it compile

\`\`\`bash
flutter analyze
\`\`\`

Expect a handful of complaints on the first pass. The likely ones and what they
mean:

| Error | Fix |
|---|---|
| \`Undefined name 'InventoryHome'\` etc. in main.dart | you added a route to a page you didn't import — add the import, or drop the route |
| \`The method 'DropdownButtonFormField.initialValue' isn't defined\` | older Flutter — change \`initialValue:\` to \`value:\` in \`product_detail_page.dart\` |
| \`Target of URI doesn't exist: 'stock_bin.g.dart'\` | step 2's build_runner didn't finish — rerun it |
| \`LocalSale.customerId isn't defined\` | your sale model names it differently; open \`lib/core/ai/pos_tools.dart\` and match your field name |
| \`LocalSale.totalAmount isn't defined\` | same — check your \`local_sale.dart\` and rename in \`pos_tools.dart\` |

Those last two are the ones I'd most expect: \`pos_tools.dart\` reads
\`sale.timestamp\`, \`sale.totalAmount\`, \`sale.items\`,
\`item.productId\`, \`item.quantity\`, \`item.price\` and
\`sale.customerId\`. If your \`LocalSale\` spells any of those
differently, fix them there — it is the only file that touches sale internals.

Loop \`flutter analyze\` until it's clean.

---

## 6. Run it on your desktop first

Faster than deploying, and catches everything except camera and RAM detection:

\`\`\`bash
flutter run -d macos      # or -d windows, -d linux, -d chrome
\`\`\`

What you should see: the assistant home — a big blue **New sale** block, four
tiles, a command bar at the bottom, and **no money figures anywhere**. Tap the
padlock, enter your supervisor PIN, and the same screen becomes the insight
feed with takings, margin and reorder cards.

Then try the command bar. Type "where is the usb cable" or "what should I
reorder". You'll get a real answer computed from your Hive data even with no
model installed — that is the deterministic fallback doing the work.

Ask "how much have we made today" as an assistant (lock the padlock first) and
it should refuse and offer the PIN. That's the confidentiality rule working.

---

## 7. Onto the phone

Plug in the phone with USB debugging on (Settings → About → tap Build number
seven times → Developer options → USB debugging). Then:

\`\`\`bash
flutter devices                  # confirm your phone is listed
flutter run -d <device-id>       # debug build, hot reload works
\`\`\`

For a build you can leave on the phone and use without the cable:

\`\`\`bash
flutter build apk --release
flutter install --release
\`\`\`

Or build a smaller APK for just your phone's architecture:

\`\`\`bash
flutter build apk --release --target-platform android-arm64
# lands in build/app/outputs/flutter-apk/app-release.apk
\`\`\`

Note your \`android/app/build.gradle.kts\` still signs release with the debug
key. Fine for your own device and for a demo; you'd need a real keystore to
distribute it.

On the phone, check two things the desktop can't show you: the camera scanner
still works, and RAM detection returns a real number. To see the tier it picked,
add this temporarily to any screen:

\`\`\`dart
final ai = context.read<AiProvider>();
debugPrint('RAM \${ai.ramMb} MB → \${ai.spec.name}');
\`\`\`

On a 4 GB phone that should print \`Gemma 2 2B\`.

---

## 8. The on-device model (optional, do it last)

Everything above works without a model. When you're ready:

**Pick a plugin.** \`flutter_gemma\` is the least work — it wraps MediaPipe
LLM Inference and takes \`.task\` model files.
\`fllama\` gives you llama.cpp and GGUF but more setup. Add it to
\`pubspec.yaml\`.

**Bind the two TODOs.** In \`lib/core/ai/llm_runtime.dart\`, class
\`OnDeviceRuntime\`, there are two \`TODO(plugin)\` lines — one in
\`load()\`, one in \`complete()\`. For flutter_gemma they become roughly:

\`\`\`dart
// load()
_model = await FlutterGemmaPlugin.instance.createModel(
  modelType: ModelType.gemmaIt,
  maxTokens: 1024,
);
_session = await _model.createSession();

// complete()
await _session.addQueryChunk(Message.text(text: prompt));
final text = await _session.getResponse();
\`\`\`

Nothing else in the app changes — every caller goes through
\`LlmRuntime.complete\`.

**Get the model onto the device.** It needs to land in
\`{applicationSupportDirectory}/models/\` with the filename from
\`DeviceTier.recommended().fileName\`. For testing, push it directly:

\`\`\`bash
adb shell run-as com.ethpos.ethpos mkdir -p files/models
adb push gemma-2-2b-it-q4_k_m.gguf /data/local/tmp/
adb shell run-as com.ethpos.ethpos cp /data/local/tmp/gemma-2-2b-it-q4_k_m.gguf files/models/
\`\`\`

For real use, build the download into the first-launch screen instead.

**Expect it to be slow the first time.** A 2B model on a 4 GB phone takes a few
seconds per answer, and the first call after launch is the slowest. That is why
the thinking state shows what it is doing, and why the numbers are computed in
Dart rather than by the model.

---

## What to expect the first time you open it with real data

- If your products have \`storeArea\`/\`aisle\`/\`binShelf\` set, the
  migration turns each into one bin holding the full stock count. Products with
  no location get no bin and show "Unassigned" in the ledger.
- Split a product across bins from its detail screen: add a second bin, then use
  **Move stock**.
- Serials and warranties are empty until you set \`ProductExtras\` on a
  product (\`serialised: true\`, \`warrantyMonths: 12\`). Nothing asks for
  a serial until you do.
- The AI actions log is empty until something acts. Call
  \`context.read<AiProvider>().refreshReorderPoints()\` once to see it
  populate — it recomputes reorder points from your sales history and logs each
  change with an undo.

---

## If you get stuck

Tell me the exact error text from \`flutter analyze\` or the red screen, and
which step you were on. The most likely sticking point is step 5 — field names
on \`LocalSale\` — and that is a five-minute fix in one file.
