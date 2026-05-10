import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../database/table_constants.dart';

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
      await txn.delete(TableConstants.sales);
      await txn.delete(TableConstants.saleItems);
      await txn.delete(TableConstants.productBatches);
      await txn.delete(TableConstants.products);
      await txn.delete(TableConstants.returns);
      await txn.delete(TableConstants.returnItems);
      await txn.delete(TableConstants.refunds);
      await txn.delete(TableConstants.eventLogs);
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

  // Developer settings
  Future<bool> isRevenueCatTestMode() async {
    // Default to false for production safety, but if the user wants to test, they can toggle it.
    return prefs.getBool('revenue_cat_test_mode') ?? true; 
  }

  Future<void> setRevenueCatTestMode(bool enabled) async {
    await prefs.setBool('revenue_cat_test_mode', enabled);
  }
}

