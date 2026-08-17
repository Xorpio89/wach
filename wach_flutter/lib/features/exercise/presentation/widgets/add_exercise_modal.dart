import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/data/settings_provider.dart';
import '../providers/exercise_providers.dart';
import '../providers/quick_pick_expanded_provider.dart';

/// Modal for adding a new exercise
class AddExerciseModal extends ConsumerStatefulWidget {
  final String? initialName;
  final int? initialReps;

  const AddExerciseModal({
    super.key,
    this.initialName,
    this.initialReps,
  });

  @override
  ConsumerState<AddExerciseModal> createState() => _AddExerciseModalState();
}

class _AddExerciseModalState extends ConsumerState<AddExerciseModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _repsController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticUtils.lightTap();

    final notifier = ref.read(exerciseProvider.notifier);
    final exercise = await notifier.createExercise(
      name: _nameController.text,
      targetReps: _repsController.text.isNotEmpty
          ? int.tryParse(_repsController.text)
          : null,
    );

    setState(() => _isLoading = false);

    if (exercise != null && mounted) {
      HapticUtils.selection();
      Navigator.of(context).pop(exercise);
    }
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
            MediaQuery.of(context).viewInsets.bottom + AppConstants.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Title
            Text(
              l10n.exerciseAdd,
              style: AppTypography.headline2,
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Schnellauswahl: fuellt das Formular vor, statt die Uebung
            // sofort anzulegen — Zielwiederholungen lassen sich so noch
            // anpassen, bevor gespeichert wird.
            _QuickPickChips(
              onPick: (name, reps) {
                HapticUtils.selection();
                setState(() {
                  _nameController.text = name;
                  _repsController.text = reps.toString();
                });
              },
            ),

            // Exercise Name
            TextFormField(
              controller: _nameController,
              // Kein autofocus: die Tastatur wuerde sofort hochfahren und
              // die Schnellauswahl darueber verdecken.
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.exerciseNameHint,
                prefixIcon: const Icon(Icons.fitness_center_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.exerciseNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Target Reps (optional)
            TextFormField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.exerciseTargetRepsHint,
                prefixIcon: const Icon(Icons.repeat_rounded),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Haeufige Zielwerte zum Antippen — schneller als tippen und
            // ein Hinweis darauf, dass das Ziel fuer ein ganzes Workout
            // gilt, nicht fuer einen Satz.
            Wrap(
              spacing: AppConstants.spacingSm,
              children: [
                for (final ziel in AppConstants.zielVorschlaege)
                  ActionChip(
                    label: Text(
                      '$ziel',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      HapticUtils.selection();
                      setState(() => _repsController.text = '$ziel');
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Text(l10n.exerciseAdd),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
          ],
        ),
      ),
    );
  }
}

/// Schnellauswahl haeufiger Uebungen.
///
/// Vorher `_QuickAddChips` unter den Kacheln im Workout-Screen und nur im
/// entsperrten Modus sichtbar. Mit dem Wegfall des Sperrmodus sitzt die
/// Auswahl dort, wo sie hingehoert: im Hinzufuegen-Dialog.
class _QuickPickChips extends ConsumerStatefulWidget {
  final void Function(String name, int reps) onPick;

  const _QuickPickChips({required this.onPick});

  @override
  ConsumerState<_QuickPickChips> createState() => _QuickPickChipsState();
}

class _QuickPickChipsState extends ConsumerState<_QuickPickChips> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Erst die haeufigsten Vorschlaege. Ob aufgeklappt wird, merkt sich die
    // App — sonst muesste man es bei jeder neuen Uebung wiederholen.
    final alleZeigen = ref.watch(quickPickExpandedProvider);
    final settingsAsync = ref.watch(quickChipSettingsProvider);
    final existingExercises = ref.watch(exercisesProvider);

    // Bereits angelegte Uebungen ausblenden (Gross-/Kleinschreibung egal).
    final existingNames = existingExercises.maybeWhen(
      data: (exercises) => exercises.map((e) => e.name.toLowerCase()).toSet(),
      orElse: () => <String>{},
    );

    return settingsAsync.when(
      data: (settings) {
        bool nochNichtAngelegt(QuickChipExercise e) =>
            !existingNames.contains(e.name.toLowerCase());

        // Eingeklappt stehen die in den Einstellungen gewaehlten
        // Lieblingsuebungen, aufgeklappt der ganze Vorrat. Ohne diese
        // Trennung waere der Schalter wirkungslos: die Voreinstellung
        // umfasst genau so viele Eintraege, wie eingeklappt passen.
        final favoriten =
            settings.enabledExercises.where(nochNichtAngelegt).toList();
        final alle = allQuickChipExercises.where(nochNichtAngelegt).toList();

        if (alle.isEmpty) return const SizedBox.shrink();

        const grenze = AppConstants.quickPickCollapsedCount;
        final sichtbar = alleZeigen ? alle : favoriten.take(grenze).toList();
        final versteckt = alle.length - sichtbar.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: AppConstants.spacingSm,
                children: sichtbar.map((exercise) {
                  return ActionChip(
                    avatar: Icon(
                      exercise.icon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      exercise.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    onPressed: () =>
                        widget.onPick(exercise.name, exercise.defaultReps),
                  );
                }).toList(),
              ),
              if (versteckt > 0 || alleZeigen)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(quickPickExpandedProvider.notifier).umschalten(),
                  icon: Icon(
                    alleZeigen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                  ),
                  label: Text(
                    alleZeigen
                        ? l10n.exerciseShowLessSuggestions
                        : l10n.exerciseShowMoreSuggestions(versteckt),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSm,
                    ),
                    minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Show add exercise modal
Future<void> showAddExerciseModal(
  BuildContext context, {
  String? initialName,
  int? initialReps,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddExerciseModal(
      initialName: initialName,
      initialReps: initialReps,
    ),
  );
}
