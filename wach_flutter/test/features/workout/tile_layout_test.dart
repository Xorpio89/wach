import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/core/constants/app_constants.dart';
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';
import 'package:wach_flutter/features/workout/presentation/screens/workout_screen.dart';

import '../../support/test_harness.dart';

/// Jede Uebung bekommt eine eigene Zeile in voller Breite.
///
/// Die frueher hier geprueften zwei Spalten sind entfallen: halbierte
/// Kacheln liessen der aufgeklappten Rueckseite zu wenig Platz. Passen
/// nicht alle Uebungen auf eine Seite, wird geblaettert.
void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('tile_layout');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

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

  /// Die Kacheln nach ihrer Lage von oben nach unten.
  List<Rect> kachelRahmen(WidgetTester tester) {
    final anzahl = find.byType(ExerciseTile).evaluate().length;
    return [
      for (var i = 0; i < anzahl; i++)
        tester.getRect(find.byType(ExerciseTile).at(i)),
    ]..sort((a, b) => a.top.compareTo(b.top));
  }

  testWidgets('vier Uebungen stehen untereinander in voller Breite',
      (tester) async {
    await pumpWorkout(tester);

    final rahmen = kachelRahmen(tester);
    expect(rahmen, hasLength(4));

    // Alle gleich breit und gleich weit links — also keine Spalten.
    for (final r in rahmen) {
      expect(r.left, closeTo(rahmen.first.left, 0.5));
      expect(r.width, closeTo(rahmen.first.width, 0.5));
    }
    // Und jede unter der vorherigen.
    for (var i = 1; i < rahmen.length; i++) {
      expect(rahmen[i].top, greaterThanOrEqualTo(rahmen[i - 1].bottom - 0.5));
    }
  });

  testWidgets('auch die fuenfte bleibt in voller Breite auf einer Seite',
      (tester) async {
    await pumpWorkout(tester);
    await legeAn(tester, 'Burpees');

    expect(find.byType(PageView), findsNothing);

    final rahmen = kachelRahmen(tester);
    expect(rahmen, hasLength(AppConstants.maxExercisesPerPage));
    for (final r in rahmen) {
      expect(
        r.width,
        closeTo(rahmen.first.width, 0.5),
        reason: 'keine Kachel darf schmaler sein als die anderen',
      );
    }
  });

  testWidgets('keine Kachel wird hoeher als die Obergrenze', (tester) async {
    await pumpWorkout(tester);

    for (final r in kachelRahmen(tester)) {
      expect(
        r.height,
        lessThanOrEqualTo(AppConstants.maxExerciseTileHeight + 0.5),
      );
    }
  });
}
