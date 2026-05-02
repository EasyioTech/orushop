import 'package:sqflite/sqflite.dart';

class MigrationV3 {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS khata_customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        address TEXT,
        notes TEXT,
        creditLimit REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0,
        totalCredit REAL NOT NULL DEFAULT 0,
        totalDebit REAL NOT NULL DEFAULT 0,
        lastTransactionAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS khata_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('credit','debit')),
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        linkedSaleId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(customerId) REFERENCES khata_customers(id) ON DELETE CASCADE,
        FOREIGN KEY(linkedSaleId) REFERENCES sales(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS khata_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT 'cash',
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(customerId) REFERENCES khata_customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_khata_customers_phone ON khata_customers(phone)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_khata_entries_customerId ON khata_entries(customerId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_khata_entries_createdAt ON khata_entries(createdAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_khata_payments_customerId ON khata_payments(customerId)');
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS khata_payments');
    await db.execute('DROP TABLE IF EXISTS khata_entries');
    await db.execute('DROP TABLE IF EXISTS khata_customers');
  }
}
