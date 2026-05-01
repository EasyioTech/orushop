import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(Product product) async {
    final db = await _dbHelper.database;
    return db.insert('products', product.toMap());
  }

  Future<Product?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<Product?> getBySku(String sku) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('products', orderBy: 'name ASC');
    final products = <Product>[];

    for (final map in result) {
      final product = Product.fromMap(map);
      final batchTotal = await getTotalQuantity(product.id);
      products.add(product.copyWith(liveBatchQuantity: batchTotal));
    }

    return products;
  }

  Future<List<Product>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchByName(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> update(Product product) async {
    final db = await _dbHelper.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTotalQuantity(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM product_batches WHERE productId = ?',
      [productId],
    );
    if (result.isEmpty) return 0;
    final total = result.first['total'];
    if (total == null) return 0;
    return (total is int) ? total : (total as num).toInt();
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM products ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }
}
