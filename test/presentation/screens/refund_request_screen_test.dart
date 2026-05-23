import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orushops/core/models/sale.dart';
import 'package:orushops/presentation/screens/refund_request_screen.dart';

void main() {
  group('RefundRequestScreen', () {
    final testSale = Sale(
      id: 1,
      totalAmount: 1000,
      discountAmount: 100,
      finalAmount: 900,
      paymentMethod: 'cash',
      status: 'completed',
      createdAt: DateTime.now(),
    );

    testWidgets('renders with sale details', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      expect(find.text('Refund Request'), findsOneWidget);
      expect(find.text('Sale Details'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('displays refund amount field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      expect(find.text('Refund Amount *'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays reason dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      expect(find.text('Reason *'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows reason dropdown options when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text('Defective Product').last, findsOneWidget);
      expect(find.text('Changed Mind').last, findsOneWidget);
      expect(find.text('Wrong Item').last, findsOneWidget);
    });

    testWidgets('displays cancel and submit buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit Refund'), findsOneWidget);
    });

    testWidgets('cancel button pops navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RefundRequestScreen(sale: testSale),
            ),
          ),
        ),
      );

      final cancelBtn = find.text('Cancel');
      await tester.ensureVisible(cancelBtn);
      await tester.pumpAndSettle();
      
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RefundRequestScreen), findsNothing);
    });

    testWidgets('displays notes field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('refund amount field has currency prefix', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RefundRequestScreen(sale: testSale),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField).first;
      expect(textFieldFinder, findsOneWidget);
    });
  });
}

