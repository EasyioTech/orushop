class StockReasons {
  static const String purchase = 'purchase';
  static const String sale = 'sale';
  static const String adjustment = 'adjustment';
  static const String damage = 'damage';
  static const String expiry = 'expiry';
  static const String return_ = 'return';

  static const List<String> all = [purchase, sale, adjustment, damage, expiry, return_];

  static String displayName(String reason) {
    return switch (reason) {
      purchase => 'Purchase',
      sale => 'Sale',
      adjustment => 'Adjustment',
      damage => 'Damage',
      expiry => 'Expiry',
      return_ => 'Return',
      _ => reason,
    };
  }
}
