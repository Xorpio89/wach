import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/exercise.dart';

/// Large exercise tile for workout screen
class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final int currentReps;
  final int? targetReps;
  final Duration elapsedTime;
  final Duration? targetTime;
  final bool isLocked;
  final VoidCallback? onTap;
  final void Function(TapZoneAction action)? onZoneTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  // Tap zone configuration (left = +, right = -)
  final double zonePercent;
  final bool showZoneOverlay;

  const ExerciseTile({
    super.key,
    required this.exercise,
    this.currentReps = 0,
    this.targetReps,
    this.elapsedTime = Duration.zero,
    this.targetTime,
    this.isLocked = true,
    this.onTap,
    this.onZoneTap,
    this.onLongPress,
    this.onEdit,
    this.zonePercent = 0.0,
    this.showZoneOverlay = false,
  });

  double get _progress {
    final target = targetReps ?? exercise.targetReps;
    if (target == null || target == 0) return 0;
    return (currentReps / target).clamp(0.0, 1.0);
  }

  bool get _isCompleted => _progress >= 1.0;

  TapZoneAction _getZoneAction(double relativeX) {
    if (zonePercent == 0) {
      // No minus zone - entire tile is plus zone
      return TapZoneAction.add;
    }
    // Left X% is minus zone, rest is plus zone
    if (relativeX <= zonePercent) {
      return TapZoneAction.subtract;
    }
    return TapZoneAction.add;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      onDoubleTapDown: (details) {
        // Store the tap position for use in onDoubleTap
        _lastTapPosition = details.localPosition;
      },
      onDoubleTap: () {
        if (_lastTapPosition != null && onZoneTap != null) {
          // Calculate relative X position (horizontal)
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final relativeX = _lastTapPosition!.dx / box.size.width;
            final action = _getZoneAction(relativeX);
            onZoneTap!(action);
          }
        }
      },
      onLongPress: onLongPress,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Main tile content
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(
                    color: _isCompleted
                        ? AppColors.primary.withOpacity( 0.5)
                        : isLocked
                            ? AppColors.surfaceVariant
                            : AppColors.secondary.withOpacity( 0.3),
                    width: _isCompleted ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Exercise Name with Edit Icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isLocked && onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        if (_isCompleted)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                      ],
                    ),

                    // Rep Counter (centered, scales to fit)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$currentReps',
                              style: AppTypography.repCount.copyWith(
                                color: _isCompleted
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (targetReps != null ||
                                exercise.targetReps != null) ...[
                              Text(
                                ' / ${targetReps ?? exercise.targetReps}',
                                style: AppTypography.repTarget,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 4,
                        backgroundColor: AppColors.progressBackground,
                        valueColor: AlwaysStoppedAnimation(
                          _isCompleted ? AppColors.primary : AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Zone overlays (only in unlock mode)
              if (!isLocked && showZoneOverlay) ...[
                // Minus zone (left, red) - only if slider > 0
                if (zonePercent > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: constraints.maxWidth * zonePercent,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppConstants.radiusLg),
                            bottomLeft: Radius.circular(AppConstants.radiusLg),
                          ),
                          color: AppColors.error.withOpacity( 0.15),
                          border: Border(
                            right: BorderSide(
                              color: AppColors.error.withOpacity( 0.4),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.remove_rounded,
                            color: AppColors.error.withOpacity( 0.5),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Plus zone (right, green) - takes remaining space
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: constraints.maxWidth * zonePercent,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: zonePercent > 0
                            ? BorderRadius.only(
                                topRight: Radius.circular(AppConstants.radiusLg),
                                bottomRight: Radius.circular(AppConstants.radiusLg),
                              )
                            : BorderRadius.circular(AppConstants.radiusLg),
                        color: AppColors.primary.withOpacity( 0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.primary.withOpacity( 0.4),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// Static variable to store last tap position (workaround for Flutter's gesture system)
Offset? _lastTapPosition;

enum TapZoneAction { add, subtract, none }
