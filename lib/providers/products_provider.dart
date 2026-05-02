import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/product.dart';
import '../core/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getAll();
});

final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  final List<Product> products;
  if (query.isEmpty) {
    products = await repository.getAll();
  } else {
    products = await repository.searchByName(query);
  }
  
  // Only show items with stock in search results to prevent confusion
  return products.where((p) => p.displayQuantity > 0).toList();
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

class PaginationNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repository;
  static const int pageSize = 500;
  int _currentPage = 0;
  bool _hasMore = true;

  PaginationNotifier(this._repository) : super([]);

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final newProducts = await _repository.getPaginated(pageSize, _currentPage * pageSize);

    if (newProducts.isEmpty) {
      _hasMore = false;
    } else {
      state = [...state, ...newProducts];
      _currentPage++;
    }
  }

  Future<void> reset() async {
    state = [];
    _currentPage = 0;
    _hasMore = true;
    await loadMore();
  }

  void decrementStock(Map<int, int> soldItems) {
    state = [
      for (final product in state)
        if (soldItems.containsKey(product.id))
          product.copyWith(
            quantity: (product.quantity - soldItems[product.id]!).clamp(0, product.quantity),
            liveBatchQuantity: product.liveBatchQuantity != null
                ? (product.liveBatchQuantity! - soldItems[product.id]!).clamp(0, product.liveBatchQuantity!)
                : null,
          )
        else
          product,
    ];
  }
}

final paginatedProductsProvider = StateNotifierProvider<PaginationNotifier, List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return PaginationNotifier(repository);
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');
final productCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(paginatedProductsProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final category = ref.watch(productCategoryProvider);

  // Filter products based on search, category AND stock
  return products.where((p) {
    final matchesSearch = p.name.toLowerCase().contains(query) ||
                        p.sku.toLowerCase().contains(query);
    final matchesCategory = category == 'All' || p.category == category;
    
    // Hide out of stock items from the main shop view to prevent confusion
    final hasStock = p.displayQuantity > 0;
    
    return matchesSearch && matchesCategory && hasStock;
  }).toList();
});
