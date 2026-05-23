import 'dart:io';
import 'package:orushops/features/onboarding/models/shop_models.dart';

class ProductFormState {
  // Navigation
  final int currentStep;

  // Step 1: Category Selection
  final ShopCategory? selectedCategory;
  final String? selectedSubcategory;
  final String selectedUnit;

  // Step 2: Product Info
  final String name;
  final String sku;
  final String? brand;
  final String? manufacturer;
  final String? hsnCode;
  final String? weight;
  final String? recipe;
  final String? isbn;
  final String? size;
  final String? color;
  final String? serialNumber;
  final String? imei;
  final String? warranty;
  final String? schedule;
  final DateTime? expiryDate;
  final String? batchNumber;

  // Step 3: Pricing
  final double sellingPrice;
  final double wholesalePrice;
  final double costPrice;
  final double? mrp;
  final double taxRate;

  // Step 4: Stock
  final double initialQuantity;
  final double reorderLevel;
  final String? packagingUnit;
  final double conversionFactor;

  // Step 5: Variants
  final List<String> variantSizes;
  final List<String> variantColors;
  final Map<String, ProductVariantOverride> variantOverrides;
  final bool isVariantTemplate;

  // Additional Flags
  final bool isService;
  final bool isLoose;

  // Media
  final File? productImage;
  final String? externalImageUrl;
  final bool showScanner;

  // UI State
  final List<CatalogItemSuggestion> catalogSuggestions;
  final bool isLoading;
  final String? errorMessage;
  final bool showAdvancedPricing;

  const ProductFormState({
    this.currentStep = 0,
    this.selectedCategory,
    this.selectedSubcategory,
    this.selectedUnit = 'Piece',
    this.name = '',
    this.sku = '',
    this.brand,
    this.manufacturer,
    this.hsnCode,
    this.weight,
    this.recipe,
    this.isbn,
    this.size,
    this.color,
    this.serialNumber,
    this.imei,
    this.warranty,
    this.schedule,
    this.expiryDate,
    this.batchNumber,
    this.sellingPrice = 0.0,
    this.wholesalePrice = 0.0,
    this.costPrice = 0.0,
    this.mrp,
    this.taxRate = 0.0,
    this.initialQuantity = 0.0,
    this.reorderLevel = 5.0,
    this.packagingUnit,
    this.conversionFactor = 1.0,
    this.variantSizes = const [],
    this.variantColors = const [],
    this.variantOverrides = const {},
    this.isVariantTemplate = false,
    this.isService = false,
    this.isLoose = false,
    this.productImage,
    this.externalImageUrl,
    this.showScanner = false,
    this.catalogSuggestions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.showAdvancedPricing = false,
  });

  ProductFormState copyWith({
    int? currentStep,
    ShopCategory? selectedCategory,
    String? selectedSubcategory,
    String? selectedUnit,
    String? name,
    String? sku,
    String? brand,
    String? manufacturer,
    String? hsnCode,
    String? weight,
    String? recipe,
    String? isbn,
    String? size,
    String? color,
    String? serialNumber,
    String? imei,
    String? warranty,
    String? schedule,
    DateTime? expiryDate,
    String? batchNumber,
    double? sellingPrice,
    double? wholesalePrice,
    double? costPrice,
    double? mrp,
    double? taxRate,
    double? initialQuantity,
    double? reorderLevel,
    String? packagingUnit,
    double? conversionFactor,
    List<String>? variantSizes,
    List<String>? variantColors,
    Map<String, ProductVariantOverride>? variantOverrides,
    bool? isVariantTemplate,
    bool? isService,
    bool? isLoose,
    File? productImage,
    String? externalImageUrl,
    bool? showScanner,
    List<CatalogItemSuggestion>? catalogSuggestions,
    bool? isLoading,
    String? errorMessage,
    bool? showAdvancedPricing,
  }) {
    return ProductFormState(
      currentStep: currentStep ?? this.currentStep,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSubcategory: selectedSubcategory ?? this.selectedSubcategory,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      brand: brand ?? this.brand,
      manufacturer: manufacturer ?? this.manufacturer,
      hsnCode: hsnCode ?? this.hsnCode,
      weight: weight ?? this.weight,
      recipe: recipe ?? this.recipe,
      isbn: isbn ?? this.isbn,
      size: size ?? this.size,
      color: color ?? this.color,
      serialNumber: serialNumber ?? this.serialNumber,
      imei: imei ?? this.imei,
      warranty: warranty ?? this.warranty,
      schedule: schedule ?? this.schedule,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      costPrice: costPrice ?? this.costPrice,
      mrp: mrp ?? this.mrp,
      taxRate: taxRate ?? this.taxRate,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      packagingUnit: packagingUnit ?? this.packagingUnit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      variantSizes: variantSizes ?? this.variantSizes,
      variantColors: variantColors ?? this.variantColors,
      variantOverrides: variantOverrides ?? this.variantOverrides,
      isVariantTemplate: isVariantTemplate ?? this.isVariantTemplate,
      isService: isService ?? this.isService,
      isLoose: isLoose ?? this.isLoose,
      productImage: productImage ?? this.productImage,
      externalImageUrl: externalImageUrl ?? this.externalImageUrl,
      showScanner: showScanner ?? this.showScanner,
      catalogSuggestions: catalogSuggestions ?? this.catalogSuggestions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      showAdvancedPricing: showAdvancedPricing ?? this.showAdvancedPricing,
    );
  }
}

/// Lightweight variant override model
class ProductVariantOverride {
  final TextEditingData price;
  final TextEditingData stock;
  final TextEditingData sku;
  final TextEditingData mrp;
  final TextEditingData barcode;

  ProductVariantOverride({
    String? price,
    String? stock,
    String? sku,
    String? mrp,
    String? barcode,
  })  : price = TextEditingData(price ?? ''),
        stock = TextEditingData(stock ?? ''),
        sku = TextEditingData(sku ?? ''),
        mrp = TextEditingData(mrp ?? ''),
        barcode = TextEditingData(barcode ?? '');

  void dispose() {
    price.dispose();
    stock.dispose();
    sku.dispose();
    mrp.dispose();
    barcode.dispose();
  }
}

/// Simple wrapper for TextEditingController without freezed complexity
class TextEditingData {
  final String text;

  TextEditingData(this.text);

  void dispose() {
    // No-op; actual controllers managed separately in notifier
  }
}

/// Catalog suggestion model (immutable)
class CatalogItemSuggestion {
  final String id;
  final String name;
  final String? category;

  CatalogItemSuggestion({
    required this.id,
    required this.name,
    this.category,
  });
}
