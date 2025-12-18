import 'package:flutter/services.dart';

/// Haptic feedback utilities for touch interactions
abstract final class HapticUtils {
  /// Light tap feedback - for normal taps
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Medium tap feedback - for rep counting
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy tap feedback - for mode changes (lock/unlock)
  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for completing a set/goal
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate feedback - for timer end
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}
