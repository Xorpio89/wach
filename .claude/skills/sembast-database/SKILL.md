---
name: sembast-database-patterns
description: Use sembast for local NoSQL database with Web support. Use when implementing data persistence, migrations, or database queries. Works on all platforms including Web via IndexedDB.
---

# Sembast Database Patterns

## Why Sembast?

- Full Web compatibility (IndexedDB backend)
- No native code required
- Works on: iOS, Android, Web, Windows, macOS, Linux
- NoSQL document store with simple API

## Setup

### Dependencies
```yaml
dependencies:
  sembast: ^3.6.0
  sembast_web: ^2.2.0  # For web support
  path_provider: ^2.1.0
```

### Database Initialization
```dart
Future<Database> openDatabase() async {
  if (kIsWeb) {
    return databaseFactoryWeb.openDatabase('wach_db');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase(
      p.join(dir.path, 'wach.db'),
    );
  }
}
```

## Store Definitions

```dart
// Integer key store (auto-increment)
final workoutStore = intMapStoreFactory.store('workouts');

// String key store
final settingsStore = stringMapStoreFactory.store('settings');
```

## CRUD Operations

### Create
```dart
final key = await workoutStore.add(db, workout.toMap());
```

### Read
```dart
// Single record
final record = await workoutStore.record(id).get(db);

// All records
final records = await workoutStore.find(db);

// With filter
final records = await workoutStore.find(
  db,
  finder: Finder(
    filter: Filter.equals('isActive', true),
    sortOrders: [SortOrder('timestamp', false)],
  ),
);
```

### Update
```dart
await workoutStore.record(id).update(db, workout.toMap());
```

### Delete
```dart
await workoutStore.record(id).delete(db);
```

## Transactions

```dart
await db.transaction((txn) async {
  await workoutStore.add(txn, workout1.toMap());
  await workoutStore.add(txn, workout2.toMap());
});
```

## Repository Pattern

```dart
class WorkoutRepositoryImpl implements WorkoutRepository {
  final Database _db;
  final _store = intMapStoreFactory.store('workouts');

  WorkoutRepositoryImpl(this._db);

  @override
  Future<List<Workout>> getAll() async {
    final records = await _store.find(_db);
    return records.map((r) => Workout.fromMap(r.value)).toList();
  }

  @override
  Future<void> save(Workout workout) async {
    await _store.record(workout.id).put(_db, workout.toMap());
  }
}
```

## Web-specific Notes

- IndexedDB storage is per-origin AND per-port
- Use consistent port (8080) for development
- Data persists across browser sessions
- Clear with browser dev tools if needed
