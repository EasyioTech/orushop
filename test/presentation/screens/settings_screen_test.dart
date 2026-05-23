import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orushops/presentation/screens/settings_screen.dart';
import 'package:orushops/providers/settings_provider.dart';
import 'package:orushops/providers/shared_prefs_provider.dart';
import 'package:orushops/core/models/app_settings.dart';
import 'package:orushops/core/repositories/owner_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences mockPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    initializeSharedPrefs(mockPrefs);
  });

  final mockSettings = AppSettings(
    storeName: 'Test Store',
    storePhone: '1234567890',
    storeAddress: '123 Test St',
    currencySymbol: '\$',
    enableDiscounts: true,
    enableUpi: true,
    defaultDiscountPercent: 0,
    lastSyncTime: DateTime.now(),
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => mockPrefs),
        settingsProvider.overrideWith((ref) => Future.value(mockSettings)),
        ownerDetailsStreamProvider.overrideWith((ref) => Stream.value({
              'storeName': 'Test Store',
              'storePhone': '1234567890',
              'storeAddress': '123 Test St',
            })),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
  }

  group('SettingsScreen', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await pumpScreen(tester, createTestWidget());
      await tester.pump();
      await tester.pump();

      try {
        expect(find.text('Settings'), findsWidgets);
      } catch (e) {
        debugDumpApp();
        rethrow;
      }
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('displays all settings sections', (WidgetTester tester) async {
      await pumpScreen(tester, createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('STORE INFORMATION'), findsOneWidget);
      expect(find.text('PRIVACY & COMPLIANCE'), findsOneWidget);
      expect(find.text('DATA MANAGEMENT'), findsOneWidget);
      expect(find.text('APP MANAGEMENT'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching settings', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => mockPrefs),
            settingsProvider.overrideWith((ref) async {
              await Future.delayed(const Duration(seconds: 1));
              return mockSettings;
            }),
            ownerDetailsStreamProvider.overrideWith((ref) => Stream.value({})),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Don't wait for settle here to see the loading state
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(); // clean up
    });

    testWidgets('displays app version', (WidgetTester tester) async {
      await pumpScreen(tester, createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('clear cache shows confirmation dialog', (WidgetTester tester) async {
      await pumpScreen(tester, createTestWidget());
      await tester.pumpAndSettle();

      final clearCacheFinder = find.text('Clear Cache');
      await tester.ensureVisible(clearCacheFinder);
      await tester.pumpAndSettle();
      
      await tester.tap(clearCacheFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('sync and backup tile is tappable', (WidgetTester tester) async {
      await pumpScreen(tester, createTestWidget());
      await tester.pumpAndSettle();

      final syncTile = find.text('Sync & Backup');
      await tester.ensureVisible(syncTile);
      await tester.pumpAndSettle();
      
      expect(syncTile, findsOneWidget);
    });
  });
}
