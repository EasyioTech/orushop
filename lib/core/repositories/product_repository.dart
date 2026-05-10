import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(Product product) async {
    final db = await _dbHelper.database;
    return db.insert(TableConstants.products, product.toMap());
  }

  Future<Product?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*, 
             (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
             (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
             (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
      FROM ${TableConstants.products} p
      WHERE p.id = ?
    ''', [id]);
    
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<Product?> getBySku(String sku) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*, 
             (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
             (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
             (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
      FROM ${TableConstants.products} p
      WHERE p.sku = ?
    ''', [sku]);
    
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*, 
             (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
             (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
             (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
      FROM ${TableConstants.products} p
      ORDER BY p.name ASC
    ''');
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getPaginated(int limit, int offset) async {
    final db = await _dbHelper.database;
    
    // Optimized query to fetch products with their total batch quantity in one go
    final result = await db.rawQuery('''
      SELECT p.*, 
             (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
             (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
             (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
      FROM ${TableConstants.products} p
      ORDER BY p.name ASC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*,
             (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
             (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
             (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
      FROM ${TableConstants.products} p
      WHERE p.category = ?
      ORDER BY p.name ASC
    ''', [category]);
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchByName(String query) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*,
             (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
             (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
             (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
      FROM ${TableConstants.products} p
      WHERE p.name LIKE ?
      ORDER BY p.name ASC
    ''', ['%$query%']);
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> update(Product product) async {
    final db = await _dbHelper.database;
    return db.update(
      TableConstants.products,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      TableConstants.products,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalQuantity(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM ${TableConstants.productBatches} WHERE productId = ?',
      [productId],
    );
    final total = result.first['total'];
    return (total is num) ? total.toDouble() : 0.0;
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM ${TableConstants.products} ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return db.delete(TableConstants.products);
  }
}

