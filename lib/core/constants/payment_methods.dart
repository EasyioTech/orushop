class PaymentMethods {
  static const String cash = 'cash';
  static const String card = 'card';
  static const String upi = 'upi';
  static const String online = 'online';

  static const List<String> all = [cash, card, upi, online];

  static String displayName(String method) {
    return switch (method) {
      cash => 'Cash',
      card => 'Card',
      upi => 'UPI',
      online => 'Online',
      _ => method,
    };
  }
}

class SaleStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [pending, completed, cancelled];
}

