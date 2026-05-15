class Customer {
  final int id;
  final String phone;
  final String name;
  final String? lastPurchaseDate;
  final double totalSpent;
  final int purchaseCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.phone,
    required this.name,
    this.lastPurchaseDate,
    this.totalSpent = 0,
    this.purchaseCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'lastPurchaseDate': lastPurchaseDate,
      'totalSpent': totalSpent,
      'purchaseCount': purchaseCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int,
      phone: map['phone'] as String,
      name: map['name'] as String,
      lastPurchaseDate: map['lastPurchaseDate'] as String?,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0,
      purchaseCount: map['purchaseCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? phone,
    String? name,
    String? lastPurchaseDate,
    double? totalSpent,
    int? purchaseCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      totalSpent: totalSpent ?? this.totalSpent,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
