sealed class AppError {
  final String message;
  const AppError(this.message);

  @override
  String toString() => message;
}

final class NetworkError extends AppError {
  final int? statusCode;
  const NetworkError(super.message, {this.statusCode});
}

final class DbError extends AppError {
  final Object? cause;
  const DbError(super.message, {this.cause});
}

final class ValidationError extends AppError {
  final String field;
  const ValidationError(super.message, {required this.field});
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

final class PermissionError extends AppError {
  const PermissionError(super.message);
}
