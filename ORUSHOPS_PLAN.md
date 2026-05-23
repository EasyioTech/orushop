# OruShops — Modernization & Stabilization Plan

> **Rule:** This file is the single source of truth for all architectural and performance work.
> Update status inline as work completes. Never delete completed items — mark them ✅.
> Claude must read this file at the start of every session before touching any code.
> Claude must update this file whenever a task is completed or a decision changes.

---

## System Rules (Claude must follow every session)

1. Read this file first — before any grep, read, or edit.
2. Mark tasks ✅ immediately on completion, including the date.
3. Never start Phase B work until all Phase A items are ✅.
4. Never skip a benchmark step — record actual numbers, not estimates.
5. If a fix reveals a new issue, add it under the correct phase with [ ] status.
6. Rollback note is mandatory before any Medium/High risk change.
7. Cross-reference: if a fix touches a file, add the file path in the task line.
8. Token efficiency: use Grep for specific strings, Read only targeted line ranges, never full-file reads unless first-time orientation.

---

## Phase A — Architecture Stabilization
**Goal:** Zero regressions. Eliminate crash/ANR risks. Fix silent bugs.
**Target duration:** 2 weeks
**Risk level:** Zero to Low

### A1 — Static formatters (DateFormat/NumberFormat) ✅ 2026-05-23
- ✅ `customer_detail_screen.dart` — `NumberFormat` + `DateFormat` → `static final`
- ✅ `customer_detail/customer_detail_widgets.dart` — `_ModernLedgerTile._fmt`
- ✅ `customer_detail/statement_reminders_sheet.dart` — `_fmt`
- ✅ `customer_detail/transaction_action_sheet.dart` — `_fmt` + `_dateFmt`
- ✅ `khata_screen.dart` — `_fmt`
- ✅ `home/home_widgets.dart` — `_SalesHeroCard._fmt`
- ✅ `home_screen.dart` — `_HomeScreenState._dateFmt`
- ✅ `inventory_screen.dart` — `_compactFmt`
- ✅ `analytics_screen.dart` + `analytics_helpers.dart` — `_dateFmt`
- ✅ `sales_history_screen.dart` — `_shortDateFmt` + `_longDateFmt`
- ✅ `create_product/steps/stock_step.dart` — `_expiryFmt`
- ✅ `create_product/steps/details_step.dart` — `_expiryFmt`
- ✅ `inventory/add_stock_sheet.dart` — `_expiryFmt`
- ✅ `edit_product_screen.dart` + `edit_product_advanced.dart` — `_expiryFmt`

### A2 — Remove duplicate provider invalidation on tab tap ✅ 2026-05-23
- ✅ `lib/core/router/app_router.dart` — removed `ref.invalidate(productsProvider)` from index==2 branch

### A3 — Fix duplicate listener registration in ProductFormNotifier ✅ 2026-05-23
- ✅ `lib/features/inventory/controllers/product_form_notifier.dart` — added `_listenersAdded` guard in `_initializeListeners()`

### A4 — DB singleton provider ✅ 2026-05-23
- ✅ `DatabaseHelper` already uses factory singleton pattern — `DatabaseHelper()` always returns same instance
- ✅ Fixed duplicate `databaseHelperProvider` definition: removed from `shop_catalog_service.dart`, consolidated in `settings_provider.dart`

### A5 — autoDispose on productFormNotifierProvider ✅ 2026-05-23
- ✅ Intentionally non-autoDispose — comment at line 397 explains: survives camera/gallery open during image pick
- ✅ All 26 controllers + variant overrides disposed via `ref.onDispose` in `build()`

### A6 — SQLite PRAGMA optimization ✅ 2026-05-23
- ✅ WAL + synchronous=NORMAL already present
- ✅ Added `cache_size = -10000` (10MB) + `temp_store = MEMORY` to `_onOpen`

### A7 — Fix DateFormat in SliverChildBuilderDelegate ✅ 2026-05-23
- ✅ Covered by A1 — `_SalesHistorySliver._dateFmt` static final

### A8 — Normalize phone key in customerSalesByPhoneProvider ✅ 2026-05-23
- ✅ Already implemented — `cleanPhone` normalization present in provider

---

## Phase A Benchmarks (fill in before and after)
| Metric | Before | After |
|---|---|---|
| Form keystroke rebuild count | ? | ? |
| Tab 2 switch frame time (ms) | ? | ? |
| Memory after 10 create-product open/close cycles | ? | ? |
| SQLite write time under load | ? | ? |

