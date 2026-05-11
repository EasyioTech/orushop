import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/repositories/product_repository.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';

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
        TableConstants.inventoryStandard,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      await txn.delete(
        TableConstants.inventorySerialized,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      await txn.delete(
        TableConstants.productVariants,
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
    ProductTemplate? template,
    String? serialNumber,
    String? imei,
  }) async {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than 0');
    if (costPrice <= 0) throw ArgumentError('Cost price must be greater than 0');

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Serialized template: insert into inventory_serialized instead of product_batches
    if (template == ProductTemplate.serialized) {
      await db.transaction((txn) async {
        await txn.insert(
          TableConstants.inventorySerialized,
          {
            'productId': productId,
            'serialNumber': serialNumber,
            'imei': imei,
            'sellingPrice': 0,
            'mrp': 0,
            'costPrice': costPrice,
            'status': 'in_stock',
          },
        );
        await txn.rawUpdate(
          'UPDATE ${TableConstants.products} SET quantity = quantity + ? WHERE id = ?',
          [quantity, productId],
        );
      });
      return;
    }

    // Bulk/UOM template: update inventory_standard directly instead of creating batches
    if (template == ProductTemplate.bulkUom) {
      await db.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE ${TableConstants.inventoryStandard} SET quantity = quantity + ? WHERE productId = ?',
          [quantity, productId],
        );
        await txn.rawUpdate(
          'UPDATE ${TableConstants.products} SET quantity = quantity + ? WHERE id = ?',
          [quantity, productId],
        );
      });
      return;
    }

    // Standard/Batch/Multi-UOM: insert batch normally
    await db.transaction((txn) async {
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

      await txn.rawUpdate(
        'UPDATE ${TableConstants.products} SET quantity = quantity + ? WHERE id = ?',
        [quantity, productId],
      );
    });
  }
}
