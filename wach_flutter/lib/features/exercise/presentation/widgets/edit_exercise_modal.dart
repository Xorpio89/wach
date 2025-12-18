import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../domain/entities/exercise.dart';
import '../providers/exercise_providers.dart';

/// Result of edit modal action
enum EditExerciseAction { updated, deleted, resetReps }

/// Modal for editing an existing exercise
class EditExerciseModal extends ConsumerStatefulWidget {
  final Exercise exercise;
  final int currentReps;
  final VoidCallback? onResetReps;

  const EditExerciseModal({
    super.key,
    required this.exercise,
    this.currentReps = 0,
    this.onResetReps,
  });

  @override
  ConsumerState<EditExerciseModal> createState() => _EditExerciseModalState();
}

class _EditExerciseModalState extends ConsumerState<EditExerciseModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _repsController;
  final _repsFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _repsController = TextEditingController(
      text: widget.exercise.targetReps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repsController.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticUtils.lightTap();

    final notifier = ref.read(exerciseNotifierProvider.notifier);
    final updatedExercise = Exercise(
      id: widget.exercise.id,
      name: _nameController.text.trim(),
      targetReps: _repsController.text.isNotEmpty
          ? int.tryParse(_repsController.text)
          : null,
      targetTime: widget.exercise.targetTime,
      createdAt: widget.exercise.createdAt,
      lastPerformedAt: widget.exercise.lastPerformedAt,
    );

    final success = await notifier.updateExercise(updatedExercise);

    setState(() => _isLoading = false);

    if (success && mounted) {
      HapticUtils.selection();
      Navigator.of(context).pop(EditExerciseAction.updated);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Exercise?'),
        content: Text(
          'Are you sure you want to delete "${widget.exercise.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    HapticUtils.heavyTap();

    final notifier = ref.read(exerciseNotifierProvider.notifier);
    final success = await notifier.deleteExercise(widget.exercise.id);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(EditExerciseAction.deleted);
    }
  }

  void _resetReps() {
    HapticUtils.mediumTap();
    widget.onResetReps?.call();
    Navigator.of(context).pop(EditExerciseAction.resetReps);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.spacingMd,
        right: AppConstants.spacingMd,
        top: AppConstants.spacingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            AppConstants.spacingMd,
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
              'Edit Exercise',
              style: AppTypography.headline2,
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Exercise Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.bodyLarge,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _repsFocusNode.requestFocus(),
              decoration: const InputDecoration(
                hintText: 'Exercise name',
                prefixIcon: Icon(Icons.fitness_center_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Target Reps
            TextFormField(
              controller: _repsController,
              focusNode: _repsFocusNode,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyLarge,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                hintText: 'Target reps (optional)',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Reset Reps Button
            if (widget.currentReps > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _resetReps,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text('Reset Reps (${widget.currentReps} -> 0)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                    ),
                  ),
                ),
              ),

            // Action Buttons Row
            Row(
              children: [
                // Delete Button
                IconButton(
                  onPressed: _isLoading ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                  tooltip: 'Delete exercise',
                ),
                const SizedBox(width: AppConstants.spacingSm),

                // Save Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
          ],
        ),
      ),
    );
  }
}

/// Show edit exercise modal
Future<EditExerciseAction?> showEditExerciseModal(
  BuildContext context, {
  required Exercise exercise,
  int currentReps = 0,
  VoidCallback? onResetReps,
}) async {
  return await showModalBottomSheet<EditExerciseAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EditExerciseModal(
      exercise: exercise,
      currentReps: currentReps,
      onResetReps: onResetReps,
    ),
  );
}
