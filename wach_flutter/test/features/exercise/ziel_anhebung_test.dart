import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/exercise/domain/entities/exercise.dart';
import 'package:wach_flutter/features/exercise/domain/ziel_anhebung.dart';
import 'package:wach_flutter/features/workout/data/models/session_model.dart';

/// Wann vorgeschlagen wird, ein Ziel anzuheben.
///
/// Reine Rechnung — die Regel aus `docs/WORKOUT_START.md` steht und fällt
/// mit diesen Tests.
void main() {
  Exercise uebung(String id, {int? ziel}) => Exercise(
        id: id,
        name: id,
        targetReps: ziel,
        createdAt: DateTime(2026, 1, 1),
      );

  var nummer = 0;

  /// Eine Session mit den angegebenen Ergebnissen, jede einen Tag später
  /// als die vorige.
  SessionModel session(Map<String, int> reps, {int tag = 0}) {
    final ende = DateTime(2026, 8, 1 + tag, 18);
    return SessionModel(
      id: 'session-${nummer++}',
      startedAt: ende.subtract(const Duration(minutes: 20)),
      finishedAt: ende,
      durationSeconds: 1200,
      exerciseReps: reps,
      exerciseNames: {for (final id in reps.keys) id: id},
    );
  }

  group('Wann nichts vorgeschlagen wird', () {
    test('ohne Sessions', () {
      expect(findeZielAnhebungen([uebung('kz', ziel: 50)], []), isEmpty);
    });

    test('bei weniger als drei Durchgaengen', () {
      final vorschlaege = findeZielAnhebungen(
        [uebung('kz', ziel: 50)],
        [
          session({'kz': 55}, tag: 0),
          session({'kz': 55}, tag: 1),
        ],
      );
      expect(vorschlaege, isEmpty);
    });

    test('wenn ein Durchgang das Ziel verfehlt hat', () {
      final vorschlaege = findeZielAnhebungen(
        [uebung('kz', ziel: 50)],
        [
          session({'kz': 55}, tag: 0),
          session({'kz': 35}, tag: 1),
          session({'kz': 55}, tag: 2),
        ],
      );
      expect(vorschlaege, isEmpty);
    });

    test('wenn das Ziel nur genau erreicht wurde', () {
      // Dreimal genau 50 heisst: das Ziel passt, nicht dass mehr geht.
      final vorschlaege = findeZielAnhebungen(
        [uebung('kz', ziel: 50)],
        [
          session({'kz': 50}, tag: 0),
          session({'kz': 50}, tag: 1),
          session({'kz': 50}, tag: 2),
        ],
      );
      expect(vorschlaege, isEmpty);
    });

    test('bei einer Uebung ohne Ziel', () {
      final vorschlaege = findeZielAnhebungen(
        [uebung('plank')],
        [
          session({'plank': 90}, tag: 0),
          session({'plank': 90}, tag: 1),
          session({'plank': 90}, tag: 2),
        ],
      );
      expect(vorschlaege, isEmpty);
    });
  });

  group('Wann vorgeschlagen wird', () {
    test('dreimal uebertroffen', () {
      final vorschlaege = findeZielAnhebungen(
        [uebung('kz', ziel: 50)],
        [
          session({'kz': 55}, tag: 0),
          session({'kz': 53}, tag: 1),
          session({'kz': 60}, tag: 2),
        ],
      );

      expect(vorschlaege, hasLength(1));
      expect(vorschlaege.single.bisher, 50);
      // Das schwaechste Ergebnis, nicht das beste: 53 wird zuverlaessig
      // geschafft, 60 war ein Ausrutscher nach oben.
      expect(vorschlaege.single.vorschlag, 53);
    });

    test('nur die letzten drei Durchgaenge zaehlen', () {
      final vorschlaege = findeZielAnhebungen(
        [uebung('kz', ziel: 50)],
        [
          // Aelter und schwach — darf das Ergebnis nicht verderben.
          session({'kz': 20}, tag: 0),
          session({'kz': 55}, tag: 1),
          session({'kz': 55}, tag: 2),
          session({'kz': 55}, tag: 3),
        ],
      );

      expect(vorschlaege, hasLength(1));
      expect(vorschlaege.single.vorschlag, 55);
    });

    test('Durchgaenge ohne die Uebung werden uebersprungen', () {
      // Wer Klimmzuege jedes zweite Mal macht, soll nicht benachteiligt
      // werden, weil zwischendurch etwas anderes trainiert wurde.
      final vorschlaege = findeZielAnhebungen(
        [uebung('kz', ziel: 50)],
        [
          session({'kz': 55}, tag: 0),
          session({'dips': 100}, tag: 1),
          session({'kz': 55}, tag: 2),
          session({'dips': 100}, tag: 3),
          session({'kz': 55}, tag: 4),
        ],
      );

      expect(vorschlaege, hasLength(1));
      expect(vorschlaege.single.vorschlag, 55);
    });

    test('mehrere Uebungen zugleich', () {
      final vorschlaege = findeZielAnhebungen(
        [
          uebung('kz', ziel: 50),
          uebung('dips', ziel: 100),
          // Diese passt noch — sie darf nicht auftauchen.
          uebung('lst', ziel: 100),
        ],
        [
          session({'kz': 55, 'dips': 105, 'lst': 100}, tag: 0),
          session({'kz': 55, 'dips': 110, 'lst': 100}, tag: 1),
          session({'kz': 55, 'dips': 105, 'lst': 100}, tag: 2),
        ],
      );

      expect(vorschlaege.map((v) => v.exercise.id), ['kz', 'dips']);
      expect(vorschlaege.map((v) => v.vorschlag), [55, 105]);
    });
  });

  test('nach einer Anhebung beginnt die Zaehlung von selbst neu', () {
    final durchgaenge = [
      session({'kz': 55}, tag: 0),
      session({'kz': 55}, tag: 1),
      session({'kz': 55}, tag: 2),
    ];

    // Vorher: Ziel 50, dreimal 55 geschafft -> Vorschlag.
    expect(findeZielAnhebungen([uebung('kz', ziel: 50)], durchgaenge),
        hasLength(1));

    // Nach dem Anheben auf 55 erreichen dieselben Durchgaenge das neue Ziel
    // nur genau — es wird nicht sofort erneut vorgeschlagen.
    expect(findeZielAnhebungen([uebung('kz', ziel: 55)], durchgaenge),
        isEmpty);
  });
}
