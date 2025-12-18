import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Timer Mode
enum TimerMode {
  stopwatch, // Counts up
  countdown, // Counts down from target
}

/// Timer State
class TimerState {
  final Duration elapsed;
  final Duration? target;
  final TimerMode mode;
  final bool isRunning;
  final bool isFinished;
  final bool showRemaining; // Toggle between elapsed/remaining display

  const TimerState({
    this.elapsed = Duration.zero,
    this.target,
    this.mode = TimerMode.stopwatch,
    this.isRunning = false,
    this.isFinished = false,
    this.showRemaining = false,
  });

  /// Get remaining time for countdown mode
  Duration get remaining {
    if (target == null) return Duration.zero;
    final rem = target! - elapsed;
    return rem.isNegative ? Duration.zero : rem;
  }

  /// Check if countdown is complete
  bool get isCountdownComplete {
    if (target == null) return false;
    return elapsed >= target!;
  }

  /// Get display duration based on mode and showRemaining toggle
  Duration get displayDuration {
    if (showRemaining && target != null) {
      // Show remaining time (can go negative if over target)
      final rem = target! - elapsed;
      return rem.isNegative ? rem.abs() : rem;
    }
    return elapsed;
  }

  /// Is the display showing overtime (negative remaining)?
  bool get isOvertime {
    if (!showRemaining || target == null) return false;
    return elapsed > target!;
  }

  /// Check if currently beating previous time
  bool get isBettingTarget {
    if (target == null) return false;
    return elapsed < target!;
  }

  TimerState copyWith({
    Duration? elapsed,
    Duration? target,
    TimerMode? mode,
    bool? isRunning,
    bool? isFinished,
    bool? showRemaining,
    bool clearTarget = false,
  }) {
    return TimerState(
      elapsed: elapsed ?? this.elapsed,
      target: clearTarget ? null : (target ?? this.target),
      mode: mode ?? this.mode,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      showRemaining: showRemaining ?? this.showRemaining,
    );
  }
}

/// Timer Notifier
class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;
  DateTime? _startTime;

  @override
  TimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const TimerState();
  }

  /// Start stopwatch mode
  void startStopwatch() {
    _startTime = DateTime.now();
    state = state.copyWith(
      mode: TimerMode.stopwatch,
      isRunning: true,
      isFinished: false,
      elapsed: Duration.zero,
    );
    _startTimer();
  }

  /// Start countdown mode with target duration
  void startCountdown(Duration target) {
    _startTime = DateTime.now();
    state = state.copyWith(
      mode: TimerMode.countdown,
      target: target,
      isRunning: true,
      isFinished: false,
      elapsed: Duration.zero,
    );
    _startTimer();
  }

  /// Pause timer
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resume timer
  void resume() {
    if (_startTime == null) return;
    state = state.copyWith(isRunning: true);
    _startTimer();
  }

  /// Stop and reset timer
  void stop() {
    _timer?.cancel();
    final finalElapsed = state.elapsed;
    state = state.copyWith(
      isRunning: false,
      isFinished: true,
      elapsed: finalElapsed,
    );
  }

  /// Reset timer
  void reset() {
    _timer?.cancel();
    _startTime = null;
    state = const TimerState();
  }

  /// Toggle between stopwatch and countdown mode
  void toggleMode(Duration? target) {
    if (state.mode == TimerMode.stopwatch && target != null) {
      state = state.copyWith(mode: TimerMode.countdown, target: target);
    } else {
      state = state.copyWith(mode: TimerMode.stopwatch);
    }
  }

  /// Set target time (without changing mode)
  void setTarget(Duration target) {
    state = state.copyWith(target: target);
  }

  /// Clear target time
  void clearTarget() {
    state = state.copyWith(clearTarget: true, showRemaining: false);
  }

  /// Toggle between showing elapsed and remaining time
  void toggleShowRemaining() {
    if (state.target != null) {
      state = state.copyWith(showRemaining: !state.showRemaining);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_startTime != null) {
        final elapsed = DateTime.now().difference(_startTime!);
        state = state.copyWith(elapsed: elapsed);
      }
    });
  }
}

/// Timer Provider
final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);
