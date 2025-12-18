import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Styled progress bar following W.A.C.H. design system
class WachProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? activeColor;
  final Color? backgroundColor;
  final bool showCompleted;

  const WachProgressBar({
    super.key,
    required this.value,
    this.height = 4,
    this.activeColor,
    this.backgroundColor,
    this.showCompleted = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = showCompleted && value >= 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? AppColors.progressBackground,
        valueColor: AlwaysStoppedAnimation(
          isCompleted
              ? AppColors.primary
              : (activeColor ?? AppColors.primaryLight),
        ),
      ),
    );
  }
}
