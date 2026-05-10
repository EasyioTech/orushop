import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';
import '../../utils/app_logger.dart';

class MigrationV9 {
  static Future<void> up(Database db) async {
    const tag = 'MigrationV9';
    AppLogger.d(tag, 'Applying MigrationV9: wholesalePrice and costPrice on products');

    final List<Map<String, dynamic>> cols =
        await db.rawQuery('PRAGMA table_info(${TableConstants.products})');
    final existing = cols.map((c) => c['name'] as String).toSet();

    final newCols = {
      'wholesalePrice': 'REAL',
      'costPrice': 'REAL',
    };

    for (final entry in newCols.entries) {
      if (!existing.contains(entry.key)) {
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

    AppLogger.d(tag, 'MigrationV9 complete');
  }
}
