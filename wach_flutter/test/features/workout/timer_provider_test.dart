import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/workout/presentation/providers/timer_provider.dart';

/// Regressionstests fuer die am 2026-08-12 gemeldeten Timer-Fehler.
void main() {
  // Der Timer haengt sich per AppLifecycleListener an das WidgetsBinding,
  // damit er im Hintergrund aufhoert zu ticken. In der App uebernimmt das
  // `main()`, im Test muss die Binding von Hand hochgezogen werden.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  SessionTimer notifier() => container.read(sessionTimerProvider.notifier);
  TimerState state() => container.read(sessionTimerProvider);

  group('Zielzeit', () {
    test('setTarget setzt das Ziel', () {
      notifier().setTarget(const Duration(minutes: 30));
      expect(state().target, const Duration(minutes: 30));
    });

    test('clearTarget entfernt das Ziel wirklich (null, nicht 0)', () {
      notifier().setTarget(const Duration(minutes: 30));
      notifier().clearTarget();

      // Der Kern des Fehlers: frueher landete hier Duration.zero, was
      // ueberall als "Ziel gesetzt" durchging — die Anzeige blieb auf
      // "Target: 00:00" und isCountdownComplete war sofort true.
      expect(state().target, isNull);
      expect(state().isCountdownComplete, isFalse);
      expect(state().showRemaining, isFalse);
    });

    test('ein Ziel von 0 wuerde den Countdown sofort als fertig melden', () {
      // Dokumentiert, warum Duration.zero kein gueltiges Ziel sein darf.
      notifier().setTarget(Duration.zero);
      expect(state().isCountdownComplete, isTrue);
    });
  });

  group('Pause', () {
    test('resume zaehlt die Pausenzeit nicht mit', () async {
      notifier().startStopwatch();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      notifier().pause();

      final atPause = state().elapsed;
      expect(state().isRunning, isFalse);

      // Waehrend der Pause vergeht echte Zeit.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      notifier().resume();
      final afterResume = state().elapsed;

      // Frueher sprang elapsed hier um die volle Pausendauer nach vorn,
      // weil _startTime unveraendert blieb.
      expect(
        afterResume - atPause,
        lessThan(const Duration(milliseconds: 100)),
        reason: 'Pausenzeit darf nicht in die Laufzeit einfliessen',
      );
    });
  });

  group('restore', () {
    test('stellt Laufzeit und Ziel pausiert wieder her', () {
      notifier().restore(
        elapsed: const Duration(minutes: 12, seconds: 34),
        target: const Duration(minutes: 20),
      );

      expect(state().elapsed, const Duration(minutes: 12, seconds: 34));
      expect(state().target, const Duration(minutes: 20));
      expect(state().isRunning, isFalse);
      expect(state().isFinished, isFalse);
    });

    test('restore ohne Ziel laesst das Ziel leer', () {
      notifier().setTarget(const Duration(minutes: 5));
      notifier().restore(elapsed: const Duration(minutes: 1));
      expect(state().target, isNull);
    });
  });

  group('Hintergrund', () {
    /// Den Lifecycle-Wechsel ueber die Binding schicken, damit der
    /// AppLifecycleListener im Notifier ihn wie in der echten App bekommt.
    Future<void> lifecycle(AppLifecycleState target) async {
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(target);
      await Future<void>.delayed(Duration.zero);
    }

    // Eine einzige durchgehende Runde: die Binding merkt sich den
    // Lifecycle-Zustand global, und AppLifecycleListener laesst nur
    // gueltige Uebergaenge zu — zwei getrennte Tests wuerden sich
    // gegenseitig den Ausgangszustand verstellen.
    test('kein Tick im Hintergrund, Zeit stimmt nach der Rueckkehr', () async {
      notifier().startStopwatch();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // App wandert in den Hintergrund.
      await lifecycle(AppLifecycleState.inactive);
      await lifecycle(AppLifecycleState.hidden);
      await lifecycle(AppLifecycleState.paused);

      final atPause = state().elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Kern des Fehlers: frueher lief der 10-ms-Ticker im Hintergrund
      // weiter und stapelte Rebuilds, ohne dass ein Frame gezeichnet wurde
      // — nach der Rueckkehr reagierte die App sekundenlang nicht.
      expect(
        state().elapsed,
        atPause,
        reason: 'Im Hintergrund darf kein Tick den State anfassen',
      );

      // Und wieder zurueck.
      await lifecycle(AppLifecycleState.hidden);
      await lifecycle(AppLifecycleState.inactive);
      await lifecycle(AppLifecycleState.resumed);

      // Die Zeit im Hintergrund zaehlt trotzdem mit, weil elapsed aus der
      // Wall-Clock kommt — nur die Anzeige pausiert.
      expect(
        state().elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 190)),
        reason: 'Hintergrundzeit muss beim Zurueckkommen nachgezogen werden',
      );
      expect(state().isRunning, isTrue);
    });
  });
}
