import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) => RevenueCatService());

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  bool _initialized = false;

  // RevenueCat API keys
  static const String _googleApiKey = 'test_gezrwgNwNVPOJFCtZUtHDCYLJXw';
  static const String _appleApiKey = 'test_gezrwgNwNVPOJFCtZUtHDCYLJXw';

  // Entitlements
  static const String _oruShopsProEntitlement = 'OruShops_Pro';

  // Product identifiers
  static const Map<String, String> productIdentifiers = {
    'monthly': 'monthly_subscription',
    'yearly': 'yearly_subscription',
    'lifetime': 'lifetime_subscription',
  };

  RevenueCatService._internal();

  factory RevenueCatService() => _instance;

  static RevenueCatService get instance => _instance;

  bool get isInitialized => _initialized;

  String get oruShopsProEntitlement => _oruShopsProEntitlement;

  /// Initialize RevenueCat with user ID
  Future<void> initialize(String userId) async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey)
          ..appUserID = userId;
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey)
          ..appUserID = userId;
      } else {
        return; // Web not supported
      }

      await Purchases.configure(configuration);

      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
      rethrow;
    }
  }

  /// Log in user with custom user ID
  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('Failed to log in to RevenueCat: $e');
      rethrow;
    }
  }

  /// Log out current user
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Failed to log out from RevenueCat: $e');
      rethrow;
    }
  }

  /// Get all available offerings and packages
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to fetch offerings: $e');
      return null;
    }
  }

  /// Purchase a specific package
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } catch (e) {
      debugPrint('Failed to purchase package: $e');
      rethrow;
    }
  }

  /// Purchase a specific product by ID
  Future<CustomerInfo> purchaseProduct(String productId) async {
    try {
      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) {
        throw Exception('Product $productId not found');
      }
      final result = await Purchases.purchase(PurchaseParams.storeProduct(products.first));
      return result.customerInfo;
    } catch (e) {
      debugPrint('Failed to purchase product: $e');
      rethrow;
    }
  }

  /// Restore purchases (useful after app reinstall)
  Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      rethrow;
    }
  }

  /// Get current customer info
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Failed to fetch customer info: $e');
      rethrow;
    }
  }

  /// Check if user has active "OruShops Pro" entitlement
  Future<bool> hasOruShopsProAccess() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_oruShopsProEntitlement);
    } catch (e) {
      debugPrint('Error checking OruShops Pro access: $e');
      return false;
    }
  }

  /// Get all active entitlements
  Future<Set<String>> getActiveEntitlements() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.keys.toSet();
    } catch (e) {
      debugPrint('Error fetching active entitlements: $e');
      return {};
    }
  }

  /// Check if user is a subscriber (has any active subscription)
  Future<bool> isSubscriber() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking subscriber status: $e');
      return false;
    }
  }

  /// Get subscription period info
  Future<EntitlementInfo?> getOruShopsProInfo() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active[_oruShopsProEntitlement];
    } catch (e) {
      debugPrint('Error fetching entitlement info: $e');
      return null;
    }
  }

  /// Get list of all active product identifiers from entitlements
  Future<Set<String>> getActivePurchases() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.keys.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Check if specific entitlement is active
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('Error checking entitlement: $e');
      return false;
    }
  }

  /// Set custom user attributes
  Future<void> setUserAttribute(String key, String value) async {
    try {
      final attr = <String, String>{key: value};
      await Purchases.setAttributes(attr);
    } catch (e) {
      debugPrint('Error setting user attribute: $e');
    }
  }

  /// Set custom user attributes (multiple at once)
  Future<void> setUserAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
    } catch (e) {
      debugPrint('Error setting user attributes: $e');
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    // Cleanup if needed
  }
}
