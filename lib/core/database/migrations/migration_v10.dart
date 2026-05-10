import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';
import '../../utils/app_logger.dart';

class MigrationV10 {
  static Future<void> up(Database db) async {
    const tag = 'MigrationV10';
    AppLogger.d(tag, 'Applying MigrationV10: product_variants table');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableConstants.productVariants} (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        size      TEXT    NOT NULL DEFAULT '',
        color     TEXT    NOT NULL DEFAULT '',
        sku       TEXT    UNIQUE NOT NULL,
        price     REAL    NOT NULL,
        stock     REAL    NOT NULL DEFAULT 0,
        costPrice REAL,
        createdAt TEXT    NOT NULL,
        updatedAt TEXT    NOT NULL,
        FOREIGN KEY(productId) REFERENCES ${TableConstants.products}(id) ON DELETE CASCADE,
        UNIQUE(productId, size, color)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_variants_productId ON ${TableConstants.productVariants}(productId)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_product_variants_sku ON ${TableConstants.productVariants}(sku)',
    );

    // Add variantId to sale_items so a sale line can point to a specific variant
    final List<Map<String, dynamic>> saleItemCols =
        await db.rawQuery('PRAGMA table_info(${TableConstants.saleItems})');
    final existingSaleItemCols = saleItemCols.map((c) => c['name'] as String).toSet();
    if (!existingSaleItemCols.contains('variantId')) {
      AppLogger.d(tag, 'Adding sale_items.variantId');
      await db.execute(
        'ALTER TABLE ${TableConstants.saleItems} ADD COLUMN variantId INTEGER',
      );
    }

    AppLogger.d(tag, 'MigrationV10 complete');
  }
}
