import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/database_service.dart';
import '../../exercise/presentation/providers/exercise_providers.dart';

/// Available quick chip exercises
class QuickChipExercise {
  final String name;
  final IconData icon;
  final int defaultReps;

  const QuickChipExercise({
    required this.name,
    required this.icon,
    required this.defaultReps,
  });
}

/// All available quick chip exercises
const allQuickChipExercises = [
  QuickChipExercise(name: 'Pull Ups', icon: Icons.fitness_center_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Chin Ups', icon: Icons.fitness_center_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Dips', icon: Icons.fitness_center_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Push Ups', icon: Icons.sports_gymnastics_rounded, defaultReps: 15),
  QuickChipExercise(name: 'Rows', icon: Icons.rowing_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Squats', icon: Icons.directions_walk_rounded, defaultReps: 15),
  QuickChipExercise(name: 'Lunges', icon: Icons.directions_run_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Leg Raises', icon: Icons.accessibility_new_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Pike Push Ups', icon: Icons.arrow_downward_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Diamond Push Ups', icon: Icons.change_history_rounded, defaultReps: 12),
  QuickChipExercise(name: 'Plank', icon: Icons.straighten_rounded, defaultReps: 60),
  QuickChipExercise(name: 'Burpees', icon: Icons.local_fire_department_rounded, defaultReps: 10),
];

/// Default calisthenics exercises (auto-created on first start)
const defaultCalisthenicsExercises = [
  QuickChipExercise(name: 'Pull Ups', icon: Icons.fitness_center_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Dips', icon: Icons.fitness_center_rounded, defaultReps: 10),
  QuickChipExercise(name: 'Push Ups', icon: Icons.sports_gymnastics_rounded, defaultReps: 15),
  QuickChipExercise(name: 'Squats', icon: Icons.directions_walk_rounded, defaultReps: 15),
];

/// Default enabled chips (complementary to the 4 basics)
const defaultEnabledChips = [
  'Chin Ups',
  'Rows',
  'Pike Push Ups',
  'Lunges',
  'Leg Raises',
  'Diamond Push Ups',
];

/// Settings state
class QuickChipSettings {
  final List<String> enabledChips;

  const QuickChipSettings({
    this.enabledChips = const [],
  });

  QuickChipSettings copyWith({List<String>? enabledChips}) {
    return QuickChipSettings(
      enabledChips: enabledChips ?? this.enabledChips,
    );
  }

  /// Get enabled exercises as QuickChipExercise objects
  List<QuickChipExercise> get enabledExercises {
    return allQuickChipExercises
        .where((e) => enabledChips.contains(e.name))
        .toList();
  }
}

/// Quick chip settings notifier
class QuickChipSettingsNotifier extends AsyncNotifier<QuickChipSettings> {
  @override
  Future<QuickChipSettings> build() async {
    return _loadSettings();
  }

  Future<QuickChipSettings> _loadSettings() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = await dbService.database;

      final record = await DatabaseService.settingsStore
          .record('quick_chips')
          .get(db);

      if (record == null) {
        // Return defaults
        return const QuickChipSettings(enabledChips: defaultEnabledChips);
      }

      final chips = (record['enabled'] as List?)?.cast<String>() ?? defaultEnabledChips;
      return QuickChipSettings(enabledChips: chips);
    } catch (e) {
      return const QuickChipSettings(enabledChips: defaultEnabledChips);
    }
  }

  Future<void> _saveSettings(List<String> enabledChips) async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = await dbService.database;

      await DatabaseService.settingsStore.record('quick_chips').put(db, {
        'enabled': enabledChips,
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> toggleChip(String chipName) async {
    final current = state.value ?? const QuickChipSettings(enabledChips: defaultEnabledChips);
    final chips = List<String>.from(current.enabledChips);

    if (chips.contains(chipName)) {
      chips.remove(chipName);
    } else {
      chips.add(chipName);
    }

    await _saveSettings(chips);
    state = AsyncValue.data(current.copyWith(enabledChips: chips));
  }

  Future<void> enableAll() async {
    final allNames = allQuickChipExercises.map((e) => e.name).toList();
    await _saveSettings(allNames);
    state = AsyncValue.data(QuickChipSettings(enabledChips: allNames));
  }

  Future<void> disableAll() async {
    await _saveSettings([]);
    state = const AsyncValue.data(QuickChipSettings(enabledChips: []));
  }

  Future<void> resetToDefaults() async {
    await _saveSettings(defaultEnabledChips);
    state = const AsyncValue.data(QuickChipSettings(enabledChips: defaultEnabledChips));
  }
}

final quickChipSettingsProvider =
    AsyncNotifierProvider<QuickChipSettingsNotifier, QuickChipSettings>(
  QuickChipSettingsNotifier.new,
);

/// Workout settings state
class WorkoutSettings {
  final bool autoStartTimerOnFirstRep;

  const WorkoutSettings({
    this.autoStartTimerOnFirstRep = true,
  });

  WorkoutSettings copyWith({bool? autoStartTimerOnFirstRep}) {
    return WorkoutSettings(
      autoStartTimerOnFirstRep: autoStartTimerOnFirstRep ?? this.autoStartTimerOnFirstRep,
    );
  }
}

/// Workout settings notifier
class WorkoutSettingsNotifier extends AsyncNotifier<WorkoutSettings> {
  @override
  Future<WorkoutSettings> build() async {
    return _loadSettings();
  }

  Future<WorkoutSettings> _loadSettings() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = await dbService.database;

      final record = await DatabaseService.settingsStore
          .record('workout_settings')
          .get(db);

      if (record == null) {
        return const WorkoutSettings();
      }

      return WorkoutSettings(
        autoStartTimerOnFirstRep: record['autoStartTimerOnFirstRep'] as bool? ?? true,
      );
    } catch (e) {
      return const WorkoutSettings();
    }
  }

  Future<void> _saveSettings(WorkoutSettings settings) async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = await dbService.database;

      await DatabaseService.settingsStore.record('workout_settings').put(db, {
        'autoStartTimerOnFirstRep': settings.autoStartTimerOnFirstRep,
      });
    } catch (e) {
      debugPrint('[WorkoutSettings] Save failed: $e');
    }
  }

  Future<void> setAutoStartTimer(bool value) async {
    final current = state.value ?? const WorkoutSettings();
    final updated = current.copyWith(autoStartTimerOnFirstRep: value);
    await _saveSettings(updated);
    state = AsyncValue.data(updated);
  }
}

final workoutSettingsProvider =
    AsyncNotifierProvider<WorkoutSettingsNotifier, WorkoutSettings>(
  WorkoutSettingsNotifier.new,
);
