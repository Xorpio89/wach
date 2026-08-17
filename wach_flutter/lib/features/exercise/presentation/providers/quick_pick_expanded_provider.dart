import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';

part 'quick_pick_expanded_provider.g.dart';

/// Ob die Vorschlagsliste im Hinzufuegen-Fenster aufgeklappt bleibt.
///
/// Wird gespeichert, weil die Entscheidung dauerhaft ist: wer einmal alle
/// Uebungen sehen wollte, will das beim naechsten Anlegen meist wieder —
/// und muesste sonst jedes Mal erneut aufklappen.
@Riverpod(keepAlive: true)
class QuickPickExpanded extends _$QuickPickExpanded {
  static const _recordKey = 'quick_pick_expanded';

  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.settingsStore;

  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    try {
      final db = await DatabaseService().database;
      final rec = await _store.record(_recordKey).get(db);
      final wert = rec?['expanded'];
      if (wert is bool) state = wert;
    } catch (e) {
      debugPrint('[QuickPick] Wiederherstellen fehlgeschlagen: $e');
    }
  }

  Future<void> setze(bool aufgeklappt) async {
    state = aufgeklappt;
    try {
      final db = await DatabaseService().database;
      await _store.record(_recordKey).put(db, {'expanded': aufgeklappt});
    } catch (e) {
      debugPrint('[QuickPick] Speichern fehlgeschlagen: $e');
    }
  }

  void umschalten() => setze(!state);
}
