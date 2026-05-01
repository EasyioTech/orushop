import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import 'batch_repository.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final BatchRepository _batchRepository = BatchRepository();

  Future<int> create(Sale sale) async {
    final db = await _dbHelper.database;
    return db.insert('sales', sale.toMap());
  }

  Future<Sale?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Sale.fromMap(result.first);
  }

  Future<List<Sale>> getAll({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<double> getTotalSalesAmount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM sales WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }

  Future<int> getSalesCount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final count = result.first['count'] as int?;
    return count ?? 0;
  }

  Future<int> update(Sale sale) async {
    final db = await _dbHelper.database;
    return db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> addItem(SaleItem item) async {
    final db = await _dbHelper.database;
    return db.insert('sale_items', item.toMap());
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sale_items',
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
    return result.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<double> getAverageSalesValue(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT AVG(finalAmount) as average FROM sales WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final average = result.first['average'] as double?;
    return average ?? 0.0;
  }

  Future<List<int>> deductFIFO(int productId, int quantity) async {
    final db = await _dbHelper.database;
    final batches = await _batchRepository.getAvailableBatches(productId);

    if (batches.isEmpty) {
      throw Exception('No available batches for product $productId');
    }

    final totalAvailable = batches.fold<int>(0, (sum, b) => sum + b.quantity);
    if (totalAvailable < quantity) {
      throw Exception('Insufficient stock. Required: $quantity, Available: $totalAvailable');
    }

    final usedBatchIds = <int>[];
    var remainingQty = quantity;

    await db.transaction((txn) async {
      for (final batch in batches) {
        if (remainingQty <= 0) break;

        final deductQty = remainingQty > batch.quantity ? batch.quantity : remainingQty;
        await txn.rawUpdate(
          'UPDATE product_batches SET quantity = quantity - ? WHERE id = ?',
          [deductQty, batch.id],
        );
        usedBatchIds.add(batch.id);
        remainingQty -= deductQty;
      }
    });

    return usedBatchIds;
  }
}
