import 'package:sqflite/sqflite.dart';
import '../table_constants.dart';

class MigrationV15 {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableConstants.returns} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        refundAmount REAL NOT NULL DEFAULT 0.0,
        reason TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        createdAt TEXT NOT NULL,
        FOREIGN KEY(saleId) REFERENCES ${TableConstants.sales}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TableConstants.returnItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        returnId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY(returnId) REFERENCES ${TableConstants.returns}(id) ON DELETE CASCADE,
        FOREIGN KEY(productId) REFERENCES ${TableConstants.products}(id)
      )
    ''');

    // Add indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_saleId ON ${TableConstants.returns}(saleId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_createdAt ON ${TableConstants.returns}(createdAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_return_items_returnId ON ${TableConstants.returnItems}(returnId)');
  }
}
