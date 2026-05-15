import 'package:sqflite/sqflite.dart';

class MigrationV17 {
  static Future<void> up(Database db) async {
    // Customers table for lookup and repeat sales tracking
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        lastPurchaseDate TEXT,
        totalSpent REAL NOT NULL DEFAULT 0,
        purchaseCount INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Add customerId foreign key to sales table
    try {
      await db.execute('ALTER TABLE sales ADD COLUMN customerId INTEGER');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_customerId ON sales(customerId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_customerPhone ON sales(customerPhone)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_createdAt ON customers(createdAt)');
    } catch (e) {
      // Column might already exist, that's fine
    }
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS customers');
  }
}
