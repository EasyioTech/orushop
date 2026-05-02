import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/presentation/screens/sync_backup_screen.dart';

void main() {
  group('SyncBackupScreen', () {
    testWidgets('displays backup and sync screen title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      expect(find.text('Backup & Sync'), findsOneWidget);
    });

    testWidgets('displays connection status card', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays cloud backup section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      expect(find.text('Cloud Backup'), findsOneWidget);
      expect(find.text('Create backup of all data to cloud'), findsOneWidget);
      expect(find.text('Backup Now'), findsOneWidget);
    });

    testWidgets('displays last backup section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      expect(find.text('Last Backup'), findsOneWidget);
    });

    testWidgets('displays data sync section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      expect(find.text('Data Sync'), findsOneWidget);
      expect(find.text('Sync sales data with cloud for analytics'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
    });

    testWidgets('backup button triggers backup action', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      final backupButton = find.text('Backup Now');
      expect(backupButton, findsOneWidget);

      await tester.tap(backupButton);
      await tester.pumpAndSettle();

      expect(find.text('Starting backup...'), findsOneWidget);
    });

    testWidgets('sync button triggers sync action', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      final syncButton = find.text('Sync Now');
      expect(syncButton, findsOneWidget);

      await tester.tap(syncButton);
      await tester.pumpAndSettle();

      expect(find.text('Starting sync...'), findsOneWidget);
    });

    testWidgets('displays all major card sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('screen is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SyncBackupScreen(),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}

