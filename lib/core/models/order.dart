class Order {
  final int id;
  final String orderNumber;
  final String supplierName;
  final double totalAmount;
  final String status; // pending, received, cancelled
  final DateTime expectedDelivery;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final String? notes;

  Order({
    required this.id,
    required this.orderNumber,
    required this.supplierName,
    required this.totalAmount,
    required this.status,
    required this.expectedDelivery,
    required this.createdAt,
    this.receivedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'supplierName': supplierName,
      'totalAmount': totalAmount,
      'status': status,
      'expectedDelivery': expectedDelivery.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'receivedAt': receivedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      orderNumber: map['orderNumber'] as String,
      supplierName: map['supplierName'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      status: map['status'] as String,
      expectedDelivery: DateTime.parse(map['expectedDelivery'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      receivedAt: map['receivedAt'] != null ? DateTime.parse(map['receivedAt'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  Order copyWith({
    int? id,
    String? orderNumber,
    String? supplierName,
    double? totalAmount,
    String? status,
    DateTime? expectedDelivery,
    DateTime? createdAt,
    DateTime? receivedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      supplierName: supplierName ?? this.supplierName,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      notes: notes ?? this.notes,
    );
  }
}

