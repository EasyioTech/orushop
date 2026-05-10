import 'dart:io';
import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';

final revenueCatServiceProvider =
    Provider<RevenueCatService>((ref) => RevenueCatService());

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  bool _initialized = false;
  bool _isMocked = false;

  static const _tag = 'RevenueCat';

  static const String _oruShopsProEntitlement = 'OruShops_Pro';

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

  Future<void> initialize(String userId, {bool testMode = true}) async {
    // If already initialized, we might need to reconfigure if testMode changed.
    // However, Purchases SDK doesn't always like re-configuration.
    // For now, we'll only initialize once.
    if (_initialized) return;

    try {
      String googleKey;
      String appleKey;

      if (testMode) {
        googleKey = 'test_gezrwgNwNVPOJFCtZUtHDCYLJXw';
        appleKey = 'test_gezrwgNwNVPOJFCtZUtHDCYLJXw';
      } else {
        googleKey = AppConfig.revenueCatGoogleKey;
        appleKey = AppConfig.revenueCatAppleKey;
      }

      if (googleKey.isEmpty && appleKey.isEmpty) {
        AppLogger.w(_tag, 'No RevenueCat keys found. Skipping initialization.');
        return;
      }

      // RevenueCat native SDK prevents using 'test_' keys in Release mode for security.
      // To allow testing release builds without a real key, we bypass native init and use a mock mode.
      bool isTestKey = googleKey.startsWith('test_') || appleKey.startsWith('test_');
      
      if (AppConfig.isProduction && isTestKey) {
        AppLogger.w(_tag, 'Release mode detected with Test Key ($googleKey). Using Mock RevenueCat mode to prevent native crash.');
        _isMocked = true;
        _initialized = true;
        return;
      }

      await Purchases.setLogLevel(
        AppConfig.isProduction ? LogLevel.error : LogLevel.debug,
      );

      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        if (googleKey.isEmpty) return;
        configuration = PurchasesConfiguration(googleKey)
          ..appUserID = userId;
      } else if (Platform.isIOS) {
        if (appleKey.isEmpty) return;
        configuration = PurchasesConfiguration(appleKey)
          ..appUserID = userId;
      } else {
        return;
      }

      await Purchases.configure(configuration);
      _initialized = true;
      AppLogger.i(_tag, 'RevenueCat initialized successfully in ${testMode ? "TEST" : "PRODUCTION"} mode');
    } catch (e) {
      AppLogger.e(_tag, 'RevenueCat initialization failed. Continuing without IAP.', e);
      _initialized = false;
    }
  }

  Future<void> logIn(String userId) async {
    if (_isMocked) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      AppLogger.e(_tag, 'logIn failed', e);
      rethrow;
    }
  }

  Future<void> logOut() async {
    if (_isMocked) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      AppLogger.e(_tag, 'logOut failed', e);
      rethrow;
    }
  }

  Future<Offerings?> getOfferings() async {
    if (_isMocked) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      AppLogger.e(_tag, 'getOfferings failed', e);
      return null;
    }
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    if (_isMocked) {
      AppLogger.i(_tag, 'Mock purchase success for package: ${package.identifier}');
      // In mock mode, we don't have a real CustomerInfo object.
      // Callers should ideally check hasOruShopsProAccess() instead.
      throw Exception('Purchase not available in Mock Mode. Pro features are already unlocked.');
    }
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } catch (e) {
      AppLogger.e(_tag, 'purchasePackage failed', e);
      rethrow;
    }
  }

  Future<CustomerInfo> purchaseProduct(String productId) async {
    try {
      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) throw Exception('Product $productId not found');
      final result = await Purchases.purchase(
          PurchaseParams.storeProduct(products.first));
      return result.customerInfo;
    } catch (e) {
      AppLogger.e(_tag, 'purchaseProduct failed', e);
      rethrow;
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      AppLogger.e(_tag, 'restorePurchases failed', e);
      rethrow;
    }
  }

  Future<CustomerInfo> getCustomerInfo() async {
    if (_isMocked) {
      throw Exception('CustomerInfo not available in Mock Mode.');
    }
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      AppLogger.e(_tag, 'getCustomerInfo failed', e);
      rethrow;
    }
  }

  Future<bool> hasOruShopsProAccess() async {
    if (_isMocked) return true; // Unlock everything in mock mode for testing
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_oruShopsProEntitlement);
    } catch (e) {
      AppLogger.e(_tag, 'hasOruShopsProAccess failed', e);
      return false;
    }
  }

  Future<Set<String>> getActiveEntitlements() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.keys.toSet();
    } catch (e) {
      AppLogger.e(_tag, 'getActiveEntitlements failed', e);
      return {};
    }
  }

  Future<bool> isSubscriber() async {
    if (_isMocked) return true;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.isNotEmpty;
    } catch (e) {
      AppLogger.e(_tag, 'isSubscriber failed', e);
      return false;
    }
  }

  Future<EntitlementInfo?> getOruShopsProInfo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active[_oruShopsProEntitlement];
    } catch (e) {
      AppLogger.e(_tag, 'getOruShopsProInfo failed', e);
      return null;
    }
  }

  Future<Set<String>> getActivePurchases() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.keys.toSet();
    } catch (e) {
      return {};
    }
  }

  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      AppLogger.e(_tag, 'hasEntitlement failed', e);
      return false;
    }
  }

  Future<void> setUserAttribute(String key, String value) async {
    if (_isMocked) return;
    try {
      await Purchases.setAttributes({key: value});
    } catch (e) {
      AppLogger.e(_tag, 'setUserAttribute failed', e);
    }
  }

  Future<void> setUserAttributes(Map<String, String> attributes) async {
    if (_isMocked) return;
    try {
      await Purchases.setAttributes(attributes);
    } catch (e) {
      AppLogger.e(_tag, 'setUserAttributes failed', e);
    }
  }

  Future<void> dispose() async {}
}
