import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';
import '../../utils/app_logger.dart';

class MigrationV7 {
  static Future<void> up(Database db) async {
    const tag = 'MigrationV7';
    AppLogger.d(tag, 'Applying MigrationV7: Adding missing columns to products table');

    final List<Map<String, dynamic>> columns =
        await db.rawQuery('PRAGMA table_info(${TableConstants.products})');
    
    final existingColumns = columns.map((col) => col['name'] as String).toSet();

    final requiredColumns = {
      'subcategory': 'TEXT',
      'unit': "TEXT NOT NULL DEFAULT 'Piece'",
      'mrp': 'REAL',
      'hsnCode': 'TEXT',
      'taxRate': 'REAL NOT NULL DEFAULT 0.0',
      'brand': 'TEXT',
      'manufacturer': 'TEXT',
      'serialNumber': 'TEXT',
      'imei': 'TEXT',
      'warranty': 'TEXT',
      'schedule': 'TEXT',
      'weight': 'TEXT',
      'recipe': 'TEXT',
      'isbn': 'TEXT',
      'size': 'TEXT',
      'color': 'TEXT',
      'expiryDate': 'TEXT',
      'batchNumber': 'TEXT',
      'imageUrl': 'TEXT',
      'imagePath': 'TEXT',
    };

    for (final entry in requiredColumns.entries) {
      if (!existingColumns.contains(entry.key)) {
        AppLogger.d(tag, 'Adding ${entry.key} column');
        try {
          await db.execute('ALTER TABLE ${TableConstants.products} ADD COLUMN ${entry.key} ${entry.value}');
        } catch (e) {
          AppLogger.w(tag, 'Failed to add column ${entry.key}: $e');
        }
      }
    }
  }
}
