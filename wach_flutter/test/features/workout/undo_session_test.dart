import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/core/database/database_service.dart';
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';
import 'package:wach_flutter/features/workout/data/datasources/session_local_datasource.dart';
import 'package:wach_flutter/features/workout/data/models/session_model.dart';

import '../../support/test_harness.dart';

/// Das "Rueckgaengig" in der Meldung nach dem Beenden.
///
/// Es ist das einzige Netz gegen ein versehentlich beendetes Workout —
/// wenn es nicht traegt, ist die Session weg.
void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('undo_session');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Finder tileOf(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byType(ExerciseTile),
      );

  Future<List<SessionModel>> gespeicherteSessions(WidgetTester tester) async {
    final sessions = await tester.runAsync(
      () => SessionLocalDataSource(DatabaseService()).getAll(),
    );
    return sessions ?? const [];
  }

  /// Ein kurzes Workout fahren und beenden.
  Future<void> workoutBeenden(WidgetTester tester) async {
    await tester.tap(find.text('Workout starten'));
    await settleAsync(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await passRealTime(tester);

    await tester.tap(tileOf('Pull Ups'));
    await pumpFrames(tester);
    await tester.tap(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('+10')),
    );
    await pumpFrames(tester);
    await tester.tap(
      find.descendant(
        of: tileOf('Pull Ups'),
        matching: find.byIcon(Icons.check_rounded),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await pumpFrames(tester);
    await tester.tap(find.text('Workout beenden'));
    await settleAsync(tester);
  }

  testWidgets('Rueckgaengig holt die Session zurueck', (tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapAppForTest());
    await settleAsync(tester);

    await workoutBeenden(tester);

    // Die Session ist gespeichert und die Meldung steht.
    expect(await gespeicherteSessions(tester), hasLength(1));
    expect(find.text('Rückgängig'), findsOneWidget);

    await tester.tap(find.text('Rückgängig'));
    await settleAsync(tester);

    // Die gespeicherte Session muss wieder verschwunden sein ...
    expect(
      await gespeicherteSessions(tester),
      isEmpty,
      reason: 'Rueckgaengig muss die gespeicherte Session wieder loeschen',
    );

    // ... und die Reps zurueck in der laufenden Session stehen.
    await tester.tap(find.text('Workout fortsetzen'));
    await settleAsync(tester);

    expect(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('10')),
      findsOneWidget,
      reason: 'Die gezaehlten Wiederholungen gehoeren zurueck',
    );
  });
}
