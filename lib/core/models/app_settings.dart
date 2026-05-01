class AppSettings {
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String currencySymbol;
  final bool enableDiscounts;
  final bool enableUpi;
  final double defaultDiscountPercent;
  final DateTime lastSyncTime;

  AppSettings({
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    required this.currencySymbol,
    required this.enableDiscounts,
    required this.enableUpi,
    required this.defaultDiscountPercent,
    required this.lastSyncTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storePhone': storePhone,
      'storeAddress': storeAddress,
      'currencySymbol': currencySymbol,
      'enableDiscounts': enableDiscounts ? 1 : 0,
      'enableUpi': enableUpi ? 1 : 0,
      'defaultDiscountPercent': defaultDiscountPercent,
      'lastSyncTime': lastSyncTime.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      storeName: map['storeName'] as String,
      storePhone: map['storePhone'] as String,
      storeAddress: map['storeAddress'] as String,
      currencySymbol: map['currencySymbol'] as String,
      enableDiscounts: (map['enableDiscounts'] as int) == 1,
      enableUpi: (map['enableUpi'] as int) == 1,
      defaultDiscountPercent: (map['defaultDiscountPercent'] as num).toDouble(),
      lastSyncTime: DateTime.parse(map['lastSyncTime'] as String),
    );
  }

  AppSettings copyWith({
    String? storeName,
    String? storePhone,
    String? storeAddress,
    String? currencySymbol,
    bool? enableDiscounts,
    bool? enableUpi,
    double? defaultDiscountPercent,
    DateTime? lastSyncTime,
  }) {
    return AppSettings(
      storeName: storeName ?? this.storeName,
      storePhone: storePhone ?? this.storePhone,
      storeAddress: storeAddress ?? this.storeAddress,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      enableDiscounts: enableDiscounts ?? this.enableDiscounts,
      enableUpi: enableUpi ?? this.enableUpi,
      defaultDiscountPercent:
          defaultDiscountPercent ?? this.defaultDiscountPercent,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
