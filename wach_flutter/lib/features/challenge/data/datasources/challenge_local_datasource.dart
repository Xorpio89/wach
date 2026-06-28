import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';
import '../models/challenge_model.dart';

/// Challenge Local DataSource - Data Layer
/// Handles direct database operations for challenges.
class ChallengeLocalDataSource {
  final DatabaseService _databaseService;

  ChallengeLocalDataSource(this._databaseService);

  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.challengesStore;

  Future<List<ChallengeModel>> getAll() async {
    debugPrint('[ChallengeDS] Getting all challenges...');
    final db = await _databaseService.database;
    final records = await _store.find(db);

    final challenges = records
        .map((record) => ChallengeModel.fromMap({
              'id': record.key,
              ...record.value,
            }))
        .toList();

    // Sort by created_at ascending (oldest first).
    challenges.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    debugPrint('[ChallengeDS] Found ${challenges.length} challenges');
    return challenges;
  }

  Future<ChallengeModel?> getById(String id) async {
    final db = await _databaseService.database;
    final record = await _store.record(id).get(db);
    if (record == null) return null;
    return ChallengeModel.fromMap({'id': id, ...record});
  }

  Future<void> insert(ChallengeModel challenge) async {
    final db = await _databaseService.database;
    final map = challenge.toMap();
    final id = map['id'] as String;
    map.remove('id'); // ID is stored as the key, not in the value.
    await _store.record(id).put(db, map);
  }

  Future<void> update(ChallengeModel challenge) async {
    final db = await _databaseService.database;
    final map = challenge.toMap();
    final id = map['id'] as String;
    map.remove('id');
    await _store.record(id).put(db, map);
  }

  Future<void> delete(String id) async {
    final db = await _databaseService.database;
    await _store.record(id).delete(db);
  }
}
