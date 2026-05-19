import 'package:sqflite/sqflite.dart';

/// Migration v18 — back-fill `inventory_standard` for product templates that
/// migration v12 left out.
///
/// v12 only seeded `inventory_standard` for `standardRetail`, `serviceLabor`
/// and `bulkUom`. Products whose template is `batchExpiry`, `batchMultiUom`
/// or `variantMatrix` therefore have no pricing row, which breaks any read
/// path that joins through `inventory_standard`. This migration inserts the
/// missing rows from the core `products` table.
class MigrationV18 {
  static Future<void> up(Database db) async {
    await db.execute('''
      INSERT INTO inventory_standard (
        productId, sellingPrice, mrp, costPrice, wholesalePrice,
        quantity, unit
      )
      SELECT
        id, price, mrp, costPrice, wholesalePrice,
        quantity, unit
      FROM products
      WHERE template IN ('batchExpiry', 'batchMultiUom', 'variantMatrix')
        AND id NOT IN (SELECT productId FROM inventory_standard)
    ''');
  }
}
