import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/workout',
        name: 'workout',
        builder: (context, state) => const WorkoutScreen(),
      ),
      GoRoute(
        path: '/workout/:exerciseId',
        name: 'workout-exercise',
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId'];
          return WorkoutScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Route Names for type-safe navigation
abstract final class Routes {
  static const home = 'home';
  static const workout = 'workout';
  static const workoutExercise = 'workout-exercise';
  static const settings = 'settings';
}
