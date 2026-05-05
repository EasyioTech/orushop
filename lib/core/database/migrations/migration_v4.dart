import 'package:sqflite/sqflite.dart';

/// Adds product_categories and product_subcategories tables.
/// These are seeded during onboarding from ShopCatalog and can be
/// customised later by the shop owner.
class MigrationV4 {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        shopType TEXT NOT NULL DEFAULT '',
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES product_categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_categories_shopType ON product_categories(shopType)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subcategories_categoryId ON product_subcategories(categoryId)',
    );

    // Add new columns to existing products table (safe, nullable with defaults)
    await _addColumnIfMissing(db, 'products', 'subcategory', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'unit', "TEXT NOT NULL DEFAULT 'Piece'");
    await _addColumnIfMissing(db, 'products', 'mrp', 'REAL');
    await _addColumnIfMissing(db, 'products', 'hsnCode', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'taxRate', 'REAL NOT NULL DEFAULT 0.0');
    await _addColumnIfMissing(db, 'products', 'brand', 'TEXT');
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS product_subcategories');
    await db.execute('DROP TABLE IF EXISTS product_categories');
    // SQLite does not support DROP COLUMN; skipping revert of products columns.
  }
}
