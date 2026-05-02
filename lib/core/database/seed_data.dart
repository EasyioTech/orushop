import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'catalog_data.dart';

class SeedData {
  static Future<void> seedProducts({bool force = false}) async {
    final repository = ProductRepository();
    
    if (force) {
      await repository.deleteAll();
    } else {
      final existing = await repository.getAll();
      if (existing.isNotEmpty) return;
    }

    for (final data in catalogData) {
      final now = DateTime.now();
      final product = Product(
        id: 0, // SQLite will autoincrement
        name: data['name'],
        sku: data['sku'],
        price: (data['price'] as num).toDouble(),
        quantity: 100, // Starting stock for catalog items
        category: data['category'],
        imageUrl: data['imageUrl'],
        createdAt: now,
        updatedAt: now,
      );
      await repository.create(product);
    }
  }
}
