import 'set_record.dart';

/// Workout Session Entity - Domain Layer
/// Represents a single workout session
class WorkoutSession {
  final String id;
  final String exerciseId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int totalReps;
  final Duration totalTime;
  final List<SetRecord> sets;
  final bool isCompleted;

  const WorkoutSession({
    required this.id,
    required this.exerciseId,
    required this.startedAt,
    this.finishedAt,
    this.totalReps = 0,
    this.totalTime = Duration.zero,
    this.sets = const [],
    this.isCompleted = false,
  });

  /// Check if session is active (started but not finished)
  bool get isActive => finishedAt == null;

  /// Get current elapsed time
  Duration get elapsedTime {
    if (finishedAt != null) {
      return finishedAt!.difference(startedAt);
    }
    return DateTime.now().difference(startedAt);
  }

  /// Create a copy with updated fields
  WorkoutSession copyWith({
    String? id,
    String? exerciseId,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? totalReps,
    Duration? totalTime,
    List<SetRecord>? sets,
    bool? isCompleted,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      totalReps: totalReps ?? this.totalReps,
      totalTime: totalTime ?? this.totalTime,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutSession(id: $id, exerciseId: $exerciseId, totalReps: $totalReps)';
  }
}
