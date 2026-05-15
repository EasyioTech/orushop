import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';

class MigrationV16 {
  static Future<void> up(Database db) async {
    // Add mrp and barcode to product_variants
    final List<Map<String, dynamic>> variantCols =
        await db.rawQuery('PRAGMA table_info(${TableConstants.productVariants})');
    final existingVariantCols = variantCols.map((c) => c['name'] as String).toSet();

    if (!existingVariantCols.contains('mrp')) {
      await db.execute('ALTER TABLE ${TableConstants.productVariants} ADD COLUMN mrp REAL');
    }
    if (!existingVariantCols.contains('barcode')) {
      await db.execute('ALTER TABLE ${TableConstants.productVariants} ADD COLUMN barcode TEXT');
    }
  }
}
