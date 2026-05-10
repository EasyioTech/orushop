import 'package:sqflite/sqflite.dart';

class MigrationV6 {
  static Future<void> up(Database db) async {
    // Add batchNumber to product_batches
    await _addColumnIfMissing(db, 'product_batches', 'batchNumber', 'TEXT');

    // Add missing product tracking columns
    await _addColumnIfMissing(db, 'products', 'serialNumber', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'imei', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'warranty', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'manufacturer', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'schedule', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'weight', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'recipe', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'isbn', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'size', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'color', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'expiryDate', 'TEXT');
    await _addColumnIfMissing(db, 'products', 'batchNumber', 'TEXT');
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
    // SQLite doesn't support dropping columns easily.
  }
}
