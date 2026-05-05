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
import 'package:orushops/core/repositories/category_repository.dart';


class OnboardingException implements Exception {
  final String message;
  const OnboardingException(this.message);
  @override
  String toString() => message;
}

class OnboardingState {
  final String language;
  final String? role;
  final String? cashierCode;
  final String? plan;
  final ShopDetails? shopDetails;
  final bool isCompleted;
  /// Phone number entered during OTP auth (screen 7). Carried forward to Basic Details.
  final String? pendingPhone;

  OnboardingState({
    this.language = 'en',
    this.role,
    this.cashierCode,
    this.plan,
    this.shopDetails,
    this.isCompleted = false,
    this.pendingPhone,
  });

  OnboardingState copyWith({
    String? language,
    Object? role = _sentinel,
    Object? cashierCode = _sentinel,
    Object? plan = _sentinel,
    Object? shopDetails = _sentinel,
    bool? isCompleted,
    Object? pendingPhone = _sentinel,
  }) {
    return OnboardingState(
      language: language ?? this.language,
      role: role == _sentinel ? this.role : role as String?,
      cashierCode: cashierCode == _sentinel ? this.cashierCode : cashierCode as String?,
      plan: plan == _sentinel ? this.plan : plan as String?,
      shopDetails: shopDetails == _sentinel ? this.shopDetails : shopDetails as ShopDetails?,
      isCompleted: isCompleted ?? this.isCompleted,
      pendingPhone: pendingPhone == _sentinel ? this.pendingPhone : pendingPhone as String?,
    );
  }

  static const _sentinel = Object();
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SharedPreferences? _prefs;
  final AuthService _authService;
  final RevenueCatService _revenueCatService;
  final OwnerRepository _ownerRepository;
  final CategoryRepository _categoryRepository;

  OnboardingNotifier(
    this._prefs,
    this._authService,
    this._revenueCatService,
    this._ownerRepository,
    this._categoryRepository,
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

  void setPendingPhone(String phone) {
    state = state.copyWith(pendingPhone: phone);
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

  /// Completes onboarding. Throws [OnboardingException] on recoverable failures
  /// so the UI can surface them to the user.
  Future<void> completeOnboarding() async {
    // Phone OTP and social auth both sign in before reaching this point.
    // If somehow the user is still unauthenticated, fail explicitly — do NOT
    // silently create an anonymous account that will be unrecoverable after
    // app reinstall.
    if (_authService.currentUser == null) {
      throw OnboardingException(
        'Could not verify your account. Please go back and sign in again.',
      );
    }

    if (_prefs != null) {
      await _prefs.setBool('onboarding_completed', true);
      await _prefs.setString('language', state.language);
    }

    // Save shop details to Firestore — rethrow as OnboardingException so the
    // UI can show a retry prompt instead of silently losing data.
    if (state.shopDetails != null) {
      try {
        await _ownerRepository.saveShopDetails(state.shopDetails!.toMap());
      } catch (e) {
        debugPrint('Failed to save shop details to Firestore: $e');
        throw OnboardingException(
          'Could not save your shop details. Check your internet connection and try again.',
        );
      }

      // Seed categories into SQLite — also surfaces failure.
      try {
        await _categoryRepository.seedFromShopType(state.shopDetails!.shopType);
      } catch (e) {
        debugPrint('Failed to seed categories: $e');
        throw OnboardingException(
          'Could not set up your product categories. Please try again.',
        );
      }
    }

    state = state.copyWith(isCompleted: true);
  }

  Future<void> resetOnboarding() async {
    if (_prefs != null) await _prefs.setBool('onboarding_completed', false);
    state = OnboardingState(language: state.language);
  }

  /// Called by the phone OTP flow to send/resend OTP.
  /// Returns the verificationId for use in [verifyOtp].
  Future<String> sendOtp(String phone) async {
    return await _authService.sendOtp(phone);
  }

  /// Verifies the OTP and signs in. Returns true on success.
  Future<bool> verifyOtp(String verificationId, String otp) async {
    final credential = await _authService.verifyOtp(verificationId, otp);
    if (credential?.user != null) {
      await _handleRevenueCatLogin(credential!.user!.uid);
      return true;
    }
    return false;
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository());

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authService = ref.watch(authServiceProvider);
  final revenueCatService = RevenueCatService.instance;
  final ownerRepository = ref.watch(ownerRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);

  return OnboardingNotifier(prefs, authService, revenueCatService, ownerRepository, categoryRepository);
});

