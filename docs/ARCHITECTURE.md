# W.A.C.H. Architektur & Projektstruktur

## Clean Architecture Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Screens   │  │   Widgets   │  │  Providers  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Entities   │  │  Use Cases  │  │ Interfaces  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Models    │  │Repositories │  │Data Sources │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Detaillierte Ordnerstruktur

```
wach/
├── .claude/
│   ├── commands/              # KI-Agenten Slash Commands
│   │   ├── review-flutter.md
│   │   ├── implement-feature.md
│   │   ├── fix-bug.md
│   │   ├── write-tests.md
│   │   ├── analyze-architecture.md
│   │   ├── optimize-performance.md
│   │   ├── start-app.md
│   │   └── stop-app.md
│   ├── skills/                # Claude Skills (Auto-Context)
│   │   ├── flutter-clean-arch/
│   │   ├── riverpod-patterns/
│   │   ├── design-system/
│   │   └── sembast-database/
│   ├── learnings/             # Dokumentierte Erkenntnisse
│   │   └── flutter-web-database.md
│   └── settings.json
│
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Pages Deployment
│
├── wach_flutter/              # Flutter App
│   ├── lib/
│   │   ├── main.dart              # App Entry Point
│   │   │
│   │   ├── core/                  # Shared/Core Module
│   │   │   ├── constants/
│   │   │   │   └── app_constants.dart
│   │   │   │
│   │   │   ├── theme/
│   │   │   │   ├── app_theme.dart
│   │   │   │   ├── app_colors.dart
│   │   │   │   └── app_typography.dart
│   │   │   │
│   │   │   ├── database/
│   │   │   │   └── database_service.dart   # sembast DB
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── google_drive_service.dart
│   │   │   │
│   │   │   └── utils/
│   │   │       ├── duration_utils.dart
│   │   │       └── haptic_utils.dart
│   │   │
│   │   ├── features/
│   │   │   │
│   │   │   ├── exercise/          # Exercise Feature Module
│   │   │   │   ├── data/
│   │   │   │   │   ├── models/
│   │   │   │   │   │   └── exercise_model.dart
│   │   │   │   │   ├── repositories/
│   │   │   │   │   │   └── exercise_repository_impl.dart
│   │   │   │   │   └── datasources/
│   │   │   │   │       └── exercise_local_datasource.dart
│   │   │   │   │
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   └── exercise.dart
│   │   │   │   │   └── repositories/
│   │   │   │   │       └── exercise_repository.dart
│   │   │   │   │
│   │   │   │   └── presentation/
│   │   │   │       ├── providers/
│   │   │   │       │   └── exercise_providers.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── exercise_tile.dart
│   │   │   │           ├── add_exercise_modal.dart
│   │   │   │           └── edit_exercise_modal.dart
│   │   │   │
│   │   │   ├── workout/           # Workout/Session Feature Module
│   │   │   │   ├── data/
│   │   │   │   │   ├── models/
│   │   │   │   │   │   └── session_model.dart
│   │   │   │   │   └── datasources/
│   │   │   │   │       └── session_local_datasource.dart
│   │   │   │   │
│   │   │   │   ├── domain/
│   │   │   │   │   └── entities/
│   │   │   │   │       ├── workout_session.dart
│   │   │   │   │       └── set_record.dart
│   │   │   │   │
│   │   │   │   └── presentation/
│   │   │   │       ├── providers/
│   │   │   │       │   ├── session_providers.dart
│   │   │   │       │   ├── timer_provider.dart
│   │   │   │       │   ├── lock_mode_provider.dart
│   │   │   │       │   └── tap_zone_provider.dart
│   │   │   │       ├── screens/
│   │   │   │       │   └── workout_screen.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── workout_timer.dart
│   │   │   │           └── session_history_modal.dart
│   │   │   │
│   │   │   ├── settings/          # Settings Feature
│   │   │   │   ├── data/
│   │   │   │   │   ├── settings_provider.dart
│   │   │   │   │   └── sync_provider.dart
│   │   │   │   └── presentation/
│   │   │   │       └── screens/
│   │   │   │           └── settings_screen.dart
│   │   │   │
│   │   │   └── home/              # Home/Dashboard Feature
│   │   │       └── presentation/
│   │   │           └── screens/
│   │   │               └── home_screen.dart
│   │   │
│   │   └── shared/                # Shared Widgets & Navigation
│   │       ├── widgets/
│   │       │   ├── widgets.dart       # Barrel Export
│   │       │   ├── empty_state.dart
│   │       │   ├── status_bar.dart
│   │       │   ├── chip_button.dart
│   │       │   └── progress_bar.dart
│   │       └── navigation/
│   │           └── app_router.dart
│   │
│   ├── web/                       # Web Platform Config
│   ├── android/                   # Android Platform
│   ├── ios/                       # iOS Platform
│   ├── windows/                   # Windows Platform
│   ├── macos/                     # macOS Platform
│   ├── linux/                     # Linux Platform
│   └── pubspec.yaml
│
├── webhook_server.py          # Remote Access Webhook Server
├── REMOTE_ACCESS.md           # Remote Access Guide
├── README.md
├── REQUIREMENTS.md
├── CONTRIBUTING.md
├── CLAUDE.md
└── ARCHITECTURE.md
```

