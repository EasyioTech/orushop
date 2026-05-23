import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:orushops/core/utils/app_logger.dart';
import 'migrations/migration_v1.dart';
import 'migrations/migration_v3.dart';
import 'migrations/migration_v4.dart';
import 'migrations/migration_v6.dart';
import 'migrations/migration_v7.dart';
import 'migrations/migration_v8.dart';
import 'migrations/migration_v9.dart';
import 'migrations/migration_v10.dart';
import 'migrations/migration_v11.dart';
import 'migrations/migration_v12.dart';
import 'migrations/migration_v13.dart';
import 'migrations/migration_v14.dart';
import 'migrations/migration_v15.dart';
import 'migrations/migration_v16.dart';
import 'migrations/migration_v17.dart';
import 'migrations/migration_v18.dart';
import 'migrations/migration_v19.dart';
import 'migrations/migration_v20.dart';

import 'table_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const _tag = 'DB';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (kIsWeb) throw Exception('SQLite is not supported on web platform');
    if (_database == null) {
      try {
        _database = await _initDatabase();
      } catch (e) {
        AppLogger.e(_tag, 'Init failed', e);
        rethrow;
      }
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      debugPrint('DB: Getting databases path...');
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'OruShops.db');
      debugPrint('DB: Opening database at $path...');
      return await openDatabase(
          path,
          version: 20,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
      );
    } catch (e) {
      debugPrint('DB: Init error: $e');
      AppLogger.e(_tag, '_initDatabase error', e);
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DB: Creating database v$version...');
    await MigrationV1.up(db);
    await MigrationV3.up(db);
    await MigrationV4.up(db);
    await MigrationV6.up(db);
    await MigrationV7.up(db);
    await MigrationV8.up(db);
    await MigrationV9.up(db);
    await MigrationV10.up(db);
    await MigrationV11.up(db);
    await MigrationV12.migrate(db);
    await MigrationV13.up(db);
    await MigrationV14.up(db);
    await MigrationV15.up(db);
    await MigrationV16.up(db);
    await MigrationV17.up(db);
    await MigrationV18.up(db);
    await MigrationV19.up(db);
    await MigrationV20.up(db);
    debugPrint('DB: Database creation complete.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 3) await MigrationV3.up(db);
    if (oldVersion < 4) await MigrationV4.up(db);
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN customerName TEXT');
      } catch (e) {
        AppLogger.v(_tag, 'customerName column already exists');
      }
    }
    if (oldVersion < 6) await MigrationV6.up(db);
    if (oldVersion < 7) await MigrationV7.up(db);
    if (oldVersion < 8) await MigrationV8.up(db);
    if (oldVersion < 9) await MigrationV9.up(db);
    if (oldVersion < 10) await MigrationV10.up(db);
    if (oldVersion < 11) await MigrationV11.up(db);
    if (oldVersion < 12) await MigrationV12.migrate(db);
    if (oldVersion < 13) await MigrationV13.up(db);
    if (oldVersion < 14) await MigrationV14.up(db);
    if (oldVersion < 15) await MigrationV15.up(db);
    if (oldVersion < 16) await MigrationV16.up(db);
    if (oldVersion < 17) await MigrationV17.up(db);
    if (oldVersion < 18) await MigrationV18.up(db);
    if (oldVersion < 19) await MigrationV19.up(db);
    if (oldVersion < 20) await MigrationV20.up(db);
  }

  Future<void> _onOpen(Database db) async {
    if (kIsWeb) return;
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
      await db.rawQuery('PRAGMA synchronous = NORMAL');
      await db.rawQuery('PRAGMA foreign_keys = ON');

      final List<Map<String, dynamic>> columns =
          await db.rawQuery('PRAGMA table_info(${TableConstants.sales})');
      final bool hasCustomerName =
          columns.any((col) => col['name'] == 'customerName');

      if (!hasCustomerName) {
        AppLogger.w(_tag, 'customerName missing in sales — adding column');
        await db.execute(
            'ALTER TABLE ${TableConstants.sales} ADD COLUMN customerName TEXT');
      }
    } catch (e) {
      AppLogger.e(_tag, '_onOpen error', e);
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      final tables = [
        TableConstants.products,
        TableConstants.productBatches,
        TableConstants.sales,
        TableConstants.saleItems,
        TableConstants.orders,
        TableConstants.orderItems,
        TableConstants.refunds,
        TableConstants.returns,
        TableConstants.returnItems,
        TableConstants.eventLogs,
        TableConstants.appSettings,
        TableConstants.khataCustomers,
        TableConstants.khataEntries,
        TableConstants.khataPayments,
        TableConstants.productCategories,
        TableConstants.productSubcategories,
        TableConstants.productVariants,
        TableConstants.customers,
        TableConstants.serviceDetails,
        TableConstants.staff,
        TableConstants.staffServiceAssignments,
        TableConstants.serviceCategories,
      ];

      for (final table in tables) {
        try {
          await txn.delete(table);
        } catch (e) {
          AppLogger.e(_tag, 'Failed to clear table $table', e);
        }
      }
    });
  }

  Future<void> seedDatabase(List<Map<String, dynamic>> catalogData, String shopTypeName) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final expiryDate = DateTime.now().add(const Duration(days: 365)).toIso8601String();

    await db.transaction((txn) async {
      // 1. Clear existing starter data
      await txn.delete(TableConstants.products);
      await txn.delete(TableConstants.productBatches);
      await txn.delete(TableConstants.inventoryStandard);
      await txn.delete(TableConstants.inventorySerialized);
      await txn.delete(TableConstants.globalCatalog);

      // Grouping by parent_sku or product_name to handle variants
      final Map<String, List<Map<String, dynamic>>> groupedData = {};
      for (final p in catalogData) {
        final key = p['parent_sku']?.toString().isNotEmpty == true 
            ? p['parent_sku'] 
            : '${p['product_name']}_${p['category']}';
        groupedData.putIfAbsent(key, () => []).add(p);
      }

      for (final entry in groupedData.entries) {
        final group = entry.value;
        final p = group.first; // Base info from first item
        
        final template = p['procurement_template'] ?? 'standardRetail';
        final isService = p['is_service'] == 1 || p['procurement_template'] == 'serviceLabor' ? 1 : 0;
        final isLoose = p['is_loose'] == 1 || p['procurement_template'] == 'bulkUom' ? 1 : 0;
        final sellingPrice = (p['selling_price'] as num?)?.toDouble() ?? 0.0;
        final costPrice = (p['cost_price'] as num?)?.toDouble() ?? 0.0;
        final mrp = (p['mrp'] as num?)?.toDouble() ?? 0.0;
        final wholesalePrice = (p['wholesale_price'] as num?)?.toDouble();
        final unit = p['base_uom'] ?? p['uom'] ?? 'Piece';

        // 2. Insert into main products table
        final productId = await txn.insert(TableConstants.products, {
          'name': p['product_name'] ?? 'Unknown',
          'sku': p['parent_sku'] ?? p['barcode'] ?? '',
          'price': sellingPrice,
          'quantity': group.fold<double>(0, (sum, item) => sum + ((item['opening_stock'] as num?)?.toDouble() ?? (item['initial_stock'] as num?)?.toDouble() ?? 0.0)),
          'category': p['category'] ?? '',
          'subcategory': null,
          'unit': unit,
          'mrp': mrp,
          'hsnCode': p['hsn_code'],
          'taxRate': (p['tax_percentage'] as num?)?.toDouble() ?? 0.0,
          'brand': p['brand'],
          'manufacturer': p['manufacturer'],
          'imageUrl': p['product_photo'],
          'template': template,
          'isService': isService,
          'isLoose': isLoose,
          'wholesalePrice': wholesalePrice,
          'costPrice': costPrice,
          'createdAt': now,
          'updatedAt': now,
        });

        // 3. Insert into search lookup
        await txn.insert(TableConstants.globalCatalog, {
          'name': p['product_name'] ?? 'Unknown',
          'category': p['category'],
          'sku': p['barcode'] ?? p['parent_sku'] ?? '',
          'shopType': shopTypeName,
        });


        // 4. Handle Template Specific Tables
        if (template == 'variantMatrix') {
          for (final variantItem in group) {
            await txn.insert(TableConstants.productVariants, {
              'productId': productId,
              'size': variantItem['variant_attr_1_value'] ?? '',
              'color': variantItem['variant_attr_2_value'] ?? '',
              'sku': variantItem['barcode'] ?? '',
              'price': (variantItem['selling_price'] as num?)?.toDouble() ?? sellingPrice,
              'stock': (variantItem['opening_stock'] as num?)?.toDouble() ?? 0.0,
              'mrp': (variantItem['mrp'] as num?)?.toDouble() ?? mrp,
              'barcode': variantItem['barcode'],
              'costPrice': (variantItem['cost_price'] as num?)?.toDouble() ?? costPrice,
              'createdAt': now,
              'updatedAt': now,
            });
          }
          // Also insert into inventory_standard for basic pricing reference
          await txn.insert(TableConstants.inventoryStandard, {
            'productId': productId,
            'sellingPrice': sellingPrice,
            'mrp': mrp,
            'costPrice': costPrice,
            'quantity': group.fold<double>(0, (sum, item) => sum + ((item['opening_stock'] as num?)?.toDouble() ?? 0.0)),
            'unit': unit,
          });
        } else if (template == 'serialized') {
          for (final serialItem in group) {
            await txn.insert(TableConstants.inventorySerialized, {
              'productId': productId,
              'serialNumber': serialItem['serial_imei_number'] ?? 'SN-${DateTime.now().millisecond}',
              'imei': serialItem['serial_imei_number'],
              'sellingPrice': (serialItem['selling_price'] as num?)?.toDouble() ?? sellingPrice,
              'mrp': (serialItem['mrp'] as num?)?.toDouble() ?? mrp,
              'costPrice': (serialItem['cost_price'] as num?)?.toDouble() ?? costPrice,
              'status': 'Available',
            });
          }
        } else {
          // Standard / Batch / Service
          await txn.insert(TableConstants.inventoryStandard, {
            'productId': productId,
            'sellingPrice': sellingPrice,
            'mrp': mrp,
            'costPrice': costPrice,
            'wholesalePrice': wholesalePrice,
            'quantity': (p['opening_stock'] as num?)?.toDouble() ?? (p['initial_stock'] as num?)?.toDouble() ?? 0.0,
            'reorderLevel': (p['reorder_level'] as num?)?.toDouble() ?? 5.0,
            'unit': unit,
            'packagingUnit': p['packaging_uom'],
            'conversionFactor': (p['conversion_factor'] as num?)?.toDouble() ?? 1.0,
          });

          // Create default batch if it has batch info or if it's a physical good
          if (p['batch_number'] != null || p['expiry_date'] != null || isService == 0) {
            await txn.insert(TableConstants.productBatches, {
              'productId': productId,
              'quantity': (p['opening_stock'] as num?)?.toDouble() ?? (p['initial_stock'] as num?)?.toDouble() ?? 0.0,
              'costPrice': costPrice,
              'batchNumber': p['batch_number'] ?? 'B1',
              'expiryDate': p['expiry_date'] ?? expiryDate,
              'createdAt': now,
            });
          }
        }
      }
    });
  }


  Future<void> close() async {
    _database?.close();
    _database = null;
  }
}
