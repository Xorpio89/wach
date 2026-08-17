import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_service.dart';
import '../../data/datasources/exercise_local_datasource.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../domain/entities/exercise.dart';
import '../../../settings/data/settings_provider.dart';
import '../../domain/repositories/exercise_repository.dart';

part 'exercise_providers.g.dart';

/// Database Service Provider
@Riverpod(keepAlive: true)
DatabaseService databaseService(Ref ref) {
  return DatabaseService();
}

/// Exercise Local DataSource Provider
@Riverpod(keepAlive: true)
ExerciseLocalDataSource exerciseLocalDataSource(Ref ref) {
  return ExerciseLocalDataSource(ref.watch(databaseServiceProvider));
}

/// Exercise Repository Provider
@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepositoryImpl(ref.watch(exerciseLocalDataSourceProvider));
}

/// All Exercises Provider (Future)
@Riverpod(keepAlive: true)
Future<List<Exercise>> exercises(Ref ref) {
  return ref.watch(exerciseRepositoryProvider).getAll();
}

/// Exercises Stream Provider (Real-time)
@Riverpod(keepAlive: true)
Stream<List<Exercise>> exercisesStream(Ref ref) {
  return ref.watch(exerciseRepositoryProvider).watchAll();
}

/// Exercise by ID Provider
@Riverpod(keepAlive: true)
Future<Exercise?> exerciseById(Ref ref, String id) {
  return ref.watch(exerciseRepositoryProvider).getById(id);
}

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
@Riverpod(keepAlive: true)
class ExerciseNotifier extends _$ExerciseNotifier {
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

      // Die Standarduebungen stehen in `defaultCalisthenicsExercises`.
      // Sie hier noch einmal aufzuzaehlen hiess, dass Namen und Zielwerte
      // an zwei Stellen gepflegt werden mussten — und beim Anheben der
      // Ziele wäre genau eine davon vergessen worden.
      final jetzt = DateTime.now();
      final defaults = [
        for (final vorlage in defaultCalisthenicsExercises)
          Exercise(
            id: _uuid.v4(),
            name: vorlage.name,
            targetReps: vorlage.defaultReps,
            createdAt: jetzt,
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