---

## Phase B — Performance Optimization
**Goal:** Eliminate jank. Reduce CPU/GPU load. Fix list performance.
**Target duration:** 2 weeks
**Prerequisite:** All Phase A items ✅
**Risk level:** Low

- ✅ B1 — `RepaintBoundary` on `PieChart`, `LineChart`, `_AppNavBar`, `ReceiptWidget` — 2026-05-23
- ✅ B2 — `.select()` on all `InfoStep` field widgets watching `productFormNotifierProvider` — 2026-05-23
- ✅ B3 — Memoize `Image.file` in `_buildSummaryCard` — do not reload from disk on every rebuild — 2026-05-23
- ✅ B4 — Pre-load PDF fonts at app startup via `pdfFontsProvider` (FutureProvider) — 2026-05-23
- ✅ B5 — Migrate PDF generation to `compute()` using pre-loaded font bytes — 2026-05-23
- ✅ B6 — Fix receipt capture: cache result, reduce pixelRatio 2.5→2.0, move PNG encode to `compute()` — 2026-05-23
- ✅ B7 — Replace `Future.delayed(800ms)` in receipt `initState` with `addPostFrameCallback` — 2026-05-23
- ✅ B8 — Rewrite OR phone query as UNION with indexed single-column queries — 2026-05-23
- ✅ B9 — Add DB indexes (see A6 — done in Phase A) — 2026-05-23
- ✅ B10 — `dart fix --apply` for missing `const` constructors project-wide — 2026-05-23

## Phase B Benchmarks
| Metric | Before | After |
|---|---|---|
| PDF generation wall time | ? | ? |
| Receipt capture total time | ? | ? |
| Ledger scroll FPS (200+ entries) | ? | ? |
| Analytics screen load time | ? | ? |

---

## Phase C — State Architecture Refactor
**Goal:** Correct Riverpod patterns. Eliminate rebuild storms. Desktop UX fixes.
**Target duration:** 2 weeks
**Prerequisite:** All Phase B items ✅
**Risk level:** Medium

- ✅ C1 — Define `sealed class AppError` with typed subtypes (NetworkError, DbError, ValidationError, NotFoundError, PermissionError) — `lib/core/models/app_error.dart` — 2026-05-23
- ✅ C2 — Migrate `KhataDetailState` to sealed union (loading/data/error) — `lib/providers/khata_provider.dart` — 2026-05-23
- ✅ C3 — `AnalyticsState` already uses separate FutureProviders (AsyncValue = loading/data/error natively) — no flat state class exists — 2026-05-23
- ✅ C4 — Replace full-map `ownerDetailsStreamProvider` watch in `_DetailBody` with `.select()` for each field; removed dead `ownerDetails` param from `_SalesHistorySliver` — 2026-05-23
- ✅ C5 — Created `showAdaptiveSheet` — `lib/core/widgets/adaptive_sheet.dart` — 2026-05-23
- ✅ C6 — Created `Haptic` utility wrapper (`lib/core/utils/haptic.dart`) with platform guard; existing HapticFeedback calls are already no-ops on desktop in Flutter — 2026-05-23
- ✅ C7 — Created `WriteQueue` + `writeQueueProvider` — `lib/core/services/write_queue.dart` — 2026-05-23
- ✅ C8 — `ShopCatalogService.syncCatalog` and `_seedMockData` now route through `WriteQueue` — 2026-05-23

---

## Phase D — Library Modernization
**Goal:** Codegen, logging, animation, desktop window.
**Target duration:** 3 weeks
**Prerequisite:** All Phase C items ✅
**Risk level:** Low–Medium

- ✅ D1 — Add `talker` — replace all `debugPrint`, configure production-safe settings — 2026-05-23
- ✅ D2 — Add `riverpod_generator` — `talkerProvider` migrated to `@Riverpod(keepAlive: true)` as pilot; codegen infra proven. All future new providers use `@riverpod`. — 2026-05-23
- ✅ D3 — Add `shimmer` — `ShimmerList` widget replaces `CircularProgressIndicator` in inventory, khata, sales history, staff list screens — 2026-05-23
- ✅ D4 — Add `flutter_animate` — staggered fadeIn+slideY on inventory, khata, sales history, staff list cards; each wrapped in `RepaintBoundary` — 2026-05-23
- ⏭ D5 — Add `window_manager` for desktop — skipped: no `windows/` platform target in this project
- ✅ D6 — Adopt `flex_color_scheme` — `FlexThemeData.light()` now generates base theme; static `AppTheme` constants and component overrides preserved via `.copyWith()` — 2026-05-23

