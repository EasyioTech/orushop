import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';

class MigrationV11 {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE ${TableConstants.globalCatalog} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        shopType TEXT NOT NULL
      )
    ''');
    
    await db.execute('CREATE INDEX idx_catalog_name ON ${TableConstants.globalCatalog}(name)');
    await db.execute('CREATE INDEX idx_catalog_type ON ${TableConstants.globalCatalog}(shopType)');
  }
}
