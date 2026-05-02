import '../database/database_helper.dart';
import '../models/return.dart';
import '../models/return_item.dart';

class ReturnRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> createReturn(Return return_) async {
    final db = await _dbHelper.database;
    return db.insert('returns', return_.toMap());
  }

  Future<Return?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'returns',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Return.fromMap(result.first);
  }

  Future<List<Return>> getBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'returns',
      where: 'saleId = ?',
      whereArgs: [saleId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Return.fromMap(map)).toList();
  }

  Future<List<Return>> getAll({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'returns',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Return.fromMap(map)).toList();
  }

  Future<int> addReturnItem(ReturnItem item) async {
    final db = await _dbHelper.database;
    return db.insert('return_items', item.toMap());
  }

  Future<List<ReturnItem>> getReturnItems(int returnId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'return_items',
      where: 'returnId = ?',
      whereArgs: [returnId],
    );
    return result.map((map) => ReturnItem.fromMap(map)).toList();
  }

  Future<double> getTotalReturnAmount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(refundAmount) as total FROM returns WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }

  Future<void> restoreInventory(List<Map<int, int>> batchesAndQty) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final entry in batchesAndQty) {
        final batchId = entry.keys.first;
        final quantity = entry[batchId]!;
        await txn.rawUpdate(
          'UPDATE product_batches SET quantity = quantity + ? WHERE id = ?',
          [quantity, batchId],
        );
      }
    });
  }
}

