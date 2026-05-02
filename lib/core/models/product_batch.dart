class ProductBatch {
  final int id;
  final int productId;
  final int quantity;
  final double costPrice;
  final DateTime expiryDate;
  final DateTime createdAt;

  ProductBatch({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.costPrice,
    required this.expiryDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'costPrice': costPrice,
      'expiryDate': expiryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductBatch.fromMap(Map<String, dynamic> map) {
    return ProductBatch(
      id: map['id'] as int,
      productId: map['productId'] as int,
      quantity: map['quantity'] as int,
      costPrice: (map['costPrice'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ProductBatch copyWith({
    int? id,
    int? productId,
    int? quantity,
    double? costPrice,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return ProductBatch(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

