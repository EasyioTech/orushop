import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(Order order, List<OrderItem> items) async {
    final db = await _dbHelper.database;
    int orderId = 0;
    await db.transaction((txn) async {
      orderId = await txn.insert('orders', order.toMap());
      for (var item in items) {
        final itemWithOrderId = item.copyWith(orderId: orderId);
        await txn.insert('order_items', itemWithOrderId.toMap());
      }
    });
    return orderId;
  }

  Future<Order?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Order.fromMap(result.first);
  }

  Future<List<Order>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'orders',
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Order.fromMap(map)).toList();
  }

  Future<List<Order>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Order.fromMap(map)).toList();
  }

  Future<List<Order>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'orders',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Order.fromMap(map)).toList();
  }

  Future<int> update(Order order) async {
    final db = await _dbHelper.database;
    return db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> cancel(int orderId) async {
    final db = await _dbHelper.database;
    return db.update(
      'orders',
      {'status': 'cancelled'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    return result.map((map) => OrderItem.fromMap(map)).toList();
  }

  Future<int> updateOrderItem(OrderItem item) async {
    final db = await _dbHelper.database;
    return db.update(
      'order_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

