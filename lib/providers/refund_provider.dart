import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/refund.dart';
import '../core/repositories/refund_repository.dart';

class RefundNotifier extends Notifier<Map<String, dynamic>?> {
  RefundRepository get _refundRepository => ref.read(refundRepositoryProvider);

  @override
  Map<String, dynamic>? build() {
    return null;
  }

  Future<Map<String, dynamic>?> createRefund({
    required int saleId,
    required double refundAmount,
    required String reason,
    String? notes,
  }) async {
    try {
      state = {'loading': true};

      final refund = Refund(
        id: 0,
        saleId: saleId,
        refundAmount: refundAmount,
        reason: reason,
        notes: notes,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final refundId = await _refundRepository.create(refund);
      final refundWithId = refund.copyWith(id: refundId);

      state = {
        'loading': false,
        'refund': refundWithId,
      };
      return state;
    } catch (e) {
      state = {'loading': false, 'error': e.toString()};
      return null;
    }
  }

  Future<bool> approveRefund(int refundId) async {
    try {
      final refund = await _refundRepository.getById(refundId);
      if (refund == null) return false;

      final updated = refund.copyWith(
        status: 'approved',
        processedAt: DateTime.now(),
      );
      await _refundRepository.update(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectRefund(int refundId) async {
    try {
      final refund = await _refundRepository.getById(refundId);
      if (refund == null) return false;

      final updated = refund.copyWith(
        status: 'rejected',
        processedAt: DateTime.now(),
      );
      await _refundRepository.update(updated);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final refundRepositoryProvider = Provider((ref) => RefundRepository());

final refundProvider = NotifierProvider<RefundNotifier, Map<String, dynamic>?>(
  RefundNotifier.new,
);

final refundListProvider = FutureProvider<List<Refund>>((ref) async {
  final repository = ref.watch(refundRepositoryProvider);
  return repository.getAll();
});

final pendingRefundsProvider = FutureProvider<List<Refund>>((ref) async {
  final repository = ref.watch(refundRepositoryProvider);
  return repository.getByStatus('pending');
});

final saleRefundsProvider = FutureProvider.family<List<Refund>, int>((ref, saleId) async {
  final repository = ref.watch(refundRepositoryProvider);
  return repository.getBySaleId(saleId);
});

