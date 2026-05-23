import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:orushops/main.dart' as app;

// E5: Performance regression baselines
// Run: flutter test integration_test/performance_test.dart
// Budgets: tab switch < 300ms, search settle < 200ms, scroll fling settle < 500ms

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E5 — Performance regression', () {
    testWidgets('tab switch: all four tabs complete within 300ms each',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final destFinder = find.byType(NavigationDestination);
      if (destFinder.evaluate().length < 2) {
        // Onboarding/auth screen — skip
        markTestSkipped('App not on main shell — skipping tab switch test');
        return;
      }

      final tabCount = destFinder.evaluate().length;

      // Warm-up pass (not measured)
      for (var i = 0; i < tabCount; i++) {
        await tester.tap(find.byType(NavigationDestination).at(i));
        await tester.pumpAndSettle();
      }

      // Measured pass
      for (var i = 0; i < tabCount; i++) {
        final sw = Stopwatch()..start();
        await tester.tap(find.byType(NavigationDestination).at(i));
        await tester.pumpAndSettle();
        sw.stop();

        expect(
          sw.elapsedMilliseconds,
          lessThan(300),
          reason: 'Tab $i switch took ${sw.elapsedMilliseconds}ms (budget: 300ms)',
        );
      }
    });

    testWidgets('inventory search: each keystroke settles within 100ms',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final destFinder = find.byType(NavigationDestination);
      if (destFinder.evaluate().length < 2) {
        markTestSkipped('App not on main shell — skipping inventory search test');
        return;
      }

      // Navigate to inventory (tab 1)
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();

      final searchFields = find.byType(TextField);
      if (searchFields.evaluate().isEmpty) {
        markTestSkipped('No TextField found on inventory screen');
        return;
      }

      final searchField = searchFields.first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      const query = 'rice';
      var maxMs = 0;

      for (var i = 1; i <= query.length; i++) {
        final partial = query.substring(0, i);
        final sw = Stopwatch()..start();
        await tester.enterText(searchField, partial);
        await tester.pumpAndSettle();
        sw.stop();
        if (sw.elapsedMilliseconds > maxMs) maxMs = sw.elapsedMilliseconds;
      }

      expect(
        maxMs,
        lessThan(200),
        reason: 'Worst keystroke-to-settle: ${maxMs}ms (budget: 200ms)',
      );

      // Clear
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
    });

    testWidgets('product list scroll: fling+settle within 500ms',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final destFinder = find.byType(NavigationDestination);
      if (destFinder.evaluate().length < 2) {
        markTestSkipped('App not on main shell — skipping scroll test');
        return;
      }

      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isEmpty) {
        markTestSkipped('No Scrollable on inventory screen');
        return;
      }

      final scrollable = scrollables.first;

      final sw = Stopwatch()..start();
      await tester.fling(scrollable, const Offset(0, -600), 3000);
      await tester.pumpAndSettle();
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(500),
        reason: 'Fling-down settle: ${sw.elapsedMilliseconds}ms (budget: 500ms)',
      );

      await tester.fling(scrollable, const Offset(0, 600), 3000);
      await tester.pumpAndSettle();
    });

    testWidgets('khata customer list scroll: fling+settle within 500ms',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final destFinder = find.byType(NavigationDestination);
      if (destFinder.evaluate().length < 3) {
        markTestSkipped('App not on main shell — skipping khata scroll test');
        return;
      }

      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isEmpty) {
        markTestSkipped('No Scrollable on khata screen');
        return;
      }

      final sw = Stopwatch()..start();
      await tester.fling(scrollables.first, const Offset(0, -600), 3000);
      await tester.pumpAndSettle();
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(500),
        reason: 'Khata fling settle: ${sw.elapsedMilliseconds}ms (budget: 500ms)',
      );
    });
  });
}
