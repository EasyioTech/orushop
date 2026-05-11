enum ShopType {
  medical,
  grocery,
  electronics,
  clothing,
  bakery,
  stationery,
  hardware,
  cosmetics,
  mobile,
  restaurant,
  other,
}

class ShopTypeConfig {
  final ShopType type;
  final String displayName;
  final List<String> defaultCategories;
  final ShopFeatures features;

  ShopTypeConfig({
    required this.type,
    required this.displayName,
    required this.defaultCategories,
    required this.features,
  });

  static final Map<ShopType, ShopTypeConfig> configs = {
    ShopType.medical: ShopTypeConfig(
      type: ShopType.medical,
      displayName: 'Medical / Pharmacy',
      defaultCategories: ['Tablets', 'Syrups', 'Injections', 'Surgical Items', 'Baby Care', 'Vitamins'],
      features: ShopFeatures(
        expiryDateTracking: true,
        batchNumber: true,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: true,
      ),
    ),
    ShopType.grocery: ShopTypeConfig(
      type: ShopType.grocery,
      displayName: 'Grocery / Kirana Store',
      defaultCategories: ['Atta & Grains', 'Dal & Pulses', 'Oil & Ghee', 'Spices', 'Dairy', 'Beverages', 'Snacks', 'Packaged Food'],
      features: ShopFeatures(
        expiryDateTracking: true,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.electronics: ShopTypeConfig(
      type: ShopType.electronics,
      displayName: 'Electronics & Appliances',
      defaultCategories: ['TV', 'Refrigerator', 'AC', 'Washing Machine', 'Small Appliances'],
      features: ShopFeatures(
        expiryDateTracking: false,
        batchNumber: false,
        serialNumberTracking: true,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.clothing: ShopTypeConfig(
      type: ShopType.clothing,
      displayName: 'Clothing & Apparel',
      defaultCategories: ["Men's Wear", "Women's Wear", "Kids' Wear", 'Innerwear', 'Ethnic Wear', 'Accessories'],
      features: ShopFeatures(
        expiryDateTracking: false,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: true,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.bakery: ShopTypeConfig(
      type: ShopType.bakery,
      displayName: 'Bakery & Confectionery',
      defaultCategories: ['Bread (White, Brown, Multigrain)', 'Cakes', 'Pastries', 'Biscuits', 'Rusk', 'Cookies'],
      features: ShopFeatures(
        expiryDateTracking: true,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.stationery: ShopTypeConfig(
      type: ShopType.stationery,
      displayName: 'Stationery & Books',
      defaultCategories: ['Notebooks', 'Pens & Pencils', 'Books', 'Paper Products', 'Art Supplies'],
      features: ShopFeatures(
        expiryDateTracking: false,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.hardware: ShopTypeConfig(
      type: ShopType.hardware,
      displayName: 'Hardware & Tools',
      defaultCategories: ['Hand Tools', 'Power Tools', 'Building Materials', 'Fasteners', 'Safety Equipment'],
      features: ShopFeatures(
        expiryDateTracking: false,
        batchNumber: false,
        serialNumberTracking: true,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.cosmetics: ShopTypeConfig(
      type: ShopType.cosmetics,
      displayName: 'Cosmetics & Beauty',
      defaultCategories: ['Skincare', 'Makeup', 'Haircare', 'Fragrances', 'Bath & Body'],
      features: ShopFeatures(
        expiryDateTracking: true,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: true,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.mobile: ShopTypeConfig(
      type: ShopType.mobile,
      displayName: 'Mobile & Accessories',
      defaultCategories: ['Mobile Phones', 'Chargers & Cables', 'Protective Cases', 'Screen Protectors', 'Power Banks'],
      features: ShopFeatures(
        expiryDateTracking: false,
        batchNumber: false,
        serialNumberTracking: true,
        gstTaxInvoicing: true,
        sizeVariant: true,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.restaurant: ShopTypeConfig(
      type: ShopType.restaurant,
      displayName: 'Restaurant',
      defaultCategories: ['Main Course', 'Appetizers', 'Desserts', 'Beverages', 'Condiments'],
      features: ShopFeatures(
        expiryDateTracking: true,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: true,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
    ShopType.other: ShopTypeConfig(
      type: ShopType.other,
      displayName: 'Other',
      defaultCategories: [],
      features: ShopFeatures(
        expiryDateTracking: false,
        batchNumber: false,
        serialNumberTracking: false,
        gstTaxInvoicing: true,
        sizeVariant: false,
        recipeIngredients: false,
        lowStockAlerts: true,
        prescriptionRequired: false,
      ),
    ),
  };

  static ShopTypeConfig getConfig(ShopType type) => configs[type]!;
}

class ShopFeatures {
  bool expiryDateTracking;
  bool batchNumber;
  bool serialNumberTracking;
  bool gstTaxInvoicing;
  bool sizeVariant;
  bool recipeIngredients;
  bool lowStockAlerts;
  bool prescriptionRequired;

  ShopFeatures({
    required this.expiryDateTracking,
    required this.batchNumber,
    required this.serialNumberTracking,
    required this.gstTaxInvoicing,
    required this.sizeVariant,
    required this.recipeIngredients,
    required this.lowStockAlerts,
    required this.prescriptionRequired,
  });

  ShopFeatures copy() {
    return ShopFeatures(
      expiryDateTracking: expiryDateTracking,
      batchNumber: batchNumber,
      serialNumberTracking: serialNumberTracking,
      gstTaxInvoicing: gstTaxInvoicing,
      sizeVariant: sizeVariant,
      recipeIngredients: recipeIngredients,
      lowStockAlerts: lowStockAlerts,
      prescriptionRequired: prescriptionRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expiryDateTracking': expiryDateTracking,
      'batchNumber': batchNumber,
      'serialNumberTracking': serialNumberTracking,
      'gstTaxInvoicing': gstTaxInvoicing,
      'sizeVariant': sizeVariant,
      'recipeIngredients': recipeIngredients,
      'lowStockAlerts': lowStockAlerts,
      'prescriptionRequired': prescriptionRequired,
    };
  }
}

class ShopDetails {
  final String shopName;
  final String ownerName;
  final String phoneNumber;
  final String shopAddress;
  final String? gstNumber;
  final ShopType shopType;
  final String? otherDetails;
  final List<String> productCategories;
  final ShopFeatures features;

  ShopDetails({
    required this.shopName,
    required this.ownerName,
    required this.phoneNumber,
    required this.shopAddress,
    this.gstNumber,
    required this.shopType,
    this.otherDetails,
    required this.productCategories,
    required this.features,
  });

  static const _sentinel = Object();

  ShopDetails copyWith({
    String? shopName,
    String? ownerName,
    String? phoneNumber,
    String? shopAddress,
    Object? gstNumber = _sentinel,
    ShopType? shopType,
    Object? otherDetails = _sentinel,
    List<String>? productCategories,
    ShopFeatures? features,
  }) {
    return ShopDetails(
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shopAddress: shopAddress ?? this.shopAddress,
      gstNumber: gstNumber == _sentinel ? this.gstNumber : gstNumber as String?,
      shopType: shopType ?? this.shopType,
      otherDetails: otherDetails == _sentinel ? this.otherDetails : otherDetails as String?,
      productCategories: productCategories ?? this.productCategories,
      features: features ?? this.features,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': shopName,
      'ownerName': ownerName,
      'storePhone': phoneNumber,
      'storeAddress': shopAddress,
      'gstNumber': gstNumber,
      'shopType': shopType.name,
      'otherDetails': otherDetails,
      'productCategories': productCategories,
      'features': features.toMap(),
    };
  }
}

/// Template types matching the 6 billing templates.
enum ProductTemplate {
  standardRetail,   // 1 — simple piece-based products
  batchExpiry,      // 2 — pharma, FMCG with batch + expiry
  variantMatrix,    // 3 — clothing, footwear with size/color
  serialized,       // 4 — electronics with serial/warranty
  bulkUom,          // 5 — grocery/agri sold by weight/volume (loose)
  batchMultiUom,    // 6 — pharma/bulk with both batch and unit conversion (e.g. Strip vs Tablet)
  serviceLabor,     // 7 — haircut, repair, consultation (no stock)
}

/// Per-shop-type product field configuration.
/// Controls which fields are shown when adding a product in a category.
class ProductFieldConfig {
  final bool hasExpiryDate;
  final bool hasBatchNumber;
  final bool hasSerialNumber;
  final bool hasImei;
  final bool hasMrp;
  final bool hasHsnCode;
  final bool hasTaxRate;
  final bool hasBrand;
  final bool hasManufacturer;
  final bool hasSchedule;      // Drug schedule (H, H1, X) — medical
  final bool hasUnit;
  final bool hasWeight;
  final bool hasSizeVariant;
  final bool hasColorVariant;
  final bool hasWarranty;
  final bool hasRecipe;
  final bool hasIsbn;          // Books
  final bool hasReorderLevel;
  final bool hasPackagingUnit;
  final bool hasServiceDuration;
  final bool hasStaffCommission;

  final String defaultUnit;
  final List<String> unitOptions;
  final double defaultTaxRate;
  final List<String> sizeOptions;
  /// Product is a service/labor — no stock tracking, quantity = sessions/hours.
  final bool isService;
  /// Product can be sold in fractional quantities (0.5 kg, 1.5 m, 250 g).
  final bool isLoose;
  final ProductTemplate template;

  const ProductFieldConfig({
    this.hasExpiryDate = false,
    this.hasBatchNumber = false,
    this.hasSerialNumber = false,
    this.hasImei = false,
    this.hasMrp = true,
    this.hasHsnCode = false,
    this.hasTaxRate = false,
    this.hasBrand = false,
    this.hasManufacturer = false,
    this.hasSchedule = false,
    this.hasUnit = false,
    this.hasWeight = false,
    this.hasSizeVariant = false,
    this.hasColorVariant = false,
    this.hasWarranty = false,
    this.hasRecipe = false,
    this.hasIsbn = false,
    this.hasReorderLevel = true,
    this.hasPackagingUnit = false,
    this.hasServiceDuration = false,
    this.hasStaffCommission = false,

    this.defaultUnit = 'Piece',
    this.unitOptions = const ['Piece'],
    this.defaultTaxRate = 18.0,
    this.sizeOptions = const [],
    this.isService = false,
    this.isLoose = false,
    this.template = ProductTemplate.standardRetail,
  });

  factory ProductFieldConfig.basic() => const ProductFieldConfig();

  factory ProductFieldConfig.service() => const ProductFieldConfig(
    isService: true,
    isLoose: false,
    hasUnit: true,
    defaultUnit: 'Session',
    unitOptions: ['Session', 'Hour', 'Visit', 'Job'],
    hasMrp: false,
    hasServiceDuration: true,
    hasStaffCommission: true,
    template: ProductTemplate.serviceLabor,
  );
}

/// A product category with optional subcategories and field config.
class ShopCategory {
  final String name;
  final List<String> subcategories;
  final ProductFieldConfig productFields;

  const ShopCategory({
    required this.name,
    this.subcategories = const [],
    required this.productFields,
  });
}
