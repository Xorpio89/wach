import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../providers/exercise_providers.dart';

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

    final notifier = ref.read(exerciseNotifierProvider.notifier);
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
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.spacingMd,
        right: AppConstants.spacingMd,
        top: AppConstants.spacingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.spacingMd,
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
              'Add Exercise',
              style: AppTypography.headline2,
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Exercise Name
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: AppTypography.bodyLarge,
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

            // Target Reps (optional)
            TextFormField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Target reps (optional)',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
              onFieldSubmitted: (_) => _submit(),
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
                    : const Text('Add Exercise'),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
          ],
        ),
      ),
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
