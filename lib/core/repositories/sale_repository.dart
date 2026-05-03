import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../exceptions/backend_exception.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/cart_item.dart';
import '../models/product_batch.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(Sale sale) async {
    final db = await _dbHelper.database;
    final map = sale.toMap()..remove('id');
    return db.insert(TableConstants.sales, map);
  }

  Future<Sale?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.sales,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Sale.fromMap(result.first);
  }

  Future<List<Sale>> getAll({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.sales,
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.sales,
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.sales,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<double> getTotalSalesAmount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(finalAmount) as total FROM ${TableConstants.sales} WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final row = result.isNotEmpty ? result.first : {};
    final total = row['total'] as double?;
    return total ?? 0.0;
  }

  Future<int> getSalesCount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${TableConstants.sales} WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final row = result.isNotEmpty ? result.first : {};
    final count = row['count'] as int?;
    return count ?? 0;
  }

  Future<int> update(Sale sale) async {
    final db = await _dbHelper.database;
    return db.update(
      TableConstants.sales,
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> addItem(Transaction txn, SaleItem item) async {
    final map = item.toMap()..remove('id');
    return txn.insert(TableConstants.saleItems, map);
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      TableConstants.saleItems,
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
    return result.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<double> getAverageSalesValue(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT AVG(finalAmount) as average FROM ${TableConstants.sales} WHERE createdAt BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final average = result.first['average'] as double?;
    return average ?? 0.0;
  }

  Future<Map<String, dynamic>> processCompleteSale({
    required Sale sale,
    required List<CartItem> items,
  }) async {
    final db = await _dbHelper.database;

    try {
      return await db.transaction((txn) async {
        debugPrint('SaleRepository: Starting transaction for ${items.length} items');

        // 1. Create Sale record
        final saleMap = sale.toMap()..remove('id');
        final saleId = await txn.insert(TableConstants.sales, saleMap);
        final saleWithId = sale.copyWith(id: saleId);

        final List<SaleItem> processedItems = [];

          // 2. Process each item
        for (final item in items) {
          // Fetch batches inside transaction with a row-level lock (implicit in txn)
          final List<Map<String, dynamic>> batchMaps = await txn.query(
            TableConstants.productBatches,
            where: 'productId = ? AND quantity > 0',
            whereArgs: [item.productId],
            orderBy: 'expiryDate ASC', // FIFO logic
          );

          var batches = batchMaps.map((m) => ProductBatch.fromMap(m)).toList();

          // Calculate what we have in batches
          var totalAvailableInBatches = batches.fold<int>(0, (sum, b) => sum + b.quantity);
          
          // FETCH source-of-truth quantity from products table
          final List<Map<String, dynamic>> productResult = await txn.query(
            TableConstants.products,
            columns: ['quantity'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          
          final productTotal = productResult.isNotEmpty ? (productResult.first['quantity'] as int) : 0;
          
          // AUTOMATIC SYNC: If batches are missing but product table says we have stock,
          // or if product table has more than batches, create a correction batch.
          if (productTotal > totalAvailableInBatches) {
            final gap = productTotal - totalAvailableInBatches;
            debugPrint('SaleRepository: Stock discrepancy detected for ${item.productName}. Batches: $totalAvailableInBatches, Product Total: $productTotal. Creating auto-batch for gap: $gap');
            
            final batchId = await txn.insert(TableConstants.productBatches, {
              'productId': item.productId,
              'quantity': gap,
              'costPrice': 0.0,
              'expiryDate': DateTime.now().add(const Duration(days: 3650)).toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
            });
            
            final newBatch = ProductBatch(
              id: batchId,
              productId: item.productId,
              quantity: gap,
              costPrice: 0.0,
              expiryDate: DateTime.now().add(const Duration(days: 3650)),
              createdAt: DateTime.now(),
            );
            batches.add(newBatch);
            totalAvailableInBatches += gap;
          }

          // Final Validation against synced total
          if (totalAvailableInBatches < item.quantity) {
            throw InsufficientStockException(item.productName, item.quantity, totalAvailableInBatches);
          }

          final usedBatchIds = <int>[];
          var remainingQty = item.quantity;

          // 3. Deduct from batches (FIFO)
          for (final batch in batches) {
            if (remainingQty <= 0) break;

            final deductQty = remainingQty > batch.quantity ? batch.quantity : remainingQty;
            
            final count = await txn.rawUpdate(
              'UPDATE ${TableConstants.productBatches} SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [deductQty, batch.id, deductQty],
            );

            if (count == 0) {
              throw TransactionException('Race condition detected for batch ${batch.id}. Stock was modified externally.');
            }

            usedBatchIds.add(batch.id);
            remainingQty -= deductQty;
          }

          // 4. Update summary quantity in products table for fast lookups
          await txn.rawUpdate(
            'UPDATE ${TableConstants.products} SET quantity = quantity - ? WHERE id = ?',
            [item.quantity, item.productId],
          );

          // 5. Create Sale Item record
          final saleItem = SaleItem(
            id: 0,
            saleId: saleId,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice.toDouble(),
            totalPrice: (item.quantity * item.unitPrice).toDouble(),
            batchIds: usedBatchIds,
          );

          final saleItemId = await addItem(txn, saleItem);
          processedItems.add(saleItem.copyWith(id: saleItemId));
        }

        debugPrint('SaleRepository: Transaction successful. Sale ID: $saleId');
        return {
          'sale': saleWithId,
          'items': processedItems,
        };
      });
    } catch (e) {
      debugPrint('SaleRepository: Transaction failed: $e');
      if (e is BackendException) rethrow;
      throw TransactionException('Failed to process sale: $e');
    }
  }
}

