import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/service_category_model.dart';

class ServiceCategoryRepository {
  final DatabaseHelper _db;

  ServiceCategoryRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<ServiceCategoryModel>> getAll({String? shopType}) async {
    final db = await _db.database;
    
    // We want universal categories (shopType is NULL) and categories specific to the current shopType
    final List<Map<String, dynamic>> maps;
    if (shopType != null) {
      maps = await db.query(
        TableConstants.serviceCategories,
        where: 'shopType IS NULL OR shopType = ?',
        whereArgs: [shopType],
        orderBy: 'isSystem DESC, sortOrder ASC, name ASC',
      );
    } else {
      maps = await db.query(
        TableConstants.serviceCategories,
        orderBy: 'isSystem DESC, sortOrder ASC, name ASC',
      );
    }

    return maps.map((map) => ServiceCategoryModel.fromMap(map)).toList();
  }

  Future<int> create(ServiceCategoryModel category) async {
    final db = await _db.database;
    return db.insert(
      TableConstants.serviceCategories,
      category.toMap(),
    );
  }

  Future<void> update(ServiceCategoryModel category) async {
    final db = await _db.database;
    if (category.id == null) return;
    await db.update(
      TableConstants.serviceCategories,
      category.toMap(),
      where: 'id = ? AND isSystem = 0',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      TableConstants.serviceCategories,
      where: 'id = ? AND isSystem = 0',
      whereArgs: [id],
    );
  }
}
