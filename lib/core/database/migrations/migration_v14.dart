import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';

class MigrationV14 {
  static Future<void> up(Database db) async {
    await db.execute('ALTER TABLE ${TableConstants.globalCatalog} ADD COLUMN sku TEXT');
    await db.execute('CREATE INDEX idx_catalog_sku ON ${TableConstants.globalCatalog}(sku)');
  }
}
