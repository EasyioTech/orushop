import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/khata_customer.dart';
import '../models/khata_entry.dart';
import '../models/khata_payment.dart';

class KhataRepository {
  final DatabaseHelper _db;

  KhataRepository(this._db);

  // ── Customers ──────────────────────────────────────────────────────────────

  Future<List<KhataCustomer>> getAllCustomers({String? search}) async {
    final db = await _db.database;
    List<Map<String, dynamic>> rows;
    if (search != null && search.isNotEmpty) {
      rows = await db.query(
        TableConstants.khataCustomers,
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$search%', '%$search%'],
        orderBy: 'lastTransactionAt DESC, name ASC',
      );
    } else {
      rows = await db.query(
        TableConstants.khataCustomers,
        orderBy: 'lastTransactionAt DESC, name ASC',
      );
    }
    return rows.map(KhataCustomer.fromMap).toList();
  }

  Future<KhataCustomer?> getCustomerById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.khataCustomers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KhataCustomer.fromMap(rows.first);
  }

  Future<KhataCustomer?> getCustomerByPhone(String phone) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.khataCustomers,
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KhataCustomer.fromMap(rows.first);
  }

  Future<int> addCustomer(KhataCustomer customer) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    return db.insert(TableConstants.khataCustomers, {
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'notes': customer.notes,
      'creditLimit': customer.creditLimit,
      'balance': 0,
      'totalCredit': 0,
      'totalDebit': 0,
      'lastTransactionAt': null,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateCustomer(KhataCustomer customer) async {
    final db = await _db.database;
    await db.update(
      TableConstants.khataCustomers,
      {
        'name': customer.name,
        'phone': customer.phone,
        'address': customer.address,
        'notes': customer.notes,
        'creditLimit': customer.creditLimit,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(int id) async {
    final db = await _db.database;
    await db.delete(
      TableConstants.khataCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Entries ────────────────────────────────────────────────────────────────

  Future<List<KhataEntry>> getEntriesForCustomer(int customerId) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.khataEntries,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<void> addEntry({
    required int customerId,
    required KhataEntryType type,
    required double amount,
    required String description,
    int? linkedSaleId,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(TableConstants.khataEntries, {
        'customerId': customerId,
        'type': type.name,
        'amount': amount,
        'description': description,
        'linkedSaleId': linkedSaleId,
        'createdAt': now,
      });

      // Update running balance and totals atomically
      if (type == KhataEntryType.credit) {
        await txn.rawUpdate('''
          UPDATE ${TableConstants.khataCustomers}
          SET balance = balance + ?,
              totalCredit = totalCredit + ?,
              lastTransactionAt = ?,
              updatedAt = ?
          WHERE id = ?
        ''', [amount, amount, now, now, customerId]);
      } else {
        await txn.rawUpdate('''
          UPDATE ${TableConstants.khataCustomers}
          SET balance = balance - ?,
              totalDebit = totalDebit + ?,
              lastTransactionAt = ?,
              updatedAt = ?
          WHERE id = ?
        ''', [amount, amount, now, now, customerId]);
      }
    });
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  Future<List<KhataPayment>> getPaymentsForCustomer(int customerId) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.khataPayments,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(KhataPayment.fromMap).toList();
  }

  Future<void> recordPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(TableConstants.khataPayments, {
        'customerId': customerId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'createdAt': now,
      });

      // Payment reduces the outstanding balance
      await txn.rawUpdate('''
        UPDATE ${TableConstants.khataCustomers}
        SET balance = balance - ?,
            totalDebit = totalDebit + ?,
            lastTransactionAt = ?,
            updatedAt = ?
        WHERE id = ?
      ''', [amount, amount, now, now, customerId]);
    });
  }

  // ── Summary ────────────────────────────────────────────────────────────────

  Future<Map<String, double>> getOverallSummary() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN balance > 0 THEN balance ELSE 0 END) AS totalReceivable,
        SUM(CASE WHEN balance < 0 THEN ABS(balance) ELSE 0 END) AS totalPayable,
        COUNT(*) AS totalCustomers
      FROM ${TableConstants.khataCustomers}
    ''');
    final row = result.first;
    return {
      'totalReceivable': (row['totalReceivable'] as num?)?.toDouble() ?? 0,
      'totalPayable': (row['totalPayable'] as num?)?.toDouble() ?? 0,
      'totalCustomers': (row['totalCustomers'] as num?)?.toDouble() ?? 0,
    };
  }

  // ── Combined ledger for a customer (entries + payments merged & sorted) ──

  Future<List<Map<String, dynamic>>> getLedgerForCustomer(int customerId) async {
    final db = await _db.database;

    final entries = await db.rawQuery('''
      SELECT id, 'entry' as recordType, type, amount, description as note, createdAt
      FROM ${TableConstants.khataEntries}
      WHERE customerId = ?
    ''', [customerId]);

    final payments = await db.rawQuery('''
      SELECT id, 'payment' as recordType, 'debit' as type, amount,
             COALESCE('Payment via ' || paymentMethod, 'Payment') as note, createdAt
      FROM ${TableConstants.khataPayments}
      WHERE customerId = ?
    ''', [customerId]);

    final combined = [...entries, ...payments];
    combined.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return combined;
  }

  Future<List<KhataEntry>> getAllEntries() async {
    final db = await _db.database;
    final rows = await db.query(TableConstants.khataEntries);
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<List<KhataPayment>> getAllPayments() async {
    final db = await _db.database;
    final rows = await db.query(TableConstants.khataPayments);
    return rows.map(KhataPayment.fromMap).toList();
  }
}
