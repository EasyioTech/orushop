import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:orushops/core/services/catalog_data.dart';
import 'migrations/migration_v1.dart';
import 'migrations/migration_v3.dart';
import 'table_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception('SQLite is not supported on web platform');
    }
    if (_database == null) {
      try {
        _database = await _initDatabase();
      } catch (e) {
        debugPrint('[DatabaseHelper] Init failed: $e');
        rethrow;
      }
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'OruShops.db');

      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    } catch (e) {
      debugPrint('[DatabaseHelper] _initDatabase error: $e');
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await MigrationV1.up(db);
    await MigrationV3.up(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 3) {
      await MigrationV3.up(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    if (kIsWeb) return;
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {
      // Ignore PRAGMA errors on some platforms
    }
  }

  Future<void> seedDatabase() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final expiryDate = DateTime.now().add(const Duration(days: 365)).toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(TableConstants.products);
      await txn.delete(TableConstants.productBatches);
      await txn.delete(TableConstants.sales);
      await txn.delete(TableConstants.saleItems);

      for (final entry in kGlobalProductCatalog.entries) {
        final p = entry.value;
        final productId = await txn.insert(TableConstants.products, {
          'name': p.name,
          'sku': p.sku,
          'price': p.typicalPrice,
          'quantity': 50,
          'category': p.category,
          'imageUrl': p.imageUrl,
          'createdAt': now,
          'updatedAt': now,
        });

        await txn.insert(TableConstants.productBatches, {
          'productId': productId,
          'quantity': 50,
          'costPrice': p.typicalCost,
          'expiryDate': expiryDate,
          'createdAt': now,
        });
      }
    });
  }

  Future<void> close() async {
    _database?.close();
    _database = null;
  }
}

