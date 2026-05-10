class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  /// Supports fractional quantities for loose/bulk products (e.g. 0.5 kg, 250 g).
  final double quantity;
  final List<int> selectedBatchIds;
  /// Non-null when selling a size/color variant (variantMatrix template).
  final int? variantId;
  /// Display label for the variant, e.g. "M / Red". Empty for non-variant items.
  final String variantLabel;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.selectedBatchIds,
    this.variantId,
    this.variantLabel = '',
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'selectedBatchIds': selectedBatchIds.join(','),
      'variantId': variantId,
      'variantLabel': variantLabel,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      selectedBatchIds: (map['selectedBatchIds'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList(),
      variantId: map['variantId'] as int?,
      variantLabel: (map['variantLabel'] as String?) ?? '',
    );
  }

  CartItem copyWith({
    int? productId,
    String? productName,
    double? unitPrice,
    double? quantity,
    List<int>? selectedBatchIds,
    int? variantId,
    String? variantLabel,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      selectedBatchIds: selectedBatchIds ?? this.selectedBatchIds,
      variantId: variantId ?? this.variantId,
      variantLabel: variantLabel ?? this.variantLabel,
    );
  }
}

