# Graphify Report: OruShops

**Extraction Mode:** Standard
**Date:** 2026-05-01 10:19:35
**Source Directory:** `.`

## Architecture Graph

```mermaid
graph TD
    subgraph App_Entry
        Main[main.dart]
    end

    subgraph Screens
        PS[ProductsScreen]
        CS[CartScreen]
        IS[InventoryScreen]
        AS[AnalyticsScreen]
        SS[SettingsScreen]
        CPS[CreateProductScreen]
    end

    subgraph Providers
        PP[ProductsProvider]
        CP[CartProvider]
        AP[AnalyticsProvider]
        SP[SettingsProvider]
    end

    subgraph Infrastructure
        DB[DatabaseHelper]
    end

    Main --> PS
    Main --> CS
    Main --> IS
    Main --> AS
    Main --> SS

    PS --> PP
    CS --> CP
    AS --> AP
    SS --> SP
    CPS --> PP

    PP --> DB
    CP --> DB
    AP --> DB
    CPS --> DB
```

## Module Breakdown

### lib/core
Contains infrastructure code including the SQLite database helper and data models.
- **Nodes:** 1
- **Primary:** `database_helper.dart`

### lib/presentation
Contains the UI layer with functional screens.
- **Nodes:** 5 primary screens.

### lib/providers
Manages global state and interaction with the database layer.
- **Nodes:** 4 primary providers.

## Statistics
- **Total Nodes:** 11
- **Total Edges:** 12
- **Inferred Edges:** 0
- **Depth:** 4 layers

