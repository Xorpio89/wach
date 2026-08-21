import '../../workout/data/models/session_model.dart';
import 'entities/exercise.dart';

/// Vorschlag, das Ziel einer Uebung anzuheben.
class ZielAnhebung {
  final Exercise exercise;

  /// Das bisher eingestellte Ziel.
  final int bisher;

  /// Der Wert, der zuverlaessig geschafft wird.
  final int vorschlag;

  const ZielAnhebung({
    required this.exercise,
    required this.bisher,
    required this.vorschlag,
  });

  @override
  String toString() => '${exercise.name}: $bisher -> $vorschlag';
}

/// Wie viele Durchgaenge das Ziel erreichen muessen, bevor vorgeschlagen
/// wird, es anzuheben.
///
/// Ein einzelner guter Tag genuegt nicht: 53 statt 50 ist oft ein voller
/// letzter Satz und kein Zeichen dafuer, dass mehr geht. Drei Mal in Folge
/// ist es eines.
const int erforderlicheDurchgaenge = 3;

/// Uebungen finden, deren Ziel zu niedrig steht.
///
/// Verglichen wird gegen das **aktuelle** Ziel, nicht gegen das damals
/// gueltige — letzteres halten die Sessions nicht fest (siehe
/// `docs/WORKOUT_START.md`). Das ist hier kein Mangel, sondern richtig:
/// nach einer Anhebung beginnt die Zaehlung von selbst neu, weil die alten
/// Durchgaenge das neue Ziel nicht mehr erreichen.
///
/// [sessions] muss nicht sortiert sein.
List<ZielAnhebung> findeZielAnhebungen(
  List<Exercise> exercises,
  List<SessionModel> sessions,
) {
  // Neueste zuerst — nur die letzten Durchgaenge zaehlen.
  final nachDatum = [...sessions]
    ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));

  final vorschlaege = <ZielAnhebung>[];

  for (final exercise in exercises) {
    final ziel = exercise.targetReps;
    // Ohne Ziel gibt es nichts anzuheben.
    if (ziel == null || ziel <= 0) continue;

    // Nur Durchgaenge, in denen die Uebung ueberhaupt vorkam. Wer
    // Klimmzuege jedes zweite Mal macht, soll nicht benachteiligt werden,
    // weil zwischendurch etwas anderes trainiert wurde.
    final ergebnisse = <int>[];
    for (final session in nachDatum) {
      final reps = session.exerciseReps[exercise.id];
      if (reps == null) continue;
      ergebnisse.add(reps);
      if (ergebnisse.length == erforderlicheDurchgaenge) break;
    }

    if (ergebnisse.length < erforderlicheDurchgaenge) continue;
    if (ergebnisse.any((reps) => reps < ziel)) continue;

    // Das schwaechste der Ergebnisse ist der Wert, der zuverlaessig
    // geschafft wird — das Beste waere ein Ausrutscher nach oben.
    final vorschlag = ergebnisse.reduce((a, b) => a < b ? a : b);
    if (vorschlag <= ziel) continue;

    vorschlaege.add(
      ZielAnhebung(exercise: exercise, bisher: ziel, vorschlag: vorschlag),
    );
  }

  return vorschlaege;
}
