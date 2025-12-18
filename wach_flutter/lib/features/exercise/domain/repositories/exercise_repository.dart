import '../entities/exercise.dart';

/// Exercise Repository Interface - Domain Layer
/// Defines the contract for exercise data operations
abstract class ExerciseRepository {
  /// Get all exercises
  Future<List<Exercise>> getAll();

  /// Get exercise by ID
  Future<Exercise?> getById(String id);

  /// Create new exercise
  Future<Exercise> create(Exercise exercise);

  /// Update existing exercise
  Future<Exercise> update(Exercise exercise);

  /// Delete exercise by ID
  Future<void> delete(String id);

  /// Update last performed timestamp
  Future<void> updateLastPerformed(String id, DateTime timestamp);

  /// Watch all exercises (stream for real-time updates)
  Stream<List<Exercise>> watchAll();
}
