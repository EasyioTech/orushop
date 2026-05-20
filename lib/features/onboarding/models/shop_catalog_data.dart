import 'shop_models.dart';

/// Full catalog: categories -> subcategories -> suggested product fields
/// Covers the most common Indian retail store types.

part 'shop_catalog/medical_catalog.dart';
part 'shop_catalog/grocery_catalog.dart';
part 'shop_catalog/electronics_catalog.dart';
part 'shop_catalog/clothing_catalog.dart';
part 'shop_catalog/bakery_catalog.dart';
part 'shop_catalog/stationery_catalog.dart';
part 'shop_catalog/hardware_catalog.dart';
part 'shop_catalog/cosmetics_catalog.dart';
part 'shop_catalog/mobile_catalog.dart';
part 'shop_catalog/restaurant_catalog.dart';
part 'shop_catalog/other_catalog.dart';

class ShopCatalog {
  static Map<ShopType, List<ShopCategory>> get catalog => _catalog;

  static List<ShopCategory> forType(ShopType type) =>
      _catalog[type] ?? _catalog[ShopType.other]!;

  /// Returns flat list of category names (for backward compat with categories screen)
  static List<String> categoryNamesFor(ShopType type) =>
      forType(type).map((c) => c.name).toList();

  static final Map<ShopType, List<ShopCategory>> _catalog = {
    ShopType.medical: _medicalCategories,
    ShopType.grocery: _groceryCategories,
    ShopType.electronics: _electronicsCategories,
    ShopType.clothing: _clothingCategories,
    ShopType.bakery: _bakeryCategories,
    ShopType.stationery: _stationeryCategories,
    ShopType.hardware: _hardwareCategories,
    ShopType.cosmetics: _cosmeticsCategories,
    ShopType.mobile: _mobileCategories,
    ShopType.restaurant: _restaurantCategories,
    ShopType.other: _otherCategories,
  };
}