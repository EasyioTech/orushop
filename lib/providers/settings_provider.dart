import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_provider.dart';

import '../core/models/app_settings.dart';
import '../core/repositories/settings_repository.dart';
import '../core/services/settings_service.dart';
import '../core/database/database_helper.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

final settingsProvider = FutureProvider<AppSettings?>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.get();
});

// Centralized sharedPreferencesProvider is now in shared_prefs_provider.dart

final databaseHelperProvider = Provider((ref) => DatabaseHelper());

final settingsServiceProvider = FutureProvider((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return SettingsService(prefs: prefs, dbHelper: dbHelper);
});

final cacheSizeProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.getCacheSize();
});

final autoBackupEnabledProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.isAutoBackupEnabled();
});

final backupFrequencyProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.getBackupFrequencyHours();
});

final autoSyncEnabledProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.isAutoSyncEnabled();
});

final syncFrequencyProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.getSyncFrequencyMinutes();
});

final dataRetentionProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.getDataRetentionDays();
});

final analyticsEnabledProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.isAnalyticsEnabled();
});

final clearCacheProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.clearCache();
});

final clearDataProvider = FutureProvider((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.clearAllData();
});

final updateAutoBackupProvider = FutureProvider.family<void, bool>((ref, enabled) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setAutoBackupEnabled(enabled);
});

final updateBackupFrequencyProvider = FutureProvider.family<void, int>((ref, hours) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setBackupFrequencyHours(hours);
});

final updateAutoSyncProvider = FutureProvider.family<void, bool>((ref, enabled) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setAutoSyncEnabled(enabled);
});

final updateSyncFrequencyProvider = FutureProvider.family<void, int>((ref, minutes) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setSyncFrequencyMinutes(minutes);
});

final updateDataRetentionProvider = FutureProvider.family<void, int>((ref, days) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setDataRetentionDays(days);
});

final updateAnalyticsProvider = FutureProvider.family<void, bool>((ref, enabled) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setAnalyticsEnabled(enabled);
});

final revenueCatTestModeProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  return settings.isRevenueCatTestMode();
});

final updateRevenueCatTestModeProvider = FutureProvider.family<void, bool>((ref, enabled) async {
  final settings = await ref.watch(settingsServiceProvider.future);
  await settings.setRevenueCatTestMode(enabled);
});

// ── Daily Sales Target Persistence ──────────────────────────────────────────
class DailySalesGoalNotifier extends StateNotifier<double> {
  final SharedPreferences _prefs;
  static const String _key = 'daily_sales_goal_v1';

  DailySalesGoalNotifier(this._prefs) : super(10000.0) {
    _loadGoal();
  }

  void _loadGoal() {
    state = _prefs.getDouble(_key) ?? 10000.0;
  }

  Future<void> setGoal(double value) async {
    state = value;
    await _prefs.setDouble(_key, value);
  }
}

final dailySalesGoalProvider = StateNotifierProvider<DailySalesGoalNotifier, double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailySalesGoalNotifier(prefs);
});


