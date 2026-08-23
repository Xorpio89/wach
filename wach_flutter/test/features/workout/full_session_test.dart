import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/core/database/database_service.dart';
import 'package:wach_flutter/features/exercise/presentation/widgets/exercise_tile.dart';
import 'package:wach_flutter/features/workout/data/datasources/session_local_datasource.dart';
import 'package:wach_flutter/features/workout/data/models/session_model.dart';

import '../../support/test_harness.dart';

/// Ein Workout so, wie es tatsaechlich abliefe: von der Startseite in den
/// Workout-Screen, alle vier Standarduebungen auf ihr Ziel zaehlen, Zeit
/// laufen lassen, pausieren, beenden — und pruefen, dass die Session
/// gespeichert in der Datenbank liegt.
///
/// Laeuft ueber den echten Router und die echten Repositories.
void main() {
  late Database db;

  // Entsprechen `defaultCalisthenicsExercises`: Zielwerte fuer ein ganzes
  // Workout, nicht fuer einen Satz.
  const ziele = <String, int>{
    'Pull Ups': 50,
    'Dips': 50,
    'Push Ups': 100,
    'Squats': 100,
  };

  /// Reps + Ziele summiert = das, was am Ende in der Session stehen muss.
  final gesamtReps = ziele.values.reduce((a, b) => a + b);

  setUp(() async {
    db = await setUpTestDatabase('full_session');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Finder tileOf(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byType(ExerciseTile),
      );

  /// Eine Uebung mit moeglichst wenigen Griffen auf ihr Ziel bringen.
  Future<void> zaehleBisZiel(
    WidgetTester tester,
    String name,
    int ziel,
  ) async {
    await tester.tap(tileOf(name));
    await pumpFrames(tester);

    var offen = ziel;
    while (offen > 0) {
      final taste = offen >= 10
          ? '+10'
          : offen >= 5
              ? '+5'
              : '+1';
      await tester.tap(
        find.descendant(of: tileOf(name), matching: find.text(taste)),
      );
      await pumpFrames(tester);
      offen -= int.parse(taste.substring(1));
    }

    await tester.tap(
      find.descendant(
        of: tileOf(name),
        matching: find.byIcon(Icons.check_rounded),
      ),
    );
    await pumpFrames(tester);
  }

  /// Die gespeicherten Sessions aus der Datenbank lesen — ueber dieselbe
  /// Datenquelle, die auch die App benutzt.
  ///
  /// `runAsync` ist hier zwingend: innerhalb von `testWidgets` laeuft die
  /// Zeit simuliert, und ein `await` auf einen echten Datenbankzugriff
  /// kaeme nie zurueck, weil niemand die Warteschlange abarbeitet.
  Future<List<SessionModel>> gespeicherteSessions(WidgetTester tester) async {
    final sessions = await tester.runAsync(
      () => SessionLocalDataSource(DatabaseService()).getAll(),
    );
    return sessions ?? const [];
  }

  testWidgets('vollstaendiges Workout von der Startseite bis zur Session',
      (tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapAppForTest());
    await settleAsync(tester);

    // --- Startseite ---
    expect(find.text('Workout starten'), findsOneWidget);
    await tester.tap(find.text('Workout starten'));
    await settleAsync(tester);

    // --- Workout-Screen mit den vier Standarduebungen ---
    expect(find.byType(ExerciseTile), findsNWidgets(4));

    // Zeit laufen lassen.
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await passRealTime(tester);

    // --- Alle vier Uebungen auf ihr Ziel ---
    for (final eintrag in ziele.entries) {
      await zaehleBisZiel(tester, eintrag.key, eintrag.value);
    }

    for (final eintrag in ziele.entries) {
      expect(
        find.descendant(
          of: tileOf(eintrag.key),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
        reason: '${eintrag.key} ist nicht als geschafft markiert',
      );
    }

    // --- Pausieren: erst dann darf die Session beendet werden ---
    expect(
      find.text('Workout beenden'),
      findsNothing,
      reason: 'Beenden darf im laufenden Betrieb nicht erreichbar sein',
    );

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await pumpFrames(tester);

    expect(find.text('Workout beenden'), findsOneWidget);

    // --- Beenden ---
    await tester.tap(find.text('Workout beenden'));
    await settleAsync(tester);

    // --- Der Aufstieg wird gefeiert ---
    //
    // Dieses Workout bringt weit mehr als die 200 Punkte fuer den D-Rang,
    // also muss die Feier kommen. Genau das fehlte hier lange, und genau
    // deshalb blieb unbemerkt, dass sie nie erschien: Sie stand hinter
    // einem `mounted`, das nach dem Wechsel zur Startseite nie mehr wahr
    // war.
    expect(
      find.text('D-RANG'),
      findsOneWidget,
      reason: 'Der Aufstieg zum D-Rang gehoert gefeiert',
    );

    // Sie verschwindet von selbst — nichts, was weggetippt werden muss.
    await passRealTime(tester, const Duration(seconds: 4));
    expect(find.text('D-RANG'), findsNothing);

    await meldungAbwarten(tester);

    // Zurueck auf der Startseite.
    expect(find.text('Workout starten'), findsOneWidget);

    // --- Die Session liegt vollstaendig in der Datenbank ---
    final sessions = await gespeicherteSessions(tester);
    expect(sessions, hasLength(1));

    final session = sessions.single;
    expect(
      session.exerciseReps.values.fold<int>(0, (a, b) => a + b),
      gesamtReps,
      reason: 'Es muessen alle $gesamtReps Wiederholungen gespeichert sein',
    );
    expect(session.exerciseReps, hasLength(4));
    expect(
      session.exerciseNames.values.toSet(),
      ziele.keys.toSet(),
      reason: 'Alle vier Uebungsnamen gehoeren in die Session',
    );
    for (final eintrag in ziele.entries) {
      final id = session.exerciseNames.entries
          .firstWhere((e) => e.value == eintrag.key)
          .key;
      expect(
        session.exerciseReps[id],
        eintrag.value,
        reason: '${eintrag.key} steht nicht auf ${eintrag.value}',
      );
    }
    expect(
      session.durationSeconds,
      greaterThan(0),
      reason: 'Die gelaufene Zeit gehoert in die Session',
    );
  });

  testWidgets('nach dem Beenden startet das naechste Workout bei null',
      (tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapAppForTest());
    await settleAsync(tester);

    await tester.tap(find.text('Workout starten'));
    await settleAsync(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await passRealTime(tester);

    await zaehleBisZiel(tester, 'Pull Ups', 10);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await pumpFrames(tester);
    await tester.tap(find.text('Workout beenden'));
    await settleAsync(tester);
    await meldungAbwarten(tester);

    // Erneut hinein: die Reps der abgeschlossenen Session duerfen nicht
    // mehr dastehen, sonst zaehlt man beim naechsten Mal weiter.
    await tester.tap(find.text('Workout starten'));
    await settleAsync(tester);

    expect(
      find.descendant(of: tileOf('Pull Ups'), matching: find.text('0')),
      findsOneWidget,
      reason: 'Die neue Session muss bei null anfangen',
    );
  });

  testWidgets('die Startzeit ueberlebt einen Ausflug in einen anderen Screen',
      (tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapAppForTest());
    await settleAsync(tester);

    await tester.tap(find.text('Workout starten'));
    await settleAsync(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await passRealTime(tester);

    // Erste Wiederholung setzt den Beginn der Session.
    await zaehleBisZiel(tester, 'Pull Ups', 10);

    // Raus aus dem Workout und wieder hinein — frueher lag der Zeitpunkt
    // im Zustand des Screens und war damit weg.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settleAsync(tester);
    await tester.tap(find.text('Workout fortsetzen'));
    await settleAsync(tester);

    await passRealTime(tester, const Duration(milliseconds: 120));

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await pumpFrames(tester);
    await tester.tap(find.text('Workout beenden'));
    await settleAsync(tester);
    await meldungAbwarten(tester);

    final session = (await gespeicherteSessions(tester)).single;
    final dauer = session.finishedAt.difference(session.startedAt);

    // Ohne gesicherten Beginn stuende hier eine Dauer nahe null.
    expect(
      dauer,
      greaterThan(const Duration(milliseconds: 100)),
      reason: 'Die Startzeit darf beim Screenwechsel nicht verloren gehen',
    );
  });

  testWidgets('ohne eine einzige Wiederholung wird nichts gespeichert',
      (tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapAppForTest());
    await settleAsync(tester);

    await tester.tap(find.text('Workout starten'));
    await settleAsync(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await passRealTime(tester);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await pumpFrames(tester);

    await tester.tap(find.text('Workout beenden'));
    await settleAsync(tester);
    await meldungAbwarten(tester);

    expect(
      await gespeicherteSessions(tester),
      isEmpty,
      reason: 'Eine Session ohne Wiederholungen ist keine Session',
    );
  });
}
