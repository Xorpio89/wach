import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/core/constants/app_constants.dart';
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';
import 'package:wach_flutter/features/workout/presentation/screens/workout_screen.dart';

import '../../support/test_harness.dart';

/// Uebungen anlegen, aendern und loeschen — alles ueber die Oberflaeche,
/// so wie es ohne den frueheren Sperrmodus ablaufen muss.
void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('exercise_management');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Future<void> pumpWorkout(WidgetTester tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapScreenForTest(const WorkoutScreen()));
    await settleAsync(tester);
  }

  Finder tileOf(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byType(ExerciseTile),
      );

  /// Die Rueckseite aufklappen und dort den Muelleimer druecken.
  Future<void> loescheUeberKachel(
    WidgetTester tester,
    String name, {
    bool bestaetigen = true,
  }) async {
    await tester.tap(tileOf(name));
    await pumpFrames(tester);
    await tester.tap(
      find.descendant(
        of: tileOf(name),
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
    );
    await settleAsync(tester);
    await tester.tap(
      find.widgetWithText(TextButton, bestaetigen ? 'Löschen' : 'Abbrechen'),
    );
    await settleAsync(tester);
  }

  /// Die Rueckseite einer Kachel aufklappen und dort auf den Stift gehen.
  Future<void> oeffneBearbeiten(WidgetTester tester, String name) async {
    await tester.tap(tileOf(name));
    await pumpFrames(tester);
    await tester.tap(
      find.descendant(
        of: tileOf(name),
        matching: find.byIcon(Icons.edit_rounded),
      ),
    );
    await settleAsync(tester);
  }

  group('Anlegen', () {
    testWidgets('eine eigene Uebung ueber das Plus anlegen', (tester) async {
      await pumpWorkout(tester);
      expect(find.byType(ExerciseTile), findsNWidgets(4));

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);

      // Erstes Feld ist der Name, zweites das Ziel.
      final felder = find.byType(TextFormField);
      await tester.enterText(felder.at(0), 'Burpees');
      await tester.enterText(felder.at(1), '20');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'));
      await settleAsync(tester);

      // Ab der fuenften Uebung ruecken je zwei Kacheln nebeneinander —
      // alle bleiben sichtbar, ohne Blaettern.
      expect(find.byType(ExerciseTile), findsNWidgets(5));
      expect(tileOf('Burpees'), findsOneWidget);
    });

    testWidgets('die Schnellauswahl fuellt Name und Ziel vor', (tester) async {
      await pumpWorkout(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);

      await tester.tap(find.text('Chin Ups'));
      await settleAsync(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'));
      await settleAsync(tester);

      expect(tileOf('Chin Ups'), findsOneWidget);
      // Das Ziel aus der Schnellauswahl ist mitgekommen.
      expect(
        find.descendant(
            of: tileOf('Chin Ups'), matching: find.textContaining('/')),
        findsOneWidget,
      );
    });

    testWidgets('ohne Namen wird nichts angelegt', (tester) async {
      await pumpWorkout(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'));
      await settleAsync(tester);

      // Der Dialog bleibt offen und meldet das fehlende Pflichtfeld.
      expect(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'),
          findsOneWidget);
    });
  });

  group('Bearbeiten', () {
    testWidgets('eine Uebung umbenennen', (tester) async {
      await pumpWorkout(tester);
      await oeffneBearbeiten(tester, 'Squats');

      await tester.enterText(find.byType(TextFormField).first, 'Kniebeugen');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
      await settleAsync(tester);

      expect(tileOf('Kniebeugen'), findsOneWidget);
      expect(find.text('Squats'), findsNothing);
    });

    testWidgets('die Reps einer Uebung zuruecksetzen', (tester) async {
      await pumpWorkout(tester);

      // Erst zaehlen ...
      await tester.tap(tileOf('Dips'));
      await pumpFrames(tester);
      await tester.tap(
        find.descendant(of: tileOf('Dips'), matching: find.text('+5')),
      );
      await pumpFrames(tester);
      await tester.tap(
        find.descendant(
          of: tileOf('Dips'),
          matching: find.byIcon(Icons.check_rounded),
        ),
      );
      await pumpFrames(tester);

      expect(
        find.descendant(of: tileOf('Dips'), matching: find.text('5')),
        findsOneWidget,
      );

      // ... dann ueber das Bearbeiten-Fenster zuruecksetzen.
      await oeffneBearbeiten(tester, 'Dips');
      await tester.tap(find.textContaining('Reps zurücksetzen'));
      await settleAsync(tester);

      expect(
        find.descendant(of: tileOf('Dips'), matching: find.text('0')),
        findsOneWidget,
      );
    });
  });

  group('Loeschen', () {
    testWidgets(
        'eine offene Kachel faerbt nach dem Loeschen nicht auf die '
        'nachrueckende ab', (tester) async {
      await pumpWorkout(tester);

      // Zweite Kachel aufklappen und offen stehen lassen.
      await tester.tap(tileOf('Dips'));
      await pumpFrames(tester);
      expect(find.text('+10'), findsOneWidget);

      // Die erste Uebung loeschen — alles darunter rueckt eine Stelle auf.
      await loescheUeberKachel(tester, 'Pull Ups');

      // Ohne Schluessel haette die nachgerueckte Kachel den Zustand ihrer
      // Vorgaengerin geerbt und stuende offen da.
      expect(find.byType(ExerciseTile), findsNWidgets(3));
      expect(
        find.text('+10'),
        findsOneWidget,
        reason: 'Genau die angetippte Kachel darf offen sein',
      );
      expect(
        find.descendant(of: tileOf('Dips'), matching: find.text('+10')),
        findsOneWidget,
        reason: 'und zwar weiterhin Dips',
      );
    });

    testWidgets('eine Uebung loeschen, nachdem die Rueckfrage bejaht wurde',
        (tester) async {
      await pumpWorkout(tester);

      // Muelleimer sitzt auf der Rueckseite, direkt vor dem Stift.
      await tester.tap(tileOf('Push Ups'));
      await pumpFrames(tester);
      await tester.tap(
        find.descendant(
          of: tileOf('Push Ups'),
          matching: find.byIcon(Icons.delete_outline_rounded),
        ),
      );
      await settleAsync(tester);

      expect(find.text('Übung löschen?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await settleAsync(tester);

      expect(find.byType(ExerciseTile), findsNWidgets(3));
      expect(find.text('Push Ups'), findsNothing);
    });

    testWidgets('bei Abbruch bleibt die Uebung stehen', (tester) async {
      await pumpWorkout(tester);
      await loescheUeberKachel(tester, 'Push Ups', bestaetigen: false);

      expect(find.text('Push Ups'), findsWidgets);
      expect(find.byType(ExerciseTile), findsNWidgets(4));
    });
  });

  group('Hoehe der Kacheln', () {
    testWidgets('eine einzelne Kachel fuellt nicht den ganzen Bildschirm',
        (tester) async {
      await pumpWorkout(tester);

      // Bis auf eine Uebung alles loeschen.
      for (final name in ['Dips', 'Push Ups', 'Squats']) {
        await loescheUeberKachel(tester, name);
      }

      expect(find.byType(ExerciseTile), findsOneWidget);
      expect(
        tester.getRect(find.byType(ExerciseTile)).height,
        lessThanOrEqualTo(AppConstants.maxExerciseTileHeight),
        reason: 'Eine einzelne Kachel darf nicht ins Riesenhafte wachsen',
      );
    });

    testWidgets('vier Kacheln teilen sich den Platz weiterhin auf',
        (tester) async {
      await pumpWorkout(tester);

      final hoehen = tester
          .widgetList<ExerciseTile>(find.byType(ExerciseTile))
          .toList()
          .asMap()
          .keys
          .map((i) => tester.getRect(find.byType(ExerciseTile).at(i)).height)
          .toList();

      expect(hoehen, hasLength(4));
      // Alle gleich hoch und keine ueber der Obergrenze.
      for (final h in hoehen) {
        expect(h, closeTo(hoehen.first, 0.5));
        expect(h, lessThanOrEqualTo(AppConstants.maxExerciseTileHeight + 0.5));
      }
    });
  });

  group('Zielwerte im Hinzufuegen-Fenster', () {
    testWidgets('ein Vorschlag fuellt das Zielfeld', (tester) async {
      await pumpWorkout(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Burpees');
      await tester.tap(find.widgetWithText(ActionChip, '100'));
      await settleAsync(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'));
      await settleAsync(tester);

      expect(
        find.descendant(
          of: tileOf('Burpees'),
          matching: find.textContaining('100'),
        ),
        findsWidgets,
        reason: 'Das angetippte Ziel gehoert an die Uebung',
      );
    });

    testWidgets('alle drei Groessenordnungen stehen bereit', (tester) async {
      await pumpWorkout(tester);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);

      for (final ziel in AppConstants.zielVorschlaege) {
        expect(
          find.widgetWithText(ActionChip, '$ziel'),
          findsOneWidget,
          reason: 'Vorschlag $ziel fehlt',
        );
      }
    });
  });

  group('Vorschlaege im Hinzufuegen-Fenster', () {
    testWidgets('zeigt erst sechs und klappt auf Wunsch alle auf',
        (tester) async {
      await pumpWorkout(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);

      // Nur die Uebungsvorschlaege zaehlen — die Zielwerte darunter sind
      // ebenfalls Chips.
      Finder vorschlagsChips() => find.descendant(
            of: find.byType(Wrap).first,
            matching: find.byType(ActionChip),
          );

      final eingeklappt = vorschlagsChips().evaluate().length;
      expect(
        eingeklappt,
        lessThanOrEqualTo(AppConstants.quickPickCollapsedCount),
        reason: 'Eingeklappt hoechstens sechs Vorschlaege',
      );

      await tester.tap(find.textContaining('weitere anzeigen'));
      await settleAsync(tester);

      expect(
        vorschlagsChips().evaluate().length,
        greaterThan(eingeklappt),
        reason: 'Aufgeklappt muessen mehr Vorschlaege erscheinen',
      );

      // Und wieder zusammenklappen.
      await tester.tap(find.text('Weniger anzeigen'));
      await settleAsync(tester);

      expect(vorschlagsChips().evaluate().length, eingeklappt);
    });
  });

  group('Ab fuenf Uebungen', () {
    /// Eine zusaetzliche Uebung anlegen.
    Future<void> legeAn(WidgetTester tester, String name) async {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await settleAsync(tester);
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'));
      await settleAsync(tester);
    }

    testWidgets('jede Kachel behaelt die volle Breite', (tester) async {
      // Die frueher hier geprueften zwei Spalten sind entfallen: halbierte
      // Kacheln liessen der aufgeklappten Rueckseite zu wenig Platz.
      await pumpWorkout(tester);
      await legeAn(tester, 'Burpees');

      expect(find.byType(ExerciseTile), findsNWidgets(5));

      final erste = tester.getRect(find.byType(ExerciseTile).at(0));
      final zweite = tester.getRect(find.byType(ExerciseTile).at(1));

      expect(zweite.left, closeTo(erste.left, 0.5));
      expect(zweite.width, closeTo(erste.width, 0.5));
      expect(
        zweite.top,
        greaterThanOrEqualTo(erste.bottom - 0.5),
        reason: 'die zweite Kachel gehoert unter die erste, nicht daneben',
      );
    });

    testWidgets('auch die fuenfte Uebung laesst sich bedienen',
        (tester) async {
      await pumpWorkout(tester);
      await legeAn(tester, 'Burpees');

      await tester.tap(tileOf('Burpees'));
      await pumpFrames(tester);
      await tester.tap(
        find.descendant(of: tileOf('Burpees'), matching: find.text('+10')),
      );
      await pumpFrames(tester);

      expect(
        find.descendant(of: tileOf('Burpees'), matching: find.text('10')),
        findsOneWidget,
      );
    });
  });
}
