import '../../domain/entities/exercise.dart';

/// Exercise Model - Data Layer
/// Handles serialization to/from database
class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.name,
    super.targetReps,
    super.targetTime,
    required super.createdAt,
    super.lastPerformedAt,
  });

  /// Create from database map
  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      name: map['name'] as String,
      targetReps: map['target_reps'] as int?,
      targetTime: map['target_time_seconds'] != null
          ? Duration(seconds: map['target_time_seconds'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastPerformedAt: map['last_performed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_performed_at'] as int)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_reps': targetReps,
      'target_time_seconds': targetTime?.inSeconds,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_performed_at': lastPerformedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create model from entity
  factory ExerciseModel.fromEntity(Exercise exercise) {
    return ExerciseModel(
      id: exercise.id,
      name: exercise.name,
      targetReps: exercise.targetReps,
      targetTime: exercise.targetTime,
      createdAt: exercise.createdAt,
      lastPerformedAt: exercise.lastPerformedAt,
    );
  }

  /// Convert to domain entity
  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      targetReps: targetReps,
      targetTime: targetTime,
      createdAt: createdAt,
      lastPerformedAt: lastPerformedAt,
    );
  }
}
