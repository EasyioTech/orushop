import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orushops/core/models/product.dart';
import 'package:orushops/core/models/product_variant.dart';
import 'package:orushops/core/database/database_helper.dart';
import 'package:orushops/core/database/table_constants.dart';
import 'package:orushops/features/inventory/models/product_form_state.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/features/onboarding/models/shop_catalog_data.dart';
import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/shop_provider.dart';
import 'package:orushops/core/services/shop_catalog_service.dart';
import 'package:orushops/core/services/global_catalog_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notifier for managing product creation form state
class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final Ref ref;
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers (not in immutable state; managed locally)
  late final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'sku': TextEditingController(),
    'price': TextEditingController(),
    'wholesalePrice': TextEditingController(),
    'costPrice': TextEditingController(),
    'initialQty': TextEditingController(text: '0'),
    'mrp': TextEditingController(),
    'hsn': TextEditingController(),
    'tax': TextEditingController(),
    'brand': TextEditingController(),
    'manufacturer': TextEditingController(),
    'batchNumber': TextEditingController(),
    'serialNumber': TextEditingController(),
    'imei': TextEditingController(),
    'warranty': TextEditingController(),
    'schedule': TextEditingController(),
    'recipe': TextEditingController(),
    'weight': TextEditingController(),
    'isbn': TextEditingController(),
    'color': TextEditingController(),
    'size': TextEditingController(),
    'reorderLevel': TextEditingController(text: '5'),
    'packagingUnit': TextEditingController(),
    'conversionFactor': TextEditingController(text: '1'),
    'serviceDuration': TextEditingController(),
    'staffCommission': TextEditingController(),
  };

  ProductFormNotifier(this.ref) : super(const ProductFormState()) {
    _initializeListeners();
  }

  void _initializeListeners() {
    controllers['name']!.addListener(_onNameChanged);
    controllers['sku']!.addListener(_onSkuChanged);
  }

  Future<void> loadCategories() async {
    try {
      // Allow selectedCategory to remain null initially so user is forced to select one.
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load categories: $e');
    }
  }

  /// Update current step
  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// Category selection changed
  void onCategoryChanged(ShopCategory? category) {
    if (category == null) return;

    final fields = category.productFields;
    state = state.copyWith(
      selectedCategory: category,
      selectedSubcategory: category.subcategories.isNotEmpty ? category.subcategories.first : null,
      selectedUnit: fields.defaultUnit,
      taxRate: fields.defaultTaxRate,
      expiryDate: null,
      isLoose: fields.isLoose,
      isService: fields.isService,
      reorderLevel: 5.0,
      packagingUnit: fields.hasPackagingUnit ? 'Box' : null,
      conversionFactor: 1.0,
    );

    controllers['tax']!.text = fields.defaultTaxRate.toString();
    controllers['reorderLevel']!.text = '5';
    controllers['conversionFactor']!.text = '1';
    if (fields.hasPackagingUnit) {
      controllers['packagingUnit']!.text = 'Box';
    }
  }

  /// Subcategory selection
  void onSubcategoryChanged(String? subcategory) {
    state = state.copyWith(selectedSubcategory: subcategory);
  }

  /// Unit selection
  void onUnitChanged(String unit) {
    state = state.copyWith(selectedUnit: unit);
  }

  /// Handle name input changes
  void _onNameChanged() {
    final query = controllers['name']!.text.trim();
    state = state.copyWith(name: query);

    if (query.length >= 2) {
      _searchCatalog(query);
    } else if (state.catalogSuggestions.isNotEmpty) {
      state = state.copyWith(catalogSuggestions: []);
    }
  }

  /// Handle SKU input changes
  void _onSkuChanged() {
    final sku = controllers['sku']!.text.trim();
    state = state.copyWith(sku: sku);

    if (sku.length >= 8) {
      _lookupGlobalProduct(sku);
    }
  }

  /// Search catalog for suggestions
  Future<void> _searchCatalog(String query) async {
    try {
      final shopType = ref.read(shopTypeProvider);
      final service = ref.read(shopCatalogServiceProvider);
      final results = await service.searchLocal(query, shopType);

      final suggestions = results
          .map((item) => CatalogItemSuggestion(
                id: item.sku ?? '${item.name}-${item.category}'.replaceAll(' ', '-').toLowerCase(),
                name: item.name,
                category: item.category,
              ))
          .toList();

      state = state.copyWith(catalogSuggestions: suggestions);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Search failed: $e',
        catalogSuggestions: [],
      );
    }
  }

  /// Lookup product globally by SKU
  Future<void> _lookupGlobalProduct(String sku) async {
    try {
      final shopType = ref.read(shopTypeProvider);
      final globalCatalogService = ref.read(globalCatalogServiceProvider);
      final product = await globalCatalogService.searchBySKU(sku, shopType.name);

      if (product != null) {
        // Populate text controllers
        controllers['name']!.text = product.name;
        controllers['price']!.text = product.typicalPrice.toString();
        controllers['costPrice']!.text = product.typicalCost.toString();
        if (product.mrp != null) {
          controllers['mrp']!.text = product.mrp.toString();
        }
        if (product.hsnCode != null) {
          controllers['hsn']!.text = product.hsnCode!;
        }
        if (product.taxRate != null) {
          controllers['tax']!.text = product.taxRate.toString();
        }
        if (product.brand != null) {
          controllers['brand']!.text = product.brand!;
        }
        if (product.manufacturer != null) {
          controllers['manufacturer']!.text = product.manufacturer!;
        }
        if (product.uom != null) {
          state = state.copyWith(selectedUnit: product.uom!);
        }

        state = state.copyWith(
          name: product.name,
          sku: product.sku,
          brand: product.brand,
          manufacturer: product.manufacturer,
          isService: product.isService,
          isLoose: product.isLoose,
          errorMessage: 'Details pre-filled for "${product.name}"',
        );
      }
    } catch (e) {
      debugPrint('Error looking up global product: $e');
    }
  }

  /// Apply catalog suggestion to form
  void applyCatalogSuggestion(CatalogItemSuggestion suggestion) {
    controllers['name']!.text = suggestion.name;
    state = state.copyWith(
      name: suggestion.name,
      catalogSuggestions: [],
    );
  }

  /// Update basic info fields
  void updateInfoField(String fieldName, String value) {
    if (!controllers.containsKey(fieldName)) return;
    controllers[fieldName]!.text = value;

    switch (fieldName) {
      case 'brand':
        state = state.copyWith(brand: value);
      case 'manufacturer':
        state = state.copyWith(manufacturer: value);
      case 'hsn':
        state = state.copyWith(hsnCode: value);
      case 'weight':
        state = state.copyWith(weight: value);
      case 'recipe':
        state = state.copyWith(recipe: value);
      case 'isbn':
        state = state.copyWith(isbn: value);
      case 'serialNumber':
        state = state.copyWith(serialNumber: value);
      case 'imei':
        state = state.copyWith(imei: value);
      case 'warranty':
        state = state.copyWith(warranty: value);
      case 'schedule':
        state = state.copyWith(schedule: value);
      case 'batchNumber':
        state = state.copyWith(batchNumber: value);
      case 'size':
        state = state.copyWith(size: value);
      case 'color':
        state = state.copyWith(color: value);
    }
  }

  /// Update pricing fields
  void updatePricingField(String fieldName, String value) {
    if (!controllers.containsKey(fieldName)) return;
    controllers[fieldName]!.text = value;

    final doubleValue = double.tryParse(value) ?? 0.0;
    switch (fieldName) {
      case 'price':
        state = state.copyWith(sellingPrice: doubleValue);
      case 'wholesalePrice':
        state = state.copyWith(wholesalePrice: doubleValue);
      case 'costPrice':
        state = state.copyWith(costPrice: doubleValue);
      case 'mrp':
        state = state.copyWith(mrp: doubleValue);
      case 'tax':
        state = state.copyWith(taxRate: doubleValue);
    }
  }

  /// Update inventory fields
  void updateInventoryField(String fieldName, String value) {
    if (!controllers.containsKey(fieldName)) return;
    controllers[fieldName]!.text = value;

    final doubleValue = double.tryParse(value) ?? 0.0;
    switch (fieldName) {
      case 'initialQty':
        state = state.copyWith(initialQuantity: doubleValue);
      case 'reorderLevel':
        state = state.copyWith(reorderLevel: doubleValue);
      case 'conversionFactor':
        state = state.copyWith(conversionFactor: doubleValue);
      case 'packagingUnit':
        state = state.copyWith(packagingUnit: value.isEmpty ? null : value);
      case 'serviceDuration':
        final intValue = int.tryParse(value);
        state = state.copyWith(serviceDuration: intValue);
      case 'staffCommission':
        state = state.copyWith(staffCommission: doubleValue);
    }
  }

  /// Set expiry date
  void setExpiryDate(DateTime? date) {
    state = state.copyWith(expiryDate: date);
  }

  /// Toggle service product
  void setIsService(bool value) {
    state = state.copyWith(isService: value, isLoose: value ? false : state.isLoose);
  }

  /// Toggle loose product
  void setIsLoose(bool value) {
    state = state.copyWith(isLoose: value, isService: value ? false : state.isService);
  }

  /// Pick image from camera or gallery
  Future<void> pickProductImage({required ImageSource source}) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.status;
        if (!status.isGranted) {
          final requestStatus = await Permission.camera.request();
          if (!requestStatus.isGranted) {
            state = state.copyWith(errorMessage: 'Camera permission denied');
            return;
          }
        }
      }

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        state = state.copyWith(productImage: File(pickedFile.path));
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Image pick failed: $e');
    }
  }

  /// Clear error message
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  /// Clear product image
  void clearProductImage() {
    state = state.copyWith(productImage: null);
  }

  /// Toggle barcode scanner visibility
  void toggleScanner(bool show) {
    state = state.copyWith(showScanner: show);
  }

  /// Apply SKU from barcode scanner
  void applyScannedBarcode(String barcode) {
    controllers['sku']!.text = barcode;
    state = state.copyWith(sku: barcode, showScanner: false);
    _lookupGlobalProduct(barcode);
  }

  /// Add variant size
  void addVariantSize(String size) {
    if (size.trim().isEmpty) return;
    final newSizes = [...state.variantSizes, size.trim()];
    state = state.copyWith(variantSizes: newSizes, isVariantTemplate: true);
  }

  /// Remove variant size
  void removeVariantSize(String size) {
    final newSizes = state.variantSizes.where((s) => s != size).toList();
    state = state.copyWith(variantSizes: newSizes);
  }

  /// Add variant color
  void addVariantColor(String color) {
    if (color.trim().isEmpty) return;
    final newColors = [...state.variantColors, color.trim()];
    state = state.copyWith(variantColors: newColors, isVariantTemplate: true);
  }

  /// Remove variant color
  void removeVariantColor(String color) {
    final newColors = state.variantColors.where((c) => c != color).toList();
    state = state.copyWith(variantColors: newColors);
  }

  /// Update variant override for a size-color combo
  void updateVariantOverride(String key, {
    String? price,
    String? stock,
    String? sku,
    String? mrp,
    String? barcode,
  }) {
    final overrides = Map<String, ProductVariantOverride>.from(state.variantOverrides);
    final existing = overrides[key] ?? ProductVariantOverride();

    overrides[key] = ProductVariantOverride(
      price: price ?? existing.price.text,
      stock: stock ?? existing.stock.text,
      sku: sku ?? existing.sku.text,
      mrp: mrp ?? existing.mrp.text,
      barcode: barcode ?? existing.barcode.text,
    );

    state = state.copyWith(variantOverrides: overrides);
  }

  /// Create the product in the database
  Future<bool> createProduct() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Validation
      if (state.name.trim().isEmpty) {
        throw 'Product name is required';
      }
      if (state.selectedCategory == null) {
        throw 'Category is required';
      }

      // Derive the storage template from the category config, then refine it:
      // an explicit variant grid wins, and a service category forces serviceLabor.
      final fields = state.selectedCategory!.productFields;
      ProductTemplate template = fields.template;
      if (state.isVariantTemplate && state.variantOverrides.isNotEmpty) {
        template = ProductTemplate.variantMatrix;
      } else if (state.isService) {
        template = ProductTemplate.serviceLabor;
      }

      final now = DateTime.now();
      final product = Product(
        id: 0,
        template: template,
        name: state.name,
        sku: state.sku,
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
        serviceDuration: state.serviceDuration,
        staffCommission: state.staffCommission,
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

        // Handle variants if applicable
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

          // Update parent quantity to sum of variants
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

      // Invalidate product providers
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

  /// Check if a draft exists
  Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('product_creation_draft');
    } catch (_) {
      return false;
    }
  }

  /// Clear the saved draft
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('product_creation_draft');
      debugPrint('Draft cleared.');
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  /// Save form state as a draft in SharedPreferences
  Future<void> saveAsDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftData = {
        'categoryName': state.selectedCategory?.name,
        'subcategory': state.selectedSubcategory,
        'unit': state.selectedUnit,
        'isLoose': state.isLoose,
        'isService': state.isService,
        'name': state.name,
        'sku': state.sku,
        'brand': state.brand,
        'manufacturer': state.manufacturer,
        'hsnCode': state.hsnCode,
        'weight': state.weight,
        'recipe': state.recipe,
        'isbn': state.isbn,
        'size': state.size,
        'color': state.color,
        'serialNumber': state.serialNumber,
        'imei': state.imei,
        'warranty': state.warranty,
        'schedule': state.schedule,
        'expiryDate': state.expiryDate?.toIso8601String(),
        'batchNumber': state.batchNumber,
        'sellingPrice': state.sellingPrice,
        'wholesalePrice': state.wholesalePrice,
        'costPrice': state.costPrice,
        'mrp': state.mrp,
        'taxRate': state.taxRate,
        'initialQuantity': state.initialQuantity,
        'reorderLevel': state.reorderLevel,
        'packagingUnit': state.packagingUnit,
        'conversionFactor': state.conversionFactor,
        'imagePath': state.productImage?.path,
        'currentStep': state.currentStep,
        'variantSizes': state.variantSizes,
        'variantColors': state.variantColors,
      };

      final jsonStr = json.encode(draftData);
      await prefs.setString('product_creation_draft', jsonStr);
      debugPrint('Draft saved successfully.');
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  /// Restore draft from SharedPreferences
  Future<bool> restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('product_creation_draft');
      if (jsonStr == null) return false;

      final data = json.decode(jsonStr) as Map<String, dynamic>;

      // 1. Resolve Category
      ShopCategory? selectedCategory;
      if (data['categoryName'] != null) {
        final shopType = ref.read(shopTypeProvider);
        final categories = ShopCatalog.forType(shopType);
        for (final cat in categories) {
          if (cat.name.toLowerCase() == data['categoryName'].toString().toLowerCase()) {
            selectedCategory = cat;
            break;
          }
        }
      }

      // Populate text controllers first
      controllers['name']!.text = data['name'] ?? '';
      controllers['sku']!.text = data['sku'] ?? '';
      controllers['brand']!.text = data['brand'] ?? '';
      controllers['manufacturer']!.text = data['manufacturer'] ?? '';
      controllers['hsn']!.text = data['hsnCode'] ?? '';
      controllers['weight']!.text = data['weight'] ?? '';
      controllers['recipe']!.text = data['recipe'] ?? '';
      controllers['isbn']!.text = data['isbn'] ?? '';
      controllers['size']!.text = data['size'] ?? '';
      controllers['color']!.text = data['color'] ?? '';
      controllers['serialNumber']!.text = data['serialNumber'] ?? '';
      controllers['imei']!.text = data['imei'] ?? '';
      controllers['warranty']!.text = data['warranty'] ?? '';
      controllers['schedule']!.text = data['schedule'] ?? '';
      controllers['batchNumber']!.text = data['batchNumber'] ?? '';
      controllers['price']!.text = data['sellingPrice']?.toString() ?? '';
      controllers['wholesalePrice']!.text = data['wholesalePrice']?.toString() ?? '';
      controllers['costPrice']!.text = data['costPrice']?.toString() ?? '';
      controllers['mrp']!.text = data['mrp']?.toString() ?? '';
      controllers['tax']!.text = data['taxRate']?.toString() ?? '';
      controllers['initialQty']!.text = data['initialQuantity']?.toString() ?? '0';
      controllers['reorderLevel']!.text = data['reorderLevel']?.toString() ?? '5';
      controllers['packagingUnit']!.text = data['packagingUnit'] ?? '';
      controllers['conversionFactor']!.text = data['conversionFactor']?.toString() ?? '1';

      // 2. Set State
      state = state.copyWith(
        selectedCategory: selectedCategory,
        selectedSubcategory: data['subcategory'],
        selectedUnit: data['unit'] ?? 'Piece',
        isLoose: data['isLoose'] ?? false,
        isService: data['isService'] ?? false,
        name: data['name'] ?? '',
        sku: data['sku'] ?? '',
        brand: data['brand'],
        manufacturer: data['manufacturer'],
        hsnCode: data['hsnCode'],
        weight: data['weight'],
        recipe: data['recipe'],
        isbn: data['isbn'],
        size: data['size'],
        color: data['color'],
        serialNumber: data['serialNumber'],
        imei: data['imei'],
        warranty: data['warranty'],
        schedule: data['schedule'],
        expiryDate: data['expiryDate'] != null ? DateTime.tryParse(data['expiryDate']) : null,
        batchNumber: data['batchNumber'],
        sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
        costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
        mrp: (data['mrp'] as num?)?.toDouble(),
        taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
        initialQuantity: (data['initialQuantity'] as num?)?.toDouble() ?? 0.0,
        reorderLevel: (data['reorderLevel'] as num?)?.toDouble() ?? 5.0,
        packagingUnit: data['packagingUnit'],
        conversionFactor: (data['conversionFactor'] as num?)?.toDouble() ?? 1.0,
        productImage: data['imagePath'] != null ? File(data['imagePath']) : null,
        variantSizes: List<String>.from(data['variantSizes'] ?? []),
        variantColors: List<String>.from(data['variantColors'] ?? []),
        currentStep: data['currentStep'] ?? 0,
      );

      debugPrint('Draft restored successfully.');
      return true;
    } catch (e) {
      debugPrint('Error restoring draft: $e');
      return false;
    }
  }

  /// Clear all form data
  void reset() {
    for (final controller in controllers.values) {
      controller.text = '';
    }
    controllers['initialQty']!.text = '0';
    controllers['reorderLevel']!.text = '5';
    controllers['conversionFactor']!.text = '1';

    state = const ProductFormState();
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    for (final override in state.variantOverrides.values) {
      override.dispose();
    }
    super.dispose();
  }
}

/// Riverpod provider for the notifier
final productFormNotifierProvider =
    StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>(
  (ref) => ProductFormNotifier(ref),
);
