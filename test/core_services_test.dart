import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orushops/core/services/settings_service.dart';
import 'package:orushops/core/database/database_helper.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  group('SettingsService', () {
    late MockSharedPreferences mockPrefs;
    late MockDatabaseHelper mockDbHelper;
    late SettingsService settingsService;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockDbHelper = MockDatabaseHelper();
      settingsService = SettingsService(
        prefs: mockPrefs,
        dbHelper: mockDbHelper,
      );
    });

    group('Auto Backup Settings', () {
      test('isAutoBackupEnabled returns true by default', () async {
        when(mockPrefs.getBool('auto_backup_enabled')).thenReturn(null);

        final result = await settingsService.isAutoBackupEnabled();

        expect(result, true);
      });

      test('setAutoBackupEnabled saves to preferences', () async {
        when(mockPrefs.setBool('auto_backup_enabled', true))
            .thenAnswer((_) async => true);

        await settingsService.setAutoBackupEnabled(true);

        verify(mockPrefs.setBool('auto_backup_enabled', true)).called(1);
      });
    });

    group('Backup Frequency', () {
      test('getBackupFrequencyHours returns 24 by default', () async {
        when(mockPrefs.getInt('backup_frequency_hours')).thenReturn(null);

        final result = await settingsService.getBackupFrequencyHours();

        expect(result, 24);
      });

      test('setBackupFrequencyHours saves custom value', () async {
        when(mockPrefs.setInt('backup_frequency_hours', 12))
            .thenAnswer((_) async => true);

        await settingsService.setBackupFrequencyHours(12);

        verify(mockPrefs.setInt('backup_frequency_hours', 12)).called(1);
      });
    });

    group('Auto Sync Settings', () {
      test('isAutoSyncEnabled returns true by default', () async {
        when(mockPrefs.getBool('auto_sync_enabled')).thenReturn(null);

        final result = await settingsService.isAutoSyncEnabled();

        expect(result, true);
      });

      test('setAutoSyncEnabled saves to preferences', () async {
        when(mockPrefs.setBool('auto_sync_enabled', false))
            .thenAnswer((_) async => true);

        await settingsService.setAutoSyncEnabled(false);

        verify(mockPrefs.setBool('auto_sync_enabled', false)).called(1);
      });
    });

    group('Sync Frequency', () {
      test('getSyncFrequencyMinutes returns 60 by default', () async {
        when(mockPrefs.getInt('sync_frequency_minutes')).thenReturn(null);

        final result = await settingsService.getSyncFrequencyMinutes();

        expect(result, 60);
      });

      test('setSyncFrequencyMinutes saves custom value', () async {
        when(mockPrefs.setInt('sync_frequency_minutes', 30))
            .thenAnswer((_) async => true);

        await settingsService.setSyncFrequencyMinutes(30);

        verify(mockPrefs.setInt('sync_frequency_minutes', 30)).called(1);
      });
    });

    group('Data Retention', () {
      test('getDataRetentionDays returns 90 by default', () async {
        when(mockPrefs.getInt('data_retention_days')).thenReturn(null);

        final result = await settingsService.getDataRetentionDays();

        expect(result, 90);
      });

      test('setDataRetentionDays saves custom value', () async {
        when(mockPrefs.setInt('data_retention_days', 180))
            .thenAnswer((_) async => true);

        await settingsService.setDataRetentionDays(180);

        verify(mockPrefs.setInt('data_retention_days', 180)).called(1);
      });
    });

    group('Analytics Settings', () {
      test('isAnalyticsEnabled returns true by default', () async {
        when(mockPrefs.getBool('analytics_enabled')).thenReturn(null);

        final result = await settingsService.isAnalyticsEnabled();

        expect(result, true);
      });

      test('setAnalyticsEnabled saves to preferences', () async {
        when(mockPrefs.setBool('analytics_enabled', false))
            .thenAnswer((_) async => true);

        await settingsService.setAnalyticsEnabled(false);

        verify(mockPrefs.setBool('analytics_enabled', false)).called(1);
      });
    });
  });
}

