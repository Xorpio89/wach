import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable status bar for displaying app state
class StatusBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final String? subLabel;
  final Color? color;
  final Widget? leading;
  final Widget? trailing;

  const StatusBar({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.subLabel,
    this.color,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingSm,
        horizontal: AppConstants.spacingMd,
      ),
      color: statusColor.withOpacity( 0.2),
      child: Row(
        children: [
          if (leading != null) leading! else const SizedBox(width: 28),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: statusColor, size: 16),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        hint!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing! else const SizedBox(width: 28),
        ],
      ),
    );
  }
}
