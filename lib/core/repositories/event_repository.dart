import '../database/database_helper.dart';
import '../models/event_log_entry.dart';

class EventRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> log(EventLogEntry entry) async {
    final db = await _dbHelper.database;
    return db.insert('event_logs', entry.toMap());
  }

  Future<EventLogEntry?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return EventLogEntry.fromMap(result.first);
  }

  Future<List<EventLogEntry>> getAll({int limit = 100, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => EventLogEntry.fromMap(map)).toList();
  }

  Future<List<EventLogEntry>> getByEventType(String eventType) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      where: 'eventType = ?',
      whereArgs: [eventType],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => EventLogEntry.fromMap(map)).toList();
  }

  Future<List<EventLogEntry>> getByEntityType(String entityType) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      where: 'entityType = ?',
      whereArgs: [entityType],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => EventLogEntry.fromMap(map)).toList();
  }

  Future<List<EventLogEntry>> getByEntity(String entityType, int entityId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      where: 'entityType = ? AND entityId = ?',
      whereArgs: [entityType, entityId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => EventLogEntry.fromMap(map)).toList();
  }

  Future<List<EventLogEntry>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => EventLogEntry.fromMap(map)).toList();
  }

  Future<EventLogEntry?> getLastEventForEntity(
      String entityType, int entityId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'event_logs',
      where: 'entityType = ? AND entityId = ?',
      whereArgs: [entityType, entityId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return EventLogEntry.fromMap(result.first);
  }

  Future<int> getEventCount(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM event_logs WHERE timestamp BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final count = result.first['count'] as int?;
    return count ?? 0;
  }

  Future<void> deleteOldEvents(DateTime beforeDate) async {
    final db = await _dbHelper.database;
    await db.delete(
      'event_logs',
      where: 'timestamp < ?',
      whereArgs: [beforeDate.toIso8601String()],
    );
  }
}
