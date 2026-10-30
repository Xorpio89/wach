import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart' show Database;
import 'package:wach_flutter/features/karten/domain/karte.dart';
import 'package:wach_flutter/features/karten/domain/karten_spiel.dart';
import 'package:wach_flutter/features/karten/presentation/providers/karten_spiel_provider.dart';
import 'package:wach_flutter/features/karten/presentation/screens/karten_screen.dart';
import 'package:wach_flutter/features/workout/presentation/providers/session_providers.dart';

import '../../support/test_harness.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('karten');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Future<void> oeffne(WidgetTester tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapScreenForTest(const KartenScreen()));
    await settleAsync(tester);
  }

  Future<void> starte(WidgetTester tester) async {
    final start = find.text("Los geht's");
    await tester.scrollUntilVisible(start, 300);
    await tester.tap(start);
    await pumpFrames(tester);
  }

  /// Aktuelle Karte abschließen; eine Wahl-Karte bekommt die erste Übung.
  Future<void> naechsteKarte(WidgetTester tester) async {
    if (find.text('Wähle deine Übung').evaluate().isNotEmpty) {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Push Ups'));
      await pumpFrames(tester);
    }
    // Der Doppeltipp-Schutz rechnet in echter Zeit. Gewartet wird vor dem
    // Tippen: das Pumpen lässt auch die simulierte Uhr weiterlaufen.
    await passRealTime(tester, const Duration(milliseconds: 500));
    final ziel = find.text('Tippen = erledigt').evaluate().isNotEmpty
        ? find.text('Tippen = erledigt')
        : find.text('Weiter');
    await tester.tap(ziel);
    await pumpFrames(tester);
  }

  testWidgets('die Einrichtung legt die vier Startübungen als Stapel an',
      (tester) async {
    await oeffne(tester);

    expect(find.text('Kurz · 28'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Stapel hinzufügen'), 300);
    // Ein Dropdown hält alle Einträge im Baum — daher findsWidgets.
    for (final name in ['Push Ups', 'Pull Ups', 'Squats', 'Dips']) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    expect(find.byTooltip('Stapel entfernen'), findsNWidgets(4));
  });

  testWidgets('eine Karte erledigen und rückgängig machen', (tester) async {
    await oeffne(tester);
    await starte(tester);

    expect(find.text('Karte 1 von 28'), findsOneWidget);
    await naechsteKarte(tester);
    expect(find.text('Karte 2 von 28'), findsOneWidget);

    await tester.tap(find.byTooltip('Rückgängig'));
    await pumpFrames(tester);
    expect(find.text('Karte 1 von 28'), findsOneWidget);
  });

  testWidgets('gegen die Uhr endet das Spiel nach dem Zeitlimit',
      (tester) async {
    await oeffne(tester);
    await tester.tap(find.text('Gegen die Uhr'));
    await pumpFrames(tester);
    await tester.tap(find.text('5 Min'));
    await pumpFrames(tester);
    await starte(tester);

    expect(find.text('Karte 1'), findsOneWidget);
    await tester.pump(const Duration(minutes: 5, seconds: 1));
    await pumpFrames(tester);

    expect(find.text('Zeit abgelaufen'), findsOneWidget);
  });

  testWidgets('beenden und als Workout speichern', (tester) async {
    await oeffne(tester);
    await starte(tester);

    // Bis mindestens eine Wiederholung gezählt ist.
    for (var i = 0; i < 6; i++) {
      await naechsteKarte(tester);
    }

    await tester.tap(find.byTooltip('Beenden'));
    await pumpFrames(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Beenden'));
    await pumpFrames(tester);
    expect(find.text('Spiel beendet'), findsOneWidget);

    final speichern = find.text('Als Workout speichern');
    await tester.ensureVisible(speichern);
    await tester.tap(speichern);
    await settleAsync(tester);

    expect(find.text('Gespeichert'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(KartenScreen)),
    );
    final sessions = container.read(sessionProvider).value ?? const [];
    expect(sessions, hasLength(1));
    expect(sessions.single.totalReps, greaterThan(0));
    expect(sessions.single.exerciseTargets, isEmpty,
        reason: 'Karten-Sessions haben keine Ziele');
  });

  testWidgets('die Startseite führt zum Karten-Workout', (tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapAppForTest());
    await settleAsync(tester);

    final karte = find.text('Karten-Workout');
    await tester.ensureVisible(karte);
    await tester.tap(karte);
    await settleAsync(tester);

    expect(find.byType(KartenScreen), findsOneWidget);
  });

  group('jede Kartenart passt auf ein schmales Handy', () {
    final achtStapel = [
      for (var i = 0; i < maxStapel; i++)
        StapelWahl(
          uebungId: 'u$i',
          name: 'Diamond Push Ups $i',
          farbe: i,
          symbol: i,
        ),
    ];
    final faelle = <String, List<Karte>>{
      'Zahl mit ×2': [
        const Karte.aktion(KartenArt.doppelt, 0),
        const Karte.zahl(7, 9),
      ],
      'Joker': [const Karte.aktion(KartenArt.joker, 1)],
      'Nochmal ohne Vorgänger': [const Karte.aktion(KartenArt.nochmal, 2)],
      'Wahl mit acht Stapeln': [const Karte.wahl()],
    };

    for (final fall in faelle.entries) {
      testWidgets(fall.key, (tester) async {
        await oeffne(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(KartenScreen)),
        );
        container.read(kartenSpielProvider.notifier).starteMit(
              stapel: achtStapel,
              spiel: KartenSpiel.ausKarten(
                const KartenRegeln(stapel: maxStapel, obergrenze: null),
                fall.value,
              ),
            );
        await pumpFrames(tester);
        if (fall.value.length > 1) {
          await tester.tap(find.text('Weiter'));
          await pumpFrames(tester);
        }
        // Ein Überlauf meldet das Testgerüst selbst als Fehler.
        expect(tester.takeException(), isNull);
        container.read(kartenSpielProvider.notifier).zurEinrichtung();
        await pumpFrames(tester);
      });
    }
  });

  Future<ProviderContainer> starteFest(
    WidgetTester tester,
    List<Karte> karten, {
    KartenRegeln regeln = const KartenRegeln(stapel: 4),
    List<String> namen = const [],
  }) async {
    await oeffne(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(KartenScreen)),
    );
    container.read(kartenSpielProvider.notifier).starteMit(
      stapel: [
        for (var i = 0; i < regeln.stapel; i++)
          StapelWahl(uebungId: 'u$i', name: 'Übung $i', farbe: i, symbol: i),
      ],
      spiel: KartenSpiel.ausKarten(regeln, karten),
      spielerNamen: namen,
    );
    await pumpFrames(tester);
    return container;
  }

  testWidgets('nach einer Übung läuft die Pause und lässt sich überspringen',
      (tester) async {
    final container = await starteFest(
      tester,
      [const Karte.zahl(0, 3), const Karte.zahl(1, 4), const Karte.zahl(2, 5)],
      regeln: const KartenRegeln(stapel: 4, pauseSekunden: 30),
    );

    await naechsteKarte(tester);
    expect(find.text('Pause überspringen'), findsOneWidget);
    await tester.tap(find.text('Pause überspringen'));
    await pumpFrames(tester);
    expect(find.text('Karte 2 von 3'), findsOneWidget);

    // Eine zweite Pause endet von selbst.
    await naechsteKarte(tester);
    expect(find.text('Pause überspringen'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    await pumpFrames(tester);
    expect(find.text('Pause überspringen'), findsNothing);
    container.read(kartenSpielProvider.notifier).zurEinrichtung();
    await pumpFrames(tester);
  });

  testWidgets('mit zwei Spielern wechselt, wer am Zug ist', (tester) async {
    final container = await starteFest(
      tester,
      [const Karte.zahl(0, 3), const Karte.zahl(1, 4)],
      regeln: const KartenRegeln(stapel: 4, spieler: 2),
      namen: ['Anna', 'Ben'],
    );

    expect(find.text('Am Zug: Anna'), findsOneWidget);
    await naechsteKarte(tester);
    expect(find.text('Am Zug: Ben'), findsOneWidget);
    container.read(kartenSpielProvider.notifier).zurEinrichtung();
    await pumpFrames(tester);
  });

  testWidgets('die 0 zeigt zehn, ein Tipp auf die Zahl schließt nicht ab',
      (tester) async {
    final container = await starteFest(
      tester,
      [const Karte.zahl(0, 0), const Karte.zahl(1, 1)],
    );
    // Titel und Zähler zeigen beide 10.
    expect(find.text('10'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Eine mehr'));
    await pumpFrames(tester);
    await passRealTime(tester, const Duration(milliseconds: 500));
    await tester.tap(find.text('11'));
    await pumpFrames(tester);

    expect(find.text('Karte 1 von 2'), findsOneWidget);
    container.read(kartenSpielProvider.notifier).zurEinrichtung();
    await pumpFrames(tester);
  });
}
