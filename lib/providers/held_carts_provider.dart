import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/cart_item.dart';

const _kHeldCartsKey = 'held_carts';

class HeldCart {
  final String id;
  final List<CartItem> items;
  final DateTime createdAt;

  HeldCart({
    required this.id,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory HeldCart.fromMap(Map<String, dynamic> map) => HeldCart(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        items: (map['items'] as List<dynamic>)
            .map((i) => CartItem.fromMap(Map<String, dynamic>.from(i as Map)))
            .toList(),
      );
}

class HeldCartsNotifier extends StateNotifier<List<HeldCart>> {
  HeldCartsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHeldCartsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => HeldCart.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = list;
    } catch (_) {
      await prefs.remove(_kHeldCartsKey);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHeldCartsKey,
      jsonEncode(state.map((c) => c.toMap()).toList()),
    );
  }

  Future<void> holdCart(List<CartItem> items) async {
    final cart = HeldCart(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(items),
      createdAt: DateTime.now(),
    );
    state = [...state, cart];
    await _save();
  }

  Future<List<CartItem>> recallCart(String cartId) async {
    final cart = state.firstWhere((c) => c.id == cartId);
    state = state.where((c) => c.id != cartId).toList();
    await _save();
    return cart.items;
  }

  Future<void> removeCart(String cartId) async {
    state = state.where((c) => c.id != cartId).toList();
    await _save();
  }
}

final heldCartsProvider =
    StateNotifierProvider<HeldCartsNotifier, List<HeldCart>>((ref) {
  return HeldCartsNotifier();
});
