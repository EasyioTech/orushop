import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/models/shop_models.dart';
import '../core/repositories/owner_provider.dart';

final shopTypeAsyncProvider = FutureProvider<ShopType>((ref) async {
  final ownerDetails = await ref.watch(ownerDetailsStreamProvider.future);
  if (ownerDetails == null) return ShopType.other;
  final typeName = ownerDetails['shopType'] as String?;
  if (typeName == null) return ShopType.other;
  return ShopType.values.firstWhere(
    (e) => e.name == typeName,
    orElse: () => ShopType.other,
  );
});

final shopTypeProvider = Provider<ShopType>((ref) {
  final ownerDetails = ref.watch(ownerDetailsStreamProvider).value;
  if (ownerDetails == null) return ShopType.other;
  final typeName = ownerDetails['shopType'] as String?;
  if (typeName == null) return ShopType.other;
  return ShopType.values.firstWhere(
    (e) => e.name == typeName,
    orElse: () => ShopType.other,
  );
});

final shopDetailsProvider = Provider<ShopDetails?>((ref) {
  final ownerDetails = ref.watch(ownerDetailsStreamProvider).value;
  if (ownerDetails == null) return null;
  
  final shopType = ShopType.values.firstWhere(
    (e) => e.name == (ownerDetails['shopType'] as String?),
    orElse: () => ShopType.other,
  );

  return ShopDetails(
    shopName: ownerDetails['storeName'] ?? '',
    ownerName: ownerDetails['ownerName'] ?? '',
    phoneNumber: ownerDetails['storePhone'] ?? '',
    shopAddress: ownerDetails['storeAddress'] ?? '',
    gstNumber: ownerDetails['gstNumber'],
    shopType: shopType,
    otherDetails: ownerDetails['otherDetails'],
    productCategories: List<String>.from(ownerDetails['productCategories'] ?? []),
    features: ShopFeatures(
      expiryDateTracking: ownerDetails['features']?['expiryDateTracking'] ?? false,
      batchNumber: ownerDetails['features']?['batchNumber'] ?? false,
      serialNumberTracking: ownerDetails['features']?['serialNumberTracking'] ?? false,
      gstTaxInvoicing: ownerDetails['features']?['gstTaxInvoicing'] ?? true,
      lowStockAlerts: ownerDetails['features']?['lowStockAlerts'] ?? true,
    ),
    referralCode: ownerDetails['referralCode'],
  );
});
