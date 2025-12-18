---
name: flutter-clean-architecture
description: Apply Clean Architecture patterns to Flutter features. Use when creating new features, organizing code structure, or implementing repositories and use cases. Follow feature-based folder structure with data/domain/presentation layers.
---

# Flutter Clean Architecture

## When to Use

Use this Skill when:
- Creating new features (workout, exercises, settings)
- Organizing code into layers
- Implementing repositories and use cases
- Setting up data sources

## Structure Pattern

```
lib/features/{feature}/
├── data/
│   ├── data_sources/      # Local/remote data access
│   ├── models/            # Data transfer objects
│   └── repositories/      # Repository implementations
├── domain/
│   ├── entities/          # Business objects
│   ├── repositories/      # Repository interfaces
│   └── use_cases/         # Business logic
└── presentation/
    ├── screens/           # Full page widgets
    ├── widgets/           # Feature-specific widgets
    └── providers/         # Riverpod providers
```

## Naming Conventions

- Screens: `*Screen` suffix (e.g., `WorkoutScreen`)
- Widgets: `*Widget` or descriptive name (e.g., `ProgressTile`)
- Controllers/Providers: `*Controller` or `*Notifier`
- Repositories: `*Repository` interface, `*RepositoryImpl` implementation
- Use Cases: Verb + Noun (e.g., `GetWorkoutHistory`, `StartSession`)

## Code Style

- Max line length: 80 characters
- Use `const` constructors always
- `snake_case` for filenames
- `PascalCase` for classes
- `camelCase` for variables and functions

## Example: New Feature Implementation

1. Create folder structure under `lib/features/{name}/`
2. Define entities in `domain/entities/`
3. Create repository interface in `domain/repositories/`
4. Implement repository in `data/repositories/`
5. Create use cases in `domain/use_cases/`
6. Build providers in `presentation/providers/`
7. Create screens and widgets in `presentation/`
