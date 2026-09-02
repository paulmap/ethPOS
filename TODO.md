# TODO / Roadmap

## Product requirements (stated 2026-07-10)

1. **Hierarchical inventory locations** — ✅ done (2026-07-10). `LocalProduct`
   now has `storeArea`/`aisle`/`binShelf` (three separate fields rather than
   a rigidly-parsed single code, for entry flexibility), plus a `locationCode`
   display getter (e.g. "A-12-B10") and `hasLocation`. Editable at creation in
   `new_product_page.dart`; shown read-only in `edit_product_page.dart`
   (routed to the dedicated transfer flow below, matching how Price/Stock/Cost
   already work in that page). Shown in the Stock Status list.
   Note: this models **one location per product**, not split stock across
   multiple locations simultaneously — if a product's stock needs to live in
   several bins at once with independent quantities, that's a bigger data
   model change (a location↔quantity join, similar to a ledger) and hasn't
   been built.

2. **Inventory transfer between locations** — ✅ done (2026-07-10). "Transfer
   Location" action added to the Stock Status page's per-item menu (alongside
   Edit/Discontinue); opens a dialog to set new Store/Area, Aisle, Bin/Shelf
   and updates the product. No separate audit/history record is kept — this
   matches the existing convention (Discontinue also just flips a flag with no
   history). Add a movement-history model later if an audit trail turns out
   to be needed.

3. **AI-powered query interface** (proof of concept) — ✅ app-side + backend
   code done and verified locally (2026-07-11); **VPS deployment is Paul's own
   follow-up, not yet done**. Full plan: `.claude/plans/logical-questing-sifakis.md`.
   - `LocalProduct.compatibleTags` added (fitment tagging, e.g. a case tagged
     `["iPhone 12", "iPhone 13"]`), editable in both new/edit product pages.
   - `AppSettings` gained `assistantBaseUrl`/`assistantApiKey`/`assistantEnabled`;
     configurable in `settings_page.dart` (with a "Generate Key" button).
   - New backend at `server/` (Dart + shelf, no database — in-memory catalog
     backed by a JSON file, deterministic keyword/tag retrieval, no
     embeddings). See `server/README.md` for the full deployment runbook
     (Ollama install, model pull, building+deploying the binary, Caddy
     HTTPS, firewall). Recommended model: `qwen2.5:3b-instruct`.
   - New Flutter feature `lib/features/assistant/` — chat UI + provider,
     manual "Sync Now" push of the active product catalog, wired into the
     dashboard.
   - **Verified for real** in this dev environment (which happened to already
     have Ollama installed): retrieval unit tests, a real running backend
     against a real pulled `qwen2.5:3b-instruct` model — including the exact
     "case for iPhone 12" / "charger for Samsung S21" interchangeability
     scenario from the requirement — and the real `AiAssistantProvider`
     Dio networking code (sync, query, 401 handling, unreachable-host
     handling) all confirmed working end to end.
   - **Not done**: actually deploying to Paul's real Contabo VPS (his own
     timeline, using the runbook), API key masking in the UI, persistent
     chat history, auto-sync-on-mutation, rate limiting, streaming
     responses, embeddings-based retrieval (only worth it if keyword
     matching proves insufficient in real use).

4. **More intuitive new product / new stock entry** — barcode scanning
   instead of manual entry.
   - **Partially done already**: `BarcodeScannerWidget` exists and is wired
     into both `new_product_page.dart` (UPC field) and `new_stock_page.dart`
     (scan to auto-select an existing product), committed in
     "Add barcode scanning to New Product and New Stock forms".
   - Revisit once (1)/(2) land, since scanning stock into a specific bin
     location will need a location picker/scanner too.

## Deferred features

- **Generate NFC** (Customer Profile → "GENERATE NFC" button): currently a
  no-op. Needs a scope decision before implementation:
  - Option A: write the customer ID to a physical NFC tag (loyalty card) —
    needs a write-capable package (e.g. `nfc_manager`) + Android NFC
    permission/hardware.
  - Option B: Host Card Emulation — the phone itself acts as the tag for
    another reader to tap; different tech (HCE) than tag-writing.
  - Or something else — needs clarification before starting.

## Known gaps (not yet scoped/prioritized)

- **"MORE INFO"** (Customer Profile): still a no-op button, no defined spec.
- **`AppSettingsPage`**
  (`lib/features/inventory/presentation/pages/app_settings_page.dart`):
  orphaned — never navigated to from anywhere. Also has a latent bug:
  `_save()` constructs a brand-new `AppSettings(...)` instead of using
  `copyWith`, which would silently reset all other settings (business info,
  receipt numbering, admin PIN, tax categories, min points for redemption,
  etc.) back to defaults if this page were ever wired up as-is.
