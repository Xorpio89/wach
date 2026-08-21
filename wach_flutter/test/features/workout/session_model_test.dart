import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/workout/data/models/session_model.dart';

/// Das Session-Modell mit den mitgeschriebenen Zielen.
///
/// Besonders wichtig: Sessions, die vor dieser Erweiterung gespeichert
/// wurden, haben das Feld nicht. Sie muessen weiter lesbar sein — es liegen
/// echte Daten in der App.
void main() {
  SessionModel session({
    Map<String, int> reps = const {'kz': 50},
    Map<String, int> ziele = const {},
  }) {
    return SessionModel(
      id: 'test',
      startedAt: DateTime(2026, 8, 21, 17),
      finishedAt: DateTime(2026, 8, 21, 18),
      durationSeconds: 3600,
      exerciseReps: reps,
      exerciseNames: {for (final id in reps.keys) id: id.toUpperCase()},
      exerciseTargets: ziele,
    );
  }

  group('Lesen und Schreiben', () {
    test('die Ziele ueberleben den Weg durch die Datenbank', () {
      final vorher = session(reps: {'kz': 53}, ziele: {'kz': 50});
      final nachher = SessionModel.fromMap(vorher.toMap());

      expect(nachher.exerciseTargets, {'kz': 50});
      expect(nachher.exerciseReps, {'kz': 53});
    });

    test('eine Session von vor der Erweiterung bleibt lesbar', () {
      // Genau so sehen die bereits gespeicherten Daten aus: ohne den
      // Schluessel `exercise_targets`.
      final alt = <String, dynamic>{
        'id': 'alt',
        'started_at': DateTime(2026, 8, 1, 17).millisecondsSinceEpoch,
        'finished_at': DateTime(2026, 8, 1, 18).millisecondsSinceEpoch,
        'duration_seconds': 3600,
        'exercise_reps': {'kz': 50},
        'exercise_names': {'kz': 'Klimmzüge'},
      };

      final gelesen = SessionModel.fromMap(alt);

      expect(gelesen.exerciseTargets, isEmpty);
      expect(gelesen.totalReps, 50);
    });
  });

  group('Ziel erreicht', () {
    test('alle Ziele erreicht', () {
      expect(
        session(reps: {'kz': 50, 'd': 100}, ziele: {'kz': 50, 'd': 100})
            .zielErreicht,
        isTrue,
      );
    });

    test('uebertroffen gilt als erreicht', () {
      expect(session(reps: {'kz': 55}, ziele: {'kz': 50}).zielErreicht, isTrue);
    });

    test('ein verfehltes Ziel genuegt', () {
      expect(
        session(reps: {'kz': 50, 'd': 90}, ziele: {'kz': 50, 'd': 100})
            .zielErreicht,
        isFalse,
      );
    });

    test('ohne gespeicherte Ziele gilt es als nicht erreicht', () {
      // Es laesst sich nicht feststellen — und eine Bestzeit auf Verdacht
      // waere schlechter als keine.
      expect(session(reps: {'kz': 50}).zielErreicht, isFalse);
    });
  });

  group('Zusammenstellung als Kennzeichen', () {
    test('gleiche Uebungen und Ziele ergeben dasselbe Kennzeichen', () {
      // Der Kern der Gruppierung: 50, 53 und 35 bei einem Ziel von 50 sind
      // Durchgaenge desselben Workouts.
      final a = session(reps: {'kz': 50}, ziele: {'kz': 50});
      final b = session(reps: {'kz': 53}, ziele: {'kz': 50});
      final c = session(reps: {'kz': 35}, ziele: {'kz': 50});

      expect(b.zusammenstellung, a.zusammenstellung);
      expect(c.zusammenstellung, a.zusammenstellung);
    });

    test('ein anderes Ziel ergibt ein anderes Kennzeichen', () {
      final fuenfzig = session(reps: {'kz': 50}, ziele: {'kz': 50});
      final hundert = session(reps: {'kz': 100}, ziele: {'kz': 100});

      expect(hundert.zusammenstellung, isNot(fuenfzig.zusammenstellung));
    });

    test('eine Uebung mehr ergibt ein anderes Kennzeichen', () {
      final allein = session(reps: {'kz': 50}, ziele: {'kz': 50});
      final zusammen =
          session(reps: {'kz': 50, 'd': 100}, ziele: {'kz': 50, 'd': 100});

      expect(zusammen.zusammenstellung, isNot(allein.zusammenstellung));
    });

    test('die Reihenfolge der Uebungen spielt keine Rolle', () {
      final eins =
          session(reps: {'kz': 50, 'd': 100}, ziele: {'kz': 50, 'd': 100});
      final andersherum =
          session(reps: {'d': 100, 'kz': 50}, ziele: {'d': 100, 'kz': 50});

      expect(andersherum.zusammenstellung, eins.zusammenstellung);
    });

    test('ohne Ziele gibt es kein Kennzeichen', () {
      // Alte Sessions lassen sich keiner Gruppe zuordnen.
      expect(session(reps: {'kz': 50}).zusammenstellung, isEmpty);
    });
  });
}
