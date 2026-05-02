import '../database/database_helper.dart';
import '../models/refund.dart';

class RefundRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(Refund refund) async {
    final db = await _dbHelper.database;
    return db.insert('refunds', refund.toMap());
  }

  Future<Refund?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'refunds',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Refund.fromMap(result.first);
  }

  Future<List<Refund>> getBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'refunds',
      where: 'saleId = ?',
      whereArgs: [saleId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<List<Refund>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'refunds',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<List<Refund>> getAll({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'refunds',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<double> getTotalRefundedAmount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(refundAmount) as total FROM refunds WHERE createdAt BETWEEN ? AND ? AND status = ?',
      [start.toIso8601String(), end.toIso8601String(), 'approved'],
    );
    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }

  Future<int> update(Refund refund) async {
    final db = await _dbHelper.database;
    return db.update(
      'refunds',
      refund.toMap(),
      where: 'id = ?',
      whereArgs: [refund.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'refunds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

