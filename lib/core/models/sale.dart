class Sale {
  final int id;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod;
  final String? transactionId;
  final String? customerPhone;
  final String? customerName;
  final int? customerId;
  final String status;
  final DateTime createdAt;

  Sale({
    required this.id,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    this.transactionId,
    this.customerPhone,
    this.customerName,
    this.customerId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'customerId': customerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      discountAmount: (map['discountAmount'] as num).toDouble(),
      finalAmount: (map['finalAmount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      transactionId: map['transactionId'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerName: map['customerName'] as String?,
      customerId: map['customerId'] as int?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Sale copyWith({
    int? id,
    double? totalAmount,
    double? discountAmount,
    double? finalAmount,
    String? paymentMethod,
    String? transactionId,
    String? customerPhone,
    String? customerName,
    int? customerId,
    String? status,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      customerPhone: customerPhone ?? this.customerPhone,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

