enum KhataEntryType { credit, debit }

class KhataEntry {
  final int id;
  final int customerId;
  final KhataEntryType type;
  final double amount;
  final String description;
  final int? linkedSaleId;
  final DateTime createdAt;

  const KhataEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.description,
    this.linkedSaleId,
    required this.createdAt,
  });

  bool get isCredit => type == KhataEntryType.credit;

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'type': type.name,
        'amount': amount,
        'description': description,
        'linkedSaleId': linkedSaleId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KhataEntry.fromMap(Map<String, dynamic> map) => KhataEntry(
        id: map['id'] as int,
        customerId: map['customerId'] as int,
        type: KhataEntryType.values.firstWhere((e) => e.name == map['type']),
        amount: (map['amount'] as num).toDouble(),
        description: map['description'] as String,
        linkedSaleId: map['linkedSaleId'] as int?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
