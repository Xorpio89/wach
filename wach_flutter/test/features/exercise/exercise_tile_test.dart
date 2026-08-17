import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/core/constants/app_constants.dart';
import 'package:wach_flutter/features/exercise/domain/entities/exercise.dart';
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';

import '../../support/test_harness.dart';

/// Regressionstests fuer die am 2026-08-15 gemeldeten Bedienfehler:
///
/// * "die klicks funktionieren nicht sauber"
/// * "die karte dreht sich nach zufaelliger zeit einfach zurueck"
/// * "nachdem sich die karte umdreht reagiert es teilweise nicht mehr auf
///   klicks/taps, bis man von locked -> unlocked modus wechselt"
///
/// Der letzte Punkt ist der eigentliche Fehler: der Tap-Handler wurde aus
/// dem Wert des Animations-Controllers abgeleitet, der das aeussere Widget
/// aber nicht neu baut. Nach dem Zurueckdrehen blieb `onTap` deshalb auf
/// `null` haengen, bis irgendein fremder Rebuild die Kachel rettete.
void main() {
  final exercise = Exercise(
    id: 'pull-ups',
    name: 'Pull Ups',
    targetReps: 10,
    createdAt: DateTime(2026, 1, 1),
  );

  /// Die Kachel so aufbauen, wie der Workout-Screen es tut: die Reps liegen
  /// aussen, die Kachel meldet nur Deltas. Genau dieses Hochreichen loeste
  /// den Rebuild aus, der den Fehler sichtbar machte.
  Future<_RepsHost> pumpTile(
    WidgetTester tester, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) async {
    final host = _RepsHost();

    await tester.pumpWidget(
      wrapForTest(
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 200,
              child: ExerciseTile(
                exercise: exercise,
                currentReps: host.reps,
                // Der Auf-/Zu-Zustand liegt ausserhalb der Kachel, damit er
                // einen Seitenwechsel uebersteht. Hier uebernimmt das der
                // Test, in der App der Provider.
                istOffen: host.istOffen,
                onToggle: () => setState(() => host.istOffen = !host.istOffen),
                onRepsDelta: (delta) => setState(() => host.reps += delta),
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            );
          },
        ),
      ),
    );

    return host;
  }

  /// Vorderseite erkennt man am grossen Zaehler, Rueckseite am Tastenfeld.
  bool keypadIsOpen() => find.text('+10').evaluate().isNotEmpty;

  group('Aufklappen', () {
    testWidgets('ein Tap dreht die Kachel auf das Tastenfeld', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      expect(keypadIsOpen(), isFalse, reason: 'startet auf der Vorderseite');

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      expect(keypadIsOpen(), isTrue);
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('der Haken klappt sie wieder zu', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();

      expect(keypadIsOpen(), isFalse);
    });
  });

  group('Kachel bleibt bedienbar', () {
    testWidgets(
        'nach Zaehlen, Zuklappen und erneutem Antippen geht sie wieder auf',
        (tester) async {
      final host = await pumpTile(tester);
      await tester.pumpAndSettle();

      // Runde 1: aufklappen, zaehlen, zuklappen.
      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();

      expect(host.reps, 5);
      expect(keypadIsOpen(), isFalse);

      // Runde 2: genau hier war die Kachel vorher tot. Das Zaehlen in
      // Runde 1 hat das aeussere Widget neu gebaut und `onTap` auf null
      // eingefroren; das Zuklappen baute es nicht wieder neu.
      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      expect(
        keypadIsOpen(),
        isTrue,
        reason: 'Kachel muss nach dem Zurueckdrehen wieder reagieren',
      );
    });

    testWidgets('haelt zehn Runden aus Zaehlen und Zuklappen durch',
        (tester) async {
      final host = await pumpTile(tester);
      await tester.pumpAndSettle();

      for (var runde = 1; runde <= 10; runde++) {
        await tester.tap(find.byType(ExerciseTile));
        await tester.pumpAndSettle();

        expect(
          keypadIsOpen(),
          isTrue,
          reason: 'Runde $runde: Kachel liess sich nicht mehr aufklappen',
        );

        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.check_rounded));
        await tester.pumpAndSettle();
      }

      expect(host.reps, 10);
    });
  });

  group('Zuklappen', () {
    testWidgets('ein Tipp auf freie Flaeche klappt zu', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();
      expect(keypadIsOpen(), isTrue);

      // Oben links auf der Rueckseite liegt keine Taste — nur Flaeche.
      final kachel = tester.getRect(find.byType(ExerciseTile));
      await tester.tapAt(Offset(kachel.left + 6, kachel.top + 6));
      await tester.pumpAndSettle();

      expect(keypadIsOpen(), isFalse);
    });

    testWidgets('ein Tipp auf eine Zaehltaste klappt nicht zu', (tester) async {
      final host = await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();

      expect(host.reps, 5);
      expect(
        keypadIsOpen(),
        isTrue,
        reason: 'Zaehlen darf die Kachel nicht zudrehen',
      );
    });
  });

  group('Kein Zuklappen von selbst', () {
    testWidgets('bleibt auch nach einer halben Minute offen', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();
      expect(keypadIsOpen(), isTrue);

      // Frueher lief hier ein Timer von sechs Sekunden, der die Kachel
      // ohne Zutun zurueckdrehte — aus Sicht der Bedienung "nach
      // zufaelliger Zeit".
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(
        keypadIsOpen(),
        isTrue,
        reason: 'Die Kachel darf sich nicht von selbst zurueckdrehen',
      );
    });
  });

  group('Zaehlen', () {
    testWidgets('die vier Tasten rechnen richtig', (tester) async {
      final host = await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(host.reps, 15);
    });

    testWidgets('minus eins bei null zaehlt nicht ins Minus', (tester) async {
      final host = await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(host.reps, 0);
    });

    testWidgets('das Tastenfeld bleibt beim Zaehlen offen', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();
        expect(
          keypadIsOpen(),
          isTrue,
          reason: 'Zaehlen darf die Kachel nicht zuklappen',
        );
      }
    });
  });

  group('Bearbeiten', () {
    testWidgets('der Stift sitzt auf der Rueckseite, nicht auf der Vorderseite',
        (tester) async {
      var editCalls = 0;
      await pumpTile(tester, onEdit: () => editCalls++);
      await tester.pumpAndSettle();

      // Vorderseite: reine Anzeige, kein Knopf neben dem Zaehler.
      expect(find.byIcon(Icons.edit_rounded), findsNothing);

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(editCalls, 1);
    });

    testWidgets('ohne Bearbeiten-Rueckruf erscheint auch kein Stift',
        (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('Groesse der Tasten', () {
    /// Gemessen wird die Schaltflaeche, nicht die Beschriftung — nur sie
    /// bestimmt, wo ein Tap ankommt.
    Finder tasteMitBeschriftung(String label) => find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );

    testWidgets('die Tasten nehmen hoechstens die halbe Kachel ein',
        (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      final kachel = tester.getRect(find.byType(ExerciseTile));
      for (final label in ['-1', '+1', '+5', '+10']) {
        expect(
          tester.getRect(tasteMitBeschriftung(label)).height,
          // Ein halbes Pixel Spielraum gegen Rundung in der Layoutrechnung.
          lessThanOrEqualTo(kachel.height / 2 + 0.5),
          reason: '"$label" ist hoeher als die halbe Kachel',
        );
      }
    });

    testWidgets('die Tasten bleiben gross genug zum Treffen', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExerciseTile));
      await tester.pumpAndSettle();

      // Die Kachel im Test ist 200 hoch; die Haelfte davon liegt deutlich
      // ueber dem Mindestmass fuer eine Schaltflaeche.
      for (final label in ['-1', '+1', '+5', '+10']) {
        expect(
          tester.getRect(tasteMitBeschriftung(label)).height,
          greaterThanOrEqualTo(AppConstants.minTouchTargetSize),
          reason: '"$label" ist zu klein zum sicheren Treffen',
        );
      }
    });
  });

  group('Trefferflaeche', () {
    testWidgets('ein Tap in die Ecke der Kachel zaehlt auch', (tester) async {
      await pumpTile(tester);
      await tester.pumpAndSettle();

      // Ohne `HitTestBehavior.opaque` lief ein Tap auf die Polsterung am
      // Rand ins Leere, weil der Treffer an das Kind weitergereicht wurde.
      final tile = tester.getRect(find.byType(ExerciseTile));
      await tester.tapAt(Offset(tile.left + 4, tile.top + 4));
      await tester.pumpAndSettle();

      expect(keypadIsOpen(), isTrue);
    });
  });
}

/// Haelt die Reps ausserhalb der Kachel, so wie es der Workout-Screen tut.
class _RepsHost {
  int reps = 0;
  bool istOffen = false;
}
