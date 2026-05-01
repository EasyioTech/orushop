import 'package:flutter_test/flutter_test.dart';
import 'package:retaildost/core/models/product.dart';
import 'package:retaildost/core/repositories/product_repository.dart';

void main() {
  group('ProductRepository', () {
    late ProductRepository repository;

    setUp(() {
      repository = ProductRepository();
    });

    test('create product returns id', () async {
      final now = DateTime.now();
      final product = Product(
        id: 0,
        name: 'Test Product',
        sku: 'TEST001',
        category: 'Test',
        price: 100,
        quantity: 10,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.create(product);
      expect(id, greaterThan(0));
    });

    test('getById retrieves created product', () async {
      final now = DateTime.now();
      final product = Product(
        id: 0,
        name: 'Test Product',
        sku: 'TEST002',
        category: 'Test',
        price: 100,
        quantity: 10,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.create(product);
      final retrieved = await repository.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved?.name, equals('Test Product'));
      expect(retrieved?.sku, equals('TEST002'));
    });

    test('getAll returns list of products', () async {
      final now = DateTime.now();
      final product1 = Product(
        id: 0,
        name: 'Product 1',
        sku: 'SKU1',
        category: 'Test',
        price: 100,
        quantity: 10,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      final product2 = Product(
        id: 0,
        name: 'Product 2',
        sku: 'SKU2',
        category: 'Test',
        price: 200,
        quantity: 20,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      await repository.create(product1);
      await repository.create(product2);

      final all = await repository.getAll();
      expect(all.length, greaterThanOrEqualTo(2));
    });

    test('update modifies product', () async {
      final now = DateTime.now();
      final product = Product(
        id: 0,
        name: 'Test Product',
        sku: 'TEST003',
        category: 'Test',
        price: 100,
        quantity: 10,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.create(product);
      final updated = product.copyWith(id: id, name: 'Updated Product', price: 150);

      await repository.update(updated);
      final retrieved = await repository.getById(id);

      expect(retrieved?.name, equals('Updated Product'));
      expect(retrieved?.price, equals(150));
    });

    test('delete removes product', () async {
      final now = DateTime.now();
      final product = Product(
        id: 0,
        name: 'Test Product',
        sku: 'TEST004',
        category: 'Test',
        price: 100,
        quantity: 10,
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.create(product);
      await repository.delete(id);
      final retrieved = await repository.getById(id);

      expect(retrieved, isNull);
    });
  });
}
