import 'dart:io';
import 'package:flutter/services.dart';

/// Platform-guarded HapticFeedback helpers.
/// Flutter's HapticFeedback is already a no-op on desktop, but this
/// makes the intent explicit and avoids any future platform-channel warnings.
abstract final class Haptic {
  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  static void light() {
    if (_supported) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_supported) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_supported) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (_supported) HapticFeedback.selectionClick();
  }

  static void vibrate() {
    if (_supported) HapticFeedback.vibrate();
  }
}
