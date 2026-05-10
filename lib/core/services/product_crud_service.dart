import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/repositories/product_repository.dart';

class ProductCrudService {
  final ProductRepository _repo = ProductRepository();

  Future<void> updateProduct(Product product) async {
    if (product.name.isEmpty || product.sku.isEmpty || product.price <= 0 || product.category.isEmpty) {
      throw ArgumentError('Invalid product data: all fields required');
    }
    await _repo.update(product);
  }

  Future<void> deleteProduct(int productId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        TableConstants.productBatches,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      await txn.delete(
        TableConstants.products,
        where: 'id = ?',
        whereArgs: [productId],
      );
    });
  }

  Future<void> addStock({
    required int productId,
    required double quantity,
    required double costPrice,
    required DateTime expiryDate,
    String? batchNumber,
  }) async {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than 0');
    if (costPrice <= 0) throw ArgumentError('Cost price must be greater than 0');

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // 1. Insert the batch
      await txn.insert(
        TableConstants.productBatches,
        {
          'productId': productId,
          'quantity': quantity,
          'costPrice': costPrice,
          'batchNumber': batchNumber,
          'expiryDate': expiryDate.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // 2. Increment the product total quantity
      await txn.rawUpdate(
        'UPDATE ${TableConstants.products} SET quantity = quantity + ? WHERE id = ?',
        [quantity, productId],
      );
    });
  }
}
