---
name: riverpod-state-management
description: Use Riverpod 3.x with Notifier pattern for state management. Use when creating providers, managing app state, or building reactive widgets. Apply to workout sessions, exercise lists, user preferences.
---

# Riverpod State Management Patterns

## Project Configuration

- Framework: Flutter with Riverpod 3.x
- Pattern: Notifier/AsyncNotifier pattern preferred
- Integration: Used throughout W.A.C.H. app

## Provider Types

### Simple State
```dart
final counterProvider = StateProvider<int>((ref) => 0);
```

### Async Data
```dart
final workoutProvider = FutureProvider<Workout>((ref) async {
  return await ref.watch(workoutRepositoryProvider).getLatest();
});
```

### Notifier Pattern (Recommended)
```dart
class WorkoutNotifier extends Notifier<WorkoutState> {
  @override
  WorkoutState build() => WorkoutState.initial();

  Future<void> startSession() async {
    state = state.copyWith(isRunning: true);
  }
}

final workoutProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(
  WorkoutNotifier.new,
);
```

### AsyncNotifier for Data Loading
```dart
class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async {
    return await ref.watch(exerciseRepositoryProvider).getAll();
  }

  Future<void> add(Exercise exercise) async {
    state = const AsyncLoading();
    await ref.read(exerciseRepositoryProvider).save(exercise);
    ref.invalidateSelf();
  }
}
```

## Best Practices

1. Keep providers in `presentation/providers/`
2. Business logic stays in domain use cases
3. Providers orchestrate, don't contain logic
4. Use `ref.watch` for reactive updates
5. Use `ref.read` for one-time actions
6. Invalidate with `ref.invalidateSelf()` after mutations

## Widget Integration

```dart
class WorkoutScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider);
    return workout.when(
      data: (data) => WorkoutView(data),
      loading: () => const LoadingWidget(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```
