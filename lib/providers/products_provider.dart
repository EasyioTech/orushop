import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/product.dart';
import '../core/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

final productsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final repository = ref.watch(productRepositoryProvider);
    return await repository.getAll();
  } catch (e) {
    return [];
  }
});

final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  if (query.isEmpty) {
    return repository.getAll();
  }
  return repository.searchByName(query);
});

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getCategories();
});

final productByIdProvider =
    FutureProvider.family<Product?, int>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getById(productId);
});
