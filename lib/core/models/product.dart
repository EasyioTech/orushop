class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final double quantity;
  final String category;
  final String? subcategory;
  final String unit;
  final double? mrp;
  final String? hsnCode;
  final double taxRate;
  final String? brand;
  final String? manufacturer;
  final String? serialNumber;
  final String? imei;
  final String? warranty;
  final String? schedule;
  final String? weight;
  final String? recipe;
  final String? isbn;
  final String? size;
  final String? color;
  final String? imageUrl;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? liveBatchQuantity;
  final String? expiryDate;
  final String? batchNumber;
  /// true = service/labor product; no stock deducted on sale.
  final bool isService;
  /// true = can be sold in fractional quantities (0.5 kg, 250 g, 1.5 m).
  final bool isLoose;
  /// Discounted sell price for bulk/wholesale customers (e.g. full bag rate).
  final double? wholesalePrice;
  /// Buying cost per unit — denormalised from batch for quick profit display.
  final double? costPrice;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.category,
    this.subcategory,
    this.unit = 'Piece',
    this.mrp,
    this.hsnCode,
    this.taxRate = 0.0,
    this.brand,
    this.manufacturer,
    this.serialNumber,
    this.imei,
    this.warranty,
    this.schedule,
    this.weight,
    this.recipe,
    this.isbn,
    this.size,
    this.color,
    this.imageUrl,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.liveBatchQuantity,
    this.expiryDate,
    this.batchNumber,
    this.isService = false,
    this.isLoose = false,
    this.wholesalePrice,
    this.costPrice,
  });

  double get displayQuantity => liveBatchQuantity ?? quantity;

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'sku': sku,
      'price': price,
      'quantity': quantity,
      'category': category,
      'subcategory': subcategory,
      'unit': unit,
      'mrp': mrp,
      'hsnCode': hsnCode,
      'taxRate': taxRate,
      'brand': brand,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'imei': imei,
      'warranty': warranty,
      'schedule': schedule,
      'weight': weight,
      'recipe': recipe,
      'isbn': isbn,
      'size': size,
      'color': color,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiryDate': expiryDate,
      'batchNumber': batchNumber,
      'isService': isService ? 1 : 0,
      'isLoose': isLoose ? 1 : 0,
      'wholesalePrice': wholesalePrice,
      'costPrice': costPrice,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      sku: map['sku'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      category: map['category'] as String,
      subcategory: map['subcategory'] as String?,
      unit: (map['unit'] as String?) ?? 'Piece',
      mrp: map['mrp'] != null ? (map['mrp'] as num).toDouble() : null,
      hsnCode: map['hsnCode'] as String?,
      taxRate: map['taxRate'] != null ? (map['taxRate'] as num).toDouble() : 0.0,
      brand: map['brand'] as String?,
      manufacturer: map['manufacturer'] as String?,
      serialNumber: map['serialNumber'] as String?,
      imei: map['imei'] as String?,
      warranty: map['warranty'] as String?,
      schedule: map['schedule'] as String?,
      weight: map['weight'] as String?,
      recipe: map['recipe'] as String?,
      isbn: map['isbn'] as String?,
      size: map['size'] as String?,
      color: map['color'] as String?,
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      liveBatchQuantity: map['liveBatchQuantity'] != null ? (map['liveBatchQuantity'] as num).toDouble() : null,
      expiryDate: map['expiryDate'] as String?,
      batchNumber: map['batchNumber'] as String?,
      isService: (map['isService'] as int? ?? 0) == 1,
      isLoose: (map['isLoose'] as int? ?? 0) == 1,
      wholesalePrice: map['wholesalePrice'] != null ? (map['wholesalePrice'] as num).toDouble() : null,
      costPrice: map['costPrice'] != null ? (map['costPrice'] as num).toDouble() : null,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    double? price,
    double? quantity,
    String? category,
    String? subcategory,
    String? unit,
    double? mrp,
    String? hsnCode,
    double? taxRate,
    String? brand,
    String? manufacturer,
    String? serialNumber,
    String? imei,
    String? warranty,
    String? schedule,
    String? weight,
    String? recipe,
    String? isbn,
    String? size,
    String? color,
    String? imageUrl,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? liveBatchQuantity,
    String? expiryDate,
    String? batchNumber,
    bool? isService,
    bool? isLoose,
    double? wholesalePrice,
    double? costPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      unit: unit ?? this.unit,
      mrp: mrp ?? this.mrp,
      hsnCode: hsnCode ?? this.hsnCode,
      taxRate: taxRate ?? this.taxRate,
      brand: brand ?? this.brand,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      imei: imei ?? this.imei,
      warranty: warranty ?? this.warranty,
      schedule: schedule ?? this.schedule,
      weight: weight ?? this.weight,
      recipe: recipe ?? this.recipe,
      isbn: isbn ?? this.isbn,
      size: size ?? this.size,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      liveBatchQuantity: liveBatchQuantity ?? this.liveBatchQuantity,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      isService: isService ?? this.isService,
      isLoose: isLoose ?? this.isLoose,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      costPrice: costPrice ?? this.costPrice,
    );
  }
}

