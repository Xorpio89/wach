# Flutter Web Database - Learnings

## Problem: sqflite_common_ffi_web funktioniert nicht zuverlässig

**Datum:** 2025-12-17
**Projekt:** W.A.C.H.

### Symptome

1. **Initiale Fehler mit Web Worker:**
   ```
   An error occurred while initializing the web worker.
   This is likely due to a failure to find the worker javascript file at sqflite_sw.js
   ```

2. **Nach Web Worker Setup:**
   ```
   DartError: unsupported result null (null)
   at database_mixin.dart:973:7
   ```

3. **Mit NoWebWorker-Variante:**
   ```
   TypeError: WebAssembly.instantiate(): Import #25 "env": module is not an object or function
   ```

### Ursache

- `sqflite_common_ffi_web` verwendet WebAssembly (WASM) für SQLite im Browser
- Die WASM-Module laden nicht korrekt oder sind inkompatibel
- Das Package hat bekannte Probleme mit neueren Flutter/Dart Versionen
- Web Worker und WASM-Initialisierung sind fehleranfällig

### Lösung: Wechsel zu sembast

**sembast** ist eine NoSQL-Datenbank die nativ für Dart entwickelt wurde und zuverlässig auf allen Plattformen funktioniert.

#### Änderungen in pubspec.yaml:

```yaml
# VORHER (problematisch)
sqflite: ^2.4.1
sqflite_common_ffi_web: ^0.4.5+2

# NACHHER (funktioniert)
sembast: ^3.7.3
sembast_web: ^2.3.0
```

#### DatabaseService mit sembast:

```dart
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';

class DatabaseService {
  static Database? _database;

  // Stores statt SQL-Tabellen
  static final exercisesStore = stringMapStoreFactory.store('exercises');
  static final sessionsStore = stringMapStoreFactory.store('sessions');

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Web: IndexedDB via sembast_web
      final factory = databaseFactoryWeb;
      return await factory.openDatabase('app.db');
    } else {
      // Mobile/Desktop: File-based
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'app.db');
      return await databaseFactoryIo.openDatabase(dbPath);
    }
  }
}
```

#### DataSource Migration:

```dart
// VORHER (sqflite)
final maps = await db.query('exercises', orderBy: 'created_at DESC');

// NACHHER (sembast)
final finder = Finder(sortOrders: [SortOrder('created_at', false)]);
final records = await _store.find(db, finder: finder);
```

### Vorteile von sembast

1. **Zuverlässig auf Web** - Keine WASM/WebWorker-Probleme
2. **Einfachere API** - NoSQL statt SQL
3. **Gute Performance** - Optimiert für Dart
4. **Kleiner Bundle Size** - Kein WASM nötig
5. **Konsistent** - Gleiche API auf allen Plattformen

### Nachteile von sembast

1. **NoSQL** - Keine SQL-Abfragen, andere Denkweise
2. **Keine Foreign Keys** - Referenzielle Integrität muss manuell gehandhabt werden
3. **Weniger bekannt** - Kleinere Community als SQLite

### Wann sqflite trotzdem verwenden

- Nur Mobile/Desktop (kein Web)
- Komplexe relationale Daten
- Bestehende SQL-Expertise im Team
- Migration von bestehender SQLite-DB

### Tags

#flutter #web #database #sqflite #sembast #webassembly #indexeddb
