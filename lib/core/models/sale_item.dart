class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  /// Non-null when the sold item is a size/color variant.
  final int? variantId;
  /// Supports fractional quantities for loose/bulk products (e.g. 0.5 kg).
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final List<int> batchIds;
  /// Product name — populated from the products table at checkout time.
  final String? productName;
  /// HSN code for GST compliance — from the products table.
  final String? hsnCode;
  /// GST rate in percent (e.g. 18.0 for 18% GST). 0.0 means no GST.
  final double taxRate;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.batchIds,
    this.productName,
    this.hsnCode,
    this.taxRate = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'batchIds': batchIds.join(','),
      // productName, hsnCode, taxRate are not stored in the DB schema —
      // they are denormalised at checkout time for the receipt only.
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      variantId: map['variantId'] as int?,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      batchIds: (map['batchIds'] as String? ?? '').isEmpty
          ? []
          : (map['batchIds'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .map(int.parse)
              .toList(),
      productName: map['productName'] as String?,
      hsnCode: map['hsnCode'] as String?,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    int? variantId,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    List<int>? batchIds,
    String? productName,
    String? hsnCode,
    double? taxRate,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      batchIds: batchIds ?? this.batchIds,
      productName: productName ?? this.productName,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}
