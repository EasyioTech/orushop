import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'app_logger.g.dart';

/// Singleton talker instance — use directly in non-widget code.
final Talker appLogger = Talker(
  settings: TalkerSettings(
    maxHistoryItems: kDebugMode ? 500 : 50,
  ),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      enableColors: kDebugMode,
      level: kDebugMode ? LogLevel.verbose : LogLevel.warning,
    ),
  ),
);

/// Riverpod accessor for screens/widgets that need the logger.
@Riverpod(keepAlive: true)
// ignore: deprecated_member_use_from_same_package
Talker talker(TalkerRef ref) => appLogger;

/// Static-API wrapper — keeps existing call sites unchanged.
abstract final class AppLogger {
  static void d(String tag, String message) =>
      appLogger.debug('[$tag] $message');

  static void i(String tag, String message) =>
      appLogger.info('[$tag] $message');

  static void w(String tag, String message) =>
      appLogger.warning('[$tag] $message');

  static void e(String tag, String message, [Object? error]) =>
      appLogger.error('[$tag] $message', error);

  static void v(String tag, String message) {
    if (kDebugMode) appLogger.verbose('[$tag] $message');
  }
}
