import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_providers.dart';

/// Editable draft for one challenge item (holds its text controllers).
class _ItemDraft {
  final String id;
  final TextEditingController name;
  final TextEditingController target;
  final TextEditingController block;

  _ItemDraft({
    required this.id,
    String? name,
    String? target,
    String? block,
  })  : name = TextEditingController(text: name ?? ''),
        target = TextEditingController(text: target ?? ''),
        block = TextEditingController(text: block ?? '10');

  void dispose() {
    name.dispose();
    target.dispose();
    block.dispose();
  }
}

/// Bottom sheet to create or edit a volume challenge.
class AddChallengeModal extends ConsumerStatefulWidget {
  final Challenge? existing;

  const AddChallengeModal({super.key, this.existing});

  @override
  ConsumerState<AddChallengeModal> createState() => _AddChallengeModalState();
}

class _AddChallengeModalState extends ConsumerState<AddChallengeModal> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _periodController;
  late final List<_ItemDraft> _items;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _periodController = TextEditingController(
      text: existing?.periodDays?.toString() ?? '',
    );
    if (existing != null && existing.items.isNotEmpty) {
      _items = existing.items
          .map((item) => _ItemDraft(
                id: item.id,
                name: item.name,
                target: item.targetReps.toString(),
                block: item.blockSize.toString(),
              ))
          .toList();
    } else {
      _items = [_ItemDraft(id: _uuid.v4())];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _periodController.dispose();
    for (final draft in _items) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    HapticUtils.lightTap();
    setState(() => _items.add(_ItemDraft(id: _uuid.v4())));
  }

  void _removeItem(_ItemDraft draft) {
    HapticUtils.lightTap();
    setState(() {
      _items.remove(draft);
      draft.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Preserve already-logged reps for items that still exist when editing.
    final doneById = <String, int>{
      for (final item in widget.existing?.items ?? const <ChallengeItem>[])
        item.id: item.doneReps,
    };

    final items = <ChallengeItem>[];
    for (final draft in _items) {
      final name = draft.name.text.trim();
      final target = int.tryParse(draft.target.text.trim());
      if (name.isEmpty || target == null || target <= 0) continue;
      final block = int.tryParse(draft.block.text.trim()) ?? 10;
      items.add(ChallengeItem(
        id: draft.id,
        name: name,
        targetReps: target,
        blockSize: block < 1 ? 1 : block,
        doneReps: doneById[draft.id] ?? 0,
      ));
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens eine Übung mit Ziel angeben')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.lightTap();

    final notifier = ref.read(challengeNotifierProvider.notifier);
    final periodDays = int.tryParse(_periodController.text.trim());

    if (_isEdit) {
      await notifier.updateChallenge(widget.existing!.copyWith(
        name: _nameController.text.trim(),
        periodDays: periodDays,
        items: items,
      ));
      if (mounted) {
        HapticUtils.selection();
        Navigator.of(context).pop(true);
      }
    } else {
      final challenge = await notifier.createChallenge(
        name: _nameController.text,
        periodDays: periodDays,
        items: items,
      );
      if (mounted && challenge != null) {
        HapticUtils.selection();
        Navigator.of(context).pop(challenge);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
            Text(
              _isEdit ? 'Challenge bearbeiten' : 'Neue Challenge',
              style: AppTypography.headline2,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Name der Challenge',
                        prefixIcon: Icon(Icons.emoji_events_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte einen Namen eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    TextFormField(
                      controller: _periodController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Zeitraum in Tagen (optional)',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text('Übungen', style: AppTypography.labelLarge),
                    const SizedBox(height: AppConstants.spacingSm),
                    ..._items.map(_buildItemRow),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.primary),
                      label: Text(
                        'Übung hinzufügen',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
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
                    : Text(_isEdit ? 'Speichern' : 'Challenge erstellen'),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_ItemDraft draft) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: draft.name,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(hintText: 'Übung'),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.target,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(hintText: 'Ziel'),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.block,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(hintText: 'Block'),
            ),
          ),
          IconButton(
            onPressed: _items.length > 1 ? () => _removeItem(draft) : null,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Show the create/edit challenge bottom sheet.
Future<dynamic> showAddChallengeModal(
  BuildContext context, {
  Challenge? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddChallengeModal(existing: existing),
  );
}
