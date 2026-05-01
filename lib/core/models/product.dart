class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int quantity;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? liveBatchQuantity;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.category,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.liveBatchQuantity,
  });

  int get displayQuantity => liveBatchQuantity ?? quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'quantity': quantity,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      sku: map['sku'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      category: map['category'] as String,
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      liveBatchQuantity: map['liveBatchQuantity'] as int?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    double? price,
    int? quantity,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? liveBatchQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      liveBatchQuantity: liveBatchQuantity ?? this.liveBatchQuantity,
    );
  }
}
