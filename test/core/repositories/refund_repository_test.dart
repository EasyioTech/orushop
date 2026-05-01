import 'package:flutter_test/flutter_test.dart';
import 'package:retaildost/core/models/refund.dart';
import 'package:retaildost/core/repositories/refund_repository.dart';

void main() {
  group('RefundRepository', () {
    late RefundRepository repository;

    setUp(() {
      repository = RefundRepository();
    });

    test('create refund returns id', () async {
      final refund = Refund(
        id: 0,
        saleId: 1,
        refundAmount: 500,
        reason: 'Defective Product',
        notes: 'Test note',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(refund);
      expect(id, greaterThan(0));
    });

    test('getById retrieves created refund', () async {
      final refund = Refund(
        id: 0,
        saleId: 1,
        refundAmount: 500,
        reason: 'Defective Product',
        notes: 'Test note',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(refund);
      final retrieved = await repository.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved?.refundAmount, equals(500));
      expect(retrieved?.status, equals('pending'));
    });

    test('getBySaleId retrieves refunds for sale', () async {
      final saleId = 1;
      final refund = Refund(
        id: 0,
        saleId: saleId,
        refundAmount: 500,
        reason: 'Defective Product',
        notes: null,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await repository.create(refund);

      final refunds = await repository.getBySaleId(saleId);
      expect(refunds.isNotEmpty, true);
      expect(refunds.first.saleId, equals(saleId));
    });

    test('getByStatus retrieves pending refunds', () async {
      final refund1 = Refund(
        id: 0,
        saleId: 1,
        refundAmount: 500,
        reason: 'Defective Product',
        notes: null,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final refund2 = Refund(
        id: 0,
        saleId: 2,
        refundAmount: 300,
        reason: 'Changed Mind',
        notes: null,
        status: 'approved',
        createdAt: DateTime.now(),
      );

      await repository.create(refund1);
      await repository.create(refund2);

      final pending = await repository.getByStatus('pending');
      expect(pending.isNotEmpty, true);
      expect(pending.every((r) => r.status == 'pending'), true);
    });

    test('update changes refund status', () async {
      final refund = Refund(
        id: 0,
        saleId: 1,
        refundAmount: 500,
        reason: 'Defective Product',
        notes: null,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(refund);
      final updated = refund.copyWith(
        id: id,
        status: 'approved',
        processedAt: DateTime.now(),
      );

      await repository.update(updated);
      final retrieved = await repository.getById(id);

      expect(retrieved?.status, equals('approved'));
    });

    test('delete removes refund', () async {
      final refund = Refund(
        id: 0,
        saleId: 1,
        refundAmount: 500,
        reason: 'Defective Product',
        notes: null,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final id = await repository.create(refund);
      await repository.delete(id);
      final retrieved = await repository.getById(id);

      expect(retrieved, isNull);
    });
  });
}
