import '../models/cart_item.dart';

class CartService {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
      (i) => i.productId == item.productId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
  }

  void updateItemQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
  }

  void updateBatchSelection(int productId, List<int> batchIds) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(selectedBatchIds: batchIds);
    }
  }

  void clear() {
    _items.clear();
  }

  CartItem? getItem(int productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasItem(int productId) {
    return _items.any((item) => item.productId == productId);
  }
}

