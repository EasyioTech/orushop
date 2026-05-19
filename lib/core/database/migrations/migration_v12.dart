import 'package:sqflite/sqflite.dart';

class MigrationV12 {
  static Future<void> migrate(Database db) async {
    // 1. Add template column to products
    await db.execute("ALTER TABLE products ADD COLUMN template TEXT DEFAULT 'standardRetail'");

    // 2. Create inventory_standard table (Standard, Bulk/UOM, Service/Labor)
    await db.execute('''
      CREATE TABLE inventory_standard (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        sellingPrice REAL NOT NULL,
        mrp REAL,
        costPrice REAL,
        wholesalePrice REAL,
        quantity REAL NOT NULL DEFAULT 0.0,
        reorderLevel REAL DEFAULT 0.0,
        unit TEXT NOT NULL DEFAULT 'Piece',
        packagingUnit TEXT,
        conversionFactor REAL,
        serviceDuration INTEGER,
        staffCommission REAL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 3. Create inventory_serialized table (Electronics/Serialized)
    await db.execute('''
      CREATE TABLE inventory_serialized (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        serialNumber TEXT NOT NULL,
        imei TEXT,
        warrantyExpiry TEXT,
        sellingPrice REAL NOT NULL,
        mrp REAL,
        costPrice REAL,
        status TEXT NOT NULL DEFAULT 'Available',
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 4. Data Migration: Move existing data to inventory_standard
    // We assume most existing products are standardRetail unless they have serial/imei

    // First, identify products that should be 'serialized'
    await db.execute('''
      UPDATE products
      SET template = 'serialized'
      WHERE serialNumber IS NOT NULL OR imei IS NOT NULL
    ''');

    // Identify products that are services
    await db.execute('''
      UPDATE products
      SET template = 'serviceLabor'
      WHERE isService = 1
    ''');

    // Identify products that are batch-tracked (if they have entries in product_batches)
    // This is a bit complex in SQL, we can do it via subquery
    await db.execute('''
      UPDATE products
      SET template = 'batchExpiry'
      WHERE id IN (SELECT DISTINCT productId FROM product_batches)
    ''');

    // Insert data into inventory_standard for standardRetail, serviceLabor, bulkUom
    await db.execute('''
      INSERT INTO inventory_standard (
        productId, sellingPrice, mrp, costPrice, wholesalePrice,
        quantity, unit, serviceDuration, staffCommission
      )
      SELECT
        id, price, mrp, costPrice, wholesalePrice,
        quantity, unit, NULL, NULL
      FROM products
      WHERE template IN ('standardRetail', 'serviceLabor', 'bulkUom')
    ''');

    // Insert data into inventory_serialized
    await db.execute('''
      INSERT INTO inventory_serialized (
        productId, serialNumber, imei, warrantyExpiry,
        sellingPrice, mrp, costPrice, status
      )
      SELECT
        id, serialNumber, imei, warranty,
        price, mrp, costPrice, 'Available'
      FROM products
      WHERE template = 'serialized'
    ''');
  }
}
