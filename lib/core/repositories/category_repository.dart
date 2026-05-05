import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../../features/onboarding/models/shop_models.dart';
import '../../features/onboarding/models/shop_catalog_data.dart';

class CategoryRepository {
  final DatabaseHelper _db;

  CategoryRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<Map<String, dynamic>>> getCategories(String shopType) async {
    final db = await _db.database;
    return db.query(
      TableConstants.productCategories,
      where: 'shopType = ?',
      whereArgs: [shopType],
      orderBy: 'sortOrder ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getSubcategories(int categoryId) async {
    final db = await _db.database;
    return db.query(
      TableConstants.productSubcategories,
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'sortOrder ASC',
    );
  }

  Future<List<String>> getCategoryNames(String shopType) async {
    final rows = await getCategories(shopType);
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> getSubcategoryNames(int categoryId) async {
    final rows = await getSubcategories(categoryId);
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<int?> getCategoryId(String shopType, String categoryName) async {
    final db = await _db.database;
    final rows = await db.query(
      TableConstants.productCategories,
      columns: ['id'],
      where: 'shopType = ? AND name = ?',
      whereArgs: [shopType, categoryName],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<void> seedFromShopType(ShopType shopType) async {
    final db = await _db.database;
    final categories = ShopCatalog.forType(shopType);
    final shopTypeName = shopType.name;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Clear existing categories for this shop type before reseeding
      final existing = await txn.query(
        TableConstants.productCategories,
        columns: ['id'],
        where: 'shopType = ?',
        whereArgs: [shopTypeName],
      );
      for (final row in existing) {
        await txn.delete(
          TableConstants.productSubcategories,
          where: 'categoryId = ?',
          whereArgs: [row['id']],
        );
      }
      await txn.delete(
        TableConstants.productCategories,
        where: 'shopType = ?',
        whereArgs: [shopTypeName],
      );

      for (int i = 0; i < categories.length; i++) {
        final cat = categories[i];
        final catId = await txn.insert(TableConstants.productCategories, {
          'name': cat.name,
          'shopType': shopTypeName,
          'sortOrder': i,
          'createdAt': now,
        });

        for (int j = 0; j < cat.subcategories.length; j++) {
          await txn.insert(TableConstants.productSubcategories, {
            'categoryId': catId,
            'name': cat.subcategories[j],
            'sortOrder': j,
            'createdAt': now,
          });
        }
      }
    });

    debugPrint('[CategoryRepository] Seeded ${categories.length} categories for $shopTypeName');
  }

  Future<bool> hasCategories(String shopType) async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${TableConstants.productCategories} WHERE shopType = ?',
        [shopType],
      ),
    );
    return (count ?? 0) > 0;
  }
}
