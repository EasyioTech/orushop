class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<int> batchIds;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.batchIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'batchIds': batchIds.join(','),
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      batchIds: (map['batchIds'] as String).isEmpty
          ? []
          : (map['batchIds'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((id) => int.parse(id))
              .toList(),
    );
  }

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<int>? batchIds,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      batchIds: batchIds ?? this.batchIds,
    );
  }
}

