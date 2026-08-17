import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// `Finder` heisst in sembast und in flutter_test dasselbe — hier ist
// immer der Widget-Finder gemeint.
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';
import 'package:wach_flutter/features/workout/presentation/screens/workout_screen.dart';

import '../../support/test_harness.dart';

/// Ein vollstaendiges Workout von vorne bis hinten: die vier
/// Standarduebungen aus dem leeren Zustand heraus auf ihr Ziel bringen.
///
/// Laeuft gegen die echten Repositories und Provider — nur die Datenbank
/// liegt im Speicher. Damit deckt der Test genau die Kette ab, in der die
/// gemeldeten Fehler sassen: Kachel -> Screen -> Provider -> Datenbank.
void main() {
  late Database db;

  /// Die Standarduebungen, die der Screen beim ersten Start anlegt.
  // Entsprechen `defaultCalisthenicsExercises`: Zielwerte fuer ein ganzes
  // Workout, nicht fuer einen Satz.
  const ziele = <String, int>{
    'Pull Ups': 50,
    'Dips': 50,
    'Push Ups': 100,
    'Squats': 100,
  };

  setUp(() async {
    db = await setUpTestDatabase('workout_flow');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  /// Den Workout-Screen aufbauen und warten, bis die Uebungen aus der
  /// Datenbank da sind.
  Future<void> pumpWorkout(WidgetTester tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapScreenForTest(const WorkoutScreen()));
    await settleAsync(tester);
  }

  /// Die Kachel einer bestimmten Uebung.
  Finder tileOf(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byType(ExerciseTile),
      );

  /// Eine Uebung von null auf [ziel] zaehlen — mit denselben Tasten, die
  /// auch ein Mensch druecken wuerde, also moeglichst wenige Griffe.
  Future<void> zaehleBisZiel(
    WidgetTester tester,
    String name,
    int ziel,
  ) async {
    await tester.tap(tileOf(name));
    await tester.pumpAndSettle();

    var offen = ziel;
    while (offen > 0) {
      final taste = offen >= 10
          ? '+10'
          : offen >= 5
              ? '+5'
              : '+1';
      await tester.tap(find.descendant(
        of: tileOf(name),
        matching: find.text(taste),
      ));
      await tester.pumpAndSettle();
      offen -= int.parse(taste.substring(1));
    }

    await tester.tap(find.descendant(
      of: tileOf(name),
      matching: find.byIcon(Icons.check_rounded),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('vier Standarduebungen aus dem leeren Zustand auf Ziel bringen',
      (tester) async {
    await pumpWorkout(tester);

    // Der Screen legt die Standarduebungen selbst an.
    expect(find.byType(ExerciseTile), findsNWidgets(4));
    for (final name in ziele.keys) {
      expect(tileOf(name), findsOneWidget, reason: '$name fehlt');
    }

    // Alle stehen auf null.
    expect(find.text('0'), findsNWidgets(4));

    for (final eintrag in ziele.entries) {
      await zaehleBisZiel(tester, eintrag.key, eintrag.value);
    }

    // Jede Uebung steht auf ihrem Ziel und traegt den Haken.
    for (final eintrag in ziele.entries) {
      expect(
        find.descendant(
          of: tileOf(eintrag.key),
          matching: find.text('${eintrag.value}'),
        ),
        findsOneWidget,
        reason: '${eintrag.key} steht nicht auf ${eintrag.value}',
      );
      expect(
        find.descendant(
          of: tileOf(eintrag.key),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
        reason: '${eintrag.key} ist nicht als geschafft markiert',
      );
    }

    // Keine Uebung steht mehr auf null.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('die Reps landen in der Datenbank und ueberleben den Screen',
      (tester) async {
    await pumpWorkout(tester);

    await zaehleBisZiel(tester, 'Pull Ups', 10);
    await zaehleBisZiel(tester, 'Dips', 10);

    // Screen verlassen (der Timer laeuft app-weit weiter) ...
    await tester.pumpWidget(wrapForTest(const SizedBox.shrink()));
    await settleAsync(tester);

    // ... und wieder betreten.
    await pumpWorkout(tester);

    expect(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('10')),
      findsOneWidget,
      reason: 'Reps duerfen beim Screenwechsel nicht verloren gehen',
    );
    expect(
      find.descendant(of: tileOf('Dips'), matching: find.text('10')),
      findsOneWidget,
    );
  });

  testWidgets('nur die angetippte Kachel klappt auf', (tester) async {
    await pumpWorkout(tester);

    await tester.tap(tileOf('Push Ups'));
    await tester.pumpAndSettle();

    // Genau ein Tastenfeld ist offen.
    expect(find.text('+10'), findsOneWidget);
    expect(
      find.descendant(of: tileOf('Push Ups'), matching: find.text('+10')),
      findsOneWidget,
    );
  });

  testWidgets('zwei Kacheln lassen sich unabhaengig bedienen', (tester) async {
    await pumpWorkout(tester);

    // Erste Kachel: 5 Reps, offen lassen.
    await tester.tap(tileOf('Pull Ups'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('+5')),
    );
    await tester.pumpAndSettle();

    // Zweite Kachel aufklappen, waehrend die erste noch offen ist.
    await tester.tap(tileOf('Squats'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tileOf('Squats'), matching: find.text('+10')),
    );
    await tester.pumpAndSettle();

    // Zurueck zur ersten Kachel — sie muss weiter reagieren.
    await tester.tap(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('+5')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: tileOf('Pull Ups'),
        matching: find.byIcon(Icons.check_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('10')),
      findsOneWidget,
    );
  });

  group('Kopfzeile ohne Sperrmodus', () {
    testWidgets('zeigt Zurueck und Plus, aber keinen Sperrhinweis',
        (tester) async {
      await pumpWorkout(tester);

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Reste des abgeschafften Sperrmodus.
      expect(find.text('GESPERRT'), findsNothing);
      expect(find.text('ENTSPERRT'), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byIcon(Icons.lock_open_rounded), findsNothing);
    });

    testWidgets('das Plus oeffnet die Uebungsauswahl', (tester) async {
      await pumpWorkout(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);

      expect(find.text('Übung hinzufügen'), findsWidgets);
      // Die Schnellauswahl ist mitgewandert und blendet bereits
      // angelegte Uebungen aus.
      expect(find.text('Pull Ups'), findsWidgets);
      expect(find.text('Chin Ups'), findsOneWidget);
    });

    testWidgets('die Zeitsteuerung ist ohne Umschalten erreichbar',
        (tester) async {
      await pumpWorkout(tester);

      // Frueher lag hinter dem Sperrmodus nur der Startknopf; Ziel und
      // Pause tauchten erst nach dem Entsperren auf.
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });
  });
}
