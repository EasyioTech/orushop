import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orushops/presentation/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('displays all setting sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Store'), findsOneWidget);
      expect(find.text('Sales Settings'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('App'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays store information tiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Store Name'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
    });

    testWidgets('displays sales settings toggles', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Enable Discounts'), findsOneWidget);
      expect(find.text('Enable UPI'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('displays cache and data management options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('Clear All Data'), findsOneWidget);
    });

    testWidgets('shows clear cache confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Cache?'), findsOneWidget);
      expect(find.text('This will remove cached data but keep your sales records.'), findsOneWidget);
    });

    testWidgets('clears cache when confirmation given', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      final clearButton = find.widgetWithText(TextButton, 'Clear').last;
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Clearing cache...'), findsOneWidget);
    });

    testWidgets('shows clear data warning dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Clear All Data'));
      await tester.pumpAndSettle();

      expect(find.text('Clear All Data?'), findsOneWidget);
      expect(
        find.text('This will permanently delete all sales, products, and other data. This action cannot be undone.'),
        findsOneWidget,
      );
    });

    testWidgets('clears data when confirmation given', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Clear All Data'));
      await tester.pumpAndSettle();

      final clearButton = find.widgetWithText(TextButton, 'Clear').last;
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Clearing all data...'), findsOneWidget);
    });
  });
}

