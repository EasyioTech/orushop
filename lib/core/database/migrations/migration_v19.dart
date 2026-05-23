import 'package:sqflite/sqflite.dart';

/// Migration v19 — Add referralCode column to app_settings table
class MigrationV19 {
  static Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE app_settings ADD COLUMN referralCode TEXT');
    } catch (e) {
      // Column might already exist, which is fine
    }
  }

  static Future<void> down(Database db) async {
    // SQLite doesn't easily support dropping columns in older versions,
    // but typically down migrations are not run in production.
  }
}
