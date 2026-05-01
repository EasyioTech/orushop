import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/cart_item.dart';
import '../core/models/sale.dart';
import '../core/models/sale_item.dart';
import '../core/repositories/sale_repository.dart';

class CheckoutNotifier extends StateNotifier<Map<String, dynamic>?> {
  final SaleRepository _saleRepository;

  CheckoutNotifier(this._saleRepository) : super(null);

  Future<Map<String, dynamic>?> saveSale({
    required List<CartItem> items,
    required int subtotal,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required Map<int, int> selectedBatches,
  }) async {
    try {
      state = {'loading': true};

      final sale = Sale(
        id: 0,
        totalAmount: subtotal.toDouble(),
        discountAmount: discountAmount.toDouble(),
        finalAmount: finalAmount.toDouble(),
        paymentMethod: paymentMethod,
        status: 'completed',
        createdAt: DateTime.now(),
      );

      final saleId = await _saleRepository.create(sale);
      final saleWithId = sale.copyWith(id: saleId);

      for (final item in items) {
        List<int> batchIds = <int>[];

        if (selectedBatches.containsKey(item.productId)) {
          batchIds = [selectedBatches[item.productId]!];
        } else {
          batchIds = await _saleRepository.deductFIFO(item.productId, item.quantity);
        }

        final saleItem = SaleItem(
          id: 0,
          saleId: saleId,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: item.unitPrice.toDouble(),
          totalPrice: (item.quantity * item.unitPrice).toDouble(),
          batchIds: batchIds,
        );
        await _saleRepository.addItem(saleItem);
      }

      final saleItems = await _saleRepository.getSaleItems(saleId);

      state = {
        'loading': false,
        'sale': saleWithId,
        'items': saleItems,
      };
      return state;
    } catch (e) {
      state = {'loading': false, 'error': e.toString()};
      return null;
    }
  }
}

final saleRepositoryProvider = Provider((ref) => SaleRepository());

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, Map<String, dynamic>?>(
  (ref) {
    final saleRepository = ref.watch(saleRepositoryProvider);
    return CheckoutNotifier(saleRepository);
  },
);
