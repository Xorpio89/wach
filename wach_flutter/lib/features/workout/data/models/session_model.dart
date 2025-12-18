/// Session Model - Data Layer
/// Stores workout session data for persistence
class SessionModel {
  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationSeconds;
  final Map<String, int> exerciseReps; // exerciseId -> reps
  final Map<String, String> exerciseNames; // exerciseId -> name (for display)

  const SessionModel({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.exerciseReps,
    required this.exerciseNames,
  });

  /// Total reps across all exercises
  int get totalReps =>
      exerciseReps.values.fold(0, (sum, reps) => sum + reps);

  /// Duration as Duration object
  Duration get duration => Duration(seconds: durationSeconds);

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
    };
  }

  @override
  String toString() {
    return 'SessionModel(id: $id, totalReps: $totalReps, '
        'duration: ${duration.inMinutes}m)';
  }
}
