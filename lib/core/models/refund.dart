class Refund {
  final int id;
  final int saleId;
  final double refundAmount;
  final String reason;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime? processedAt;

  Refund({
    required this.id,
    required this.saleId,
    required this.refundAmount,
    required this.reason,
    this.notes,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'refundAmount': refundAmount,
      'reason': reason,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory Refund.fromMap(Map<String, dynamic> map) {
    return Refund(
      id: map['id'] as int,
      saleId: map['saleId'] as int,
      refundAmount: (map['refundAmount'] as num).toDouble(),
      reason: map['reason'] as String,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      processedAt: map['processedAt'] != null ? DateTime.parse(map['processedAt'] as String) : null,
    );
  }

  Refund copyWith({
    int? id,
    int? saleId,
    double? refundAmount,
    String? reason,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return Refund(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      refundAmount: refundAmount ?? this.refundAmount,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

