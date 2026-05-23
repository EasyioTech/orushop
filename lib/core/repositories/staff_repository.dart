import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';
import '../models/staff_member.dart';

class StaffRepository {
  final DatabaseHelper _db;

  StaffRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<StaffMember>> getAll() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableConstants.staff,
      orderBy: 'name ASC',
    );
    return maps.map((map) => StaffMember.fromMap(map)).toList();
  }

  Future<List<StaffMember>> getActive() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableConstants.staff,
      where: 'isActive = 1',
      orderBy: 'name ASC',
    );
    return maps.map((map) => StaffMember.fromMap(map)).toList();
  }

  Future<StaffMember?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableConstants.staff,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return StaffMember.fromMap(maps.first);
  }

  Future<int> create(StaffMember staff) async {
    final db = await _db.database;
    return db.insert(
      TableConstants.staff,
      staff.toMap(),
    );
  }

  Future<void> update(StaffMember staff) async {
    final db = await _db.database;
    if (staff.id == null) return;
    await db.update(
      TableConstants.staff,
      staff.toMap(),
      where: 'id = ?',
      whereArgs: [staff.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Assignments are deleted via CASCADE from FOREIGN KEY constraint,
      // but let's delete them explicitly to be safe and robust.
      await txn.delete(
        TableConstants.staffServiceAssignments,
        where: 'staffId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        TableConstants.staff,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // --- Assignments ---

  Future<List<StaffMember>> getAssignedStaff(int productId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM ${TableConstants.staff} s
      INNER JOIN ${TableConstants.staffServiceAssignments} a ON s.id = a.staffId
      WHERE a.productId = ? AND s.isActive = 1
      ORDER BY s.name ASC
    ''', [productId]);
    return maps.map((map) => StaffMember.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAssignedServicesWithOverrides(int staffId) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT p.*, a.priceOverride, a.durationOverride 
      FROM ${TableConstants.products} p
      INNER JOIN ${TableConstants.staffServiceAssignments} a ON p.id = a.productId
      WHERE a.staffId = ?
      ORDER BY p.name ASC
    ''', [staffId]);
  }

  Future<void> assignToService(
    int staffId,
    int productId, {
    double? priceOverride,
    int? durationOverride,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    
    // Use INSERT OR REPLACE (or check first)
    await db.insert(
      TableConstants.staffServiceAssignments,
      {
        'staffId': staffId,
        'productId': productId,
        'priceOverride': priceOverride,
        'durationOverride': durationOverride,
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unassignFromService(int staffId, int productId) async {
    final db = await _db.database;
    await db.delete(
      TableConstants.staffServiceAssignments,
      where: 'staffId = ? AND productId = ?',
      whereArgs: [staffId, productId],
    );
  }

  Future<void> unassignAllFromService(int productId) async {
    final db = await _db.database;
    await db.delete(
      TableConstants.staffServiceAssignments,
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  Future<List<Map<String, dynamic>>> getServiceOverridesForProduct(int productId) async {
    final db = await _db.database;
    return db.query(
      TableConstants.staffServiceAssignments,
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }
}
