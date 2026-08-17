import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../data/datasources/session_local_datasource.dart';
import '../../data/models/session_model.dart';

part 'session_providers.g.dart';

/// Session datasource provider
@Riverpod(keepAlive: true)
SessionLocalDataSource sessionDataSource(Ref ref) {
  return SessionLocalDataSource(ref.watch(databaseServiceProvider));
}

/// All sessions stream provider
@Riverpod(keepAlive: true)
Stream<List<SessionModel>> sessionsStream(Ref ref) async* {
  yield await ref.watch(sessionDataSourceProvider).getAll();
}

/// Recent sessions provider (for home screen)
@Riverpod(keepAlive: true)
Future<List<SessionModel>> recentSessions(Ref ref) {
  return ref.watch(sessionDataSourceProvider).getRecent(limit: 10);
}

/// Session notifier for mutations
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
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
    final dataSource = ref.read(sessionDataSourceProvider);
    await dataSource.insert(session);
    await _loadSessions();
    // Invalidate recent sessions too
    ref.invalidate(recentSessionsProvider);
  }

  Future<void> deleteSession(String id) async {
    final dataSource = ref.read(sessionDataSourceProvider);
    await dataSource.delete(id);
    await _loadSessions();
    ref.invalidate(recentSessionsProvider);
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
