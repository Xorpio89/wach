import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/challenge_vorlagen.dart';

/// Der Name einer Vorlage in der Sprache der App.
String vorlagenName(AppLocalizations l10n, String id) {
  return switch (id) {
    'ersteHundert' => l10n.challengeTplErsteHundert,
    'hundertAmTag' => l10n.challengeTplHundertAmTag,
    'halbMurph' => l10n.challengeTplHalbMurph,
    'angie' => l10n.challengeTplAngie,
    'murph' => l10n.challengeTplMurph,
    'tausendKlimmzuege' => l10n.challengeTplTausendKlimmzuege,
    'wochenvolumen' => l10n.challengeTplWochenvolumen,
    'fuenftausend' => l10n.challengeTplFuenftausend,
    _ => id,
  };
}

String _beschreibung(AppLocalizations l10n, String id) {
  return switch (id) {
    'ersteHundert' => l10n.challengeTplErsteHundertDesc,
    'hundertAmTag' => l10n.challengeTplHundertAmTagDesc,
    'halbMurph' => l10n.challengeTplHalbMurphDesc,
    'angie' => l10n.challengeTplAngieDesc,
    'murph' => l10n.challengeTplMurphDesc,
    'tausendKlimmzuege' => l10n.challengeTplTausendKlimmzuegeDesc,
    'wochenvolumen' => l10n.challengeTplWochenvolumenDesc,
    'fuenftausend' => l10n.challengeTplFuenftausendDesc,
    _ => '',
  };
}

/// Was ausgewaehlt wurde: eine Vorlage — oder der Wunsch, selbst
/// zusammenzustellen.
class VorlagenAuswahl {
  final ChallengeVorlage? vorlage;

  const VorlagenAuswahl.eigene() : vorlage = null;
  const VorlagenAuswahl.aus(this.vorlage);

  bool get istEigene => vorlage == null;
}

/// Laesst zwischen den bekannten Challenges waehlen.
///
/// Steht vor dem Zusammenstellen von Hand, nicht daneben: Wer nicht ohnehin
/// weiss, was eine sinnvolle Zahl ist, faengt sonst gar nicht erst an. Der
/// eigene Weg bleibt als letzte Zeile immer offen.
Future<VorlagenAuswahl?> zeigeVorlagen(BuildContext context) {
  return showModalBottomSheet<VorlagenAuswahl>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusLg),
      ),
    ),
    builder: (_) => const _VorlagenSheet(),
  );
}

class _VorlagenSheet extends StatelessWidget {
  const _VorlagenSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(l10n.challengeTemplatesTitle, style: AppTypography.headline3),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            l10n.challengeTemplatesSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          for (final vorlage in challengeVorlagen)
            _VorlagenKarte(vorlage: vorlage),
          const SizedBox(height: AppConstants.spacingSm),
          // Der eigene Weg bleibt offen — und steht unten, weil die
          // Vorlagen der schnellere Einstieg sind.
          Card(
            color: AppColors.background,
            child: ListTile(
              leading: const Icon(Icons.tune_rounded,
                  color: AppColors.textSecondary),
              title: Text(l10n.challengeTemplatesOwn),
              subtitle: Text(
                l10n.challengeTemplatesOwnSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.of(context)
                  .pop(const VorlagenAuswahl.eigene()),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],
      ),
    );
  }
}

class _VorlagenKarte extends StatelessWidget {
  final ChallengeVorlage vorlage;

  const _VorlagenKarte({required this.vorlage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Zeitraum und Tagespensum: "1.000 Wiederholungen" und "33/Tag" sind
    // dieselbe Zahl mit ganz verschiedener Wirkung.
    final zeitraum = switch (vorlage.art) {
      VorlagenArt.einTag => l10n.challengeTemplateOneDay,
      VorlagenArt.ohneFrist => l10n.challengeTemplateNoDeadline,
      VorlagenArt.ueberZeit =>
        l10n.challengeTemplateDays(vorlage.tage ?? 0),
    };
    final proTag = vorlage.repsProTag;

    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: () =>
            Navigator.of(context).pop(VorlagenAuswahl.aus(vorlage)),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vorlagenName(l10n, vorlage.id),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    zeitraum,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                _beschreibung(l10n, vorlage.id),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: AppConstants.spacingXs,
                children: [
                  _Marke(
                    text: l10n.challengeTemplateTotal(vorlage.gesamtReps),
                    hervorgehoben: true,
                  ),
                  if (proTag != null)
                    _Marke(text: l10n.challengeTemplatePerDay(proTag)),
                  for (final uebung in vorlage.uebungen)
                    _Marke(text: '${uebung.name} ${uebung.ziel}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marke extends StatelessWidget {
  final String text;
  final bool hervorgehoben;

  const _Marke({required this.text, this.hervorgehoben = false});

  @override
  Widget build(BuildContext context) {
    final farbe =
        hervorgehoben ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: farbe),
      ),
    );
  }
}
