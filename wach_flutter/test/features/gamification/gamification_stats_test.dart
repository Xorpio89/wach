import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/gamification/domain/gamification_stats.dart';
import 'package:wach_flutter/features/workout/data/models/session_model.dart';

/// Punkte, Stufen und Serie.
///
/// Reine Rechnung ohne Datenbank und ohne Oberflaeche — die Regeln aus
/// `docs/GAMIFICATION.md` stehen und fallen mit diesen Tests.
void main() {
  var laufendeNummer = 0;

  /// Eine beendete Session mit [reps] Wiederholungen an [tag].
  SessionModel session(int reps, {DateTime? tag}) {
    final ende = tag ?? DateTime(2026, 8, 17, 18);
    return SessionModel(
      id: 'session-${laufendeNummer++}',
      startedAt: ende.subtract(const Duration(minutes: 20)),
      finishedAt: ende,
      durationSeconds: 1200,
      exerciseReps: {'pull-ups': reps},
      exerciseNames: const {'pull-ups': 'Pull Ups'},
    );
  }

  group('Punkte', () {
    test('ohne Sessions steht alles auf null', () {
      final stats = GamificationStats.aus([]);
      expect(stats.punkte, 0);
      expect(stats.stufe, 1);
      expect(stats.serie, 0);
      expect(stats.abzeichen, isEmpty);
    });

    test('jede Wiederholung zaehlt einen Punkt', () {
      final stats = GamificationStats.aus([session(50), session(30)]);
      expect(stats.punkte, 80);
    });

    test('Wiederholungen mehrerer Uebungen werden zusammengezaehlt', () {
      final gemischt = SessionModel(
        id: 'gemischt',
        startedAt: DateTime(2026, 8, 17, 17),
        finishedAt: DateTime(2026, 8, 17, 18),
        durationSeconds: 3600,
        exerciseReps: const {'a': 10, 'b': 15, 'c': 25},
        exerciseNames: const {'a': 'A', 'b': 'B', 'c': 'C'},
      );
      expect(GamificationStats.aus([gemischt]).punkte, 50);
    });
  });

  group('Stufen', () {
    test('die Schwellen wachsen um je 50 Punkte', () {
      expect(GamificationStats.schwelleFuer(1), 0);
      expect(GamificationStats.schwelleFuer(2), 200);
      expect(GamificationStats.schwelleFuer(3), 450);
      expect(GamificationStats.schwelleFuer(4), 750);
      expect(GamificationStats.schwelleFuer(5), 1100);
    });

    test('genau auf der Schwelle gilt die neue Stufe', () {
      expect(GamificationStats.stufeFuer(199), 1);
      expect(GamificationStats.stufeFuer(200), 2);
      expect(GamificationStats.stufeFuer(449), 2);
      expect(GamificationStats.stufeFuer(450), 3);
    });

    test('Stufe und Schwelle passen ueber einen weiten Bereich zusammen', () {
      // Faengt Rundungsfehler der Wurzel ab, die nur bei einzelnen Werten
      // auftreten wuerden.
      for (var punkte = 0; punkte <= 20000; punkte += 7) {
        final stufe = GamificationStats.stufeFuer(punkte);
        expect(
          GamificationStats.schwelleFuer(stufe),
          lessThanOrEqualTo(punkte),
          reason: 'Stufe $stufe zu hoch fuer $punkte Punkte',
        );
        expect(
          GamificationStats.schwelleFuer(stufe + 1),
          greaterThan(punkte),
          reason: 'Stufe $stufe zu niedrig fuer $punkte Punkte',
        );
      }
    });

    test('der Fortschritt zeigt die Strecke innerhalb der Stufe', () {
      // 300 Punkte: Stufe 2 (ab 200), naechste ab 450 — also 100 von 250.
      final stats = GamificationStats.aus([session(300)]);
      expect(stats.stufe, 2);
      expect(stats.punkteInStufe, 100);
      expect(stats.spanneDerStufe, 250);
      expect(stats.punkteBisNaechsteStufe, 150);
      expect(stats.fortschritt, closeTo(0.4, 0.001));
    });
  });

  group('Serie', () {
    final heute = DateTime(2026, 8, 17, 20);
    DateTime vorTagen(int n) => heute.subtract(Duration(days: n));

    test('heute trainiert ist eine Serie von einem Tag', () {
      final stats = GamificationStats.aus([session(10)], heute: heute);
      expect(stats.serie, 1);
    });

    test('drei Tage am Stueck zaehlen als drei', () {
      final stats = GamificationStats.aus(
        [
          session(10, tag: heute),
          session(10, tag: vorTagen(1)),
          session(10, tag: vorTagen(2)),
        ],
        heute: heute,
      );
      expect(stats.serie, 3);
    });

    test('mehrere Sessions am selben Tag zaehlen einmal', () {
      final stats = GamificationStats.aus(
        [
          session(10, tag: DateTime(2026, 8, 17, 8)),
          session(10, tag: DateTime(2026, 8, 17, 19)),
        ],
        heute: heute,
      );
      expect(stats.serie, 1);
    });

    test('ein ausgelassener Tag unterbricht', () {
      final stats = GamificationStats.aus(
        [
          session(10, tag: heute),
          // gestern nichts
          session(10, tag: vorTagen(2)),
        ],
        heute: heute,
      );
      expect(stats.serie, 1);
    });

    test('gestern trainiert haelt die Serie am Leben', () {
      // Sonst stuende sie jeden Morgen auf null, bevor man dazu kommt.
      final stats = GamificationStats.aus(
        [
          session(10, tag: vorTagen(1)),
          session(10, tag: vorTagen(2)),
        ],
        heute: heute,
      );
      expect(stats.serie, 2);
    });

    test('das letzte Training vor zwei Tagen beendet die Serie', () {
      final stats = GamificationStats.aus(
        [session(10, tag: vorTagen(2))],
        heute: heute,
      );
      expect(stats.serie, 0);
    });
  });

  group('Abzeichen', () {
    final heute = DateTime(2026, 8, 17, 20);

    test('die erste Session bringt "angefangen"', () {
      final stats = GamificationStats.aus([session(5)], heute: heute);
      expect(stats.abzeichen, contains(Abzeichen.angefangen));
      expect(stats.abzeichen, isNot(contains(Abzeichen.tausend)));
    });

    test('ab tausend Wiederholungen gibt es "tausend"', () {
      final stats = GamificationStats.aus(
        [session(600), session(400)],
        heute: heute,
      );
      expect(stats.abzeichen, contains(Abzeichen.tausend));
    });

    test('sieben Tage in Folge bringen "eine Woche"', () {
      final stats = GamificationStats.aus(
        [
          for (var t = 0; t < 7; t++)
            session(10, tag: heute.subtract(Duration(days: t))),
        ],
        heute: heute,
      );
      expect(stats.serie, 7);
      expect(stats.abzeichen, contains(Abzeichen.eineWoche));
    });

    test('sechs Tage reichen noch nicht', () {
      final stats = GamificationStats.aus(
        [
          for (var t = 0; t < 6; t++)
            session(10, tag: heute.subtract(Duration(days: t))),
        ],
        heute: heute,
      );
      expect(stats.abzeichen, isNot(contains(Abzeichen.eineWoche)));
    });
  });
}
