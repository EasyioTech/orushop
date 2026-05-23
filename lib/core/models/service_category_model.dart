class ServiceCategoryModel {
  final int? id;
  final String name;
  final String? icon;
  final String? shopType;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;

  ServiceCategoryModel({
    this.id,
    required this.name,
    this.icon,
    this.shopType,
    this.isSystem = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'shopType': shopType,
      'isSystem': isSystem ? 1 : 0,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceCategoryModel.fromMap(Map<String, dynamic> map) {
    return ServiceCategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      shopType: map['shopType'] as String?,
      isSystem: (map['isSystem'] as int? ?? 0) == 1,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  ServiceCategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? shopType,
    bool? isSystem,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ServiceCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      shopType: shopType ?? this.shopType,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
