import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../../../../core/database/database_service.dart';
import '../models/exercise_model.dart';

/// Exercise Local DataSource - Data Layer
/// Handles direct database operations for exercises
class ExerciseLocalDataSource {
  final DatabaseService _databaseService;

  ExerciseLocalDataSource(this._databaseService);

  /// Get the store for exercises
  StoreRef<String, Map<String, Object?>> get _store =>
      DatabaseService.exercisesStore;

  /// Get all exercises from database
  Future<List<ExerciseModel>> getAll() async {
    debugPrint('[ExerciseDS] Getting all exercises...');
    final db = await _databaseService.database;

    // Find all records
    final records = await _store.find(db);

    debugPrint('[ExerciseDS] Found ${records.length} exercises');
    final exercises = records
        .map((record) => ExerciseModel.fromMap({
              'id': record.key,
              ...record.value,
            }))
        .toList();

    // Sort by created_at ascending (oldest first, newest at bottom)
    exercises.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return exercises;
  }

  /// Get exercise by ID
  Future<ExerciseModel?> getById(String id) async {
    debugPrint('[ExerciseDS] Getting exercise by id: $id');
    final db = await _databaseService.database;
    final record = await _store.record(id).get(db);

    if (record == null) {
      debugPrint('[ExerciseDS] Exercise not found');
      return null;
    }

    debugPrint('[ExerciseDS] Exercise found');
    return ExerciseModel.fromMap({
      'id': id,
      ...record,
    });
  }

  /// Insert new exercise
  Future<void> insert(ExerciseModel exercise) async {
    debugPrint('[ExerciseDS] Inserting exercise: ${exercise.name}');
    final db = await _databaseService.database;

    final map = exercise.toMap();
    final id = map['id'] as String;
    map.remove('id'); // ID is stored as the key, not in the value

    await _store.record(id).put(db, map);
    debugPrint('[ExerciseDS] Exercise inserted');
  }

  /// Update existing exercise
  Future<void> update(ExerciseModel exercise) async {
    debugPrint('[ExerciseDS] Updating exercise: ${exercise.id}');
    final db = await _databaseService.database;

    final map = exercise.toMap();
    final id = map['id'] as String;
    map.remove('id');

    await _store.record(id).put(db, map);
    debugPrint('[ExerciseDS] Exercise updated');
  }

  /// Delete exercise by ID
  Future<void> delete(String id) async {
    debugPrint('[ExerciseDS] Deleting exercise: $id');
    final db = await _databaseService.database;
    await _store.record(id).delete(db);
    debugPrint('[ExerciseDS] Exercise deleted');
  }

  /// Update last performed timestamp
  Future<void> updateLastPerformed(String id, DateTime timestamp) async {
    debugPrint('[ExerciseDS] Updating last performed for: $id');
    final db = await _databaseService.database;

    await _store.record(id).update(
      db,
      {'last_performed_at': timestamp.millisecondsSinceEpoch},
    );
    debugPrint('[ExerciseDS] Last performed updated');
  }
}
