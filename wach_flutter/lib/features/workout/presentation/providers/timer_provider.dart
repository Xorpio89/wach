import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';

part 'timer_provider.g.dart';

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
@Riverpod(keepAlive: true)
class SessionTimer extends _$SessionTimer {
  /// Wie oft die Anzeige nachgezogen wird.
  ///
  /// Vorher 10 ms — 100 State-Updates pro Sekunde, von denen ein
  /// 60-Hz-Display nicht einmal die Haelfte zu Gesicht bekommt. Ein Tick
  /// pro Frame reicht fuer die Hundertstel-Anzeige und drittelt die Last.
  static const _tickInterval = Duration(milliseconds: 16);

  /// Ab wann ein gespeicherter Lauf nicht mehr aufgenommen wird.
  ///
  /// Eine Session, die seit einem halben Tag offen steht, ist vergessen
  /// worden und nicht pausiert. Sie wieder aufzuschlagen wuerde eine
  /// zwoelfstellige Laufzeit anzeigen, statt zu helfen.
  static const _maxRestoreAge = Duration(hours: 12);

  static const _recordKey = 'current';

  Timer? _timer;
  DateTime? _startTime;
  AppLifecycleListener? _lifecycle;

  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.activeTimerStore;

  @override
  TimerState build() {
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    _restore();
    return const TimerState();
  }

  /// Den Stand der Uhr sichern.
  ///
  /// Gespeichert wird der Startzeitpunkt, nicht die verstrichene Zeit: nur
  /// so laeuft die Uhr korrekt weiter, wenn das Handy die App zwischendurch
  /// aus dem Speicher wirft.
  Future<void> _persist() async {
    try {
      final db = await DatabaseService().database;
      await _store.record(_recordKey).put(db, {
        'startedAtMillis': _startTime?.millisecondsSinceEpoch,
        'elapsedMillis': state.elapsed.inMilliseconds,
        'targetMillis': state.target?.inMilliseconds,
        'isRunning': state.isRunning,
      });
    } catch (e) {
      // Die laufende Session darf an der Persistenz nie haengenbleiben.
      debugPrint('[Timer] Speichern fehlgeschlagen: $e');
    }
  }

  Future<void> _clearPersisted() async {
    try {
      final db = await DatabaseService().database;
      await _store.record(_recordKey).delete(db);
    } catch (e) {
      debugPrint('[Timer] Loeschen fehlgeschlagen: $e');
    }
  }

  /// Einen gesicherten Stand wieder aufnehmen.
  Future<void> _restore() async {
    try {
      final db = await DatabaseService().database;
      final rec = await _store.record(_recordKey).get(db);
      if (rec == null) return;

      final startedAtMillis = rec['startedAtMillis'];
      final elapsedMillis = rec['elapsedMillis'];
      if (startedAtMillis is! int || elapsedMillis is! int) return;

      final targetMillis = rec['targetMillis'];
      final target =
          targetMillis is int ? Duration(milliseconds: targetMillis) : null;
      final wasRunning = rec['isRunning'] == true;

      final startTime = DateTime.fromMillisecondsSinceEpoch(startedAtMillis);
      // Bei einer laufenden Uhr zaehlt die Zeit weiter, die weg war —
      // genau darum wird der Startzeitpunkt gesichert und nicht der Stand.
      final elapsed = wasRunning
          ? DateTime.now().difference(startTime)
          : Duration(milliseconds: elapsedMillis);

      if (elapsed.isNegative || elapsed > _maxRestoreAge) {
        await _clearPersisted();
        return;
      }
      if (elapsed == Duration.zero && !wasRunning) return;

      _startTime = startTime;
      state = TimerState(
        elapsed: elapsed,
        target: target,
        isRunning: wasRunning,
      );
      if (wasRunning) _startTimer();

      debugPrint('[Timer] Stand wiederhergestellt: $elapsed');
    } catch (e) {
      debugPrint('[Timer] Wiederherstellen fehlgeschlagen: $e');
    }
  }

  /// Im Hintergrund wird nicht getickt.
  ///
  /// `elapsed` leitet sich ohnehin aus `_startTime` (Wall-Clock) ab, der
  /// Timer verliert also keine Sekunde — beim Zurueckkommen wird einmal
  /// nachgezogen statt tausende Updates aufzustauen.
  ///
  /// **Bugfix 2026-08-15:** Genau dieser Rueckstau war die Ursache dafuer,
  /// dass die App nach einem Wechsel in eine andere App sekundenlang nicht
  /// auf Taps reagierte: der Ticker lief im Hintergrund mit 100 Hz weiter
  /// und markierte jedes Mal Widgets als "neu zu bauen", obwohl gar kein
  /// Frame gezeichnet wurde.
  void _onLifecycleChanged(AppLifecycleState lifecycleState) {
    if (!state.isRunning) return;

    switch (lifecycleState) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        // `inactive` heisst nur "nicht im Fokus" — Benachrichtigungsleiste,
        // App-Umschalter, eingehender Anruf. Die Uhr ist dabei sichtbar und
        // darf nicht stehenbleiben.
        _syncElapsed();
        _startTimer();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _timer?.cancel();
        _timer = null;
        _syncElapsed();
        // Der Wechsel in den Hintergrund ist der Moment, in dem eine
        // installierte Web-App entladen werden kann.
        _persist();
    }
  }

  /// Anzeige einmalig auf die tatsaechlich verstrichene Zeit setzen.
  void _syncElapsed() {
    final startTime = _startTime;
    if (startTime == null) return;
    state = state.copyWith(elapsed: DateTime.now().difference(startTime));
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
    _persist();
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
    _persist();
  }

  /// Pause timer
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _persist();
  }

  /// Resume timer
  void resume() {
    if (_startTime == null) return;
    // Re-anchor the start time so the paused span is not counted. Every
    // tick derives elapsed from _startTime, so leaving it untouched would
    // make the pause button a no-op.
    _startTime = DateTime.now().subtract(state.elapsed);
    state = state.copyWith(isRunning: true);
    _startTimer();
    _persist();
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
    _persist();
  }

  /// Reset timer
  void reset() {
    _timer?.cancel();
    _startTime = null;
    state = const TimerState();
    _clearPersisted();
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
    _persist();
  }

  /// Clear target time
  void clearTarget() {
    state = state.copyWith(clearTarget: true, showRemaining: false);
    _persist();
  }

  /// Einen beendeten Lauf wiederherstellen (für "Rückgängig").
  ///
  /// Setzt den Timer pausiert auf [elapsed] zurück, damit ein
  /// versehentlich beendetes Workout ohne Zeitverlust weitergeht.
  void restore({required Duration elapsed, Duration? target}) {
    _timer?.cancel();
    _startTime = DateTime.now().subtract(elapsed);
    state = TimerState(
      elapsed: elapsed,
      target: target,
      isRunning: false,
      isFinished: false,
    );
    _persist();
  }

  /// Toggle between showing elapsed and remaining time
  void toggleShowRemaining() {
    if (state.target != null) {
      state = state.copyWith(showRemaining: !state.showRemaining);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) => _syncElapsed());
  }
}

