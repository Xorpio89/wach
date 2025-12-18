/// Exercise Entity - Domain Layer
/// Represents a workout exercise
class Exercise {
  final String id;
  final String name;
  final int? targetReps;
  final Duration? targetTime;
  final DateTime createdAt;
  final DateTime? lastPerformedAt;

  const Exercise({
    required this.id,
    required this.name,
    this.targetReps,
    this.targetTime,
    required this.createdAt,
    this.lastPerformedAt,
  });

  /// Check if exercise has a target
  bool get hasTarget => targetReps != null || targetTime != null;

  /// Check if exercise was ever performed
  bool get wasPerformed => lastPerformedAt != null;

  /// Create a copy with updated fields
  Exercise copyWith({
    String? id,
    String? name,
    int? targetReps,
    Duration? targetTime,
    DateTime? createdAt,
    DateTime? lastPerformedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      targetReps: targetReps ?? this.targetReps,
      targetTime: targetTime ?? this.targetTime,
      createdAt: createdAt ?? this.createdAt,
      lastPerformedAt: lastPerformedAt ?? this.lastPerformedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, targetReps: $targetReps)';
  }
}
