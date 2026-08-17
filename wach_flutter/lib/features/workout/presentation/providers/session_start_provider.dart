import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';

part 'session_start_provider.g.dart';

/// Wann die laufende Session begonnen hat.
///
/// **Bugfix 2026-08-17:** Der Zeitpunkt lag als `_sessionStartTime` im
/// Zustand des Workout-Screens. Beim Verlassen des Screens wurde dieser
/// verworfen, und beim Speichern sprang die Startzeit auf "jetzt" — im
/// Verlauf stand die Session dann mit falscher Uhrzeit und einer Dauer
/// nahe null. Dieselbe Ursache wie bei den Reps am 2026-08-07, hier nur
/// uebersehen.
///
/// Liegt aus demselben Grund wie die Reps in der Datenbank: eine Session
/// muss auch einen Neustart der App ueberstehen.
@Riverpod(keepAlive: true)
class SessionStart extends _$SessionStart {
  static const _recordKey = 'session_started_at';

  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.activeWorkoutStore;

  @override
  DateTime? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    try {
      final db = await DatabaseService().database;
      final rec = await _store.record(_recordKey).get(db);
      final millis = rec?['millis'];
      if (millis is int) {
        state = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (e) {
      debugPrint('[SessionStart] Wiederherstellen fehlgeschlagen: $e');
    }
  }

  Future<void> _persist(DateTime? zeitpunkt) async {
    try {
      final db = await DatabaseService().database;
      if (zeitpunkt == null) {
        await _store.record(_recordKey).delete(db);
      } else {
        await _store.record(_recordKey).put(db, {
          'millis': zeitpunkt.millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('[SessionStart] Speichern fehlgeschlagen: $e');
    }
  }

  /// Den Beginn festhalten — nur beim allerersten Mal.
  ///
  /// Spaetere Wiederholungen duerfen den Startzeitpunkt nicht nach hinten
  /// schieben, sonst schrumpft die Dauer mit jedem gezaehlten Rep.
  void startIfUnset() {
    if (state != null) return;
    final jetzt = DateTime.now();
    state = jetzt;
    _persist(jetzt);
  }

  /// Einen gesicherten Beginn zurueckspielen (fuer "Rueckgaengig").
  void restore(DateTime? zeitpunkt) {
    state = zeitpunkt;
    _persist(zeitpunkt);
  }

  /// Session abgeschlossen oder verworfen.
  void clear() {
    state = null;
    _persist(null);
  }
}

