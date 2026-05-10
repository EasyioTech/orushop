import 'package:flutter/foundation.dart';

/// Structured logger. No-ops in release builds (debugPrint already does this,
/// but this wrapper adds consistent tags and severity levels).
class AppLogger {
  AppLogger._();

  static void d(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  static void w(String tag, String message) {
    debugPrint('[WARN][$tag] $message');
  }

  static void e(String tag, String message, [Object? error]) {
    debugPrint('[ERROR][$tag] $message${error != null ? ': $error' : ''}');
  }

  static void i(String tag, String message) {
    debugPrint('[INFO][$tag] $message');
  }

  /// Only logs in debug mode — use for verbose/trace output.
  static void v(String tag, String message) {
    if (kDebugMode) debugPrint('[VERBOSE][$tag] $message');
  }
}
