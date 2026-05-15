import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/product.dart';
import '../../features/onboarding/models/shop_models.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> create(Product product, {Transaction? txn}) async {
    final db = await _dbHelper.database;
    // Logic inside a local closure to be used with or without external txn
    Future<int> internalCreate(dynamic ex) async {
      // 1. Insert into core products table
      final coreMap = product.toCoreMap();
      if (product.id == 0) coreMap.remove('id');
      final productId = await ex.insert(TableConstants.products, coreMap);
      
      // 2. Insert into template-specific table
      if (product.template == ProductTemplate.serialized) {
        await ex.insert(
          TableConstants.inventorySerialized, 
          product.toInventorySerializedMap(productId)
        );
      } else {
        // Standard, Bulk, Batch, Variant, Service all use inventory_standard for base price/qty
        await ex.insert(
          TableConstants.inventoryStandard, 
          product.toInventoryStandardMap(productId)
        );

        // 3. Handle Initial Stock for physical goods (Create a default batch)
        if (!product.isService && product.quantity > 0 && product.template != ProductTemplate.variantMatrix) {
          await ex.insert(TableConstants.productBatches, {
            'productId': productId,
            'quantity': product.quantity,
            'costPrice': product.costPrice ?? 0.0,
            'batchNumber': product.batchNumber ?? 'INITIAL',
            'expiryDate': product.expiryDate ?? DateTime.now().add(const Duration(days: 365)).toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
      return productId;
    }

    if (txn != null) {
      return await internalCreate(txn);
    } else {
      return await db.transaction((t) => internalCreate(t));
    }
  }



  String get _joinedSelect => '''
    SELECT p.*, 
           s.sellingPrice as standardPrice, s.mrp as standardMrp, s.costPrice as standardCost, 
           s.quantity as standardQty, s.unit as standardUnit, s.reorderLevel, 
           s.packagingUnit, s.conversionFactor, s.serviceDuration, s.staffCommission,
           e.serialNumber as serialNo, e.imei as serialImei, e.warrantyExpiry, e.status as serialStatus,
           (SELECT SUM(pb.quantity) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id) as liveBatchQuantity,
           (SELECT MIN(pb.expiryDate) FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0) as expiryDate,
           (SELECT pb.batchNumber FROM ${TableConstants.productBatches} pb WHERE pb.productId = p.id AND pb.quantity > 0 ORDER BY pb.expiryDate ASC LIMIT 1) as batchNumber
    FROM ${TableConstants.products} p
    LEFT JOIN ${TableConstants.inventoryStandard} s ON p.id = s.productId
    LEFT JOIN ${TableConstants.inventorySerialized} e ON p.id = e.productId
  ''';

  Product _mapToProduct(Map<String, dynamic> row) {
    // Map joined fields back to Product structure
    final map = Map<String, dynamic>.from(row);
    
    if (map['template'] == 'standardRetail' || 
        map['template'] == 'bulkUom' || 
        map['template'] == 'batchMultiUom' ||
        map['template'] == 'batchExpiry' ||
        map['template'] == 'variantMatrix' ||
        map['template'] == 'serviceLabor') {
      map['price'] = map['standardPrice'] ?? map['price'];
      map['mrp'] = map['standardMrp'] ?? map['mrp'];
      map['costPrice'] = map['standardCost'] ?? map['costPrice'];
      map['quantity'] = map['standardQty'] ?? map['quantity'];
      map['unit'] = map['standardUnit'] ?? map['unit'];
    } else if (map['template'] == 'serialized') {
      map['serialNumber'] = map['serialNo'] ?? map['serialNumber'];
      map['imei'] = map['serialImei'] ?? map['imei'];
      map['status'] = map['serialStatus'] ?? map['status'];
    }
    
    return Product.fromMap(map);
  }

  Future<Product?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('$_joinedSelect WHERE p.id = ?', [id]);
    if (result.isEmpty) return null;
    return _mapToProduct(result.first);
  }

  Future<Product?> getBySku(String sku) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('$_joinedSelect WHERE p.sku = ?', [sku]);
    if (result.isEmpty) return null;
    return _mapToProduct(result.first);
  }

  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('$_joinedSelect ORDER BY p.name ASC');
    return result.map((row) => _mapToProduct(row)).toList();
  }

  Future<List<Product>> getPaginated(int limit, int offset) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('$_joinedSelect ORDER BY p.name ASC LIMIT ? OFFSET ?', [limit, offset]);
    return result.map((row) => _mapToProduct(row)).toList();
  }

  Future<List<Product>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('$_joinedSelect WHERE p.category = ? ORDER BY p.name ASC', [category]);
    return result.map((row) => _mapToProduct(row)).toList();
  }

  Future<List<Product>> searchByName(String query) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('$_joinedSelect WHERE p.name LIKE ? ORDER BY p.name ASC', ['%$query%']);
    return result.map((row) => _mapToProduct(row)).toList();
  }


  Future<int> update(Product product, {Transaction? txn}) async {
    final db = await _dbHelper.database;
    Future<int> internalUpdate(dynamic ex) async {
      // 1. Update core products table
      final count = await ex.update(
        TableConstants.products,
        product.toCoreMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

        // Cleanup ALL template-specific tables first to handle template changes correctly
        await ex.delete(TableConstants.inventoryStandard, where: 'productId = ?', whereArgs: [product.id]);
        await ex.delete(TableConstants.inventorySerialized, where: 'productId = ?', whereArgs: [product.id]);

        if (product.template == ProductTemplate.serialized) {
          await ex.insert(
            TableConstants.inventorySerialized, 
            product.toInventorySerializedMap(product.id)
          );
        } else {
          // Standard, Bulk, Batch, Variant, Service
          // Read live quantity from product_batches (physical) or variants (variantMatrix)
          double liveQty = product.quantity;
          
          if (product.template == ProductTemplate.variantMatrix) {
            final varQtyResult = await ex.rawQuery(
              'SELECT SUM(stock) as q FROM ${TableConstants.productVariants} WHERE productId = ?',
              [product.id],
            );
            if (varQtyResult.isNotEmpty && varQtyResult.first['q'] != null) {
              liveQty = (varQtyResult.first['q'] as num).toDouble();
            }
          } else if (!product.isService) {
            final batchQtyResult = await ex.rawQuery(
              'SELECT SUM(quantity) as q FROM ${TableConstants.productBatches} WHERE productId = ?',
              [product.id],
            );
            if (batchQtyResult.isNotEmpty && batchQtyResult.first['q'] != null) {
              liveQty = (batchQtyResult.first['q'] as num).toDouble();
            }
          }

          await ex.insert(
            TableConstants.inventoryStandard, 
            product.toInventoryStandardMap(product.id, liveQty: liveQty)
          );

          // Update master product quantity to match live calculated quantity
          await ex.update(
            TableConstants.products,
            {'quantity': liveQty, 'updatedAt': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [product.id],
          );
        }
      return count;
    }

    if (txn != null) {
      return await internalUpdate(txn);
    } else {
      return await db.transaction((t) => internalUpdate(t));
    }
  }


  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      // Cleanup all related tables
      await txn.delete(TableConstants.inventoryStandard, where: 'productId = ?', whereArgs: [id]);
      await txn.delete(TableConstants.inventorySerialized, where: 'productId = ?', whereArgs: [id]);
      await txn.delete(TableConstants.productBatches, where: 'productId = ?', whereArgs: [id]);
      await txn.delete(TableConstants.productVariants, where: 'productId = ?', whereArgs: [id]);
      
      return await txn.delete(
        TableConstants.products,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<double> getTotalQuantity(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM ${TableConstants.productBatches} WHERE productId = ?',
      [productId],
    );
    final total = result.first['total'];
    return (total is num) ? total.toDouble() : 0.0;
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM ${TableConstants.products} ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return db.delete(TableConstants.products);
  }
}

