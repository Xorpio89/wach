import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../exercise/presentation/providers/ziel_anhebung_provider.dart';
import '../../../exercise/presentation/widgets/target_bump_sheet.dart';
import '../../../gamification/presentation/widgets/gamification_bar.dart';
import '../../../workout/presentation/providers/session_providers.dart';
import '../../../workout/presentation/providers/timer_provider.dart';
import '../../../workout/presentation/widgets/session_history_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        // Der Inhalt fuellt den Bildschirm, wenn er passt, und wird
        // scrollbar, wenn nicht. Vorher lief die Spalte auf kurzen
        // Geraeten unten heraus — mit vier Karten und einer grossen
        // Systemschrift reicht die Hoehe sonst nicht.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
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
                                    AppColors.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
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
                            const SizedBox(height: AppConstants.spacingSm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingSm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusSm),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context).homeBetaBadge,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingLg),

                      // Stufe und Serie — steht vor den Karten, damit der
                      // Fortschritt beim Oeffnen als Erstes ins Auge faellt.
                      const GamificationBar(),
                      const SizedBox(height: AppConstants.spacingMd),

                      // Hinweis auf zu niedrige Ziele — antippbar, nie im
                      // Weg. Nach dem Beenden soll nichts erscheinen, was
                      // erst weggetippt werden muss.
                      const _ZielAnhebungHinweis(),

                      // Quick Start Card
                      Builder(
                        builder: (context) {
                          final timerState = ref.watch(sessionTimerProvider);
                          final hasActiveSession =
                              timerState.elapsed > Duration.zero ||
                                  timerState.isRunning;
                          final exercisesAsync = ref.watch(exercisesProvider);
                          final hasExercises = exercisesAsync.maybeWhen(
                            data: (exercises) => exercises.isNotEmpty,
                            orElse: () => false,
                          );
                          final sessionsAsync =
                              ref.watch(sessionProvider);
                          final hasPreviousSession = sessionsAsync.maybeWhen(
                            data: (sessions) => sessions.isNotEmpty,
                            orElse: () => false,
                          );

                          return _QuickStartCard(
                            onTap: () => context.push('/workout'),
                            isContinue: hasActiveSession,
                            isDefaultSetup: !hasExercises && !hasActiveSession,
                            hasPreviousSession:
                                hasPreviousSession && !hasActiveSession,
                          );
                        },
                      ),

                      // Challenge Card (always visible)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppConstants.spacingMd),
                        child: _ChallengeCard(
                          onTap: () => context.push('/challenges'),
                        ),
                      ),

                      // Battle Card (always visible)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppConstants.spacingMd),
                        child: _BattleCard(
                          onTap: () => context.push('/battle'),
                        ),
                      ),

                      // History Card (only show if there are sessions)
                      Builder(
                        builder: (context) {
                          final sessionsAsync =
                              ref.watch(sessionProvider);
                          final hasSessions = sessionsAsync.maybeWhen(
                            data: (sessions) => sessions.isNotEmpty,
                            orElse: () => false,
                          );

                          if (!hasSessions) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(
                                top: AppConstants.spacingMd),
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
                          // Haelt die Versionsnummer in der Mitte, obwohl
                          // rechts zwei Knoepfe stehen.
                          const SizedBox(width: 96),
                          Text(
                            'v${AppConstants.appVersion}',
                            style: AppTypography.labelSmall,
                          ),
                          IconButton(
                            onPressed: () => context.push('/achievements'),
                            tooltip:
                                AppLocalizations.of(context)
                                    .achievementsTooltip,
                            icon: const Icon(
                              Icons.military_tech_rounded,
                              color: AppColors.textSecondary,
                            ),
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
            ),
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

  String _title(AppLocalizations l10n) {
    if (isContinue) return l10n.homeContinueWorkout;
    return l10n.homeStartWorkout;
  }

  String _subtitle(AppLocalizations l10n) {
    if (isContinue) return l10n.homeSubtitleResume;
    if (isDefaultSetup) return l10n.homeSubtitleDefaultSetup;
    if (hasPreviousSession) return l10n.homeSubtitleOverload;
    return l10n.homeSubtitleBegin;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                ? AppColors.secondary.withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.3),
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
                        ? AppColors.secondary.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
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
                        _title(l10n),
                        style: AppTypography.headline3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(l10n),
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

class _ChallengeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ChallengeCard({required this.onTap});

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
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).homeChallengesTitle,
                    style: AppTypography.headline3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).homeChallengesSubtitle,
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

class _BattleCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BattleCard({required this.onTap});

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
            color: AppColors.secondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: const Icon(
                Icons.sports_kabaddi_rounded,
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
                    AppLocalizations.of(context).homeBattleTitle,
                    style: AppTypography.headline3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).homeBattleSubtitle,
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
            color: AppColors.secondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
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
                    AppLocalizations.of(context).homeHistoryTitle,
                    style: AppTypography.headline3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).homeHistorySubtitle,
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

/// Zeile, die auf zu niedrige Ziele hinweist.
///
/// Erscheint nur, wenn es etwas anzuheben gibt, und oeffnet beim Antippen
/// die Auswahl. Bewusst hier und nicht nach dem Beenden: dort wuerde sie
/// einem zweiten Durchgang im Weg stehen.
class _ZielAnhebungHinweis extends ConsumerWidget {
  const _ZielAnhebungHinweis();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vorschlaege = ref.watch(zielAnhebungenProvider);
    if (vorschlaege.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: InkWell(
        onTap: () => zeigeZielAnhebung(context, vorschlaege),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  l10n.targetBumpHint(vorschlaege.length),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
