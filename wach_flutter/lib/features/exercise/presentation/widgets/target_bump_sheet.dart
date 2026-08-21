import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/ziel_anhebung.dart';
import '../providers/exercise_providers.dart';

/// Auswahl, welche Ziele angehoben werden.
///
/// Erscheint nur, wenn man es antippt — nach dem Beenden steht bewusst
/// nichts im Weg. Alle Vorschlaege sind vorausgewaehlt, weil das der Fall
/// ist, den man meistens will; einzelne lassen sich abwaehlen.
Future<void> zeigeZielAnhebung(
  BuildContext context,
  List<ZielAnhebung> vorschlaege,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ZielAnhebungSheet(vorschlaege: vorschlaege),
  );
}

class _ZielAnhebungSheet extends ConsumerStatefulWidget {
  final List<ZielAnhebung> vorschlaege;

  const _ZielAnhebungSheet({required this.vorschlaege});

  @override
  ConsumerState<_ZielAnhebungSheet> createState() =>
      _ZielAnhebungSheetState();
}

class _ZielAnhebungSheetState extends ConsumerState<_ZielAnhebungSheet> {
  late final Set<String> _ausgewaehlt = {
    for (final v in widget.vorschlaege) v.exercise.id,
  };

  bool _laeuft = false;

  Future<void> _uebernehmen() async {
    setState(() => _laeuft = true);
    HapticUtils.mediumTap();

    final notifier = ref.read(exerciseProvider.notifier);
    for (final vorschlag in widget.vorschlaege) {
      if (!_ausgewaehlt.contains(vorschlag.exercise.id)) continue;
      await notifier.updateExercise(
        vorschlag.exercise.copyWith(targetReps: vorschlag.vorschlag),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.spacingMd,
        right: AppConstants.spacingMd,
        top: AppConstants.spacingMd,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppConstants.spacingLg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(l10n.targetBumpTitle, style: AppTypography.headline2),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            l10n.targetBumpExplain,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          for (final vorschlag in widget.vorschlaege)
            _Zeile(
              vorschlag: vorschlag,
              gewaehlt: _ausgewaehlt.contains(vorschlag.exercise.id),
              onChanged: (an) => setState(() {
                an
                    ? _ausgewaehlt.add(vorschlag.exercise.id)
                    : _ausgewaehlt.remove(vorschlag.exercise.id);
              }),
            ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _laeuft ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                  ),
                  child: Text(l10n.targetBumpLater),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: ElevatedButton(
                  // Ohne Auswahl gibt es nichts zu uebernehmen.
                  onPressed: _laeuft || _ausgewaehlt.isEmpty
                      ? null
                      : _uebernehmen,
                  child: Text(l10n.targetBumpApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  final ZielAnhebung vorschlag;
  final bool gewaehlt;
  final ValueChanged<bool> onChanged;

  const _Zeile({
    required this.vorschlag,
    required this.gewaehlt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!gewaehlt),
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vorschlag.exercise.name,
                style: AppTypography.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${vorschlag.bisher}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${vorschlag.vorschlag}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Checkbox(
              value: gewaehlt,
              onChanged: (an) => onChanged(an ?? false),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