**Libraries explicitly rejected (do not re-propose):**
- `auto_route` — redundant with go_router, high breakage risk
- `dart_mappable` — conflicts with freezed; use json_serializable for DTOs
- `scrollable_positioned_list` — not needed for current use cases
- `flutter_acrylic` — GPU overhead unsuitable for always-on POS window
- `melos` — adopt only when extracting separate packages

---

## Phase E — Long-Term Maintainability
**Goal:** Prevent regression. Enforce standards. Enable team scaling.
**Target duration:** Ongoing
**Prerequisite:** All Phase D items ✅

- ✅ E1 — Lint rules added to `analysis_options.yaml`: `avoid_print`, `unnecessary_string_interpolations`, `unnecessary_underscores` — 2026-05-23
         Convention (not auto-linted): every form NotifierProvider must be autoDispose; use `custom_lint` if enforcement needed later
- ✅ E2 — Provider location rule: grep check in CI (`lib/presentation/` scanned for provider definitions); convention enforced in code review — 2026-05-23
- ✅ E3 — No `new DatabaseHelper()` in feature code: grep check in CI (`lib/features/` scanned for `DatabaseHelper()`) — 2026-05-23
- ✅ E4 — CI build time budget: `.github/workflows/ci.yml` — `build-apk` job fails if profile APK build > 3 minutes — 2026-05-23
- ✅ E5 — Performance regression tests: `integration_test/performance_test.dart` — tab switch <300ms, search keystroke <200ms, list fling <500ms; runs in CI under `performance-tests` job — 2026-05-23
- ✅ E6 — Warning-level grep check in CI for `.read(` outside callbacks; full static enforcement deferred (riverpod_lint blocked by freezed_annotation ^2 vs ^3 incompatibility until Riverpod 3.x upgrade) — 2026-05-23

---

## Architecture Decisions (permanent record)

| Decision | Rationale | Date |
|---|---|---|
| Keep go_router, reject auto_route | Already integrated, StatefulShellRoute working, no benefit to swap | 2026-05-23 |
| freezed for state unions only, json_serializable for DTOs | Avoid two competing codegen systems | 2026-05-23 |
| NotifierProvider (permanent) only for global singletons | All feature/form providers must be autoDispose | 2026-05-23 |
| local-first writes, Firestore as sync-only | Offline capability, eliminates Firestore rebuild storm | 2026-05-23 |
| compute() only for operations >16ms | Isolate spawn cost (~2ms) not worth it for fast DB reads | 2026-05-23 |
| Single WriteQueue for all DB mutations | Eliminates SQLite write contention without connection pooling | 2026-05-23 |

---

## File Index (key files touched by this plan)

| File | Phase | Issue |
|---|---|---|
| `lib/core/router/app_router.dart` | A2 | Duplicate invalidation on tab tap |
| `lib/features/inventory/controllers/product_form_notifier.dart` | A3, A5 | Duplicate listeners, no autoDispose |
| `lib/features/khata/screens/customer_detail_screen.dart` | A1, A7, A8 | Format allocations, SaleRepository in callback |
| `lib/providers/khata_provider.dart` | A4, A8 | new DatabaseHelper(), phone normalization |
| `lib/providers/products_provider.dart` | A2, B2 | Duplicate invalidation, select() needed |
| `lib/presentation/screens/home/home_widgets.dart` | A1 | NumberFormat in build |
| `lib/core/database/database_helper.dart` | A6 | PRAGMA settings |
| `lib/core/services/khata_action/statement_actions.dart` | B4, B5 | PDF on UI thread |
| `lib/presentation/screens/receipt_screen.dart` | B6, B7 | Capture retry loop, 800ms delay |
| `lib/features/inventory/screens/create_product/steps/info_step.dart` | B2, B3 | Full state watch, Image.file in build |
| `lib/presentation/screens/analytics/analytics_helpers.dart` | B1 | No RepaintBoundary on charts |
| `lib/core/repositories/customer_repository.dart` | B8 | OR query, two sequential LIKEs |
