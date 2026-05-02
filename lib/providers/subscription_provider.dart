import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:orushops/core/services/revenue_cat_service.dart';
import 'package:orushops/providers/auth_provider.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});

// Check if user has any active subscription
final subscriptionStatusProvider = FutureProvider<bool>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return false;
  }

  final rcService = ref.watch(revenueCatServiceProvider);

  if (!rcService.isInitialized) {
    return false;
  }

  try {
    return await rcService.isSubscriber();
  } catch (e) {
    return false;
  }
});

// Check if user has OruShops Pro access
final oruShopsProAccessProvider = FutureProvider<bool>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return false;
  }

  final rcService = ref.watch(revenueCatServiceProvider);

  if (!rcService.isInitialized) {
    return false;
  }

  try {
    return await rcService.hasOruShopsProAccess();
  } catch (e) {
    return false;
  }
});

// Get all offerings
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return null;
  }

  final rcService = ref.watch(revenueCatServiceProvider);

  if (!rcService.isInitialized) {
    return null;
  }

  try {
    return await rcService.getOfferings();
  } catch (e) {
    return null;
  }
});

// Get customer info
final customerInfoProvider = FutureProvider<CustomerInfo?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return null;
  }

  final rcService = ref.watch(revenueCatServiceProvider);

  if (!rcService.isInitialized) {
    return null;
  }

  try {
    return await rcService.getCustomerInfo();
  } catch (e) {
    return null;
  }
});

// Get OruShops Pro entitlement info
final oruShopsProInfoProvider = FutureProvider<EntitlementInfo?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return null;
  }

  final rcService = ref.watch(revenueCatServiceProvider);

  if (!rcService.isInitialized) {
    return null;
  }

  try {
    return await rcService.getOruShopsProInfo();
  } catch (e) {
    return null;
  }
});

// Get all active entitlements
final activeEntitlementsProvider = FutureProvider<Set<String>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return {};
  }

  final rcService = ref.watch(revenueCatServiceProvider);

  if (!rcService.isInitialized) {
    return {};
  }

  try {
    return await rcService.getActiveEntitlements();
  } catch (e) {
    return {};
  }
});
