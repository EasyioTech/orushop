import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class SettingsService {
  final SharedPreferences prefs;
  final DatabaseHelper dbHelper;

  SettingsService({required this.prefs, required this.dbHelper});

  // Cache management
  Future<int> getCacheSize() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      "SELECT SUM(page_count * page_size) as size FROM pragma_page_count(), pragma_page_size()",
    );
    return (result.first['size'] as int?) ?? 0;
  }

  Future<void> clearCache() async {
    final db = await dbHelper.database;
    await db.execute('VACUUM');
  }

  // Data management
  Future<void> clearAllData() async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('sales');
      await txn.delete('sale_items');
      await txn.delete('product_batches');
      await txn.delete('products');
      await txn.delete('returns');
      await txn.delete('return_items');
      await txn.delete('refunds');
      await txn.delete('event_logs');
    });
  }

  // Backup settings
  Future<bool> isAutoBackupEnabled() async {
    return prefs.getBool('auto_backup_enabled') ?? true;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await prefs.setBool('auto_backup_enabled', enabled);
  }

  Future<int> getBackupFrequencyHours() async {
    return prefs.getInt('backup_frequency_hours') ?? 24;
  }

  Future<void> setBackupFrequencyHours(int hours) async {
    await prefs.setInt('backup_frequency_hours', hours);
  }

  Future<String?> getLastAutoBackupTime() async {
    return prefs.getString('last_auto_backup_time');
  }

  Future<void> setLastAutoBackupTime(String timestamp) async {
    await prefs.setString('last_auto_backup_time', timestamp);
  }

  // Sync settings
  Future<bool> isAutoSyncEnabled() async {
    return prefs.getBool('auto_sync_enabled') ?? true;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    await prefs.setBool('auto_sync_enabled', enabled);
  }

  Future<int> getSyncFrequencyMinutes() async {
    return prefs.getInt('sync_frequency_minutes') ?? 60;
  }

  Future<void> setSyncFrequencyMinutes(int minutes) async {
    await prefs.setInt('sync_frequency_minutes', minutes);
  }

  // Data retention
  Future<int> getDataRetentionDays() async {
    return prefs.getInt('data_retention_days') ?? 90;
  }

  Future<void> setDataRetentionDays(int days) async {
    await prefs.setInt('data_retention_days', days);
  }

  // Privacy settings
  Future<bool> isAnalyticsEnabled() async {
    return prefs.getBool('analytics_enabled') ?? true;
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    await prefs.setBool('analytics_enabled', enabled);
  }
}
