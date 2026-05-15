import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/customer.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get or create customer by phone number
  Future<Customer> getOrCreateByPhone(String phone, String name) async {
    final db = await _dbHelper.database;

    // Try to find existing customer
    final result = await db.query(
      TableConstants.customers,
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }

    // Create new customer
    final now = DateTime.now();
    final customer = Customer(
      id: 0,
      phone: phone,
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert(TableConstants.customers, customer.toMap()..remove('id'));
    return customer.copyWith(id: id);
  }

  Future<Customer?> getByPhone(String phone) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<Customer?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<List<Customer>> searchByName(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'lastPurchaseDate DESC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> searchByPhone(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      where: 'phone LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'lastPurchaseDate DESC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> searchByQuery(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'lastPurchaseDate DESC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> getRecentCustomers({int limit = 10}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      orderBy: 'lastPurchaseDate DESC',
      limit: limit,
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> getAll({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.customers,
      orderBy: 'lastPurchaseDate DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Update customer purchase stats after sale
  Future<int> updateAfterSale(int customerId, double amount) async {
    final db = await _dbHelper.database;
    final customer = await getById(customerId);
    if (customer == null) return 0;

    return db.update(
      TableConstants.customers,
      {
        'lastPurchaseDate': DateTime.now().toIso8601String(),
        'totalSpent': customer.totalSpent + amount,
        'purchaseCount': customer.purchaseCount + 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<int> update(Customer customer) async {
    final db = await _dbHelper.database;
    return db.update(
      TableConstants.customers,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }
}
