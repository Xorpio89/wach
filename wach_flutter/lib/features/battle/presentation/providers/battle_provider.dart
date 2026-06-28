import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/battle.dart';

enum BattlePhase { setup, running, finished }

/// In-memory state for a same-device battle. No persistence — a battle is a
/// one-off, throwaway session.
class BattleState {
  final BattlePhase phase;
  final String title;
  final List<BattleStage> stages;
  final List<String> players;
  final int? timeCapMs;

  final int currentPlayer;
  final int currentStage;
  final List<int> reps; // reps logged per stage for the current player's run
  final int elapsedMs;
  final bool isTiming;

  final List<BattleScore> scores;

  const BattleState({
    this.phase = BattlePhase.setup,
    this.title = '',
    this.stages = const [],
    this.players = const [],
    this.timeCapMs,
    this.currentPlayer = 0,
    this.currentStage = 0,
    this.reps = const [],
    this.elapsedMs = 0,
    this.isTiming = false,
    this.scores = const [],
  });

  BattleStage? get activeStage =>
      currentStage < stages.length ? stages[currentStage] : null;

  int get currentStageReps =>
      currentStage < reps.length ? reps[currentStage] : 0;

  int get totalReps => reps.fold(0, (sum, value) => sum + value);

  String get currentPlayerName =>
      currentPlayer < players.length ? players[currentPlayer] : '';

  /// Remaining time in ms when a cap is set (else null).
  int? get remainingMs =>
      timeCapMs == null ? null : (timeCapMs! - elapsedMs).clamp(0, timeCapMs!);

  BattleState copyWith({
    BattlePhase? phase,
    String? title,
    List<BattleStage>? stages,
    List<String>? players,
    int? timeCapMs,
    int? currentPlayer,
    int? currentStage,
    List<int>? reps,
    int? elapsedMs,
    bool? isTiming,
    List<BattleScore>? scores,
  }) {
    return BattleState(
      phase: phase ?? this.phase,
      title: title ?? this.title,
      stages: stages ?? this.stages,
      players: players ?? this.players,
      timeCapMs: timeCapMs ?? this.timeCapMs,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      currentStage: currentStage ?? this.currentStage,
      reps: reps ?? this.reps,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isTiming: isTiming ?? this.isTiming,
      scores: scores ?? this.scores,
    );
  }
}

class BattleNotifier extends Notifier<BattleState> {
  Timer? _ticker;

  @override
  BattleState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const BattleState();
  }

  /// Start a battle with the given task and players.
  void configure({
    required String title,
    required List<BattleStage> stages,
    required List<String> players,
    int? timeCapMs,
  }) {
    _ticker?.cancel();
    state = BattleState(
      phase: BattlePhase.running,
      title: title,
      stages: stages,
      players: players,
      timeCapMs: timeCapMs,
      reps: List<int>.filled(stages.length, 0),
    );
  }

  void _startTimingIfNeeded() {
    if (state.isTiming) return;
    state = state.copyWith(isTiming: true);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final next = state.elapsedMs + 100;
      state = state.copyWith(elapsedMs: next);
      if (state.timeCapMs != null && next >= state.timeCapMs!) {
        _finishCurrentPlayer(completed: false);
      }
    });
  }

  /// Log [delta] reps for the active stage (starts the clock on first rep).
  void addRep([int delta = 1]) {
    if (state.phase != BattlePhase.running) return;
    final stageIdx = state.currentStage;
    if (stageIdx >= state.stages.length) return;
    _startTimingIfNeeded();

    final reps = [...state.reps];
    final target = state.stages[stageIdx].targetReps;
    reps[stageIdx] = (reps[stageIdx] + delta).clamp(0, target);

    // Advance past every completed stage (sequential gate).
    var newStage = stageIdx;
    while (newStage < state.stages.length &&
        reps[newStage] >= state.stages[newStage].targetReps) {
      newStage++;
    }

    state = state.copyWith(reps: reps, currentStage: newStage);

    if (newStage >= state.stages.length) {
      _finishCurrentPlayer(completed: true);
    }
  }

  /// Correct a mis-count by removing one rep from the current/last stage.
  void removeRep() {
    if (state.phase != BattlePhase.running) return;
    final reps = [...state.reps];
    var stageIdx = state.currentStage;
    if (stageIdx >= state.stages.length) stageIdx = state.stages.length - 1;
    if (reps[stageIdx] == 0 && stageIdx > 0) stageIdx -= 1;
    if (reps[stageIdx] > 0) reps[stageIdx] -= 1;
    state = state.copyWith(reps: reps, currentStage: stageIdx);
  }

  /// Give up the current player's attempt (counts as not completed).
  void surrender() {
    if (state.phase == BattlePhase.running) {
      _finishCurrentPlayer(completed: false);
    }
  }

  void _finishCurrentPlayer({required bool completed}) {
    _ticker?.cancel();
    final score = BattleScore(
      player: state.currentPlayerName,
      elapsedMs: state.elapsedMs,
      completed: completed,
      totalReps: state.totalReps,
    );
    final scores = [...state.scores, score];
    final nextPlayer = state.currentPlayer + 1;

    if (nextPlayer >= state.players.length) {
      state = state.copyWith(
        phase: BattlePhase.finished,
        scores: scores,
        isTiming: false,
      );
    } else {
      state = state.copyWith(
        currentPlayer: nextPlayer,
        currentStage: 0,
        reps: List<int>.filled(state.stages.length, 0),
        elapsedMs: 0,
        isTiming: false,
        scores: scores,
      );
    }
  }

  /// Replay the same task with the same players.
  void rematch() {
    final title = state.title;
    final stages = state.stages;
    final players = state.players;
    final cap = state.timeCapMs;
    configure(
      title: title,
      stages: stages,
      players: players,
      timeCapMs: cap,
    );
  }

  void reset() {
    _ticker?.cancel();
    state = const BattleState();
  }
}

final battleProvider =
    NotifierProvider<BattleNotifier, BattleState>(BattleNotifier.new);
