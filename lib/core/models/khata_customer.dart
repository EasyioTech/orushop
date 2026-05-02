class KhataCustomer {
  final int id;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final double creditLimit;
  final double balance; // positive = customer owes us, negative = we owe customer
  final double totalCredit;
  final double totalDebit;
  final DateTime? lastTransactionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KhataCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    this.creditLimit = 0,
    this.balance = 0,
    this.totalCredit = 0,
    this.totalDebit = 0,
    this.lastTransactionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasOutstanding => balance > 0;
  bool get hasAdvance => balance < 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'creditLimit': creditLimit,
        'balance': balance,
        'totalCredit': totalCredit,
        'totalDebit': totalDebit,
        'lastTransactionAt': lastTransactionAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory KhataCustomer.fromMap(Map<String, dynamic> map) => KhataCustomer(
        id: map['id'] as int,
        name: map['name'] as String,
        phone: map['phone'] as String,
        address: map['address'] as String?,
        notes: map['notes'] as String?,
        creditLimit: (map['creditLimit'] as num).toDouble(),
        balance: (map['balance'] as num).toDouble(),
        totalCredit: (map['totalCredit'] as num).toDouble(),
        totalDebit: (map['totalDebit'] as num).toDouble(),
        lastTransactionAt: map['lastTransactionAt'] != null
            ? DateTime.parse(map['lastTransactionAt'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  KhataCustomer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? creditLimit,
    double? balance,
    double? totalCredit,
    double? totalDebit,
    DateTime? lastTransactionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      KhataCustomer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        creditLimit: creditLimit ?? this.creditLimit,
        balance: balance ?? this.balance,
        totalCredit: totalCredit ?? this.totalCredit,
        totalDebit: totalDebit ?? this.totalDebit,
        lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
