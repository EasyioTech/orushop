class ProductVariant {
  final int id;
  final int productId;
  final String size;
  final String color;
  final String sku;
  final double price;
  final double stock;
  final double? costPrice;
  final double? mrp;
  final String? barcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    required this.sku,
    required this.price,
    required this.stock,
    this.costPrice,
    this.mrp,
    this.barcode,
    required this.createdAt,
    required this.updatedAt,
  });

  String get label {
    if (size.isNotEmpty && color.isNotEmpty) return '$size / $color';
    if (size.isNotEmpty) return size;
    if (color.isNotEmpty) return color;
    return sku;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'productId': productId,
      'size': size,
      'color': color,
      'sku': sku,
      'price': price,
      'stock': stock,
      'costPrice': costPrice,
      'mrp': mrp,
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (id != 0) map['id'] = id;
    return map;
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as int,
      productId: map['productId'] as int,
      size: (map['size'] as String?) ?? '',
      color: (map['color'] as String?) ?? '',
      sku: map['sku'] as String,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as num? ?? 0).toDouble(),
      costPrice: map['costPrice'] != null ? (map['costPrice'] as num).toDouble() : null,
      mrp: map['mrp'] != null ? (map['mrp'] as num).toDouble() : null,
      barcode: map['barcode'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ProductVariant copyWith({
    int? id,
    int? productId,
    String? size,
    String? color,
    String? sku,
    double? price,
    double? stock,
    double? costPrice,
    double? mrp,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      size: size ?? this.size,
      color: color ?? this.color,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      costPrice: costPrice ?? this.costPrice,
      mrp: mrp ?? this.mrp,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
