/// Battle Entities - Domain Layer
///
/// A same-device battle: two (or more) players take turns completing the same
/// task as fast as possible. A task is a list of [BattleStage]s done in order
/// (a stage only unlocks once the previous one is finished). The fastest player
/// who completes all stages wins.

/// One stage of a battle task (e.g. "50 Pull-ups").
class BattleStage {
  final String exercise;
  final int targetReps;

  const BattleStage({required this.exercise, required this.targetReps});
}

/// A finished player's result.
class BattleScore {
  final String player;
  final int elapsedMs;
  final bool completed;
  final int totalReps;

  const BattleScore({
    required this.player,
    required this.elapsedMs,
    required this.completed,
    required this.totalReps,
  });
}
