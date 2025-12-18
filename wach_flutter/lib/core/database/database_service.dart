import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';

import '../constants/app_constants.dart';

/// Database Service for sembast operations
/// Supports Web, Mobile, and Desktop platforms
class DatabaseService {
  static Database? _database;
  static bool _initialized = false;

  // Store references (like SQL tables)
  static final exercisesStore = stringMapStoreFactory.store('exercises');
  static final sessionsStore = stringMapStoreFactory.store('sessions');
  static final setRecordsStore = stringMapStoreFactory.store('set_records');
  static final settingsStore = stringMapStoreFactory.store('settings');

  /// Get database instance (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;

    debugPrint('[DB] Initializing database...');
    _database = await _initDatabase();
    debugPrint('[DB] Database initialized successfully');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    debugPrint('[DB] _initDatabase starting...');
    debugPrint('[DB] Platform is web: $kIsWeb');

    if (kIsWeb) {
      // Web: Use IndexedDB via sembast_web
      debugPrint('[DB] Opening web database...');
      final factory = databaseFactoryWeb;
      return await factory.openDatabase(AppConstants.dbName);
    } else {
      // Mobile/Desktop: Use file-based storage
      debugPrint('[DB] Opening file database...');
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, AppConstants.dbName);
      debugPrint('[DB] Database path: $dbPath');
      return await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  /// Close database
  Future<void> close() async {
    debugPrint('[DB] Closing database...');
    await _database?.close();
    _database = null;
    _initialized = false;
    debugPrint('[DB] Database closed');
  }

  /// Clear all data from all stores (factory reset)
  Future<void> clearAllData() async {
    debugPrint('[DB] Clearing all data...');
    final db = await database;

    // Delete all records from each store
    await exercisesStore.delete(db);
    await sessionsStore.delete(db);
    await setRecordsStore.delete(db);

    debugPrint('[DB] All data cleared');
  }

  /// Initialize database factory (kept for compatibility, now a no-op)
  static Future<void> initializeDatabaseFactory() async {
    if (_initialized) return;
    debugPrint('[DB] Database factory initialized (sembast)');
    _initialized = true;
  }
}
