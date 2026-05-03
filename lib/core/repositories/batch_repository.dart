import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/product_batch.dart';

class BatchRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(ProductBatch batch) async {
    final db = await _dbHelper.database;
    return db.insert(TableConstants.productBatches, batch.toMap());
  }

  Future<ProductBatch?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.productBatches,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ProductBatch.fromMap(result.first);
  }

  Future<List<ProductBatch>> getByProductId(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.productBatches,
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'expiryDate ASC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<List<ProductBatch>> getAvailableBatches(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.productBatches,
      where: 'productId = ? AND quantity > 0',
      whereArgs: [productId],
      orderBy: 'expiryDate ASC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<int> update(ProductBatch batch) async {
    final db = await _dbHelper.database;
    return db.update(
      TableConstants.productBatches,
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<int> deductQuantity(int batchId, int quantity) async {
    final db = await _dbHelper.database;
    return db.rawUpdate(
      'UPDATE ${TableConstants.productBatches} SET quantity = quantity - ? WHERE id = ?',
      [quantity, batchId],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      TableConstants.productBatches,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductBatch>> getExpiredBatches() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      TableConstants.productBatches,
      where: 'expiryDate < ?',
      whereArgs: [now],
      orderBy: 'expiryDate ASC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<int> getTotalQuantityByProduct(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM ${TableConstants.productBatches} WHERE productId = ?',
      [productId],
    );
    if (result.isEmpty) return 0;
    final total = result.first['total'];
    if (total == null) return 0;
    return (total is int) ? total : (total as num).toInt();
  }

  Future<List<ProductBatch>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.productBatches,
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => ProductBatch.fromMap(map)).toList();
  }

  Future<void> syncBatchesForProduct(int productId, int productQuantity) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final batchResult = await txn.query(
        TableConstants.productBatches,
        where: 'productId = ?',
        whereArgs: [productId],
      );

      final currentBatchTotal = batchResult.fold<int>(0, (sum, b) => sum + (b['quantity'] as int? ?? 0));

      if (currentBatchTotal == 0 && productQuantity > 0) {
        await txn.insert(TableConstants.productBatches, {
          'productId': productId,
          'quantity': productQuantity,
          'costPrice': 0,
          'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else if (currentBatchTotal != productQuantity) {
        final difference = productQuantity - currentBatchTotal;
        if (difference > 0) {
          await txn.insert(TableConstants.productBatches, {
            'productId': productId,
            'quantity': difference,
            'costPrice': 0,
            'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }
}

