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

  static const _tag = 'RevenueCat';

  static String get _googleApiKey => AppConfig.revenueCatGoogleKey;
  static String get _appleApiKey => AppConfig.revenueCatAppleKey;

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

  Future<void> initialize(String userId) async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(
        AppConfig.isProduction ? LogLevel.error : LogLevel.debug,
      );

      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey)
          ..appUserID = userId;
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey)
          ..appUserID = userId;
      } else {
        return;
      }

      await Purchases.configure(configuration);
      _initialized = true;
    } catch (e) {
      AppLogger.e(_tag, 'initialize failed', e);
      rethrow;
    }
  }

  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      AppLogger.e(_tag, 'logIn failed', e);
      rethrow;
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      AppLogger.e(_tag, 'logOut failed', e);
      rethrow;
    }
  }

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      AppLogger.e(_tag, 'getOfferings failed', e);
      return null;
    }
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
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
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      AppLogger.e(_tag, 'getCustomerInfo failed', e);
      rethrow;
    }
  }

  Future<bool> hasOruShopsProAccess() async {
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
    try {
      await Purchases.setAttributes({key: value});
    } catch (e) {
      AppLogger.e(_tag, 'setUserAttribute failed', e);
    }
  }

  Future<void> setUserAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
    } catch (e) {
      AppLogger.e(_tag, 'setUserAttributes failed', e);
    }
  }

  Future<void> dispose() async {}
}
