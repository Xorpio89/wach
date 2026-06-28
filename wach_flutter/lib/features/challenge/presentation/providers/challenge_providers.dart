import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../exercise/presentation/providers/exercise_providers.dart'
    show databaseServiceProvider;
import '../../data/datasources/challenge_local_datasource.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';

/// Challenge Local DataSource Provider
final challengeLocalDataSourceProvider =
    Provider<ChallengeLocalDataSource>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ChallengeLocalDataSource(dbService);
});

/// Challenge Repository Provider
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final dataSource = ref.watch(challengeLocalDataSourceProvider);
  return ChallengeRepositoryImpl(dataSource);
});

/// All Challenges Provider
final challengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getAll();
});

/// Single Challenge Provider (by id)
final challengeByIdProvider =
    FutureProvider.family<Challenge?, String>((ref, id) async {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getById(id);
});

/// Challenge Notifier for CRUD + progress operations.
/// State is a simple `isLoading` flag.
class ChallengeNotifier extends Notifier<bool> {
  final Uuid _uuid = const Uuid();

  @override
  bool build() => false;

  ChallengeRepository get _repository => ref.read(challengeRepositoryProvider);

  Future<Challenge?> createChallenge({
    required String name,
    int? periodDays,
    required List<ChallengeItem> items,
  }) async {
    state = true;
    try {
      final challenge = Challenge(
        id: _uuid.v4(),
        name: name.trim(),
        periodDays: periodDays,
        createdAt: DateTime.now(),
        items: items,
      );
      await _repository.create(challenge);
      _invalidate();
      return challenge;
    } catch (_) {
      return null;
    } finally {
      state = false;
    }
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _repository.update(challenge);
    _invalidate(id: challenge.id);
  }

  Future<void> deleteChallenge(String id) async {
    await _repository.delete(id);
    _invalidate(id: id);
  }

  /// Add (or subtract, if negative) reps to a single item and persist.
  Future<void> addReps(Challenge challenge, String itemId, int reps) async {
    final items = challenge.items.map((item) {
      if (item.id != itemId) return item;
      final next = (item.doneReps + reps).clamp(0, item.targetReps);
      return item.copyWith(doneReps: next);
    }).toList();
    await updateChallenge(challenge.copyWith(items: items));
  }

  /// Set the absolute done-reps value for an item (used when tapping boxes).
  Future<void> setDone(Challenge challenge, String itemId, int doneReps) async {
    final items = challenge.items.map((item) {
      if (item.id != itemId) return item;
      final next = doneReps.clamp(0, item.targetReps);
      return item.copyWith(doneReps: next);
    }).toList();
    await updateChallenge(challenge.copyWith(items: items));
  }

  /// Create the ready-made 1-week calisthenics volume challenge.
  Future<Challenge?> createCalisthenicsTemplate() {
    return createChallenge(
      name: '1-Week Calisthenics Challenge',
      periodDays: 7,
      items: [
        ChallengeItem(id: _uuid.v4(), name: 'Klimmzüge', targetReps: 700),
        ChallengeItem(id: _uuid.v4(), name: 'Liegestütze', targetReps: 1200),
        ChallengeItem(id: _uuid.v4(), name: 'Dips', targetReps: 1000),
      ],
    );
  }

  void _invalidate({String? id}) {
    ref.invalidate(challengesProvider);
    if (id != null) ref.invalidate(challengeByIdProvider(id));
  }
}

final challengeNotifierProvider =
    NotifierProvider<ChallengeNotifier, bool>(ChallengeNotifier.new);
