/// W.A.C.H. App Constants
abstract final class AppConstants {
  // App Info
  static const appName = 'W.A.C.H.';
  static const appFullName = 'Workout Awareness & Continuous Health';
  /// Version der laufenden App.
  ///
  /// Wird beim Bauen aus der Anzahl der Commits gebildet (siehe
  /// `tools/build.mjs`) und ueber `--dart-define` hereingereicht. Damit
  /// tickt sie von selbst hoch, ohne dass jemand eine Zahl pflegen muss —
  /// und ohne dass jeder Commit eine Datei aendert, nur um die Version
  /// anzuheben.
  ///
  /// Der Rueckfallwert kennzeichnet einen Lauf ohne diesen Schritt, etwa
  /// aus der Entwicklungsumgebung heraus.
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0-dev',
  );
  static const isBeta = true;

  // Feedback
  // TODO: Google-Form-Link (oder anderen Feedback-Link) hier eintragen.
  static const feedbackUrl = '';

  // UI Constants
  static const maxTilesPerPage = 5;
  static const longPressDelayMs = 500;
  static const minTouchTargetSize = 48.0;

  /// Wie hoch eine Uebungskachel hoechstens wird.
  ///
  /// Ohne Obergrenze teilen sich die Kacheln den Platz gleichmaessig auf —
  /// bei einer einzigen Uebung fuellt sie den ganzen Bildschirm, ohne dass
  /// mehr zu sehen waere. Reicht der Platz fuer alle nicht, wird weiterhin
  /// gleichmaessig verkleinert.
  static const maxExerciseTileHeight = 160.0;

  /// Wie viele Uebungen auf eine Seite passen.
  ///
  /// Jede bekommt eine eigene Zeile in voller Breite; ab der sechsten wird
  /// geblaettert. Mehr Kacheln uebereinander werden so flach, dass auf der
  /// aufgeklappten Rueckseite nichts mehr zu treffen ist.
  static const maxExercisesPerPage = 5;

  /// Wie viele Vorschlaege im Hinzufuegen-Fenster ohne Aufklappen
  /// erscheinen.
  static const quickPickCollapsedCount = 6;

  /// Zielwerte, die im Hinzufuegen-Fenster zum Antippen bereitstehen.
  ///
  /// Decken die ueblichen Groessenordnungen ab: ein kurzer Einstieg, ein
  /// normales Workout und ein forderndes Ziel.
  static const zielVorschlaege = [10, 50, 100];

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
