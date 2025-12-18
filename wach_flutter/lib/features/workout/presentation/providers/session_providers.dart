import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/session_local_datasource.dart';
import '../../data/models/session_model.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';

/// Session datasource provider
final sessionDataSourceProvider = Provider<SessionLocalDataSource>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SessionLocalDataSource(dbService);
});

/// All sessions stream provider
final sessionsStreamProvider = StreamProvider<List<SessionModel>>((ref) async* {
  final dataSource = ref.watch(sessionDataSourceProvider);
  // Initial fetch
  yield await dataSource.getAll();
});

/// Recent sessions provider (for home screen)
final recentSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  final dataSource = ref.watch(sessionDataSourceProvider);
  return dataSource.getRecent(limit: 10);
});

/// Session notifier for mutations
class SessionNotifier extends Notifier<AsyncValue<List<SessionModel>>> {
  @override
  AsyncValue<List<SessionModel>> build() {
    _loadSessions();
    return const AsyncValue.loading();
  }

  Future<void> _loadSessions() async {
    try {
      final dataSource = ref.read(sessionDataSourceProvider);
      final sessions = await dataSource.getAll();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveSession(SessionModel session) async {
    try {
      final dataSource = ref.read(sessionDataSourceProvider);
      await dataSource.insert(session);
      await _loadSessions();
      // Invalidate recent sessions too
      ref.invalidate(recentSessionsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final dataSource = ref.read(sessionDataSourceProvider);
      await dataSource.delete(id);
      await _loadSessions();
      ref.invalidate(recentSessionsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadSessions();
  }

  /// Get all sessions (for sync)
  Future<List<SessionModel>> getAllSessions() async {
    final dataSource = ref.read(sessionDataSourceProvider);
    return dataSource.getAll();
  }

  /// Add a single session (for restore)
  Future<void> addSession(SessionModel session) async {
    final dataSource = ref.read(sessionDataSourceProvider);
    await dataSource.insert(session);
  }

  /// Clear all sessions (for restore with replace)
  Future<void> clearAllSessions() async {
    final dataSource = ref.read(sessionDataSourceProvider);
    await dataSource.deleteAll();
  }
}

final sessionNotifierProvider =
    NotifierProvider<SessionNotifier, AsyncValue<List<SessionModel>>>(
  SessionNotifier.new,
);
