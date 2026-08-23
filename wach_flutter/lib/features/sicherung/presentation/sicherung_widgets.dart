import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/sicherung.dart';
import 'sicherung_provider.dart';

/// Kopiert einen Abzug aller Daten in die Zwischenablage.
///
/// Bewusst die Zwischenablage und keine Datei: Auf dem Handy ist ein
/// Herunterladen und Wiederfinden von Dateien muehsam, das Einfuegen dagegen
/// ein Handgriff. Wer den Text aufbewahren will, legt ihn in eine Notiz.
Future<void> abzugKopieren(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);

  try {
    final abzug = await ref.refresh(abzugProvider.future);
    await Clipboard.setData(ClipboardData(text: abzug.alsText()));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.backupCopied(
            abzug.anzahlIn('sessions'),
            abzug.anzahlIn('exercises'),
          ),
        ),
      ),
    );
  } catch (fehler) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commonError(fehler.toString())),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Fragt einen Abzug ab und liest ihn ein.
Future<void> abzugEinlesen(BuildContext context, WidgetRef ref) async {
  final text = await showDialog<String>(
    context: context,
    builder: (_) => const _EinlesenDialog(),
  );
  if (text == null || text.trim().isEmpty || !context.mounted) return;

  final l10n = AppLocalizations.of(context);
  final melder = ScaffoldMessenger.of(context);

  try {
    final ergebnis = await ref.read(einlesenProvider.notifier).ausText(text);
    melder.showSnackBar(
      SnackBar(
        content: Text(
          ergebnis.uebernommen == 0 && ergebnis.uebersprungen > 0
              // Alles war schon da — kein Fehler, aber es soll klar sein,
              // dass nichts passiert ist.
              ? l10n.backupNothingNew(ergebnis.uebersprungen)
              : l10n.backupImported(
                  ergebnis.uebernommen,
                  ergebnis.uebersprungen,
                ),
        ),
      ),
    );
  } on SicherungFehler catch (fehler) {
    melder.showSnackBar(
      SnackBar(
        content: Text(
          switch (fehler.art) {
            SicherungFehlerArt.keinAbzug => l10n.backupNotAnExport,
            SicherungFehlerArt.zuNeu => l10n.backupTooNew,
          },
        ),
        backgroundColor: AppColors.error,
      ),
    );
  } catch (fehler) {
    melder.showSnackBar(
      SnackBar(
        content: Text(l10n.commonError(fehler.toString())),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

class _EinlesenDialog extends StatefulWidget {
  const _EinlesenDialog();

  @override
  State<_EinlesenDialog> createState() => _EinlesenDialogState();
}

class _EinlesenDialogState extends State<_EinlesenDialog> {
  final _eingabe = TextEditingController();

  @override
  void dispose() {
    _eingabe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.backupImportTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backupImportBody,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          // Eingefuegt wird von Hand statt aus der Zwischenablage gelesen:
          // Das Lesen der Zwischenablage ist im Browser nicht ueberall
          // erlaubt, und so ist auch zu sehen, was da ankommt.
          TextField(
            controller: _eingabe,
            minLines: 3,
            maxLines: 5,
            autofocus: true,
            style: AppTypography.bodySmall,
            decoration: InputDecoration(
              hintText: l10n.backupImportHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_eingabe.text),
          child: Text(l10n.backupImportAction),
        ),
      ],
    );
  }
}
