import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_service.dart';
import '../../data/datasources/exercise_local_datasource.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

/// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Exercise Local DataSource Provider
final exerciseLocalDataSourceProvider = Provider<ExerciseLocalDataSource>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ExerciseLocalDataSource(dbService);
});

/// Exercise Repository Provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final dataSource = ref.watch(exerciseLocalDataSourceProvider);
  return ExerciseRepositoryImpl(dataSource);
});

/// All Exercises Provider (Future)
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getAll();
});

/// Exercises Stream Provider (Real-time)
final exercisesStreamProvider = StreamProvider<List<Exercise>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchAll();
});

/// Exercise by ID Provider
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, id) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getById(id);
});

/// Exercise Notifier State
class ExerciseNotifierState {
  final bool isLoading;
  final String? error;

  const ExerciseNotifierState({
    this.isLoading = false,
    this.error,
  });

  ExerciseNotifierState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ExerciseNotifierState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Exercise Notifier for CRUD operations
class ExerciseNotifier extends Notifier<ExerciseNotifierState> {
  final Uuid _uuid = const Uuid();

  @override
  ExerciseNotifierState build() {
    return const ExerciseNotifierState();
  }

  ExerciseRepository get _repository => ref.read(exerciseRepositoryProvider);

  /// Create new exercise
  Future<Exercise?> createExercise({
    required String name,
    int? targetReps,
    Duration? targetTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exercise = Exercise(
        id: _uuid.v4(),
        name: name.trim(),
        targetReps: targetReps,
        targetTime: targetTime,
        createdAt: DateTime.now(),
      );
      await _repository.create(exercise);
      state = state.copyWith(isLoading: false);
      ref.invalidate(exercisesProvider);
      ref.invalidate(exercisesStreamProvider);
      return exercise;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update exercise
  Future<bool> updateExercise(Exercise exercise) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.update(exercise);
      state = state.copyWith(isLoading: false);
      ref.invalidate(exercisesProvider);
      ref.invalidate(exercisesStreamProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete exercise
  Future<bool> deleteExercise(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.delete(id);
      state = state.copyWith(isLoading: false);
      ref.invalidate(exercisesProvider);
      ref.invalidate(exercisesStreamProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Seed default calisthenics exercises if database is empty
  Future<void> seedDefaultExercisesIfEmpty() async {
    try {
      final exercises = await _repository.getAll();
      if (exercises.isNotEmpty) return;

      // Add the 4 basic calisthenics exercises
      final defaults = [
        Exercise(
          id: _uuid.v4(),
          name: 'Pull Ups',
          targetReps: 10,
          createdAt: DateTime.now(),
        ),
        Exercise(
          id: _uuid.v4(),
          name: 'Dips',
          targetReps: 10,
          createdAt: DateTime.now(),
        ),
        Exercise(
          id: _uuid.v4(),
          name: 'Push Ups',
          targetReps: 15,
          createdAt: DateTime.now(),
        ),
        Exercise(
          id: _uuid.v4(),
          name: 'Squats',
          targetReps: 15,
          createdAt: DateTime.now(),
        ),
      ];

      for (final exercise in defaults) {
        await _repository.create(exercise);
      }

      ref.invalidate(exercisesProvider);
      ref.invalidate(exercisesStreamProvider);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}

/// Exercise Notifier Provider
final exerciseNotifierProvider =
    NotifierProvider<ExerciseNotifier, ExerciseNotifierState>(
  ExerciseNotifier.new,
);
