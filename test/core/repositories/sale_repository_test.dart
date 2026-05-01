import 'package:flutter_test/flutter_test.dart';
import 'package:retaildost/core/models/sale.dart';
import 'package:retaildost/core/repositories/sale_repository.dart';

void main() {
  group('SaleRepository', () {
    late SaleRepository repository;

    setUp(() {
      repository = SaleRepository();
    });

    test('create sale returns id', () async {
      final sale = Sale(
        id: 0,
        totalAmount: 1000,
        discountAmount: 100,
        finalAmount: 900,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(sale);
      expect(id, greaterThan(0));
    });

    test('getById retrieves created sale', () async {
      final sale = Sale(
        id: 0,
        totalAmount: 1000,
        discountAmount: 100,
        finalAmount: 900,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(sale);
      final retrieved = await repository.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved?.totalAmount, equals(1000));
      expect(retrieved?.finalAmount, equals(900));
    });

    test('getAll returns sales', () async {
      final sale1 = Sale(
        id: 0,
        totalAmount: 1000,
        discountAmount: 100,
        finalAmount: 900,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      final sale2 = Sale(
        id: 0,
        totalAmount: 2000,
        discountAmount: 200,
        finalAmount: 1800,
        paymentMethod: 'upi',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      await repository.create(sale1);
      await repository.create(sale2);

      final all = await repository.getAll();
      expect(all.length, greaterThanOrEqualTo(2));
    });

    test('getByDateRange retrieves sales in range', () async {
      final now = DateTime.now();
      final sale = Sale(
        id: 0,
        totalAmount: 1000,
        discountAmount: 0,
        finalAmount: 1000,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: now,
      );

      await repository.create(sale);

      final sales = await repository.getByDateRange(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );

      expect(sales.length, greaterThanOrEqualTo(1));
      expect(sales.first.totalAmount, equals(1000));
    });

    test('update modifies sale', () async {
      final sale = Sale(
        id: 0,
        totalAmount: 1000,
        discountAmount: 0,
        finalAmount: 1000,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(sale);
      final updated = sale.copyWith(id: id, status: 'cancelled');

      await repository.update(updated);
      final retrieved = await repository.getById(id);

      expect(retrieved?.status, equals('cancelled'));
    });
  });
}
