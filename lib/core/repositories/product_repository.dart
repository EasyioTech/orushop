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
      final productMap = product.toMap();
      if (product.id == 0) productMap.remove('id');
      final productId = await ex.insert(TableConstants.products, productMap);
      
      // 2. Insert into template-specific table
      if (product.template == ProductTemplate.standardRetail || 
          product.template == ProductTemplate.bulkUom || 
          product.template == ProductTemplate.batchMultiUom ||
          product.template == ProductTemplate.batchExpiry ||
          product.template == ProductTemplate.variantMatrix ||
          product.template == ProductTemplate.serviceLabor) {
        await ex.insert(TableConstants.inventoryStandard, {
          'productId': productId,
          'sellingPrice': product.price,
          'mrp': product.mrp,
          'costPrice': product.costPrice,
          'wholesalePrice': product.wholesalePrice,
          'quantity': product.quantity,
          'reorderLevel': product.reorderLevel,
          'unit': product.unit,
          'packagingUnit': product.packagingUnit,
          'conversionFactor': product.conversionFactor,
          'serviceDuration': product.serviceDuration,
          'staffCommission': product.staffCommission,
        });
      } else if (product.template == ProductTemplate.serialized) {
        await ex.insert(TableConstants.inventorySerialized, {
          'productId': productId,
          'serialNumber': product.serialNumber,
          'imei': product.imei,
          'warrantyExpiry': product.warrantyExpiry,
          'sellingPrice': product.price,
          'mrp': product.mrp,
          'costPrice': product.costPrice,
          'status': product.status,
        });
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
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      // 2. Update template-specific table
      if (product.template == ProductTemplate.standardRetail ||
          product.template == ProductTemplate.bulkUom ||
          product.template == ProductTemplate.batchMultiUom ||
          product.template == ProductTemplate.batchExpiry ||
          product.template == ProductTemplate.variantMatrix ||
          product.template == ProductTemplate.serviceLabor) {
        // Read live quantity from product_batches to avoid overwriting with stale value
        final liveQtyResult = await ex.rawQuery(
          'SELECT SUM(quantity) as q FROM ${TableConstants.productBatches} WHERE productId = ?',
          [product.id],
        );
        final liveQty = (liveQtyResult.isNotEmpty && liveQtyResult.first['q'] != null)
            ? (liveQtyResult.first['q'] as num).toDouble()
            : product.quantity;

        await ex.delete(TableConstants.inventoryStandard, where: 'productId = ?', whereArgs: [product.id]);
        await ex.insert(TableConstants.inventoryStandard, {
          'productId': product.id,
          'sellingPrice': product.price,
          'mrp': product.mrp,
          'costPrice': product.costPrice,
          'wholesalePrice': product.wholesalePrice,
          'quantity': liveQty,
          'reorderLevel': product.reorderLevel,
          'unit': product.unit,
          'packagingUnit': product.packagingUnit,
          'conversionFactor': product.conversionFactor,
          'serviceDuration': product.serviceDuration,
          'staffCommission': product.staffCommission,
        });
      } else if (product.template == ProductTemplate.serialized) {
        await ex.delete(TableConstants.inventorySerialized, where: 'productId = ?', whereArgs: [product.id]);
        await ex.insert(TableConstants.inventorySerialized, {
          'productId': product.id,
          'serialNumber': product.serialNumber,
          'imei': product.imei,
          'warrantyExpiry': product.warrantyExpiry,
          'sellingPrice': product.price,
          'mrp': product.mrp,
          'costPrice': product.costPrice,
          'status': product.status,
        });
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
    return db.delete(
      TableConstants.products,
      where: 'id = ?',
      whereArgs: [id],
    );
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

