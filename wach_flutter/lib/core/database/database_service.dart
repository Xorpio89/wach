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
  static final challengesStore = stringMapStoreFactory.store('challenges');
  static final settingsStore = stringMapStoreFactory.store('settings');
  // 2026-08-07 Bugfix: Reps der LAUFENDEN Session lagen nur im Widget-State
  // (workout_screen `_repsMap`) und waren beim Verlassen des Screens verloren.
  // Der Timer ueberlebte, weil er ein app-weiter Provider ist -> Inkonsistenz.
  static final activeWorkoutStore =
      stringMapStoreFactory.store('active_workout');
  // 2026-08-15: Der Stand der Uhr lag nur im Arbeitsspeicher. Als
  // installierte Web-App wird die Seite vom Handy im Hintergrund entladen
  // und beim Zurueckkehren neu geladen — die Reps kamen dann aus der
  // Datenbank zurueck, die gelaufene Zeit stand wieder auf null.
  static final activeTimerStore = stringMapStoreFactory.store('active_timer');
  // 2026-08-21: Rueckmeldungen werden erst im Geraet gesammelt und spaeter
  // weitergegeben. Beim Training ist oft kein Netz, und ein Einfall
  // zwischen zwei Saetzen ueberlebt keinen Wechsel in den Browser.
  static final feedbackStore = stringMapStoreFactory.store('feedback');

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
    await challengesStore.delete(db);

    debugPrint('[DB] All data cleared');
  }

  /// Initialize database factory (kept for compatibility, now a no-op)
  static Future<void> initializeDatabaseFactory() async {
    if (_initialized) return;
    debugPrint('[DB] Database factory initialized (sembast)');
    _initialized = true;
  }

  /// Setzt die Datenbank von aussen — ausschliesslich fuer Tests.
  ///
  /// Damit laeuft die komplette Kette (Repositories, Provider, Screens)
  /// im Test unveraendert gegen eine In-Memory-Datenbank, statt sie mit
  /// Fakes nachzubauen. Ohne diesen Einstieg wuerde jeder Widget-Test am
  /// `path_provider` scheitern, den es im Testumfeld nicht gibt.
  @visibleForTesting
  static void setDatabaseForTests(Database? db) {
    _database = db;
    _initialized = db != null;
  }
}
