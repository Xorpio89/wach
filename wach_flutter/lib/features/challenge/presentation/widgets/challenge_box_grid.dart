import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../domain/entities/challenge.dart';

/// A grid of tappable boxes, one per [ChallengeItem.blockSize] reps.
///
/// Tap an empty box to fill progress up to that box. Tap a filled box to
/// remove it (and everything after it). Each box shows the rep count it
/// represents; a partially filled box shows how many reps are logged in it.
class ChallengeBoxGrid extends StatelessWidget {
  final ChallengeItem item;
  final Color color;

  /// Called with the new absolute done-reps value.
  final ValueChanged<int> onSetDone;

  const ChallengeBoxGrid({
    super.key,
    required this.item,
    required this.color,
    required this.onSetDone,
  });

  @override
  Widget build(BuildContext context) {
    final blockCount = item.blockCount;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(blockCount, (i) {
        final lower = i * item.blockSize;
        final upper = ((i + 1) * item.blockSize).clamp(0, item.targetReps);
        final isFull = item.doneReps >= upper;
        final isPartial = !isFull && item.doneReps > lower;
        final label = isPartial
            ? '${item.doneReps - lower}'
            : '${upper - lower}';

        return GestureDetector(
          onTap: () {
            HapticUtils.mediumTap();
            // Filled box -> clear it (set progress back to its lower bound).
            // Otherwise -> fill progress up to this box.
            onSetDone(isFull ? lower : upper);
          },
          child: Container(
            width: 40,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFull
                  ? color.withOpacity(0.85)
                  : isPartial
                      ? color.withOpacity(0.30)
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: (isFull || isPartial)
                    ? color
                    : color.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isFull ? Colors.black : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}
