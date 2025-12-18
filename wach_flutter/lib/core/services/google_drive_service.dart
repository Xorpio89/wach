import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../../features/workout/data/models/session_model.dart';

/// Google Drive sync service for W.A.C.H. sessions
class GoogleDriveService {
  static const _scopes = [drive.DriveApi.driveAppdataScope];
  static const _backupFileName = 'wach_sessions_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Get current user email
  String? get userEmail => _currentUser?.email;

  /// Initialize and try silent sign in
  Future<bool> initialize() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[GoogleDrive] Silent sign-in failed: $e');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[GoogleDrive] Sign-in failed: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  /// Initialize Drive API with authenticated client
  Future<void> _initDriveApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient != null) {
      _driveApi = drive.DriveApi(httpClient);
    }
  }

  /// Upload sessions to Google Drive
  Future<bool> uploadSessions(List<SessionModel> sessions) async {
    if (_driveApi == null) {
      debugPrint('[GoogleDrive] Not authenticated');
      return false;
    }

    try {
      final backupData = BackupData(
        version: 1,
        exportedAt: DateTime.now(),
        sessions: sessions,
      );

      final jsonString = jsonEncode(backupData.toJson());
      final bytes = utf8.encode(jsonString);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      // Check if file already exists
      final existingFileId = await _findBackupFileId();

      if (existingFileId != null) {
        // Update existing file
        await _driveApi!.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        debugPrint('[GoogleDrive] Updated existing backup');
      } else {
        // Create new file in appDataFolder
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];

        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        debugPrint('[GoogleDrive] Created new backup');
      }

      return true;
    } catch (e) {
      debugPrint('[GoogleDrive] Upload failed: $e');
      return false;
    }
  }

  /// Download sessions from Google Drive
  Future<BackupData?> downloadSessions() async {
    if (_driveApi == null) {
      debugPrint('[GoogleDrive] Not authenticated');
      return null;
    }

    try {
      final fileId = await _findBackupFileId();
      if (fileId == null) {
        debugPrint('[GoogleDrive] No backup file found');
        return null;
      }

      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return BackupData.fromJson(json);
    } catch (e) {
      debugPrint('[GoogleDrive] Download failed: $e');
      return null;
    }
  }

  /// Get backup info without downloading full data
  Future<BackupInfo?> getBackupInfo() async {
    if (_driveApi == null) return null;

    try {
      final fileId = await _findBackupFileId();
      if (fileId == null) return null;

      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'id,name,modifiedTime,size',
      ) as drive.File;

      return BackupInfo(
        lastModified: file.modifiedTime,
        sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
      );
    } catch (e) {
      debugPrint('[GoogleDrive] Get backup info failed: $e');
      return null;
    }
  }

  /// Find the backup file ID in appDataFolder
  Future<String?> _findBackupFileId() async {
    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('[GoogleDrive] Find file failed: $e');
      return null;
    }
  }

  /// Delete backup from Google Drive
  Future<bool> deleteBackup() async {
    if (_driveApi == null) return false;

    try {
      final fileId = await _findBackupFileId();
      if (fileId != null) {
        await _driveApi!.files.delete(fileId);
        debugPrint('[GoogleDrive] Backup deleted');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[GoogleDrive] Delete failed: $e');
      return false;
    }
  }
}

/// Backup data structure
class BackupData {
  final int version;
  final DateTime exportedAt;
  final List<SessionModel> sessions;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.sessions,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'sessions': sessions.map((s) => s.toMap()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int? ?? 1,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      sessions: (json['sessions'] as List)
          .map((s) => SessionModel.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Backup info for display
class BackupInfo {
  final DateTime? lastModified;
  final int sizeBytes;

  BackupInfo({this.lastModified, this.sizeBytes = 0});

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
