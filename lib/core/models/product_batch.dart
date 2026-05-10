class ProductBatch {
  final int id;
  final int productId;
  final double quantity;
  final double costPrice;
  final String? batchNumber;
  final DateTime expiryDate;
  final DateTime createdAt;

  ProductBatch({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.costPrice,
    this.batchNumber,
    required this.expiryDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'costPrice': costPrice,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductBatch.fromMap(Map<String, dynamic> map) {
    return ProductBatch(
      id: map['id'] as int,
      productId: map['productId'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      batchNumber: map['batchNumber'] as String?,
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ProductBatch copyWith({
    int? id,
    int? productId,
    double? quantity,
    double? costPrice,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return ProductBatch(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

