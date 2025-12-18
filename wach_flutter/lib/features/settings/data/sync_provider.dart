import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/google_drive_service.dart';
import '../../exercise/presentation/providers/exercise_providers.dart';
import '../../workout/presentation/providers/session_providers.dart';

/// Sync state
class SyncState {
  final bool isEnabled;
  final bool isSignedIn;
  final String? userEmail;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final String? error;
  final BackupInfo? backupInfo;

  const SyncState({
    this.isEnabled = false,
    this.isSignedIn = false,
    this.userEmail,
    this.lastSyncTime,
    this.isSyncing = false,
    this.error,
    this.backupInfo,
  });

  SyncState copyWith({
    bool? isEnabled,
    bool? isSignedIn,
    String? userEmail,
    DateTime? lastSyncTime,
    bool? isSyncing,
    String? error,
    BackupInfo? backupInfo,
    bool clearError = false,
    bool clearBackupInfo = false,
  }) {
    return SyncState(
      isEnabled: isEnabled ?? this.isEnabled,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      userEmail: userEmail ?? this.userEmail,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      backupInfo: clearBackupInfo ? null : (backupInfo ?? this.backupInfo),
    );
  }
}

/// Sync notifier
class SyncNotifier extends Notifier<SyncState> {
  GoogleDriveService? _driveService;

  GoogleDriveService get driveService {
    _driveService ??= GoogleDriveService();
    return _driveService!;
  }

  @override
  SyncState build() {
    _initializeAsync();
    return const SyncState();
  }

  void _initializeAsync() {
    Future.microtask(() => _initialize());
  }

  Future<void> _initialize() async {
    // Load settings
    final settings = await _loadSettings();
    final isEnabled = settings['autoSync'] as bool? ?? false;
    final lastSyncTime = settings['lastSyncTime'] != null
        ? DateTime.tryParse(settings['lastSyncTime'] as String)
        : null;

    state = state.copyWith(
      isEnabled: isEnabled,
      lastSyncTime: lastSyncTime,
    );

    // Try silent sign-in if enabled
    if (isEnabled) {
      try {
        final success = await driveService.initialize();
        if (success) {
          state = state.copyWith(
            isSignedIn: true,
            userEmail: driveService.userEmail,
          );
          // Fetch backup info
          await _fetchBackupInfo();
        }
      } catch (e) {
        debugPrint('[Sync] Silent sign-in failed: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = await dbService.database;
      final record = await DatabaseService.settingsStore
          .record('sync_settings')
          .get(db);
      return record ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveSettings({bool? autoSync, DateTime? lastSyncTime}) async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = await dbService.database;

      final current = await _loadSettings();
      if (autoSync != null) current['autoSync'] = autoSync;
      if (lastSyncTime != null) {
        current['lastSyncTime'] = lastSyncTime.toIso8601String();
      }

      await DatabaseService.settingsStore
          .record('sync_settings')
          .put(db, current);
    } catch (e) {
      debugPrint('[Sync] Save settings failed: $e');
    }
  }

  /// Enable auto-sync (triggers sign-in if needed)
  Future<bool> enableSync() async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // Sign in if not already
      if (!driveService.isSignedIn) {
        final success = await driveService.signIn();
        if (!success) {
          state = state.copyWith(
            isSyncing: false,
            error: 'Sign-in cancelled or failed',
          );
          return false;
        }
      }

      // Save settings and update state
      await _saveSettings(autoSync: true);
      state = state.copyWith(
        isEnabled: true,
        isSignedIn: true,
        userEmail: driveService.userEmail,
        isSyncing: false,
      );

      // Fetch backup info
      await _fetchBackupInfo();

      // Perform initial sync
      await syncNow();

      return true;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Disable auto-sync
  Future<void> disableSync() async {
    await driveService.signOut();
    await _saveSettings(autoSync: false);
    state = state.copyWith(
      isEnabled: false,
      isSignedIn: false,
      userEmail: null,
      clearBackupInfo: true,
    );
  }

  /// Sync sessions now
  Future<bool> syncNow() async {
    if (!driveService.isSignedIn) return false;

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // Get local sessions
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      final localSessions = await sessionNotifier.getAllSessions();

      // Upload to Drive
      final success = await driveService.uploadSessions(localSessions);

      if (success) {
        final now = DateTime.now();
        await _saveSettings(lastSyncTime: now);
        await _fetchBackupInfo();
        state = state.copyWith(
          isSyncing: false,
          lastSyncTime: now,
        );
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          error: 'Upload failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Restore sessions from cloud
  Future<RestoreResult> restoreFromCloud({bool merge = false}) async {
    if (!driveService.isSignedIn) {
      return RestoreResult(success: false, error: 'Not signed in');
    }

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // Download backup
      final backup = await driveService.downloadSessions();
      if (backup == null) {
        state = state.copyWith(isSyncing: false);
        return RestoreResult(
          success: false,
          error: 'No backup found in cloud',
        );
      }

      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

      if (merge) {
        // Merge: add cloud sessions that don't exist locally
        final localSessions = await sessionNotifier.getAllSessions();
        final localIds = localSessions.map((s) => s.id).toSet();

        int added = 0;
        for (final cloudSession in backup.sessions) {
          if (!localIds.contains(cloudSession.id)) {
            await sessionNotifier.addSession(cloudSession);
            added++;
          }
        }

        state = state.copyWith(isSyncing: false);
        return RestoreResult(
          success: true,
          sessionsRestored: added,
          message: 'Merged $added new sessions from cloud',
        );
      } else {
        // Replace: clear local and restore from cloud
        await sessionNotifier.clearAllSessions();

        for (final session in backup.sessions) {
          await sessionNotifier.addSession(session);
        }

        // Refresh providers
        ref.invalidate(sessionNotifierProvider);

        state = state.copyWith(isSyncing: false);
        return RestoreResult(
          success: true,
          sessionsRestored: backup.sessions.length,
          message: 'Restored ${backup.sessions.length} sessions from cloud',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return RestoreResult(success: false, error: e.toString());
    }
  }

  Future<void> _fetchBackupInfo() async {
    final info = await driveService.getBackupInfo();
    state = state.copyWith(backupInfo: info);
  }
}

/// Restore result
class RestoreResult {
  final bool success;
  final int sessionsRestored;
  final String? error;
  final String? message;

  RestoreResult({
    required this.success,
    this.sessionsRestored = 0,
    this.error,
    this.message,
  });
}

/// Sync provider
final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
