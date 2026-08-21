/// Session Model - Data Layer
/// Stores workout session data for persistence
class SessionModel {
  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationSeconds;
  final Map<String, int> exerciseReps; // exerciseId -> reps
  final Map<String, String> exerciseNames; // exerciseId -> name (for display)

  /// Das Ziel, das zum Zeitpunkt der Session galt (exerciseId -> Ziel).
  ///
  /// Ohne diese Angabe liesse sich eine vergangene Session nicht
  /// wiederverwenden: aus "35 Klimmzuege" allein geht nicht hervor, ob 35
  /// das Vorhaben war oder ein Abbruch bei einem Ziel von 50. Daran hingen
  /// vier Dinge — Workouts aus dem Verlauf wiederholen, sie nach Zielen
  /// gruppieren, Bestzeiten nur bei erreichtem Ziel und der Zielbonus der
  /// Punkte.
  ///
  /// Uebungen ohne Ziel fehlen hier. Sessions von vor dieser Erweiterung
  /// haben das Feld nicht — dann bleibt die Map leer, und wer sie liest,
  /// muss mit fehlenden Eintraegen rechnen.
  final Map<String, int> exerciseTargets;

  const SessionModel({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.exerciseReps,
    required this.exerciseNames,
    this.exerciseTargets = const {},
  });

  /// Total reps across all exercises
  int get totalReps => exerciseReps.values.fold(0, (sum, reps) => sum + reps);

  /// Duration as Duration object
  Duration get duration => Duration(seconds: durationSeconds);

  /// Ob jede Uebung mit Ziel dieses auch erreicht hat.
  ///
  /// Sessions ohne gespeicherte Ziele gelten als nicht vollstaendig — es
  /// laesst sich schlicht nicht feststellen, und eine Bestzeit auf Verdacht
  /// waere schlechter als keine.
  bool get zielErreicht {
    if (exerciseTargets.isEmpty) return false;
    for (final eintrag in exerciseTargets.entries) {
      final geschafft = exerciseReps[eintrag.key] ?? 0;
      if (geschafft < eintrag.value) return false;
    }
    return true;
  }

  /// Kennzeichen der Zusammenstellung: welche Uebungen mit welchen Zielen.
  ///
  /// Zwei Sessions mit demselben Kennzeichen sind Durchgaenge desselben
  /// Workouts — unabhaengig davon, wie sie ausgingen. 50, 53 und 35
  /// Klimmzuege bei einem Ziel von 50 gehoeren damit zusammen.
  ///
  /// Leer, wenn keine Ziele bekannt sind; solche Sessions lassen sich nicht
  /// zuordnen.
  String get zusammenstellung {
    if (exerciseTargets.isEmpty) return '';
    final teile = exerciseTargets.entries
        .map((e) => '${exerciseNames[e.key] ?? e.key}:${e.value}')
        .toList()
      // Sortiert, damit die Reihenfolge der Uebungen keine Rolle spielt.
      ..sort();
    return teile.join('|');
  }

  /// Create from Map (database)
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      finishedAt:
          DateTime.fromMillisecondsSinceEpoch(map['finished_at'] as int),
      durationSeconds: map['duration_seconds'] as int,
      exerciseReps: Map<String, int>.from(map['exercise_reps'] as Map),
      exerciseNames: Map<String, String>.from(map['exercise_names'] as Map),
      // Fehlt bei Sessions von vor dieser Erweiterung.
      exerciseTargets: map['exercise_targets'] == null
          ? const {}
          : Map<String, int>.from(map['exercise_targets'] as Map),
    );
  }

  /// Convert to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started_at': startedAt.millisecondsSinceEpoch,
      'finished_at': finishedAt.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'exercise_reps': exerciseReps,
      'exercise_names': exerciseNames,
      'exercise_targets': exerciseTargets,
    };
  }

  @override
  String toString() {
    return 'SessionModel(id: $id, totalReps: $totalReps, '
        'duration: ${duration.inMinutes}m)';
  }
}
