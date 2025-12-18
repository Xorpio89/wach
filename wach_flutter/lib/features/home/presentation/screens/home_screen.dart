import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../workout/presentation/providers/session_providers.dart';
import '../../../workout/presentation/providers/timer_provider.dart';
import '../../../workout/presentation/widgets/session_history_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Logo
              const SizedBox(height: AppConstants.spacingLg),
              Center(
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity( 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity( 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      AppConstants.appName,
                      style: AppTypography.headline1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      AppConstants.appFullName,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingXl),

              // Quick Start Card
              Builder(
                builder: (context) {
                  final timerState = ref.watch(timerProvider);
                  final hasActiveSession = timerState.elapsed > Duration.zero ||
                      timerState.isRunning;
                  final exercisesAsync = ref.watch(exercisesProvider);
                  final hasExercises = exercisesAsync.maybeWhen(
                    data: (exercises) => exercises.isNotEmpty,
                    orElse: () => false,
                  );
                  final sessionsAsync = ref.watch(sessionNotifierProvider);
                  final hasPreviousSession = sessionsAsync.maybeWhen(
                    data: (sessions) => sessions.isNotEmpty,
                    orElse: () => false,
                  );

                  return _QuickStartCard(
                    onTap: () => context.push('/workout'),
                    isContinue: hasActiveSession,
                    isDefaultSetup: !hasExercises && !hasActiveSession,
                    hasPreviousSession: hasPreviousSession && !hasActiveSession,
                  );
                },
              ),

              // History Card (only show if there are sessions)
              Builder(
                builder: (context) {
                  final sessionsAsync = ref.watch(sessionNotifierProvider);
                  final hasSessions = sessionsAsync.maybeWhen(
                    data: (sessions) => sessions.isNotEmpty,
                    orElse: () => false,
                  );

                  if (!hasSessions) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacingMd),
                    child: _HistoryCard(
                      onTap: () => showSessionHistoryModal(context),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Bottom row with version and settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance for settings button
                  Text(
                    'v${AppConstants.appVersion}',
                    style: AppTypography.labelSmall,
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isContinue;
  final bool isDefaultSetup;
  final bool hasPreviousSession;

  const _QuickStartCard({
    required this.onTap,
    this.isContinue = false,
    this.isDefaultSetup = false,
    this.hasPreviousSession = false,
  });

  String get _title {
    if (isContinue) return 'Continue Workout';
    return 'Start Workout';
  }

  String get _subtitle {
    if (isContinue) return 'Resume your active session';
    if (isDefaultSetup) return 'Default calisthenics setup';
    if (hasPreviousSession) return 'Overload your last session';
    return 'Begin your training session';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: isContinue
                ? AppColors.secondary.withOpacity( 0.5)
                : AppColors.primary.withOpacity( 0.3),
            width: isContinue ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isContinue
                        ? AppColors.secondary.withOpacity( 0.2)
                        : AppColors.primary.withOpacity( 0.2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    isContinue
                        ? Icons.play_circle_outline_rounded
                        : Icons.play_arrow_rounded,
                    color: isContinue ? AppColors.secondary : AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: AppTypography.headline3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HistoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: AppColors.secondary.withOpacity( 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity( 0.2),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.secondary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session History',
                    style: AppTypography.headline3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View your past workouts',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
