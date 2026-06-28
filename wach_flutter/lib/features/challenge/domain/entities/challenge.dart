/// Challenge Entities - Domain Layer
///
/// A [Challenge] is a volume goal (e.g. "700 pull-ups this week") made up of
/// one or more [ChallengeItem]s. Each item is tracked in blocks (e.g. 10 reps
/// per box) that the user checks off until the target is reached.

/// A single exercise goal within a challenge.
class ChallengeItem {
  final String id;
  final String name;
  final int targetReps;
  final int blockSize;
  final int doneReps;

  const ChallengeItem({
    required this.id,
    required this.name,
    required this.targetReps,
    this.blockSize = 10,
    this.doneReps = 0,
  });

  /// Number of boxes to display (each box represents [blockSize] reps).
  int get blockCount =>
      blockSize <= 0 ? 0 : (targetReps / blockSize).ceil();

  /// Reps still missing to reach the target.
  int get remaining => (targetReps - doneReps).clamp(0, targetReps);

  /// Progress in the range 0.0 .. 1.0
  double get progress =>
      targetReps == 0 ? 0 : (doneReps / targetReps).clamp(0.0, 1.0);

  bool get isComplete => targetReps > 0 && doneReps >= targetReps;

  ChallengeItem copyWith({
    String? id,
    String? name,
    int? targetReps,
    int? blockSize,
    int? doneReps,
  }) {
    return ChallengeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      targetReps: targetReps ?? this.targetReps,
      blockSize: blockSize ?? this.blockSize,
      doneReps: doneReps ?? this.doneReps,
    );
  }
}

/// A volume challenge made up of several exercise goals.
class Challenge {
  final String id;
  final String name;
  final int? periodDays;
  final DateTime createdAt;
  final List<ChallengeItem> items;

  const Challenge({
    required this.id,
    required this.name,
    this.periodDays,
    required this.createdAt,
    this.items = const [],
  });

  int get totalTarget =>
      items.fold(0, (sum, item) => sum + item.targetReps);

  int get totalDone => items.fold(0, (sum, item) => sum + item.doneReps);

  double get progress =>
      totalTarget == 0 ? 0 : (totalDone / totalTarget).clamp(0.0, 1.0);

  bool get isComplete =>
      items.isNotEmpty && items.every((item) => item.isComplete);

  Challenge copyWith({
    String? id,
    String? name,
    int? periodDays,
    DateTime? createdAt,
    List<ChallengeItem>? items,
  }) {
    return Challenge(
      id: id ?? this.id,
      name: name ?? this.name,
      periodDays: periodDays ?? this.periodDays,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Challenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Challenge(id: $id, name: $name, items: ${items.length})';
}
