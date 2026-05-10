import 'package:flutter/foundation.dart';

/// Central app configuration. Prod keys are injected via --dart-define at build time:
///   flutter build apk --dart-define=RC_GOOGLE_KEY=appl_xxx --dart-define=RC_APPLE_KEY=appl_yyy
class AppConfig {
  AppConfig._();

  // RevenueCat keys — override at build time via --dart-define
  static const String revenueCatGoogleKey = String.fromEnvironment(
    'RC_GOOGLE_KEY',
    defaultValue: 'test_gezrwgNwNVPOJFCtZUtHDCYLJXw',
  );

  static const String revenueCatAppleKey = String.fromEnvironment(
    'RC_APPLE_KEY',
    defaultValue: 'test_gezrwgNwNVPOJFCtZUtHDCYLJXw',
  );

  /// True when running with real (non-test) RevenueCat keys.
  static bool get isRevenueCatProduction =>
      (revenueCatGoogleKey.isNotEmpty && !revenueCatGoogleKey.startsWith('test_')) ||
      (revenueCatAppleKey.isNotEmpty && !revenueCatAppleKey.startsWith('test_'));

  /// True in release builds.
  static bool get isProduction => kReleaseMode;
}