## Dependency Injection

```dart
// Riverpod Provider Pattern

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Database Service (sembast)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Data Sources
final exerciseLocalDataSourceProvider = Provider<ExerciseLocalDataSource>(
  (ref) => ExerciseLocalDataSourceImpl(ref.watch(databaseServiceProvider)),
);

// Repositories
final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepositoryImpl(ref.watch(exerciseLocalDataSourceProvider)),
);

// Async State (Notifier Pattern)
final exercisesProvider = AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(
  () => ExercisesNotifier(),
);
```

## State Management Flow

```
User Action
    │
    ▼
┌─────────────┐
│   Widget    │  (UI Event)
└─────────────┘
    │
    ▼
┌─────────────┐
│  Provider   │  (State Notifier)
└─────────────┘
    │
    ▼
┌─────────────┐
│  Use Case   │  (Business Logic)
└─────────────┘
    │
    ▼
┌─────────────┐
│ Repository  │  (Data Access)
└─────────────┘
    │
    ▼
┌─────────────┐
│ DataSource  │  (sembast DB)
└─────────────┘
```

## Kernentitäten

### Exercise
```dart
class Exercise {
  final int id;
  final String name;
  final int? targetReps;
  final Duration? targetTime;
  final DateTime createdAt;
  final DateTime? lastPerformedAt;
}
```

### WorkoutSession
```dart
class WorkoutSession {
  final int id;
  final int exerciseId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int totalReps;
  final Duration totalTime;
  final List<SetRecord> sets;
  final bool isCompleted;
}
```

### SetRecord
```dart
class SetRecord {
  final int reps;
  final DateTime recordedAt;
}
```

## Implementation Status

### Phase 1: Foundation ✅
- [x] Flutter Projekt Setup
- [x] sembast Database Konfiguration
- [x] Riverpod 3.x Setup
- [x] Theme & Design System
- [x] GoRouter Navigation

### Phase 2: Exercise Feature ✅
- [x] Exercise Entity & Model
- [x] Exercise Repository
- [x] Exercise CRUD Operations
- [x] Exercise UI (List, Add/Edit Modal)

### Phase 3: Workout Feature ✅
- [x] Session Entity & Model
- [x] Timer Logic (Stopwatch/Countdown)
- [x] Session Repository
- [x] Lock/Unlock Modus
- [x] Rep Tracking mit Tap-Zonen
- [x] Session History

### Phase 4: Progressive Overload ✅
- [x] Last Session Query
- [x] Suggestion Algorithm
- [x] Countdown from Previous Time
- [x] Visual Indicators

### Phase 5: Polish & Deployment ✅
- [x] Settings Screen
- [x] GitHub Pages Deployment
- [x] Remote Access (Webhook Server)
- [x] Shared UI Components
- [ ] Testing (Unit, Widget, Integration)
