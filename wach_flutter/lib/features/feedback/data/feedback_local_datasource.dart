import 'package:sembast/sembast.dart';

import '../../../core/database/database_service.dart';
import '../domain/feedback_notiz.dart';

/// Legt Rueckmeldungen im Geraet ab.
///
/// Sie bleiben auch nach dem Weitergeben liegen: Wer nachschauen will, was
/// er schon gemeldet hat, findet es hier — und schreibt dasselbe nicht
/// zweimal auf.
class FeedbackLocalDataSource {
  final DatabaseService _databaseService;

  FeedbackLocalDataSource(this._databaseService);

  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.feedbackStore;

  /// Alle Notizen, die neueste zuerst.
  Future<List<FeedbackNotiz>> getAll() async {
    final db = await _databaseService.database;
    final finder = Finder(sortOrders: [SortOrder('erstellt_am', false)]);
    final records = await _store.find(db, finder: finder);

    return records
        .map((r) => FeedbackNotiz.fromMap({'id': r.key, ...r.value}))
        .toList();
  }

  Future<void> speichere(FeedbackNotiz notiz) async {
    final db = await _databaseService.database;
    final map = notiz.toMap()..remove('id');
    await _store.record(notiz.id).put(db, map);
  }

  Future<void> loesche(String id) async {
    final db = await _databaseService.database;
    await _store.record(id).delete(db);
  }
}
