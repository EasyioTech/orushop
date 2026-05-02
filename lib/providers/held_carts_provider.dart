import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/cart_item.dart';

class HeldCart {
  final String id;
  final List<CartItem> items;
  final DateTime createdAt;

  HeldCart({
    required this.id,
    required this.items,
    required this.createdAt,
  });
}

class HeldCartsNotifier extends StateNotifier<List<HeldCart>> {
  HeldCartsNotifier() : super([]);

  void holdCart(List<CartItem> items) {
    final cart = HeldCart(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(items),
      createdAt: DateTime.now(),
    );
    state = [...state, cart];
  }

  List<CartItem> recallCart(String cartId) {
    final cart = state.firstWhere((c) => c.id == cartId);
    state = state.where((c) => c.id != cartId).toList();
    return cart.items;
  }

  void removeCart(String cartId) {
    state = state.where((c) => c.id != cartId).toList();
  }
}

final heldCartsProvider = StateNotifierProvider<HeldCartsNotifier, List<HeldCart>>((ref) {
  return HeldCartsNotifier();
});

