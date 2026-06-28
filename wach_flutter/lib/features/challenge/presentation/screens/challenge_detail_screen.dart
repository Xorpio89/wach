import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_providers.dart';
import '../widgets/add_challenge_modal.dart';
import '../widgets/challenge_box_grid.dart';

/// Per-item accent colours, cycled by index.
const _itemColors = <Color>[
  AppColors.primary,
  AppColors.info,
  AppColors.secondary,
  AppColors.accent,
];

/// Detail view of a single challenge: tap boxes to log progress.
class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(challengeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge'),
        actions: [
          challengeAsync.maybeWhen(
            data: (challenge) => challenge == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () =>
                        showAddChallengeModal(context, existing: challenge),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: challengeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Fehler: $error', style: AppTypography.bodyMedium),
          ),
          data: (challenge) {
            if (challenge == null) {
              return Center(
                child: Text('Challenge nicht gefunden',
                    style: AppTypography.bodyMedium),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                _ChallengeHeader(challenge: challenge),
                const SizedBox(height: AppConstants.spacingLg),
                for (var i = 0; i < challenge.items.length; i++)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spacingLg),
                    child: _ChallengeItemSection(
                      challenge: challenge,
                      item: challenge.items[i],
                      color: _itemColors[i % _itemColors.length],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeHeader extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeHeader({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final percent = (challenge.progress * 100).round();
    return Container(
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
          Text(challenge.name, style: AppTypography.headline2),
          const SizedBox(height: AppConstants.spacingMd),
          WachProgressBar(value: challenge.progress, height: 10),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            '${challenge.totalDone} / ${challenge.totalTarget} Reps  •  $percent%'
            '${challenge.isComplete ? '  •  geschafft 🎉' : ''}',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ChallengeItemSection extends ConsumerWidget {
  final Challenge challenge;
  final ChallengeItem item;
  final Color color;

  const _ChallengeItemSection({
    required this.challenge,
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(challengeNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            )),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(item.name, style: AppTypography.headline3),
            ),
            TextButton.icon(
              onPressed: () => _showAddSetDialog(context, ref),
              icon: Icon(Icons.add_rounded, color: color, size: 20),
              label: Text('Satz',
                  style: AppTypography.labelLarge.copyWith(color: color)),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          item.isComplete
              ? 'Ziel erreicht • ${item.doneReps} Reps'
              : '${item.doneReps} / ${item.targetReps} • noch ${item.remaining}',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        ChallengeBoxGrid(
          item: item,
          color: color,
          onSetDone: (newDone) => notifier.setDone(challenge, item.id, newDone),
        ),
      ],
    );
  }

  Future<void> _showAddSetDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reps = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Satz eintragen — ${item.name}',
            style: AppTypography.headline3),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'Wiederholungen (z.B. 8)',
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(int.tryParse(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(controller.text)),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    if (reps != null && reps != 0) {
      HapticUtils.selection();
      await ref
          .read(challengeNotifierProvider.notifier)
          .addReps(challenge, item.id, reps);
    }
  }
}
