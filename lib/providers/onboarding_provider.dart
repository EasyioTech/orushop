import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_provider.dart';
import 'package:orushops/core/services/auth_service.dart';
import 'package:orushops/core/services/revenue_cat_service.dart';
import 'package:orushops/features/onboarding/models/shop_models.dart';
import 'package:orushops/core/repositories/owner_repository.dart';
import 'package:orushops/core/repositories/owner_provider.dart';


class OnboardingState {
  final String language;
  final String? role;
  final String? cashierCode;
  final String? plan;
  final ShopDetails? shopDetails;
  final bool isCompleted;

  OnboardingState({
    this.language = 'en',
    this.role,
    this.cashierCode,
    this.plan,
    this.shopDetails,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    String? language,
    Object? role = _sentinel,
    Object? cashierCode = _sentinel,
    Object? plan = _sentinel,
    Object? shopDetails = _sentinel,
    bool? isCompleted,
  }) {
    return OnboardingState(
      language: language ?? this.language,
      role: role == _sentinel ? this.role : role as String?,
      cashierCode: cashierCode == _sentinel ? this.cashierCode : cashierCode as String?,
      plan: plan == _sentinel ? this.plan : plan as String?,
      shopDetails: shopDetails == _sentinel ? this.shopDetails : shopDetails as ShopDetails?,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static const _sentinel = Object();
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SharedPreferences? _prefs;
  final AuthService _authService;
  final RevenueCatService _revenueCatService;
  final OwnerRepository _ownerRepository;

  OnboardingNotifier(
    this._prefs,
    this._authService,
    this._revenueCatService,
    this._ownerRepository,
  ) : super(OnboardingState()) {
    if (_prefs != null) _loadOnboarding();
  }

  User? get currentUser => _authService.currentUser;

  void _loadOnboarding() {
    if (_prefs == null) return;
    final isCompleted = _prefs.getBool('onboarding_completed') ?? false;
    final language = _prefs.getString('language') ?? 'en';
    if (isCompleted) {
      state = state.copyWith(isCompleted: true, language: language);
    } else {
      state = state.copyWith(language: language);
    }
  }

  Future<void> setLanguage(String language) async {
    if (_prefs != null) await _prefs.setString('language', language);
    state = state.copyWith(language: language);
  }

  void setRole(String role) {
    state = state.copyWith(role: role);
  }


  void setCashierCode(String value) {
    state = state.copyWith(cashierCode: value);
  }

  void setPlan(String value) {
    state = state.copyWith(plan: value);
  }

  void setShopDetails(ShopDetails details) {
    state = state.copyWith(shopDetails: details);
  }

  void updateShopDetails({
    String? shopName,
    String? ownerName,
    String? phoneNumber,
    String? shopAddress,
    String? gstNumber,
    ShopType? shopType,
    String? otherDetails,
  }) {
    if (state.shopDetails == null) {
      // If no details exist, we create a temporary one with default values for missing required fields
      // This is safe because the flow ensures all required fields are filled by the end.
      state = state.copyWith(
        shopDetails: ShopDetails(
          shopName: shopName ?? '',
          ownerName: ownerName ?? '',
          phoneNumber: phoneNumber ?? '',
          shopAddress: shopAddress ?? '',
          shopType: shopType ?? ShopType.other,
          gstNumber: gstNumber,
          otherDetails: otherDetails,
          productCategories: ShopTypeConfig.getConfig(shopType ?? ShopType.other).defaultCategories,
          features: ShopTypeConfig.getConfig(shopType ?? ShopType.other).features.copy(),
        ),
      );
    } else {
      final oldType = state.shopDetails!.shopType;
      final newType = shopType ?? oldType;
      
      // If shop type changed, we should reset features and categories to new type defaults
      ShopFeatures updatedFeatures = state.shopDetails!.features;
      List<String> updatedCategories = state.shopDetails!.productCategories;
      if (shopType != null && shopType != oldType) {
        final config = ShopTypeConfig.getConfig(shopType);
        updatedFeatures = config.features.copy();
        updatedCategories = config.defaultCategories;
      }

      state = state.copyWith(
        shopDetails: state.shopDetails!.copyWith(
          shopName: shopName,
          ownerName: ownerName,
          phoneNumber: phoneNumber,
          shopAddress: shopAddress,
          gstNumber: gstNumber,
          shopType: newType,
          otherDetails: otherDetails,
          features: updatedFeatures,
          productCategories: updatedCategories,
        ),
      );
    }
  }

  void updateShopCategories(List<String> categories) {
    if (state.shopDetails != null) {
      state = state.copyWith(
        shopDetails: state.shopDetails!.copyWith(productCategories: categories),
      );
    }
  }

  void updateShopFeatures(ShopFeatures features) {
    if (state.shopDetails != null) {
      state = state.copyWith(
        shopDetails: state.shopDetails!.copyWith(features: features),
      );
    }
  }

  Future<void> signInWithGoogle({bool complete = true}) async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          await _authService.updateDisplayName(user.displayName!);
        }
        await _handleRevenueCatLogin(user.uid);
        if (complete) {
          if (_prefs != null) await _prefs.setBool('onboarding_completed', true);
          state = state.copyWith(isCompleted: true);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithApple({bool complete = true}) async {
    try {
      final userCredential = await _authService.signInWithApple();
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          await _authService.updateDisplayName(user.displayName!);
        }
        await _handleRevenueCatLogin(user.uid);
        if (complete) {
          if (_prefs != null) await _prefs.setBool('onboarding_completed', true);
          state = state.copyWith(isCompleted: true);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleRevenueCatLogin(String uid) async {
    try {
      if (!_revenueCatService.isInitialized) {
        await _revenueCatService.initialize(uid);
      } else {
        await _revenueCatService.logIn(uid);
      }
    } catch (e) {
      debugPrint('RevenueCat login failed: $e');
      // We don't rethrow here to allow user to continue even if payment service fails
    }
  }

  Future<void> completeOnboarding() async {
    // Ensure the user is authenticated so they don't see the login screen again
    if (_authService.currentUser == null) {
      try {
        await _authService.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous sign-in failed during onboarding completion: $e');
      }
    }
    
    // Final check to ensure auth state has propagated
    int retry = 0;
    while (_authService.currentUser == null && retry < 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      retry++;
    }

    if (_prefs != null) {
      await _prefs.setBool('onboarding_completed', true);
      await _prefs.setString('language', state.language);
    }

    // Save Shop Details to Firestore
    if (state.shopDetails != null) {
      try {
        await _ownerRepository.saveShopDetails(state.shopDetails!.toMap());
      } catch (e) {
        debugPrint('Failed to save shop details to Firestore: $e');
      }
    }
    
    state = state.copyWith(isCompleted: true);
  }

  Future<void> resetOnboarding() async {
    if (_prefs != null) await _prefs.setBool('onboarding_completed', false);
    state = OnboardingState(language: state.language);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authService = ref.watch(authServiceProvider);
  final revenueCatService = RevenueCatService.instance;
  final ownerRepository = ref.watch(ownerRepositoryProvider);

  return OnboardingNotifier(prefs, authService, revenueCatService, ownerRepository);
});

