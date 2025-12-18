/// W.A.C.H. App Constants
abstract final class AppConstants {
  // App Info
  static const appName = 'W.A.C.H.';
  static const appFullName = 'Workout Awareness & Continuous Health';
  static const appVersion = '1.0.0';

  // UI Constants
  static const maxTilesPerPage = 5;
  static const longPressDelayMs = 500;
  static const minTouchTargetSize = 48.0;

  // Animation Durations
  static const defaultAnimationDuration = Duration(milliseconds: 300);
  static const quickAnimationDuration = Duration(milliseconds: 150);
  static const timerTickDuration = Duration(milliseconds: 10);

  // Timer
  static const timerPrecisionMs = 10; // 10ms precision for stopwatch
  static const defaultCountdownSeconds = 60;

  // Database
  static const dbName = 'wach_database.db';
  static const dbVersion = 1;

  // Spacing
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  // Border Radius
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
}
