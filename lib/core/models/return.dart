class Return {
  final int id;
  final int saleId;
  final double refundAmount;
  final String reason;
  final DateTime createdAt;

  Return({
    required this.id,
    required this.saleId,
    required this.refundAmount,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'refundAmount': refundAmount,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Return fromMap(Map<String, dynamic> map) {
    return Return(
      id: map['id'] as int,
      saleId: map['saleId'] as int,
      refundAmount: map['refundAmount'] as double,
      reason: map['reason'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Return copyWith({
    int? id,
    int? saleId,
    double? refundAmount,
    String? reason,
    DateTime? createdAt,
  }) {
    return Return(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      refundAmount: refundAmount ?? this.refundAmount,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

