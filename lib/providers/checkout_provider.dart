import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/cart_item.dart';
import '../core/models/sale.dart';
import '../core/repositories/sale_repository.dart';
import '../core/exceptions/backend_exception.dart';

import 'package:orushops/providers/products_provider.dart';
import 'package:orushops/providers/sale_provider.dart' show saleRepositoryProvider;

class CheckoutState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  CheckoutState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? result,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final SaleRepository _saleRepository;
  final Ref _ref;

  CheckoutNotifier(this._saleRepository, this._ref) : super(CheckoutState());

  Future<Map<String, dynamic>?> saveSale({
    required List<CartItem> items,
    required int subtotal,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required Map<int, int> selectedBatches,
  }) async {
    try {
      debugPrint('Checkout: Starting saveSale');
      state = state.copyWith(isLoading: true, error: null);

      final sale = Sale(
        id: 0,
        totalAmount: subtotal.toDouble(),
        discountAmount: discountAmount.toDouble(),
        finalAmount: finalAmount.toDouble(),
        paymentMethod: paymentMethod,
        status: 'completed',
        createdAt: DateTime.now(),
      );

      debugPrint('Checkout: Processing sale in repository');
      final result = await _saleRepository.processCompleteSale(
        sale: sale,
        items: items,
      );
      debugPrint('Checkout: Repository processing complete');

      // Build productId → quantitySold map from the committed sale items
      final soldItems = <int, int>{};
      for (final saleItem in (result['items'] as List)) {
        soldItems[saleItem.productId] =
            (soldItems[saleItem.productId] ?? 0) + (saleItem.quantity as int);
      }

      // Surgical in-place stock decrement — no full reload, no empty-screen flash
      _ref.read(paginatedProductsProvider.notifier).decrementStock(soldItems);

      final checkoutResult = {
        'sale': result['sale'],
        'items': result['items'],
      };

      state = state.copyWith(
        isLoading: false,
        result: checkoutResult,
      );
      
      return checkoutResult;
    } on InsufficientStockException catch (e) {
      debugPrint('Insufficient stock: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } on TransactionException catch (e) {
      debugPrint('Transaction failed: ${e.message}');
      state = state.copyWith(isLoading: false, error: 'Payment recorded, but inventory update failed. Please check stock manually.');
      return null;
    } catch (e) {
      debugPrint('Checkout error caught in notifier: $e');
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred: ${e.toString()}');
      return null;
    }
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    final saleRepository = ref.watch(saleRepositoryProvider);
    return CheckoutNotifier(saleRepository, ref);
  },
);
