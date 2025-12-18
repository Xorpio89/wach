import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';
import '../models/session_model.dart';

/// Session Local DataSource - Data Layer
/// Handles direct database operations for sessions
class SessionLocalDataSource {
  final DatabaseService _databaseService;

  SessionLocalDataSource(this._databaseService);

  /// Get the store for sessions
  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.sessionsStore;

  /// Get all sessions from database (sorted by date, newest first)
  Future<List<SessionModel>> getAll() async {
    debugPrint('[SessionDS] Getting all sessions...');
    final db = await _databaseService.database;

    final finder = Finder(
      sortOrders: [SortOrder('finished_at', false)],
    );
    final records = await _store.find(db, finder: finder);

    debugPrint('[SessionDS] Found ${records.length} sessions');
    return records.map((record) {
      return SessionModel.fromMap({
        'id': record.key,
        ...record.value,
      });
    }).toList();
  }

  /// Get recent sessions (limit)
  Future<List<SessionModel>> getRecent({int limit = 10}) async {
    debugPrint('[SessionDS] Getting recent $limit sessions...');
    final db = await _databaseService.database;

    final finder = Finder(
      sortOrders: [SortOrder('finished_at', false)],
      limit: limit,
    );
    final records = await _store.find(db, finder: finder);

    debugPrint('[SessionDS] Found ${records.length} sessions');
    return records.map((record) {
      return SessionModel.fromMap({
        'id': record.key,
        ...record.value,
      });
    }).toList();
  }

  /// Insert new session
  Future<void> insert(SessionModel session) async {
    debugPrint('[SessionDS] Inserting session: ${session.id}');
    final db = await _databaseService.database;

    final map = session.toMap();
    final id = map['id'] as String;
    map.remove('id');

    await _store.record(id).put(db, map);
    debugPrint('[SessionDS] Session inserted');
  }

  /// Delete session by ID
  Future<void> delete(String id) async {
    debugPrint('[SessionDS] Deleting session: $id');
    final db = await _databaseService.database;
    await _store.record(id).delete(db);
    debugPrint('[SessionDS] Session deleted');
  }

  /// Delete all sessions
  Future<void> deleteAll() async {
    debugPrint('[SessionDS] Deleting all sessions...');
    final db = await _databaseService.database;
    await _store.delete(db);
    debugPrint('[SessionDS] All sessions deleted');
  }
}
