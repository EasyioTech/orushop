import 'package:sqflite/sqflite.dart';
import '../../../features/inventory/data/service_categories_seed.dart';

/// Migration v20 — Setup Service Separated Tables (service_details, staff, staff_service_assignments, service_categories)
class MigrationV20 {
  static Future<void> up(Database db) async {
    // 1. service_details Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL UNIQUE,
        durationMinutes INTEGER,
        durationUnit TEXT NOT NULL DEFAULT 'Session',
        availabilityNotes TEXT,
        bookingEnabled INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // 2. staff Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT,
        phone TEXT,
        photoPath TEXT,
        hourlyRate REAL DEFAULT 0.0,
        commissionPct REAL DEFAULT 0.0,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 3. staff_service_assignments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_service_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staffId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        priceOverride REAL,
        durationOverride INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(staffId) REFERENCES staff(id) ON DELETE CASCADE,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE(staffId, productId)
      )
    ''');

    // 4. service_categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        shopType TEXT,
        isSystem INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Indexes for foreign keys
    await db.execute('CREATE INDEX IF NOT EXISTS idx_service_details_productId ON service_details(productId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_staff_service_assignments_staffId ON staff_service_assignments(staffId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_staff_service_assignments_productId ON staff_service_assignments(productId)');

    // Seed the service_categories table
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final cat in ServiceCategorySeed.categories) {
      batch.insert('service_categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'shopType': cat['shopType'],
        'isSystem': cat['isSystem'],
        'sortOrder': cat['sortOrder'],
        'createdAt': now,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS service_details');
    await db.execute('DROP TABLE IF EXISTS staff_service_assignments');
    await db.execute('DROP TABLE IF EXISTS staff');
    await db.execute('DROP TABLE IF EXISTS service_categories');
  }
}
