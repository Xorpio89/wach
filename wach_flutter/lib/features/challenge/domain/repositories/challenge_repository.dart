import '../entities/challenge.dart';

/// Challenge Repository - Domain Layer (abstract contract)
abstract class ChallengeRepository {
  Future<List<Challenge>> getAll();
  Future<Challenge?> getById(String id);
  Future<Challenge> create(Challenge challenge);
  Future<Challenge> update(Challenge challenge);
  Future<void> delete(String id);
  Stream<List<Challenge>> watchAll();
}
