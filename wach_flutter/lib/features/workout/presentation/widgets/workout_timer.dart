import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_utils.dart';
import '../providers/timer_provider.dart';

/// Large workout timer display
class WorkoutTimer extends ConsumerWidget {
  final bool showCentiseconds;

  const WorkoutTimer({
    super.key,
    this.showCentiseconds = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    // Determine color based on target and overtime
    Color timerColor;
    if (timerState.target != null) {
      if (timerState.isOvertime) {
        timerColor = AppColors.timerWorse;
      } else if (timerState.showRemaining && timerState.isBettingTarget) {
        timerColor = AppColors.timerBetter;
      } else if (!timerState.showRemaining && timerState.isCountdownComplete) {
        timerColor = AppColors.timerWorse;
      } else {
        timerColor = AppColors.timerDefault;
      }
    } else {
      timerColor = AppColors.timerDefault;
    }

    final displayDuration = timerState.displayDuration;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode indicator (tap to toggle)
        if (timerState.target != null)
          GestureDetector(
            onTap: () => timerNotifier.toggleShowRemaining(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: timerColor.withOpacity( 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      timerState.showRemaining
                          ? Icons.hourglass_bottom_rounded
                          : Icons.timer_rounded,
                      color: timerColor.withOpacity( 0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timerState.isOvertime
                          ? 'OVERTIME'
                          : timerState.showRemaining
                              ? 'REMAINING'
                              : 'ELAPSED',
                      style: AppTypography.labelSmall.copyWith(
                        color: timerColor.withOpacity( 0.8),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: timerColor.withOpacity( 0.5),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Main timer display (tap to toggle if target set)
        GestureDetector(
          onTap: timerState.target != null
              ? () => timerNotifier.toggleShowRemaining()
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (timerState.isOvertime)
                Text(
                  '+',
                  style: AppTypography.timerLarge.copyWith(
                    color: timerColor,
                  ),
                ),
              Text(
                showCentiseconds
                    ? displayDuration.toMinutesSecondsCentis()
                    : displayDuration.toMinutesSeconds(),
                style: AppTypography.timerLarge.copyWith(
                  color: timerColor,
                ),
              ),
            ],
          ),
        ),

        // Target time indicator
        if (timerState.target != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Target: ${timerState.target!.toMinutesSeconds()}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

        // Running indicator
        if (timerState.isRunning)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity( 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Timer control buttons
class TimerControls extends ConsumerWidget {
  final VoidCallback? onEndSession;
  final bool isLocked;

  const TimerControls({
    super.key,
    this.onEndSession,
    this.isLocked = false,
  });

  Future<void> _handleReset(
    BuildContext context,
    TimerState timerState,
    TimerNotifier timerNotifier,
  ) async {
    // Show confirmation if timer > 1 minute
    if (timerState.elapsed.inMinutes >= 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Reset Timer?'),
          content: const Text(
            'Are you sure you want to reset the timer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    timerNotifier.reset();
  }

  Future<void> _setTargetTime(
    BuildContext context,
    TimerNotifier timerNotifier,
    Duration? currentTarget,
  ) async {
    final result = await showDialog<Duration?>(
      context: context,
      builder: (context) => _TargetTimeDialog(currentTarget: currentTarget),
    );

    if (result != null) {
      timerNotifier.setTarget(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    // In locked mode: only show play button when timer is 0
    if (isLocked) {
      if (timerState.elapsed == Duration.zero && !timerState.isRunning) {
        return IconButton(
          onPressed: () => timerNotifier.startStopwatch(),
          icon: const Icon(Icons.play_arrow_rounded, size: 32),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(56, 56),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Target time button
        IconButton(
          onPressed: () => _setTargetTime(context, timerNotifier, timerState.target),
          icon: Icon(
            timerState.target != null
                ? Icons.flag_rounded
                : Icons.flag_outlined,
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: timerState.target != null
                ? AppColors.secondary.withOpacity( 0.2)
                : AppColors.surfaceVariant,
            foregroundColor: timerState.target != null
                ? AppColors.secondary
                : AppColors.textSecondary,
            minimumSize: const Size(44, 44),
          ),
        ),

        const SizedBox(width: 12),

        // Start/Pause button
        IconButton(
          onPressed: () {
            if (timerState.isRunning) {
              timerNotifier.pause();
            } else if (timerState.elapsed > Duration.zero) {
              timerNotifier.resume();
            } else {
              timerNotifier.startStopwatch();
            }
          },
          icon: Icon(
            timerState.isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 32,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(56, 56),
          ),
        ),

        const SizedBox(width: 12),

        // Reset button
        IconButton(
          onPressed: timerState.elapsed > Duration.zero
              ? () => _handleReset(context, timerState, timerNotifier)
              : null,
          icon: const Icon(
            Icons.refresh_rounded,
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(44, 44),
          ),
        ),

        // End session button
        if (onEndSession != null) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: onEndSession,
            icon: const Icon(
              Icons.stop_rounded,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity( 0.2),
              foregroundColor: AppColors.error,
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dialog for setting target time
class _TargetTimeDialog extends StatefulWidget {
  final Duration? currentTarget;

  const _TargetTimeDialog({this.currentTarget});

  @override
  State<_TargetTimeDialog> createState() => _TargetTimeDialogState();
}

class _TargetTimeDialogState extends State<_TargetTimeDialog> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.currentTarget?.inMinutes ?? 5;
    _seconds = (widget.currentTarget?.inSeconds ?? 0) % 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Set Target Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes
              Column(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _minutes = (_minutes + 1).clamp(0, 99)),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  Text(
                    _minutes.toString().padLeft(2, '0'),
                    style: AppTypography.headline1,
                  ),
                  IconButton(
                    onPressed: () => setState(() => _minutes = (_minutes - 1).clamp(0, 99)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  Text('min', style: AppTypography.labelSmall),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: AppTypography.headline1),
              ),
              // Seconds
              Column(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _seconds = (_seconds + 5) % 60),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  Text(
                    _seconds.toString().padLeft(2, '0'),
                    style: AppTypography.headline1,
                  ),
                  IconButton(
                    onPressed: () => setState(() => _seconds = (_seconds - 5 + 60) % 60),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  Text('sec', style: AppTypography.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 5, 10, 15, 20, 30, 45, 60].map((mins) {
              return ActionChip(
                label: Text('$mins min'),
                onPressed: () => setState(() {
                  _minutes = mins;
                  _seconds = 0;
                }),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        if (widget.currentTarget != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(Duration.zero),
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final duration = Duration(minutes: _minutes, seconds: _seconds);
            Navigator.of(context).pop(duration);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
