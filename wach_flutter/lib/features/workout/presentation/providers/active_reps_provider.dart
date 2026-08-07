import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';

/// Reps der AKTUELL laufenden Session — app-weiter Zustand, nicht Widget-State.
///
/// **Bugfix 2026-08-07:** Vorher lagen die Reps als `_repsMap` direkt im State von
/// `WorkoutScreen`. Beim Verlassen des Screens wurde der State disposed und die Reps
/// waren weg — der Timer lief weiter, weil `timerProvider` ein app-weiter
/// `NotifierProvider` ist. Genau diese Inkonsistenz war der gemeldete Fehler.
///
/// Zusaetzlich wird nach sembast gespiegelt, damit die Reps auch einen **App-Neustart**
/// ueberleben (Android beendet Hintergrund-Apps aggressiv — sonst waere der Fehler
/// nur verschoben, nicht behoben).
class ActiveRepsNotifier extends Notifier<Map<String, int>> {
  static const _recordKey = 'current';

  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.activeWorkoutStore;

  @override
  Map<String, int> build() {
    // Synchron leer starten, dann asynchron aus der DB nachladen.
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    try {
      final db = await DatabaseService().database;
      final rec = await _store.record(_recordKey).get(db);
      if (rec == null) return;
      final restored = <String, int>{};
      for (final e in rec.entries) {
        final v = e.value;
        if (v is int && v > 0) restored[e.key] = v;
      }
      if (restored.isNotEmpty) {
        state = restored;
        debugPrint('[ActiveReps] ${restored.length} Übung(en) wiederhergestellt');
      }
    } catch (e) {
      // Persistenz darf die laufende Session nie blockieren.
      debugPrint('[ActiveReps] Wiederherstellen fehlgeschlagen: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final db = await DatabaseService().database;
      await _store.record(_recordKey).put(db, {...state});
    } catch (e) {
      debugPrint('[ActiveReps] Speichern fehlgeschlagen: $e');
    }
  }

  /// Reps einer Übung um 1 erhöhen.
  void increment(String exerciseId) {
    state = {...state, exerciseId: (state[exerciseId] ?? 0) + 1};
    _persist();
  }

  /// Reps einer Übung um 1 verringern (nicht unter 0).
  void decrement(String exerciseId) {
    final current = state[exerciseId] ?? 0;
    if (current <= 0) return;
    state = {...state, exerciseId: current - 1};
    _persist();
  }

  /// Reps einer Übung auf 0 setzen (Eintrag bleibt bestehen).
  void reset(String exerciseId) {
    state = {...state, exerciseId: 0};
    _persist();
  }

  /// Übung ganz aus der laufenden Session entfernen.
  void remove(String exerciseId) {
    final next = {...state}..remove(exerciseId);
    state = next;
    _persist();
  }

  /// Komplette laufende Session verwerfen (z. B. nach Speichern/Abbrechen).
  void clear() {
    state = const {};
    _persist();
  }

  /// Reps einer einzelnen Übung.
  int repsOf(String exerciseId) => state[exerciseId] ?? 0;

  /// Hat die laufende Session überhaupt schon Reps?
  bool get hasAnyReps => state.values.any((r) => r > 0);
}

final activeRepsProvider =
    NotifierProvider<ActiveRepsNotifier, Map<String, int>>(
  ActiveRepsNotifier.new,
);
