import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'shared_prefs_provider.dart';

import '../core/models/cart_item.dart';
import '../core/services/cart_service.dart';

class CartStateNotifier extends Notifier<List<CartItem>> {
  CartService get _cartService => ref.read(cartServiceProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<CartItem> build() {
    Future.microtask(_loadCart);
    return [];
  }

  Future<void> _loadCart() async {
    final saved = _prefs.getString('cart_state');
    if (saved != null) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        state = decoded
            .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveCart() async {
    final encoded =
        jsonEncode(state.map((item) => item.toMap()).toList());
    await _prefs.setString('cart_state', encoded);
  }

  void addItem(CartItem item) {
    _cartService.addItem(item);
    state = [..._cartService.items];
    _saveCart();
  }

  void removeItem(int productId) {
    _cartService.removeItem(productId);
    state = [..._cartService.items];
    _saveCart();
  }

  void updateQuantity(int productId, double quantity) {
    _cartService.updateItemQuantity(productId, quantity);
    state = [..._cartService.items];
    _saveCart();
  }

  void updateBatchSelection(int productId, List<int> batchIds) {
    _cartService.updateBatchSelection(productId, batchIds);
    state = [..._cartService.items];
    _saveCart();
  }

  void clearCart() {
    _cartService.clear();
    state = [];
    _prefs.remove('cart_state');
  }
}

final cartServiceProvider = Provider((ref) => CartService());

// Centralized sharedPreferencesProvider is now in shared_prefs_provider.dart

final cartProvider = NotifierProvider<CartStateNotifier, List<CartItem>>(
  CartStateNotifier.new,
);

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalPrice);
});

final cartTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).length;
});

final cartTotalQuantityProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.quantity);
});

