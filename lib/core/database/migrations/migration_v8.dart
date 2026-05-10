import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';
import '../../utils/app_logger.dart';

class MigrationV8 {
  static Future<void> up(Database db) async {
    const tag = 'MigrationV8';
    AppLogger.d(tag, 'Applying MigrationV8: isService, isLoose, fractional sale quantity');

    // Add isService and isLoose to products
    final List<Map<String, dynamic>> productCols =
        await db.rawQuery('PRAGMA table_info(${TableConstants.products})');
    final existingProductCols = productCols.map((c) => c['name'] as String).toSet();

    final newProductCols = {
      'isService': 'INTEGER NOT NULL DEFAULT 0',
      'isLoose': 'INTEGER NOT NULL DEFAULT 0',
    };
    for (final entry in newProductCols.entries) {
      if (!existingProductCols.contains(entry.key)) {
        AppLogger.d(tag, 'Adding products.${entry.key}');
        try {
          await db.execute(
            'ALTER TABLE ${TableConstants.products} ADD COLUMN ${entry.key} ${entry.value}',
          );
        } catch (e) {
          AppLogger.w(tag, 'Skip ${entry.key}: $e');
        }
      }
    }

    // SQLite cannot change column type; quantity in sale_items is stored as REAL from now on.
    // Existing INTEGER values are automatically readable as REAL — no migration needed for data.
    // New rows written by the app will use REAL. Nothing to do for sale_items table structure.
    AppLogger.d(tag, 'MigrationV8 complete');
  }
}
