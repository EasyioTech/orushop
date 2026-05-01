import '../database/database_helper.dart';
import '../models/product_batch.dart';

class BatchRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(ProductBatch batch) async {
    final db = await _dbHelper.database;
    return db.insert('product_batches', batch.toMap());
  }

  Future<ProductBatch?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'product_batches',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ProductBatch.fromMap(result.first);
  }

  Future<List<ProductBatch>> getByProductId(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'product_batches',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'expiryDate ASC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<List<ProductBatch>> getAvailableBatches(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'product_batches',
      where: 'productId = ? AND quantity > 0',
      whereArgs: [productId],
      orderBy: 'expiryDate ASC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<int> update(ProductBatch batch) async {
    final db = await _dbHelper.database;
    return db.update(
      'product_batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<int> deductQuantity(int batchId, int quantity) async {
    final db = await _dbHelper.database;
    return db.rawUpdate(
      'UPDATE product_batches SET quantity = quantity - ? WHERE id = ?',
      [quantity, batchId],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'product_batches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductBatch>> getExpiredBatches() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'product_batches',
      where: 'expiryDate < ?',
      whereArgs: [now],
      orderBy: 'expiryDate ASC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<int> getTotalQuantityByProduct(int productId) async {
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
}
