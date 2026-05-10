import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/product_variant.dart';

class VariantRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<ProductVariant>> getByProduct(int productId) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.productVariants,
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'size ASC, color ASC',
    );
    return rows.map(ProductVariant.fromMap).toList();
  }

  Future<ProductVariant?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.productVariants,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ProductVariant.fromMap(rows.first);
  }

  Future<ProductVariant?> getBySku(String sku) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.productVariants,
      where: 'sku = ?',
      whereArgs: [sku],
      limit: 1,
    );
    return rows.isEmpty ? null : ProductVariant.fromMap(rows.first);
  }

  /// Insert a batch of variants inside an existing transaction.
  Future<void> insertBatch(
    dynamic txn,
    List<ProductVariant> variants,
  ) async {
    for (final v in variants) {
      final map = v.toMap()..remove('id');
      await txn.insert(
        TableConstants.productVariants,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
  }

  Future<int> upsert(ProductVariant variant) async {
    final db = await _db.database;
    final map = variant.toMap();
    if (variant.id == 0) {
      map.remove('id');
      return db.insert(
        TableConstants.productVariants,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    await db.update(
      TableConstants.productVariants,
      map,
      where: 'id = ?',
      whereArgs: [variant.id],
    );
    return variant.id;
  }

  Future<void> deleteByProduct(int productId) async {
    final db = await _db.database;
    await db.delete(
      TableConstants.productVariants,
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      TableConstants.productVariants,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> syncParentQuantity(int productId, double totalStock) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE ${TableConstants.products} SET quantity = ?, updatedAt = ? WHERE id = ?',
      [totalStock, DateTime.now().toIso8601String(), productId],
    );
  }

  /// Deduct stock atomically. Throws if insufficient.
  Future<void> deductStock(dynamic txn, int variantId, double qty) async {
    final rows = await txn.query(
      TableConstants.productVariants,
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [variantId],
    ) as List<Map<String, dynamic>>;

    if (rows.isEmpty) throw Exception('Variant $variantId not found');
    final current = (rows.first['stock'] as num).toDouble();
    if (current < qty) {
      throw Exception('Insufficient stock for variant $variantId (have $current, need $qty)');
    }
    await txn.rawUpdate(
      'UPDATE ${TableConstants.productVariants} SET stock = stock - ?, updatedAt = ? WHERE id = ?',
      [qty, DateTime.now().toIso8601String(), variantId],
    );
  }
}
