# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ethPOS (internal app name/title: **VendorVault**) is a Flutter point-of-sale and inventory app aimed at
small informal grocery vendors (originally scoped for Zimbabwe). It is currently a fully offline,
single-device app: all data lives in local Hive boxes and there is no backend, sync, or auth layer
implemented yet.

Note: `PROJECT_STRUCTURE.md` at the repo root describes an aspirational clean-architecture design
(data/domain/presentation layers per feature, Firebase backend, sync queue, etc.). That structure was
**not built** — treat it as a future roadmap doc, not a description of the current code. The real
structure is much flatter (see below).

## Commands

```bash
flutter pub get                 # install dependencies
flutter pub run build_runner build --delete-conflicting-outputs
                                 # regenerate Hive adapters (*.g.dart) after changing any
                                 # @HiveType/@HiveField model in lib/core/storage/models/
flutter analyze                 # static analysis / lint (flutter_lints, see analysis_options.yaml)
flutter test                    # run all tests
flutter test test/widget_test.dart          # run a single test file
flutter run                     # run the app (defaults to connected device/emulator)
flutter build apk               # build Android APK
```

There is only one test file (`test/widget_test.dart`) today.

## Architecture

**State management**: `provider` (`ChangeNotifier`), wired up in `lib/main.dart` via a single
`MultiProvider` at app root. There is one provider per feature: `InventoryProvider`, `SalesProvider`,
`LoyaltyProvider`, `SupplierProvider`, `PurchaseProvider`.

**Persistence**: `hive`/`hive_flutter`. All Hive boxes are opened once in `main()` before `runApp`, and
adapters are registered there too. Providers hold direct references to the boxes they need
(`Hive.box<T>('box_name')`) — there is no repository/datasource abstraction. Models live in
`lib/core/storage/models/` as `HiveObject` subclasses with a paired generated `*.g.dart` file (run
`build_runner` after editing a model). Current boxes: `products_box`, `sales_box`, `customers_box`,
`settings_box`, `suppliers_box`, `purchases_box`.

**Feature layout** (`lib/features/<feature>/presentation/{pages,providers}/`): each feature folder has
only a `presentation` layer with `pages/` (UI) and a single `providers/<feature>_provider.dart`
(business logic + Hive access). There is no `data/` or `domain/` layer despite what
`PROJECT_STRUCTURE.md` describes. Features: `inventory`, `sales`, `loyalty`, `suppliers`, `purchases`,
`settings`.

**Shared/core code** (`lib/core/`):
- `constants/` — app-wide constants (`AppConstants`, `UiConstants`)
- `storage/models/` — Hive models shared across features
- `themes/` — `AppTheme` / `colors.dart`
- `widgets/common/` — shared widgets, including `MainHomeView` (bottom-nav shell) and
  `scanner/barcode_scanner_widget.dart` (wraps `mobile_scanner`; scanning is gated to
  `Platform.isAndroid || Platform.isIOS`, with a manual barcode-entry fallback for other platforms)

**Multi-currency**: `AppSettings` (in `core/storage/models/app_settings.dart`) holds a `baseCurrency`
and an `exchangeRates` map (rates expressed as "1 USD = X currency"). `InventoryProvider` exposes
`convertToUSD` / `convertToCurrency` / `getExchangeRate`, which other providers (e.g. `SalesProvider`)
call to normalize cart totals into the configured base currency. `AppSettings` also stores receipt/
invoice/PO numbering (prefix + incrementing counter), business profile fields, and tax categories —
each with an `effectiveX` getter that falls back to a default since most fields are nullable for
backward-compatible Hive migrations.

**Sales flow**: `SalesProvider` holds an in-memory cart (`List<LocalSaleItem>`, not persisted until
checkout). `processSale()` deducts stock from `products_box`, awards/redeems loyalty points via
`LoyaltyProvider` (1 USD spent = 100 points), converts totals into the base currency, persists a
`LocalSale` record, and increments the receipt counter in `AppSettings`.

**Receipts/documents**: `pdf` + `screenshot` + `share_plus` are used to generate and share PDF
receipts/invoices/purchase orders.
