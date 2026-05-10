class BackendException implements Exception {
  final String message;
  final String? code;

  BackendException(this.message, {this.code});

  @override
  String toString() => 'BackendException: $message ${code != null ? "($code)" : ""}';
}

class InsufficientStockException extends BackendException {
  InsufficientStockException(String productName, num required, num available)
      : super(
          'Insufficient stock for $productName. Required: $required, Available: $available',
          code: 'INSUFFICIENT_STOCK',
        );
}

class TransactionException extends BackendException {
  TransactionException(super.message) : super(code: 'TRANSACTION_FAILED');
}

class NetworkException extends BackendException {
  NetworkException([super.message = 'No internet connection. Please check your network.'])
      : super(code: 'NETWORK_ERROR');
}
