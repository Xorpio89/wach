import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/exercise.dart';

/// Rueckfrage vor dem Loeschen einer Uebung.
///
/// Liegt als eigene Funktion vor, weil sie von zwei Stellen gebraucht wird:
/// vom Muelleimer auf der Kachel und (frueher) aus dem Bearbeiten-Fenster.
/// Zwei getrennte Dialoge waeren mit der Zeit auseinandergelaufen.
///
/// Gibt `true` zurueck, wenn geloescht werden soll.
Future<bool> zeigeLoeschRueckfrage(
  BuildContext context,
  Exercise exercise,
) async {
  final l10n = AppLocalizations.of(context);

  final bestaetigt = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.exerciseDeleteTitle),
      content: Text(l10n.exerciseDeleteConfirm(exercise.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );

  return bestaetigt ?? false;
}
