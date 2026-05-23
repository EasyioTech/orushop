class StaffMember {
  final int? id;
  final String name;
  final String? role;
  final String? phone;
  final String? photoPath;
  final double hourlyRate;
  final double commissionPct;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffMember({
    this.id,
    required this.name,
    this.role,
    this.phone,
    this.photoPath,
    this.hourlyRate = 0.0,
    this.commissionPct = 0.0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'photoPath': photoPath,
      'hourlyRate': hourlyRate,
      'commissionPct': commissionPct,
      'isActive': isActive ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      id: map['id'] as int?,
      name: map['name'] as String,
      role: map['role'] as String?,
      phone: map['phone'] as String?,
      photoPath: map['photoPath'] as String?,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      commissionPct: (map['commissionPct'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  StaffMember copyWith({
    int? id,
    String? name,
    String? role,
    String? phone,
    String? photoPath,
    double? hourlyRate,
    double? commissionPct,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      commissionPct: commissionPct ?? this.commissionPct,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
