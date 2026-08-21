import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/gamification_stats.dart';
import '../providers/gamification_provider.dart';

/// Übersicht über Stufe, Punkte und Abzeichen.
///
/// Eine reine Anzeige — alles hier ist aus dem Verlauf gerechnet, es gibt
/// nichts einzustellen.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  /// Wie viele Stufen über der aktuellen noch gezeigt werden.
  static const _stufenVoraus = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(gamificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.achievementsTitle),
        backgroundColor: AppColors.background,
      ),
      body: stats.sessions == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Text(
                  l10n.achievementsNothingYet,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                _StufenKopf(stats: stats),
                const SizedBox(height: AppConstants.spacingLg),
                _Kennzahlen(stats: stats),
                const SizedBox(height: AppConstants.spacingLg),
                _Abschnitt(titel: l10n.achievementsBadges),
                const SizedBox(height: AppConstants.spacingSm),
                for (final abzeichen in Abzeichen.values)
                  _AbzeichenZeile(
                    abzeichen: abzeichen,
                    erreicht: stats.abzeichen.contains(abzeichen),
                  ),
                const SizedBox(height: AppConstants.spacingLg),
                _Abschnitt(titel: l10n.achievementsLevels),
                const SizedBox(height: AppConstants.spacingSm),
                // Die aktuelle Stufe und ein paar darüber — die ganze
                // Leiter wäre eine endlose Liste ohne Aussage.
                for (var stufe = stats.stufe;
                    stufe <= stats.stufe + _stufenVoraus;
                    stufe++)
                  _StufenZeile(
                    stufe: stufe,
                    schwelle: GamificationStats.schwelleFuer(stufe),
                    istAktuell: stufe == stats.stufe,
                  ),
              ],
            ),
    );
  }
}

class _StufenKopf extends StatelessWidget {
  final GamificationStats stats;

  const _StufenKopf({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Text(
          '${stats.stufe}',
          style: AppTypography.timerLarge.copyWith(
            color: AppColors.primary,
            fontSize: 72,
          ),
        ),
        Text(
          l10n.gamificationLevel(stats.stufe),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stats.fortschritt,
            minHeight: 8,
            backgroundColor: AppColors.progressBackground,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.gamificationToNextLevel(stats.punkteBisNaechsteStufe),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Kennzahlen extends StatelessWidget {
  final GamificationStats stats;

  const _Kennzahlen({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _Kennzahl(
            wert: '${stats.punkte}',
            bezeichnung: l10n.achievementsPoints,
          ),
        ),
        Expanded(
          child: _Kennzahl(
            wert: '${stats.sessions}',
            bezeichnung: l10n.achievementsSessions,
          ),
        ),
        Expanded(
          child: _Kennzahl(
            wert: l10n.achievementsDays(stats.serie),
            bezeichnung: l10n.achievementsStreakLabel,
          ),
        ),
      ],
    );
  }
}

class _Kennzahl extends StatelessWidget {
  final String wert;
  final String bezeichnung;

  const _Kennzahl({required this.wert, required this.bezeichnung});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            wert,
            style: AppTypography.headline2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          bezeichnung,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final String titel;

  const _Abschnitt({required this.titel});

  @override
  Widget build(BuildContext context) {
    return Text(
      titel,
      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _AbzeichenZeile extends StatelessWidget {
  final Abzeichen abzeichen;
  final bool erreicht;

  const _AbzeichenZeile({required this.abzeichen, required this.erreicht});

  /// Name und Erklaerung je Abzeichen.
  (String, String, IconData) _text(AppLocalizations l10n) {
    switch (abzeichen) {
      case Abzeichen.angefangen:
        return (
          l10n.badgeStartedName,
          l10n.badgeStartedHint,
          Icons.flag_rounded,
        );
      case Abzeichen.tausend:
        return (
          l10n.badgeThousandName,
          l10n.badgeThousandHint,
          Icons.military_tech_rounded,
        );
      case Abzeichen.eineWoche:
        return (
          l10n.badgeOneWeekName,
          l10n.badgeOneWeekHint,
          Icons.local_fire_department_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (name, hinweis, symbol) = _text(l10n);
    // Nicht erreichte Abzeichen bleiben sichtbar, aber blass — sie zeigen,
    // was noch kommt, ohne sich in den Vordergrund zu draengen.
    final farbe = erreicht ? AppColors.primary : AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: farbe.withValues(alpha: erreicht ? 0.15 : 0.06),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: farbe.withValues(alpha: 0.4)),
            ),
            child: Icon(symbol, color: farbe, size: 20),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: erreicht
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: erreicht ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  hinweis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (erreicht)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _StufenZeile extends StatelessWidget {
  final int stufe;
  final int schwelle;
  final bool istAktuell;

  const _StufenZeile({
    required this.stufe,
    required this.schwelle,
    required this.istAktuell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$stufe',
              style: AppTypography.bodyMedium.copyWith(
                color: istAktuell ? AppColors.primary : AppColors.textSecondary,
                fontWeight: istAktuell ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            l10n.achievementsLevelAt(schwelle),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
