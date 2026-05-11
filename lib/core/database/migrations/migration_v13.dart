import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';
import '../../utils/app_logger.dart';

class MigrationV13 {
  static Future<void> up(Database db) async {
    const tag = 'MigrationV13';
    AppLogger.d(tag, 'Applying MigrationV13: Adding mrp and barcode to product_variants');

    final List<Map<String, dynamic>> variantCols =
        await db.rawQuery('PRAGMA table_info(${TableConstants.productVariants})');
    final existingVariantCols = variantCols.map((c) => c['name'] as String).toSet();

    if (!existingVariantCols.contains('mrp')) {
      await db.execute('ALTER TABLE ${TableConstants.productVariants} ADD COLUMN mrp REAL');
    }
    if (!existingVariantCols.contains('barcode')) {
      await db.execute('ALTER TABLE ${TableConstants.productVariants} ADD COLUMN barcode TEXT');
    }

    AppLogger.d(tag, 'MigrationV13 complete');
  }
}
