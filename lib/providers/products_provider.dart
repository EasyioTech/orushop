import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/product.dart';
import '../core/repositories/product_repository.dart';
import '../core/repositories/batch_repository.dart';
import '../core/repositories/category_repository.dart';
import '../features/onboarding/models/shop_models.dart';
import '../features/onboarding/models/shop_catalog_data.dart';
import 'shop_provider.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());
final batchRepositoryProvider = Provider((ref) => BatchRepository());
final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final batchRepo = ref.watch(batchRepositoryProvider);
  final products = await repository.getAll();

  // Sync batches for any products with mismatched quantities
  for (final product in products) {
    if (product.displayQuantity != (product.liveBatchQuantity ?? 0)) {
      await batchRepo.syncBatchesForProduct(product.id, product.quantity);
    }
  }

  return products;
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

final shopCategoriesProvider = FutureProvider<List<ShopCategory>>((ref) async {
  final shopType = await ref.watch(shopTypeAsyncProvider.future);
  return ShopCatalog.forType(shopType);
});

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final categoriesAsync = await ref.watch(shopCategoriesProvider.future);
  return categoriesAsync.map((c) => c.name).toList();
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
            quantity: (product.quantity - soldItems[product.id]!).clamp(0, 999999),
            liveBatchQuantity: product.liveBatchQuantity != null
                ? (product.liveBatchQuantity! - soldItems[product.id]!).clamp(0, 999999)
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
final productSubcategoryProvider = StateProvider<String>((ref) => 'All');

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(paginatedProductsProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final category = ref.watch(productCategoryProvider);
  final subcategory = ref.watch(productSubcategoryProvider);

  // Filter products based on search, category, subcategory AND stock
  return products.where((p) {
    final matchesSearch = p.name.toLowerCase().contains(query) ||
                        p.sku.toLowerCase().contains(query);
    
    final matchesCategory = category == 'All' || p.category == category;
    final matchesSubcategory = subcategory == 'All' || p.subcategory == subcategory;
    
    // Hide out of stock items from the main shop view to prevent confusion
    final hasStock = p.displayQuantity > 0;
    
    return matchesSearch && matchesCategory && matchesSubcategory && hasStock;
  }).toList();
});
