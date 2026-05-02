import 'package:sqflite/sqflite.dart';

class MigrationV1 {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        imageUrl TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        costPrice REAL NOT NULL,
        expiryDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalAmount REAL NOT NULL,
        discountAmount REAL NOT NULL DEFAULT 0,
        finalAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        transactionId TEXT,
        customerPhone TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        createdAt TEXT NOT NULL,
        syncedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        batchIds TEXT NOT NULL,
        FOREIGN KEY(saleId) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventType TEXT NOT NULL,
        entityType TEXT NOT NULL,
        entityId INTEGER NOT NULL,
        changes TEXT NOT NULL,
        previousHash TEXT,
        currentHash TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        storeName TEXT NOT NULL,
        storePhone TEXT NOT NULL,
        storeAddress TEXT NOT NULL,
        currencySymbol TEXT NOT NULL DEFAULT '₹',
        enableDiscounts INTEGER NOT NULL DEFAULT 1,
        enableUpi INTEGER NOT NULL DEFAULT 1,
        defaultDiscountPercent REAL NOT NULL DEFAULT 0,
        lastSyncTime TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS refunds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        refundAmount REAL NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        processedAt TEXT,
        FOREIGN KEY(saleId) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderNumber TEXT UNIQUE NOT NULL,
        supplierName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        expectedDelivery TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        receivedAt TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        receivedQuantity INTEGER,
        FOREIGN KEY(orderId) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_batches_productId ON product_batches(productId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_createdAt ON sales(createdAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_saleId ON sale_items(saleId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_event_logs_timestamp ON event_logs(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_event_logs_entityType ON event_logs(entityType)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_refunds_saleId ON refunds(saleId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_refunds_status ON refunds(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_expectedDelivery ON orders(expectedDelivery)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_createdAt ON orders(createdAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_order_items_orderId ON order_items(orderId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_order_items_productId ON order_items(productId)');
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS order_items');
    await db.execute('DROP TABLE IF EXISTS orders');
    await db.execute('DROP TABLE IF EXISTS refunds');
    await db.execute('DROP TABLE IF EXISTS sale_items');
    await db.execute('DROP TABLE IF EXISTS sales');
    await db.execute('DROP TABLE IF EXISTS product_batches');
    await db.execute('DROP TABLE IF EXISTS event_logs');
    await db.execute('DROP TABLE IF EXISTS products');
    await db.execute('DROP TABLE IF EXISTS app_settings');
  }
}

