# Project Memory: OruShops

This file serves as the persistent knowledge base for the OruShops project. It is maintained by the AI assistant to ensure continuity across sessions.

## 🚀 Core Mission
OruShops is a high-performance, mobile-first POS and retail management system designed for speed, reliability, and modularity.

## 🛠 Tech Stack
- **Framework**: Flutter (Dart 3.x)
- **State Management**: Riverpod (Provider-based)
- **Local Persistence**: SQLite (`sqflite`)
- **Remote Sync**: Supabase
- **Architecture**: Modular Feature-based (`lib/features`) with a generic Presentation layer for legacy screens.

## 🏗 Modular Structure
Detailed architecture is maintained in [graphify-out/report.md](./graphify-out/report.md).

- **`lib/core`**: The "Engine" of the app.
  - `database_helper.dart`: Primary SQLite interface.
  - `repositories/`: Abstracted data access layer.
  - `services/`: Complex business logic (receipts, sync, hashing).
  - `models/`: Immutable DTOs (Product, Sale, CartItem).
- **`lib/providers`**: The "State" layer.
  - Reactive providers for Cart, Products, Sales, and Sync.
- **`lib/features`**: The "Business" modules.
  - `analytics/`, `billing/`, `inventory/`, `onboarding/`, `payment/`, `settings/`.
- **`lib/presentation`**: The "UI" hub.
  - Main navigation via `MyHomePage` in `main.dart`.

## 💾 State Management Patterns
- **Cart Management**: `CartProvider` handles local checkout state, interacting with `CartService` for calculations.
- **Data Sync**: `SyncProvider` manages background synchronization between SQLite and Supabase.
- **Global Config**: `SettingsProvider` backed by `SharedPreferences`.

- ✅ Finalized 9-step Onboarding Flow with branch-based routing for Email/Phone/Social auth.
- ✅ Implemented `PopScope` navigation and persistent top-left back buttons for consistent UX.
- ✅ Balanced onboarding UI spacing and hierarchy for a more premium first-launch experience.
- 🎯 **Next Goal**: Optimize synchronization logic and further modularize the legacy presentation layer into the `features` directory.

## 🤖 AI Workflow (Graph-First)
- All architectural decisions are grounded in the `graphify-out/` cache.
- Every significant change must be followed by a `/graphify --update`.

