import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/exercise.dart';

/// Large exercise tile for workout screen.
///
/// Tapping the tile flips it over to a keypad with -1 / +1 / +5 / +10
/// buttons. This replaces the earlier double-tap-with-zones interaction,
/// which needed two taps per single rep and had no visible affordance.
class ExerciseTile extends StatefulWidget {
  final Exercise exercise;
  final int currentReps;
  final int? targetReps;
  final Duration elapsedTime;
  final Duration? targetTime;
  final bool isLocked;

  /// Called with the amount to add (may be negative).
  final void Function(int delta)? onRepsDelta;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  const ExerciseTile({
    super.key,
    required this.exercise,
    this.currentReps = 0,
    this.targetReps,
    this.elapsedTime = Duration.zero,
    this.targetTime,
    this.isLocked = true,
    this.onRepsDelta,
    this.onLongPress,
    this.onEdit,
  });

  @override
  State<ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile>
    with SingleTickerProviderStateMixin {
  /// How long the keypad stays open without any input before it flips
  /// back on its own. Long enough to think between sets, short enough
  /// that the tile does not stay stuck on its back side.
  static const _autoCloseDelay = Duration(seconds: 6);

  late final AnimationController _flipController;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: AppConstants.quickAnimationDuration,
    );
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _flipController.dispose();
    super.dispose();
  }

  bool get _showsKeypad => _flipController.value > 0.5;

  double get _progress {
    final target = widget.targetReps ?? widget.exercise.targetReps;
    if (target == null || target == 0) return 0;
    return (widget.currentReps / target).clamp(0.0, 1.0);
  }

  bool get _isCompleted => _progress >= 1.0;

  void _openKeypad() {
    HapticUtils.lightTap();
    _flipController.forward();
    _restartAutoClose();
  }

  void _closeKeypad() {
    _autoCloseTimer?.cancel();
    _flipController.reverse();
  }

  void _restartAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(_autoCloseDelay, () {
      if (mounted) _flipController.reverse();
    });
  }

  void _applyDelta(int delta) {
    // Never count below zero: a -1 on an empty tile should do nothing
    // rather than push the counter negative.
    if (delta < 0 && widget.currentReps <= 0) return;
    HapticUtils.mediumTap();
    widget.onRepsDelta?.call(delta);
    _restartAutoClose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showsKeypad ? null : _openKeypad,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, _) {
          final angle = _flipController.value * math.pi;
          final isBack = _flipController.value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                // Counter-rotate so the back side is not mirrored.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildKeypadSide(),
                  )
                : _buildFrontSide(),
          );
        },
      ),
    );
  }

  BoxDecoration _tileDecoration({required bool highlighted}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      border: Border.all(
        color: highlighted
            ? AppColors.secondary.withOpacity(0.6)
            : _isCompleted
                ? AppColors.primary.withOpacity(0.5)
                : widget.isLocked
                    ? AppColors.surfaceVariant
                    : AppColors.secondary.withOpacity(0.3),
        width: _isCompleted || highlighted ? 2 : 1,
      ),
    );
  }

  Widget _buildRepCounter({required bool compact}) {
    final target = widget.targetReps ?? widget.exercise.targetReps;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${widget.currentReps}',
            style: (compact
                    ? AppTypography.headline2
                    : AppTypography.repCount)
                .copyWith(
              color: _isCompleted
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
          if (target != null)
            Text(
              ' / $target',
              style: compact
                  ? AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    )
                  : AppTypography.repTarget,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 4,
        backgroundColor: AppColors.progressBackground,
        valueColor: AlwaysStoppedAnimation(
          _isCompleted ? AppColors.primary : AppColors.primaryLight,
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: _tileDecoration(highlighted: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isCompleted)
                const Padding(
                  padding: EdgeInsets.only(right: AppConstants.spacingXs),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              if (!widget.isLocked && widget.onEdit != null)
                _EditButton(onTap: widget.onEdit!),
            ],
          ),
          Expanded(
            child: Center(child: _buildRepCounter(compact: false)),
          ),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildKeypadSide() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: _tileDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: name, live counter, close button.
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              _buildRepCounter(compact: true),
              const SizedBox(width: AppConstants.spacingXs),
              _TileIconButton(
                icon: Icons.check_rounded,
                color: AppColors.primary,
                tooltip: AppLocalizations.of(context).commonDone,
                onTap: _closeKeypad,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          // Keypad: each button stretches to fill the tile, so the
          // touch targets are as large as the layout allows.
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _RepButton(
                    label: '-1',
                    isSubtract: true,
                    enabled: widget.currentReps > 0,
                    onTap: () => _applyDelta(-1),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Expanded(
                  child: _RepButton(
                    label: '+1',
                    onTap: () => _applyDelta(1),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Expanded(
                  child: _RepButton(
                    label: '+5',
                    onTap: () => _applyDelta(5),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Expanded(
                  child: _RepButton(
                    label: '+10',
                    onTap: () => _applyDelta(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single rep button on the keypad side of the tile.
class _RepButton extends StatelessWidget {
  final String label;
  final bool isSubtract;
  final bool enabled;
  final VoidCallback onTap;

  const _RepButton({
    required this.label,
    required this.onTap,
    this.isSubtract = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSubtract ? AppColors.error : AppColors.primary;
    final effectiveColor = enabled ? color : AppColors.textDisabled;

    return Material(
      color: effectiveColor.withOpacity(enabled ? 0.15 : 0.05),
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTargetSize,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: effectiveColor.withOpacity(enabled ? 0.5 : 0.2),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.headline3.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Edit affordance on the front side.
///
/// Previously a bare 16px icon with 4px padding — a 24x24 target with no
/// outline, which was near impossible to hit. Now a visible button that
/// meets the 48x48 minimum.
class _EditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TileIconButton(
      icon: Icons.edit_rounded,
      color: AppColors.secondary,
      tooltip: AppLocalizations.of(context).exerciseEdit,
      onTap: onTap,
    );
  }
}

/// Small icon button with a full-size touch target and a visible outline.
class _TileIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _TileIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppConstants.minTouchTargetSize,
            height: 36,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
