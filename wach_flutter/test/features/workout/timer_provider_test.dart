import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/workout/presentation/providers/timer_provider.dart';

/// Regressionstests fuer die am 2026-08-12 gemeldeten Timer-Fehler.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  TimerNotifier notifier() => container.read(timerProvider.notifier);
  TimerState state() => container.read(timerProvider);

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

    test('ein Ziel von 0 wuerde den Countdown sofort als fertig melden',
        () {
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
}
