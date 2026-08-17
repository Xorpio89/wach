import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/core/constants/app_constants.dart';
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';
import 'package:wach_flutter/features/workout/presentation/screens/workout_screen.dart';

import '../../support/test_harness.dart';

/// Blaettern ab der sechsten Uebung.
void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('paging');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Finder tileOf(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byType(ExerciseTile),
      );

  Future<void> pumpWorkout(WidgetTester tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapScreenForTest(const WorkoutScreen()));
    await settleAsync(tester);
  }

  Future<void> legeAn(WidgetTester tester, String name) async {
    await tester.tap(find.byIcon(Icons.add_rounded));
    await settleAsync(tester);
    await tester.enterText(find.byType(TextFormField).first, name);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Übung hinzufügen'));
    await settleAsync(tester);
  }

  /// Auf [gesamt] Uebungen auffuellen — vier gibt es beim Start schon.
  Future<void> fuelleAuf(WidgetTester tester, int gesamt) async {
    for (var i = 5; i <= gesamt; i++) {
      await legeAn(tester, 'Zusatz $i');
    }
  }

  Future<void> naechsteSeite(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await settleAsync(tester);
  }

  group('Wann geblaettert wird', () {
    testWidgets('fuenf Uebungen passen auf eine Seite', (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 5);

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(ExerciseTile), findsNWidgets(5));
    });

    testWidgets('ab der sechsten gibt es eine zweite Seite', (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 6);

      expect(find.byType(PageView), findsOneWidget);
      // Fuenf pro Seite, die sechste liegt dahinter.
      expect(
        find.byType(ExerciseTile),
        findsNWidgets(AppConstants.maxExercisesPerPage),
      );
      expect(tileOf('Zusatz 6'), findsNothing);
    });
  });

  group('Seite wechseln', () {
    testWidgets('durch Wischen', (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 6);

      await naechsteSeite(tester);

      expect(tileOf('Zusatz 6'), findsOneWidget);
    });

    testWidgets('durch Antippen des Pfeils', (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 6);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await settleAsync(tester);

      expect(tileOf('Zusatz 6'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await settleAsync(tester);

      expect(tileOf('Zusatz 6'), findsNothing);
    });
  });

  group('Aufgeklappte Kacheln ueberleben den Seitenwechsel', () {
    testWidgets('eine offene Kachel steht nach dem Zurueckblaettern noch offen',
        (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 6);

      // Auf Seite eins eine Kachel aufklappen.
      await tester.tap(tileOf('Pull Ups'));
      await pumpFrames(tester);
      expect(find.text('+10'), findsOneWidget);

      // Auf Seite zwei und zurueck.
      await naechsteSeite(tester);
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await settleAsync(tester);

      // Frueher lag der Zustand in der Kachel — beim Blaettern nimmt der
      // PageView sie aus dem Baum, und sie kam zugeklappt zurueck.
      expect(
        find.descendant(of: tileOf('Pull Ups'), matching: find.text('+10')),
        findsOneWidget,
        reason: 'Die Kachel muss weiterhin aufgeklappt sein',
      );
    });

    testWidgets('gezaehlte Reps bleiben ueber den Seitenwechsel erhalten',
        (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 6);

      await tester.tap(tileOf('Pull Ups'));
      await pumpFrames(tester);
      await tester.tap(
        find.descendant(of: tileOf('Pull Ups'), matching: find.text('+10')),
      );
      await pumpFrames(tester);

      await naechsteSeite(tester);
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await settleAsync(tester);

      expect(
        find.descendant(of: tileOf('Pull Ups'), matching: find.text('10')),
        findsOneWidget,
      );
    });

    testWidgets('eine Kachel auf Seite zwei bleibt beim Wechsel offen',
        (tester) async {
      await pumpWorkout(tester);
      await fuelleAuf(tester, 6);

      await naechsteSeite(tester);
      await tester.tap(tileOf('Zusatz 6'));
      await pumpFrames(tester);
      expect(find.text('+10'), findsOneWidget);

      // Nach vorne und wieder zurueck.
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await settleAsync(tester);
      await naechsteSeite(tester);

      expect(
        find.descendant(of: tileOf('Zusatz 6'), matching: find.text('+10')),
        findsOneWidget,
      );
    });
  });
}
