import 'dart:io';
import '../../../core/utils/app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

part 'product_form/field_updates.dart';
part 'product_form/create_product.dart';
part 'product_form/persistence.dart';

/// Notifier for managing product creation form state
class ProductFormNotifier extends Notifier<ProductFormState> {
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers live here (not in immutable state) and are disposed via
  // ref.onDispose registered inside build().
  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'sku': TextEditingController(),
    'price': TextEditingController(),
    'wholesalePrice': TextEditingController(),
    'costPrice': TextEditingController(),
    'initialQty': TextEditingController(),
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
    'reorderLevel': TextEditingController(),
    'packagingUnit': TextEditingController(),
    'conversionFactor': TextEditingController(),
    'serviceDuration': TextEditingController(),
    'staffCommission': TextEditingController(),
  };

  // Tracks whether the notifier has been disposed so async callbacks can bail out early
  bool _disposed = false;
  bool _listenersAdded = false;

  @override
  ProductFormState build() {
    _disposed = false;
    _initializeListeners();
    ref.onDispose(() {
      _disposed = true;
      cancelSearches();
      for (final c in controllers.values) {
        c.dispose();
      }
      for (final o in state.variantOverrides.values) {
        o.dispose();
      }
    });
    return const ProductFormState();
  }

  void _initializeListeners() {
    if (_listenersAdded) return;
    _listenersAdded = true;
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

    controllers['tax']!.text = '';
    controllers['reorderLevel']!.text = '';
    controllers['conversionFactor']!.text = '';
    if (fields.hasPackagingUnit) {
      controllers['packagingUnit']!.text = '';
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

  Timer? _nameDebounce;
  Timer? _skuDebounce;
  String _currentSearchQuery = '';
  String _currentSkuSearch = '';

  /// Handle name input changes
  void _onNameChanged() {
    final query = controllers['name']!.text.trim();
    state = state.copyWith(name: query);

    if (query.length < 2) {
      if (state.catalogSuggestions.isNotEmpty) {
        state = state.copyWith(catalogSuggestions: []);
      }
      return;
    }

    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchCatalog(query);
    });
  }

  /// Handle SKU input changes
  void _onSkuChanged() {
    final sku = controllers['sku']!.text.trim();
    state = state.copyWith(sku: sku);

    if (sku.length < 8) return;

    _skuDebounce?.cancel();
    _skuDebounce = Timer(const Duration(milliseconds: 400), () {
      _lookupGlobalProduct(sku);
    });
  }

  void cancelSearches() {
    _nameDebounce?.cancel();
    _skuDebounce?.cancel();
    _currentSearchQuery = '';
    _currentSkuSearch = '';
  }

  /// Search catalog for suggestions
  Future<void> _searchCatalog(String query) async {
    _currentSearchQuery = query;
    try {
      final shopType = ref.read(shopTypeProvider);
      final service = ref.read(shopCatalogServiceProvider);
      final results = await service.searchLocal(query, shopType);

      if (_disposed) return; // Prevent updating state after widget dispose
      if (_currentSearchQuery != query) return; // Cancelled or superseded

      final suggestions = results
          .map((item) => CatalogItemSuggestion(
                id: item.sku ?? '${item.name}-${item.category}'.replaceAll(' ', '-').toLowerCase(),
                name: item.name,
                category: item.category,
              ))
          .toList();

      state = state.copyWith(catalogSuggestions: suggestions);
    } catch (e) {
      if (_disposed) return; // Prevent updating state after widget dispose
      state = state.copyWith(
        errorMessage: 'Search failed: $e',
        catalogSuggestions: [],
      );
    }
  }

  /// Lookup product globally by SKU
  Future<void> _lookupGlobalProduct(String sku) async {
    _currentSkuSearch = sku;
    try {
      final shopType = ref.read(shopTypeProvider);
      final globalCatalogService = ref.read(globalCatalogServiceProvider);
      final product = await globalCatalogService.searchBySKU(sku, shopType.name);

      if (_disposed) return; // Prevent updating state after widget dispose
      if (_currentSkuSearch != sku) return; // Cancelled or superseded

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
      if (_disposed) return; // Prevent updating state after widget dispose
      appLogger.debug('Error looking up global product: $e');
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
      // Save current state as draft before launching external camera/gallery
      // This protects against Android OS killing the background app to free memory
      await saveAsDraft();

      // Allow image_picker to handle permissions natively to avoid intent conflicts or crashes
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        // Guard: provider may have been disposed while camera/gallery was open
        if (_disposed) return;
        state = state.copyWith(productImage: File(pickedFile.path));
        // Save draft again after successful image pick
        await saveAsDraft();
      }
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(errorMessage: 'Image pick failed: $e');
    }
  }

  /// Toggle advanced pricing options
  void setAdvancedPricing(bool show) {
    state = state.copyWith(showAdvancedPricing: show);
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

  /// Clear all form data
  void reset() {
    cancelSearches();
    for (final controller in controllers.values) {
      controller.text = '';
    }

    state = const ProductFormState();
  }

}

/// Not autoDispose — survives while camera/gallery is open during image picking.
/// Disposal is handled via ref.onDispose registered inside build().
final productFormNotifierProvider =
    NotifierProvider<ProductFormNotifier, ProductFormState>(
  ProductFormNotifier.new,
);