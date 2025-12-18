import 'dart:async';

import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/exercise_local_datasource.dart';
import '../models/exercise_model.dart';

/// Exercise Repository Implementation - Data Layer
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseLocalDataSource _localDataSource;

  // Stream controller for real-time updates
  final _exercisesController = StreamController<List<Exercise>>.broadcast();

  ExerciseRepositoryImpl(this._localDataSource);

  @override
  Future<List<Exercise>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Exercise?> getById(String id) async {
    final model = await _localDataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<Exercise> create(Exercise exercise) async {
    final model = ExerciseModel.fromEntity(exercise);
    await _localDataSource.insert(model);
    _notifyListeners();
    return exercise;
  }

  @override
  Future<Exercise> update(Exercise exercise) async {
    final model = ExerciseModel.fromEntity(exercise);
    await _localDataSource.update(model);
    _notifyListeners();
    return exercise;
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
    _notifyListeners();
  }

  @override
  Future<void> updateLastPerformed(String id, DateTime timestamp) async {
    await _localDataSource.updateLastPerformed(id, timestamp);
    _notifyListeners();
  }

  @override
  Stream<List<Exercise>> watchAll() {
    // Emit current data immediately
    getAll().then((exercises) {
      if (!_exercisesController.isClosed) {
        _exercisesController.add(exercises);
      }
    });
    return _exercisesController.stream;
  }

  /// Notify listeners about data changes
  Future<void> _notifyListeners() async {
    final exercises = await getAll();
    if (!_exercisesController.isClosed) {
      _exercisesController.add(exercises);
    }
  }

  /// Dispose resources
  void dispose() {
    _exercisesController.close();
  }
}
