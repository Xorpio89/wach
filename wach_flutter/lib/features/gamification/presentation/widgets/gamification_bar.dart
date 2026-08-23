import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../rang_text.dart';
import '../providers/gamification_provider.dart';

/// Stufe, Fortschritt und Serie — eine Zeile auf der Startseite.
///
/// Bewusst schmal und ohne eigenen Bildschirm: die Zahlen sollen im
/// Vorbeigehen mitgenommen werden, nicht zum Verweilen einladen.
class GamificationBar extends ConsumerWidget {
  const GamificationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(gamificationProvider);

    // Vor der ersten beendeten Session gibt es nichts zu zeigen — eine
    // Leiste auf null waere nur ein Platzhalter.
    if (stats.sessions == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  rangText(l10n, stats.stufe),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                '${stats.punkte}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.fortschritt,
              minHeight: 6,
              backgroundColor: AppColors.progressBackground,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 6),
          // Beide Angaben duerfen schrumpfen: nebeneinander sind sie auf
          // schmalen Geraeten und bei grosser Systemschrift sonst zu breit.
          Row(
            children: [
              Flexible(
                child: Text(
                  l10n.gamificationToNextLevel(stats.punkteBisNaechsteStufe),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stats.serie > 0) ...[
                const SizedBox(width: AppConstants.spacingSm),
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.secondary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.gamificationStreak(stats.serie),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
