import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/service_category_model.dart';
import '../core/repositories/service_category_repository.dart';

final serviceCategoryRepositoryProvider = Provider((ref) => ServiceCategoryRepository());

final serviceCategoriesProvider = FutureProvider.family<List<ServiceCategoryModel>, String?>((ref, shopType) async {
  final repository = ref.watch(serviceCategoryRepositoryProvider);
  return repository.getAll(shopType: shopType);
});
