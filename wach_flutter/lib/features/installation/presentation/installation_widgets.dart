import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/installation_zustand.dart';
import 'installation_provider.dart';

/// Loest das Hinzufuegen aus — oder erklaert den Weg, wo es nichts
/// auszuloesen gibt.
///
/// Auf dem iPhone gibt es kein Angebot, das eine Seite ausloesen koennte;
/// dort fuehrt der Weg nur ueber "Teilen". Ein Knopf, der dann nichts tut,
/// waere schlimmer als eine Anleitung.
Future<void> installationAnstossen(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final zustand = ref.read(installationProvider);

  if (zustand == InstallationZustand.nurAnleitung) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.installIosTitle),
        content: Text(l10n.installIosBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.installIosUnderstood),
          ),
        ],
      ),
    );
    return;
  }

  final zugesagt = await ref.read(installationProvider.notifier).hinzufuegen();
  if (!zugesagt || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.installDone)),
  );
}

/// Der Hinweis auf der Startseite.
///
/// Erscheint nur im Browser und nur, solange er nicht weggewischt wurde.
/// Als eigene App gestartet, ist er unsichtbar — dann gibt es nichts mehr
/// hinzuzufuegen.
class InstallationHinweis extends ConsumerWidget {
  const InstallationHinweis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final zustand = ref.watch(installationProvider);
    final sichtbar = ref.watch(hinweisSichtbarProvider);

    if (!zustand.kannHinzufuegen || !sichtbar) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.add_to_home_screen_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.installBannerTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.installBannerBody,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => installationAnstossen(context, ref),
                child: Text(l10n.installAction),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(hinweisSichtbarProvider.notifier).wegwischen(),
                child: Text(
                  l10n.installLater,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
