class KhataPayment {
  final int id;
  final int customerId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;

  const KhataPayment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KhataPayment.fromMap(Map<String, dynamic> map) => KhataPayment(
        id: map['id'] as int,
        customerId: map['customerId'] as int,
        amount: (map['amount'] as num).toDouble(),
        paymentMethod: map['paymentMethod'] as String,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
