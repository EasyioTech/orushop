class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final List<int> selectedBatchIds;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.selectedBatchIds,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'selectedBatchIds': selectedBatchIds.join(','),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      quantity: map['quantity'] as int,
      selectedBatchIds: (map['selectedBatchIds'] as String)
          .split(',')
          .map((id) => int.parse(id))
          .toList(),
    );
  }

  CartItem copyWith({
    int? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    List<int>? selectedBatchIds,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      selectedBatchIds: selectedBatchIds ?? this.selectedBatchIds,
    );
  }
}
