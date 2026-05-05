import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/services/revenue_cat_service.dart';

final paywallProvider = StateNotifierProvider<PaywallNotifier, PaywallState>((ref) {
  final service = ref.watch(revenueCatServiceProvider);
  return PaywallNotifier(service);
});

class PaywallState {
  final bool isLoading;
  final bool isPurchasing;
  final String? error;
  final bool purchaseSuccess;

  PaywallState({
    this.isLoading = false,
    this.isPurchasing = false,
    this.error,
    this.purchaseSuccess = false,
  });

  PaywallState copyWith({
    bool? isLoading,
    bool? isPurchasing,
    String? error,
    bool? purchaseSuccess,
  }) {
    return PaywallState(
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      error: error,
      purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
    );
  }
}

class PaywallNotifier extends StateNotifier<PaywallState> {
  final RevenueCatService _service;

  PaywallNotifier(this._service) : super(PaywallState());

  Future<bool> purchasePackage(Package package) async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      final result = await _service.purchasePackage(package);
      if (result.entitlements.active.isNotEmpty) {
        state = state.copyWith(isPurchasing: false, purchaseSuccess: true);
        return true;
      }
      state = state.copyWith(isPurchasing: false, error: 'Purchase failed');
      return false;
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
      return false;
    }
  }

  void resetState() {
    state = PaywallState();
  }
}
