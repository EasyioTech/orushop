import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/product_batch.dart';
import '../core/repositories/batch_repository.dart';

final batchRepositoryProvider = Provider((ref) => BatchRepository());

final batchesByProductProvider =
    FutureProvider.family<List<ProductBatch>, int>((ref, productId) async {
  final repository = ref.watch(batchRepositoryProvider);
  return repository.getByProductId(productId);
});

final availableBatchesProvider =
    FutureProvider.family<List<ProductBatch>, int>((ref, productId) async {
  final repository = ref.watch(batchRepositoryProvider);
  return repository.getAvailableBatches(productId);
});

final expiredBatchesProvider = FutureProvider<List<ProductBatch>>((ref) async {
  final repository = ref.watch(batchRepositoryProvider);
  return repository.getExpiredBatches();
});
