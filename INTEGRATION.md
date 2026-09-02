# ethPOS redesign — integration guide

These files are additive. Nothing in your existing `lib/` is deleted, and
`LocalProduct` (typeId 0) is **not** modified, so there is no risky Hive
migration on your product data.

Copy `flutter/lib/**` into your repo's `lib/**` (paths already match), then
work through the five steps below.

---

## 1. Dependencies

```yaml
dependencies:
  path_provider: ^2.1.4        # model directory
  # already present: hive, hive_flutter, provider, mobile_scanner, pdf

flutter:
  fonts:
    - family: Archivo
      fonts:
        - asset: assets/fonts/Archivo-Regular.ttf
        - asset: assets/fonts/Archivo-Medium.ttf
          weight: 500
        - asset: assets/fonts/Archivo-SemiBold.ttf
          weight: 600
```

Drop the Archivo TTFs into `assets/fonts/`, or delete `fontFamily` from
`app_theme.dart` to fall back to the platform sans.

## 2. Generate the Hive adapters

Five new models were added. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

New typeIds used: **20** StockBin, **21** SerialUnit, **22** ProductExtras,
**23** ShiftRecord, **24** AiActionKind, **25** AiAction. If you have taken any
of these, change them before generating.

## 3. Wire main.dart

```dart
await Hive.initFlutter();
// ... your existing adapter registrations and box opens ...
await PosBootstrap.openNewBoxes();
await PosBootstrap.migrateLegacyLocations();   // backfills bins from storeArea/aisle/binShelf

runApp(MultiProvider(
  providers: [
    ...yourExistingProviders,
    ...PosBootstrap.newProviders(),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const HomePage(),
    routes: {
      '/home': (_) => const HomePage(),
      '/stock': (_) => StockLedgerPage(products: Hive.box<LocalProduct>('products_box')),
      '/cash-up': (_) => const CashUpPage(expectedCash: 0, mobileMoneyTotal: 0, cardTotal: 0),
      '/ai-log': (_) => const AiActionsLogPage(),
    },
  ),
));
```

Replace the two demo PINs in `PosBootstrap.staff` with real staff, and hash
them before this leaves your bench.

## 4. Hook the sale flow

Three call sites in your existing `SalesProvider`:

```dart
// when a cart is started — relocks supervisor views so an unlocked till is
// never handed over. Pass supervisorSale: true for a cost-visible sale.
session.onSaleStarted();

// after the cart, before payment, if any line is serialised
final units = await Navigator.push<List<SerialUnit>>(context,
  MaterialPageRoute(builder: (_) => SerialCapturePage(...)));

// when stock is deducted, draw bins down in pick order so the counter drawer
// empties before the storeroom
final touched = await binService.pick(productId, quantity);

// after the receipt
session.onSaleFinished();
```

Basket suggestions on the cart come from
`aiProvider.tools.basketSuggestions(cartProductIds)` — it filters to items
actually in stock, so it never recommends something you cannot sell.

## 5. Ship a model

`OnDeviceRuntime` has two `TODO(plugin)` lines. Bind them to whichever
inference plugin you choose (`flutter_gemma`, `fllama`, or your own
llama.cpp FFI binding); everything else in the app talks only to
`LlmRuntime.complete`.

Download the GGUF named by `DeviceTier.recommended()` into
`{applicationSupport}/models/`. Until a model is present the app still answers
every question — see below.

---

## How the AI layer is built, and why

**Tools, not free reasoning.** `PosTools` runs every calculation in Dart over
Hive. The model is asked only to phrase the result. On a 4 GB phone a 2B model
gets arithmetic wrong often enough to matter at a till, and a confidently wrong
stock figure is worse than no answer. This also produces the query string behind
the supervisor's "show the query" expander.

**Graceful with no model.** `AiProvider` falls back to
`ToolResult.facts` — a plain sentence built from the real numbers. The till is
never blocked by inference, and answers stay correct if slightly flatter.

**Device tiering is invisible.** `DeviceTier` reads `/proc/meminfo` on
Android and allows a model at most ~45% of RAM: 8 GB+ → Qwen2.5 7B, 6 GB →
Llama 3.2 3B, 3.5 GB → Gemma 2 2B, below that → tiny or rules-only. The only
place this surfaces is the first-launch screen. For iOS, add a platform channel
to `ProcessInfo.physicalMemory`; until then it assumes a modest device.

**Phase 2 is a one-line swap.** `CloudRuntime` implements the same interface,
so moving inference to a cloud VM alongside a mirrored database changes
`ai.useCloud(...)` and nothing else. `ai.queueForCloud(q)` parks heavy
questions until it is reachable.

**Confidentiality is enforced in the provider, not the UI.** Every tool declares
a `ToolScope`. `AiProvider.ask` refuses supervisor-only tools when
`session.canSeeMoney` is false and offers the PIN instead of guessing. Hiding
a widget is not a permission model.

---

## Multi-bin model

A product's bins live in `stock_bins_box`, one row per location with its own
quantity and a `pickOrder`. `LocalProduct.currentStock` stays the
authoritative total that sales deduct from; bins explain **where** that total
sits. Keeping them separate means your existing sales, receipts and stock
reports keep working untouched, and a bin count that drifts from the total is a
recoverable data problem rather than a broken till.

Pick order defaults: counter drawer 10, display 20, storeroom 30 — so the till
consumes front-of-shop stock first.

---

## Still to build

The screens below exist in the design canvas but not yet in Dart. They are all
compositions of `PosScaffold`, `PaperCard`, `AiNote` and `StackedList`:

- Sign-in keypad (`SessionProvider.signIn` is ready)
- Scan + search (wrap your existing `BarcodeScannerWidget`)
- Cart and supervisor cart (your `checkout_page.dart`, restyled; add the
  suggestion row and the per-line cost reveal)
- Payment: method first, then amount, with the ZWL equivalent
- Receipt: app card plus the 58 mm slip preview
- Inventory hub, new/edit product, reports, settings, first-launch download
