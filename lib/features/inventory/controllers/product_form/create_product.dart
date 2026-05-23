// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../product_form_notifier.dart';

/// Product persistence to DB
extension ProductFormCreate on ProductFormNotifier {
  /// Create the product in the database
  Future<bool> createProduct() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      if (state.name.trim().isEmpty) {
        throw 'Product name is required';
      }
      if (state.selectedCategory == null) {
        throw 'Category is required';
      }

      final fields = state.selectedCategory!.productFields;
      ProductTemplate template = fields.template;
      if (state.isVariantTemplate && state.variantOverrides.isNotEmpty) {
        template = ProductTemplate.variantMatrix;
      } else if (state.isService) {
        template = ProductTemplate.serviceLabor;
      } else if (template == ProductTemplate.serialized &&
          (state.serialNumber == null || state.serialNumber!.trim().isEmpty)) {
        template = ProductTemplate.standardRetail;
      }

      final now = DateTime.now();
      final sku = state.sku.trim().isNotEmpty
          ? state.sku.trim()
          : 'SKU-${now.millisecondsSinceEpoch}';
      final product = Product(
        id: 0,
        template: template,
        name: state.name,
        sku: sku,
        price: state.sellingPrice,
        quantity: state.initialQuantity,
        category: state.selectedCategory!.name,
        subcategory: state.selectedSubcategory,
        unit: state.selectedUnit,
        mrp: state.mrp,
        hsnCode: state.hsnCode,
        taxRate: state.taxRate,
        brand: state.brand,
        manufacturer: state.manufacturer,
        serialNumber: state.serialNumber,
        imei: state.imei,
        warranty: state.warranty,
        schedule: state.schedule,
        weight: state.weight,
        recipe: state.recipe,
        isbn: state.isbn,
        size: state.size,
        color: state.color,
        imageUrl: state.externalImageUrl,
        imagePath: state.productImage?.path,
        createdAt: now,
        updatedAt: now,
        reorderLevel: state.reorderLevel,
        packagingUnit: state.packagingUnit,
        conversionFactor: state.conversionFactor,
        serviceDuration: null,
        staffCommission: null,
        expiryDate: state.expiryDate?.toIso8601String(),
        batchNumber: state.batchNumber,
        isService: state.isService,
        isLoose: state.isLoose,
        wholesalePrice: state.wholesalePrice > 0 ? state.wholesalePrice : null,
        costPrice: state.costPrice > 0 ? state.costPrice : null,
      );

      final db = await DatabaseHelper().database;
      await db.transaction((txn) async {
        final productRepo = ref.read(productRepositoryProvider);
        final productId = await productRepo.create(product, txn: txn);

        if (state.isVariantTemplate && state.variantOverrides.isNotEmpty) {
          for (final entry in state.variantOverrides.entries) {
            final parts = entry.key.split('|');
            final size = parts[0];
            final color = parts.length > 1 ? parts[1] : '';
            final ov = entry.value;

            final varPrice = double.tryParse(ov.price.text) ?? state.sellingPrice;
            final varStock = double.tryParse(ov.stock.text) ?? 0.0;
            final varSku = ov.sku.text.trim().isNotEmpty
                ? ov.sku.text.trim()
                : '${state.sku}-${[size, color].where((s) => s.isNotEmpty).join('-')}';

            final variant = ProductVariant(
              id: 0,
              productId: productId,
              size: size,
              color: color,
              sku: varSku,
              price: varPrice,
              stock: varStock,
              costPrice: state.costPrice > 0 ? state.costPrice : null,
              mrp: double.tryParse(ov.mrp.text),
              barcode: ov.barcode.text.trim().isEmpty ? null : ov.barcode.text.trim(),
              createdAt: now,
              updatedAt: now,
            );

            final varMap = variant.toMap()..remove('id');
            await txn.insert(TableConstants.productVariants, varMap);
          }

          final totalStock = state.variantOverrides.values.fold<double>(
            0,
            (s, ov) => s + (double.tryParse(ov.stock.text) ?? 0),
          );

          await txn.rawUpdate(
            'UPDATE products SET quantity = ? WHERE id = ?',
            [totalStock, productId],
          );
          await txn.rawUpdate(
            'UPDATE inventory_standard SET quantity = ? WHERE productId = ?',
            [totalStock, productId],
          );
        }
      });

      ref.invalidate(productsProvider);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create product: $e',
      );
      return false;
    }
  }
}
