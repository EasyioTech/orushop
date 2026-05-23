import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/cart_item.dart';
import '../core/models/sale.dart';
import '../core/repositories/sale_repository.dart';
import '../core/exceptions/backend_exception.dart';
import '../core/models/khata_customer.dart';
import '../core/models/khata_entry.dart';
import 'khata_provider.dart';
import 'analytics_provider.dart';
import 'products_provider.dart';
import 'sale_provider.dart' show saleRepositoryProvider, customerRepositoryProvider;

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

class CheckoutNotifier extends Notifier<CheckoutState> {
  SaleRepository get _saleRepository => ref.read(saleRepositoryProvider);

  @override
  CheckoutState build() {
    return CheckoutState();
  }

  Future<Map<String, dynamic>?> saveSale({
    required List<CartItem> items,
    required double subtotal,
    required double discountAmount,
    required double finalAmount,
    required String paymentMethod,
    required Map<int, int> selectedBatches,
    String? customerPhone,
    String? customerName,
    double? amountPaid,
    String? receivedPaymentMode, // New: Cash or Other for partial payment
  }) async {
    try {
      debugPrint('Checkout: Starting saveSale');
      state = state.copyWith(isLoading: true, error: null);

      // Get or create customer if phone is provided
      final customerRepository = ref.read(customerRepositoryProvider);
      int? customerId;
      if (customerPhone != null && customerPhone.isNotEmpty) {
        final customer = await customerRepository.getOrCreateByPhone(
          customerPhone,
          customerName ?? 'Customer',
        );
        customerId = customer.id;
      }

      final sale = Sale(
        id: 0,
        totalAmount: subtotal.toDouble(),
        discountAmount: discountAmount.toDouble(),
        finalAmount: finalAmount.toDouble(),
        paymentMethod: paymentMethod,
        customerPhone: customerPhone,
        customerName: customerName,
        customerId: customerId,
        status: paymentMethod == 'Khata' ? 'pending' : 'completed',
        createdAt: DateTime.now(),
      );

      debugPrint('Checkout: Processing sale in repository');
      final result = await _saleRepository.processCompleteSale(
        sale: sale,
        items: items,
      );
      debugPrint('Checkout: Repository processing complete');

      // Update customer purchase stats after successful sale
      if (customerId != null) {
        await customerRepository.updateAfterSale(customerId, finalAmount);
      }

      // ── Khata Integration ──────────────────────────────────────────────────
      if (paymentMethod == 'Khata' && customerPhone != null) {
        final khataRepo = ref.read(khataRepositoryProvider);
        var customer = await khataRepo.getCustomerByPhone(customerPhone);
        
        int customerId;
        if (customer == null) {
          final now = DateTime.now();
          customerId = await khataRepo.addCustomer(KhataCustomer(
            id: 0,
            name: customerName ?? 'Customer',
            phone: customerPhone,
            createdAt: now,
            updatedAt: now,
          ));
        } else {
          customerId = customer.id;
          // Update name if we have a better one now
          if (customerName != null && (customer.name == 'Customer' || customer.name.isEmpty)) {
            await khataRepo.updateCustomer(customer.copyWith(name: customerName));
          }
        }

        final committedSale = result['sale'] as Sale;
        final totalAmount = finalAmount.toDouble();
        final receivedAmount = amountPaid ?? 0.0;
        
        // 1. Record the FULL amount as Credit (Sales entry)
        await khataRepo.addEntry(
          customerId: customerId,
          type: KhataEntryType.credit,
          amount: totalAmount,
          description: 'Bill #${committedSale.id}',
          linkedSaleId: committedSale.id,
        );

        // 2. Record the payment separately if received
        if (receivedAmount > 0) {
          await khataRepo.recordPayment(
            customerId: customerId,
            amount: receivedAmount,
            paymentMethod: receivedPaymentMode ?? 'Cash',
            notes: 'Payment for Bill #${committedSale.id}',
          );
        }
        
        // Refresh khata state
        ref.invalidate(khataListProvider);
      }

      // Build productId → quantitySold map from the committed sale items
      final soldItems = <int, double>{};
      for (final saleItem in (result['items'] as List)) {
        soldItems[saleItem.productId] =
            (soldItems[saleItem.productId] ?? 0.0) + (saleItem.quantity as double);
      }

      // Surgical in-place stock decrement — no full reload, no empty-screen flash
      ref.read(paginatedProductsProvider.notifier).decrementStock(soldItems);

      // Increment revision to trigger global refresh of all analytics-dependent providers
      debugPrint('Checkout: Syncing analytics revision...');
      ref.read(analyticsRevisionProvider.notifier).state++;

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

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);
