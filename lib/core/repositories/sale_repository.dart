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
          // FETCH product meta (quantity, isService, template) for this item
          final List<Map<String, dynamic>> productResult = await txn.query(
            TableConstants.products,
            columns: ['quantity', 'isService', 'template', 'name', 'costPrice', 'hsnCode', 'taxRate'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (productResult.isEmpty) {
            throw TransactionException('Product ${item.productId} not found');
          }

          final productData = productResult.first;
          final isService = (productData['isService'] as int? ?? 0) == 1;
          final template = productData['template'] as String? ?? 'standardRetail';
          final productName = productData['name'] as String? ?? 'Unknown Product';
          final usedBatchIds = <int>[];

          // --- STOCK DEDUCTION LOGIC ---
          if (isService) {
            debugPrint('SaleRepository: Skipping stock deduction for service: $productName');
          } else if (template == 'variantMatrix') {
            if (item.variantId == null) {
              throw TransactionException('Variant ID missing for variant product: $productName');
            }
            final variantCount = await txn.rawUpdate(
              'UPDATE ${TableConstants.productVariants} SET stock = stock - ?, updatedAt = ? WHERE id = ? AND stock >= ?',
              [item.quantity, DateTime.now().toIso8601String(), item.variantId, item.quantity],
            );
            if (variantCount == 0) {
              final varData = await txn.query(TableConstants.productVariants, columns: ['stock'], where: 'id = ?', whereArgs: [item.variantId]);
              final currentStock = varData.isNotEmpty ? (varData.first['stock'] as num).toDouble() : 0.0;
              throw InsufficientStockException(productName, item.quantity, currentStock);
            }
          } else if (template == 'serialized') {
            final availableSerials = await txn.query(
              TableConstants.inventorySerialized,
              where: 'productId = ? AND status = ?',
              whereArgs: [item.productId, 'Available'],
              limit: item.quantity.toInt(),
            );

            if (availableSerials.length < item.quantity) {
              throw InsufficientStockException(productName, item.quantity, availableSerials.length.toDouble());
            }

            for (final serial in availableSerials) {
              await txn.update(
                TableConstants.inventorySerialized,
                {'status': 'Sold'},
                where: 'id = ?',
                whereArgs: [serial['id']],
              );
            }
          } else {
            // Standard / Batch / Bulk
            final batchMaps = await txn.query(
              TableConstants.productBatches,
              where: 'productId = ? AND quantity > 0',
              whereArgs: [item.productId],
              orderBy: 'expiryDate ASC',
            );

            var batches = batchMaps.map((m) => ProductBatch.fromMap(m)).toList();
            var totalAvailableInBatches = batches.fold<double>(0.0, (sum, b) => sum + b.quantity);
            final productTotal = (productData['quantity'] as num).toDouble();
            
            // Sync batches if master quantity is higher (auto-correction)
            if (productTotal > totalAvailableInBatches) {
              final gap = productTotal - totalAvailableInBatches;
              final batchId = await txn.insert(TableConstants.productBatches, {
                'productId': item.productId,
                'quantity': gap,
                'costPrice': (productData['costPrice'] as num?)?.toDouble() ?? 0.0,
                'batchNumber': 'AUTO-CORRECT',
                'expiryDate': DateTime.now().add(const Duration(days: 3650)).toIso8601String(),
                'createdAt': DateTime.now().toIso8601String(),
              });
              
              batches.add(ProductBatch(
                id: batchId,
                productId: item.productId,
                quantity: gap,
                costPrice: 0.0,
                expiryDate: DateTime.now().add(const Duration(days: 3650)),
                createdAt: DateTime.now(),
              ));
              totalAvailableInBatches += gap;
            }

            if (totalAvailableInBatches < item.quantity) {
              throw InsufficientStockException(productName, item.quantity, totalAvailableInBatches);
            }

            var remainingQty = item.quantity;
            for (final batch in batches) {
              if (remainingQty <= 0) break;
              final deductQty = remainingQty > batch.quantity ? batch.quantity : remainingQty;
              
              await txn.rawUpdate(
                'UPDATE ${TableConstants.productBatches} SET quantity = quantity - ? WHERE id = ?',
                [deductQty, batch.id],
              );

              usedBatchIds.add(batch.id);
              remainingQty -= deductQty;
            }

            // Update inventory_standard
            await txn.rawUpdate(
              'UPDATE ${TableConstants.inventoryStandard} SET quantity = quantity - ? WHERE productId = ?',
              [item.quantity, item.productId],
            );
          }

          // COMMON: Update master product total for all physical goods
          if (!isService) {
            await txn.rawUpdate(
              'UPDATE ${TableConstants.products} SET quantity = quantity - ?, updatedAt = ? WHERE id = ?',
              [item.quantity, DateTime.now().toIso8601String(), item.productId],
            );
          }

          // Create Sale Item record (include product meta for receipt display)
          final hsnCode = productData['hsnCode'] as String?;
          final taxRate = (productData['taxRate'] as num?)?.toDouble() ?? 0.0;

          final saleItem = SaleItem(
            id: 0,
            saleId: saleId,
            productId: item.productId,
            variantId: item.variantId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            totalPrice: item.quantity * item.unitPrice,
            batchIds: usedBatchIds,
            productName: productName,
            hsnCode: hsnCode,
            taxRate: taxRate,
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

