import '../models/product.dart';
import '../repositories/product_repository.dart';

class SeedData {
  static Future<void> seedProducts() async {
    final repository = ProductRepository();
    final existing = await repository.getAll();
    
    if (existing.isNotEmpty) return;

    final samples = [
      Product(
        id: 0,
        name: 'Classic White T-Shirt',
        sku: 'TSH-WHT-01',
        price: 499.0,
        quantity: 50,
        category: 'Apparel',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 0,
        name: 'Blue Denim Jeans',
        sku: 'JNS-BLU-02',
        price: 1299.0,
        quantity: 30,
        category: 'Apparel',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 0,
        name: 'Leather Wallet',
        sku: 'WLT-LTH-03',
        price: 899.0,
        quantity: 20,
        category: 'Accessories',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 0,
        name: 'Wireless Mouse',
        sku: 'MSE-WRL-04',
        price: 750.0,
        quantity: 15,
        category: 'Electronics',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 0,
        name: 'Coffee Mug',
        sku: 'MUG-CER-05',
        price: 250.0,
        quantity: 100,
        category: 'Home',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final product in samples) {
      await repository.create(product);
    }
  }
}
