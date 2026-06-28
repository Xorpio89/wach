import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_providers.dart';
import '../widgets/add_challenge_modal.dart';

/// Overview of all challenges with progress + entry points to create new ones.
class ChallengesListScreen extends ConsumerWidget {
  const ChallengesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddChallengeModal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Neu'),
      ),
      body: SafeArea(
        child: challengesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Fehler: $error', style: AppTypography.bodyMedium),
          ),
          data: (challenges) {
            if (challenges.isEmpty) {
              return _EmptyChallenges(
                onCreate: () => showAddChallengeModal(context),
                onTemplate: () async {
                  final challenge = await ref
                      .read(challengeNotifierProvider.notifier)
                      .createCalisthenicsTemplate();
                  if (challenge != null && context.mounted) {
                    context.push('/challenges/${challenge.id}');
                  }
                },
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingMd,
                AppConstants.spacingMd,
                96, // leave space for the FAB
              ),
              itemCount: challenges.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppConstants.spacingMd),
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return _ChallengeCard(
                  challenge: challenge,
                  onTap: () {
                    HapticUtils.lightTap();
                    context.push('/challenges/${challenge.id}');
                  },
                  onEdit: () =>
                      showAddChallengeModal(context, existing: challenge),
                  onDelete: () => _confirmDelete(context, ref, challenge),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Challenge löschen?', style: AppTypography.headline3),
        content: Text(
          '"${challenge.name}" wird endgültig entfernt.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(challengeNotifierProvider.notifier)
          .deleteChallenge(challenge.id);
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (challenge.progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: challenge.isComplete
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            width: challenge.isComplete ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  challenge.isComplete
                      ? Icons.emoji_events_rounded
                      : Icons.checklist_rtl_rounded,
                  color: challenge.isComplete
                      ? AppColors.accent
                      : AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(challenge.name, style: AppTypography.headline3),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceVariant,
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                    const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            WachProgressBar(value: challenge.progress, height: 8),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              '${challenge.totalDone} / ${challenge.totalTarget} Reps  •  $percent%'
              '${challenge.periodDays != null ? '  •  ${challenge.periodDays} Tage' : ''}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChallenges extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onTemplate;

  const _EmptyChallenges({required this.onCreate, required this.onTemplate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: AppColors.textDisabled, size: 64),
            const SizedBox(height: AppConstants.spacingMd),
            Text('Noch keine Challenges',
                style: AppTypography.headline3, textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Setz dir ein Volumenziel und hak die Sätze ab.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCreate,
                child: const Text('Challenge erstellen'),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTemplate,
                child: const Text('Calisthenics-Vorlage laden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
