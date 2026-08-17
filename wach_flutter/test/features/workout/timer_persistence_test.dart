import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/features/workout/presentation/providers/timer_provider.dart';

import '../../support/test_harness.dart';

/// Die Uhr muss einen Neustart der App ueberstehen.
///
/// Hintergrund: die App laeuft als installierte Web-App auf dem Handy.
/// Wird sie in den Hintergrund geschoben, kann das Betriebssystem die
/// Seite entladen und beim Zurueckkehren neu laden. Die Reps kamen dabei
/// schon immer aus der Datenbank zurueck — die gelaufene Zeit stand
/// hinterher wieder auf null und die Session war praktisch verloren.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('timer_persistence');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  /// Einen kompletten Neustart nachstellen: neuer Container, gleiche
  /// Datenbank. Genau das passiert, wenn die Web-App neu geladen wird.
  Future<ProviderContainer> neustart() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Der Provider laedt beim Erzeugen asynchron nach.
    container.read(sessionTimerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return container;
  }

  test('eine laufende Uhr zaehlt ueber den Neustart hinweg weiter', () async {
    final erste = ProviderContainer();
    erste.read(sessionTimerProvider.notifier).startStopwatch();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final vorher = erste.read(sessionTimerProvider).elapsed;
    erste.dispose();

    final zweite = await neustart();
    final nachher = zweite.read(sessionTimerProvider);

    expect(
      nachher.isRunning,
      isTrue,
      reason: 'Eine laufende Session laeuft nach dem Neustart weiter',
    );
    expect(
      nachher.elapsed,
      greaterThanOrEqualTo(vorher),
      reason: 'Die Zeit darf durch den Neustart nicht zurueckfallen',
    );
  });

  test('eine pausierte Uhr kommt mit ihrem Stand zurueck', () async {
    final erste = ProviderContainer();
    erste.read(sessionTimerProvider.notifier).startStopwatch();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    erste.read(sessionTimerProvider.notifier).pause();
    final beiPause = erste.read(sessionTimerProvider).elapsed;
    // Das Sichern laeuft asynchron. Ohne diese kurze Pause wird der
    // Container verworfen, bevor der pausierte Stand in der Datenbank
    // steht — zurueck kaeme dann der Stand vom Start.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    erste.dispose();

    // Waehrend die App weg ist, vergeht Zeit — bei einer Pause darf sie
    // nicht mitzaehlen.
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final zweite = await neustart();
    final nachher = zweite.read(sessionTimerProvider);

    expect(nachher.isRunning, isFalse);
    // Gespeichert werden ganze Millisekunden, die Mikrosekunden fallen
    // dabei weg — verglichen wird deshalb auf Millisekunden genau.
    expect(
      (nachher.elapsed - beiPause).abs(),
      lessThan(const Duration(milliseconds: 2)),
      reason: 'Der Stand zum Zeitpunkt der Pause gehoert zurueck',
    );
    expect(
      nachher.elapsed,
      lessThan(beiPause + const Duration(milliseconds: 100)),
      reason: 'Die 150 ms Pause duerfen nicht mitgezaehlt werden',
    );
  });

  test('die Zielzeit kommt mit zurueck', () async {
    final erste = ProviderContainer();
    erste.read(sessionTimerProvider.notifier).startStopwatch();
    erste.read(sessionTimerProvider.notifier).setTarget(const Duration(minutes: 20));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    erste.dispose();

    final zweite = await neustart();

    expect(zweite.read(sessionTimerProvider).target, const Duration(minutes: 20));
  });

  test('ein beendeter Lauf wird nicht wieder aufgeschlagen', () async {
    final erste = ProviderContainer();
    erste.read(sessionTimerProvider.notifier).startStopwatch();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // `reset` ist das, was beim Beenden einer Session passiert.
    erste.read(sessionTimerProvider.notifier).reset();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    erste.dispose();

    final zweite = await neustart();
    final nachher = zweite.read(sessionTimerProvider);

    expect(nachher.elapsed, Duration.zero);
    expect(nachher.isRunning, isFalse);
  });

  test('ein uralter Lauf wird verworfen statt aufgenommen', () async {
    // Direkt in die Datenbank schreiben: ein Lauf, der vor zwei Tagen
    // gestartet wurde. So etwas ist vergessen worden, nicht pausiert —
    // wieder aufgenommen stuende dort eine sinnlose Laufzeit.
    final vorZweiTagen = DateTime.now().subtract(const Duration(days: 2));
    await setUpTestDatabaseRecord(db, {
      'startedAtMillis': vorZweiTagen.millisecondsSinceEpoch,
      'elapsedMillis': const Duration(days: 2).inMilliseconds,
      'targetMillis': null,
      'isRunning': true,
    });

    final container = await neustart();
    final nachher = container.read(sessionTimerProvider);

    expect(nachher.elapsed, Duration.zero);
    expect(nachher.isRunning, isFalse);
  });
}
