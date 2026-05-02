# Graph Report - OruShops  (2026-05-01)

## Corpus Check
- 75 files · ~30,852 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 571 nodes · 640 edges · 37 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter_riverpod/flutter_riverpod.dart` - 27 edges
2. `package:flutter/material.dart` - 20 edges
3. `../../core/theme/app_theme.dart` - 11 edges
4. `../database/database_helper.dart` - 9 edges
5. `package:intl/intl.dart` - 9 edges
6. `../../core/utils/currency_formatter.dart` - 9 edges
7. `package:flutter_test/flutter_test.dart` - 9 edges
8. `package:flutter/services.dart` - 6 edges
9. `../core/models/cart_item.dart` - 6 edges
10. `../core/models/sale.dart` - 6 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (34): dart:async, dart:convert, ../database/database_helper.dart, SeedData, AnalyticsRepository, DailySalesData, DailySalesTotal, ExpiringBatch (+26 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (32): AppTheme, ThemeData, build, ErrorBoundary, _ErrorBoundaryState, initState, _resetError, Scaffold (+24 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (35): ../core/database/database_helper.dart, ../core/models/app_settings.dart, ../core/repositories/settings_repository.dart, ../core/services/settings_service.dart, core/widgets/error_boundary.dart, SettingsService, AnalyticsScreen, build (+27 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (35): ../core/models/sale.dart, ../core/models/sale_item.dart, CurrencyFormatter, format, formatCompact, formatWithLocale, parse, build (+27 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (30): ../core/models/product.dart, ../core/models/refund.dart, ../../core/models/return.dart, ../../core/models/return_item.dart, ../core/repositories/analytics_repository.dart, ../core/repositories/product_repository.dart, ../core/repositories/refund_repository.dart, ../../core/repositories/return_repository.dart (+22 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (34): ../../core/utils/currency_formatter.dart, build, dispose, initState, RefundRequestScreen, _RefundRequestScreenState, Scaffold, SizedBox (+26 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (32): ../core/models/product_batch.dart, ../core/repositories/batch_repository.dart, create_product_screen.dart, _AddStockBottomSheet, _AddStockBottomSheetState, Align, BatchRepository, build (+24 more)

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (26): _AlertsSection, AnalyticsScreen, _AnalyticsScreenState, build, _buildAlertCard, _buildEmptyState, _buildMetricCard, _buildPaymentBreakdown (+18 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (26): cart_screen.dart, _addToCart, _AnimatedCounter, build, _buildCategorySelector, _buildEmptyState, _buildSummaryBar, Center (+18 more)

### Community 9 - "Community 9"
Cohesion: 0.08
Nodes (23): checkout_screen.dart, build, _buildCustomerSection, _buildSummaryRow, _CartItemTile, CartScreen, _CartSummary, _CartSummaryState (+15 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (23): _applyDiscount, _BatchSelector, BoxShadow, build, CheckoutScreen, _CheckoutScreenState, dispose, Divider (+15 more)

### Community 11 - "Community 11"
Cohesion: 0.09
Nodes (20): ../../core/theme/app_theme.dart, build, Card, _ClearCacheTile, _ClearDataTile, Column, Scaffold, SettingsScreen (+12 more)

### Community 12 - "Community 12"
Cohesion: 0.11
Nodes (18): build, _buildInputField, _buildSectionHeader, _buildSquareButton, ChoiceChip, Column, Container, CreateProductScreen (+10 more)

### Community 13 - "Community 13"
Cohesion: 0.11
Nodes (16): DatabaseHelper, Exception, openDatabase, app_settings, event_logs, KEY, MigrationV1, product_batches (+8 more)

### Community 14 - "Community 14"
Cohesion: 0.11
Nodes (17): _BackupActionsCard, BackupSyncScreen, build, Card, _ConnectionStatusCard, Container, _DataRow, _getErrorMessage (+9 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (15): batch_repository.dart, currency_formatter.dart, Exception, SaleRepository, _centerText, generateReceipt, generateReceiptPlain, ReceiptService (+7 more)

### Community 16 - "Community 16"
Cohesion: 0.13
Nodes (13): ../core/models/cart_item.dart, ../core/services/cart_service.dart, addItem, CartStateNotifier, clearCart, initializeSharedPrefs, removeItem, updateBatchSelection (+5 more)

### Community 17 - "Community 17"
Cohesion: 0.22
Nodes (11): Database Helper, Main Entry, Analytics Screen, Cart Screen, Inventory Screen, Products Screen, Settings Screen, Analytics Provider (+3 more)

### Community 18 - "Community 18"
Cohesion: 0.22
Nodes (8): addItem, CartService, clear, hasItem, removeItem, updateBatchSelection, updateItemQuantity, ../models/cart_item.dart

### Community 19 - "Community 19"
Cohesion: 0.22
Nodes (8): DateFormat, DateFormatter, formatDate, formatDateRange, formatDateTime, formatRelative, formatTime, isSameDay

### Community 20 - "Community 20"
Cohesion: 0.33
Nodes (5): generateHash, HashService, _mapToString, verifyHashChain, package:crypto/crypto.dart

### Community 21 - "Community 21"
Cohesion: 0.5
Nodes (3): displayName, PaymentMethods, SaleStatus

### Community 22 - "Community 22"
Cohesion: 0.5
Nodes (3): copyWith, _encodeChanges, EventLogEntry

### Community 23 - "Community 23"
Cohesion: 0.5
Nodes (3): copyWith, fromMap, Return

### Community 24 - "Community 24"
Cohesion: 0.5
Nodes (3): ReturnRepository, ../models/return.dart, ../models/return_item.dart

### Community 25 - "Community 25"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 26 - "Community 26"
Cohesion: 0.67
Nodes (2): EntityTypes, EventTypes

### Community 27 - "Community 27"
Cohesion: 0.67
Nodes (2): displayName, StockReasons

### Community 28 - "Community 28"
Cohesion: 0.67
Nodes (2): AppSettings, copyWith

### Community 29 - "Community 29"
Cohesion: 0.67
Nodes (2): CartItem, copyWith

### Community 30 - "Community 30"
Cohesion: 0.67
Nodes (2): copyWith, Product

### Community 31 - "Community 31"
Cohesion: 0.67
Nodes (2): copyWith, ProductBatch

### Community 32 - "Community 32"
Cohesion: 0.67
Nodes (2): copyWith, Refund

### Community 33 - "Community 33"
Cohesion: 0.67
Nodes (2): fromMap, ReturnItem

### Community 34 - "Community 34"
Cohesion: 0.67
Nodes (2): copyWith, Sale

### Community 35 - "Community 35"
Cohesion: 0.67
Nodes (2): copyWith, SaleItem

### Community 36 - "Community 36"
Cohesion: 1.0
Nodes (1): MainActivity

## Knowledge Gaps
- **449 isolated node(s):** `MainActivity`, `MyApp`, `MyHomePage`, `_MyHomePageState`, `main` (+444 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 25`** (3 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant`, `.registerWith()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (3 nodes): `EntityTypes`, `EventTypes`, `event_types.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (3 nodes): `displayName`, `StockReasons`, `stock_reasons.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (3 nodes): `AppSettings`, `copyWith`, `app_settings.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (3 nodes): `CartItem`, `copyWith`, `cart_item.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (3 nodes): `copyWith`, `Product`, `product.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (3 nodes): `copyWith`, `ProductBatch`, `product_batch.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (3 nodes): `copyWith`, `Refund`, `refund.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (3 nodes): `fromMap`, `ReturnItem`, `return_item.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (3 nodes): `copyWith`, `Sale`, `sale.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (3 nodes): `copyWith`, `SaleItem`, `sale_item.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 4` to `Community 1`, `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 14`, `Community 16`?**
  _High betweenness centrality (0.253) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `Community 1` to `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 14`?**
  _High betweenness centrality (0.163) - this node is a cross-community bridge._
- **Why does `../database/database_helper.dart` connect `Community 0` to `Community 2`, `Community 15`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **What connects `MainActivity`, `MyApp`, `MyHomePage` to the rest of the system?**
  _449 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
