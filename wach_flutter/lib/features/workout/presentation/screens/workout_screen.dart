import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../exercise/domain/entities/exercise.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../exercise/presentation/widgets/add_exercise_modal.dart';
import '../../../exercise/presentation/widgets/edit_exercise_modal.dart';
import '../../../exercise/presentation/widgets/exercise_tile.dart';
import '../../data/models/session_model.dart';
import '../../../settings/data/settings_provider.dart';
import '../providers/lock_mode_provider.dart';
import '../providers/session_providers.dart';
import '../providers/tap_zone_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/workout_timer.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String? exerciseId;

  const WorkoutScreen({super.key, this.exerciseId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  // Track reps per exercise (in-memory for now)
  final Map<String, int> _repsMap = {};
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Seed default exercises if empty
      ref.read(exerciseNotifierProvider.notifier).seedDefaultExercisesIfEmpty();
      // Timer starts via play button, not automatically
    });
  }

  void _toggleLockMode() {
    HapticUtils.heavyTap();
    toggleLockMode(ref);
  }

  void _addRep(String exerciseId) {
    HapticUtils.mediumTap();

    // Check if this is the first rep and auto-start timer if enabled
    final isFirstRep = _repsMap.values.every((r) => r == 0) || _repsMap.isEmpty;
    if (isFirstRep) {
      final workoutSettings = ref.read(workoutSettingsProvider).value;
      final timerState = ref.read(timerProvider);
      if (workoutSettings?.autoStartTimerOnFirstRep == true &&
          !timerState.isRunning &&
          timerState.elapsed == Duration.zero) {
        ref.read(timerProvider.notifier).startStopwatch();
      }
    }

    setState(() {
      // Track session start on first rep
      _sessionStartTime ??= DateTime.now();
      _repsMap[exerciseId] = (_repsMap[exerciseId] ?? 0) + 1;
    });
  }

  void _subtractRep(String exerciseId) {
    HapticUtils.lightTap();
    setState(() {
      final current = _repsMap[exerciseId] ?? 0;
      if (current > 0) {
        _repsMap[exerciseId] = current - 1;
      }
    });
  }

  void _resetReps(String exerciseId) {
    setState(() {
      _repsMap[exerciseId] = 0;
    });
  }

  Future<void> _editExercise(Exercise exercise) async {
    final action = await showEditExerciseModal(
      context,
      exercise: exercise,
      currentReps: _repsMap[exercise.id] ?? 0,
      onResetReps: () => _resetReps(exercise.id),
    );

    if (action == EditExerciseAction.resetReps) {
      // Already handled by callback
    } else if (action == EditExerciseAction.deleted) {
      // Remove from local reps map
      setState(() {
        _repsMap.remove(exercise.id);
      });
    }
    // For updated: the stream will auto-refresh
  }

  Future<void> _endSession() async {
    final timerState = ref.read(timerProvider);
    final hasData = timerState.elapsed.inSeconds > 0 || _repsMap.isNotEmpty;

    // Show confirmation if session has data
    if (hasData) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('End Session?'),
          content: const Text(
            'Are you sure you want to end this workout session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('End Session'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    // Save session if there's data
    if (hasData && _repsMap.values.any((reps) => reps > 0)) {
      await _saveSession();
    }

    // Reset timer and reps
    ref.read(timerProvider.notifier).reset();
    setState(() {
      _repsMap.clear();
      _sessionStartTime = null;
    });

    // Navigate back to home
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _saveSession() async {
    final timerState = ref.read(timerProvider);
    final exercisesAsync = ref.read(exercisesStreamProvider);
    final exercises = exercisesAsync.value ?? [];

    // Build exercise names map
    final exerciseNames = <String, String>{};
    for (final exercise in exercises) {
      if (_repsMap.containsKey(exercise.id)) {
        exerciseNames[exercise.id] = exercise.name;
      }
    }

    // Filter to only exercises with reps > 0
    final repsWithData = Map<String, int>.fromEntries(
      _repsMap.entries.where((e) => e.value > 0),
    );

    if (repsWithData.isEmpty) return;

    final session = SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: _sessionStartTime ?? DateTime.now(),
      finishedAt: DateTime.now(),
      durationSeconds: timerState.elapsed.inSeconds,
      exerciseReps: repsWithData,
      exerciseNames: exerciseNames,
    );

    try {
      await ref.read(sessionNotifierProvider.notifier).saveSession(session);
    } catch (e) {
      // Silently fail - don't block ending the session
      debugPrint('Failed to save session: $e');
    }
  }

  Widget _buildExerciseTile(Exercise exercise, bool isLocked) {
    final tapZone = ref.watch(tapZoneProvider);

    return ExerciseTile(
      exercise: exercise,
      currentReps: _repsMap[exercise.id] ?? 0,
      isLocked: isLocked,
      onTap: () => _addRep(exercise.id),
      onZoneTap: (action) {
        switch (action) {
          case TapZoneAction.add:
            _addRep(exercise.id);
            break;
          case TapZoneAction.subtract:
            _subtractRep(exercise.id);
            break;
          case TapZoneAction.none:
            // In locked mode with no zone, just add
            if (isLocked) _addRep(exercise.id);
            break;
        }
      },
      onLongPress: _toggleLockMode,
      onEdit: () => _editExercise(exercise),
      zonePercent: tapZone.zonePercent,
      showZoneOverlay: !isLocked && tapZone.showZoneOverlay,
    );
  }

  Widget _buildExerciseLayout(List<Exercise> exercises, bool isLocked) {
    // 1-4 exercises: vertical split (each takes equal space)
    if (exercises.length <= 4) {
      return Column(
        children: exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: index < exercises.length - 1
                    ? AppConstants.spacingSm
                    : 0,
              ),
              child: _buildExerciseTile(exercise, isLocked),
            ),
          );
        }).toList(),
      );
    }

    // 5+ exercises: paginated view (4 per page) with arrow navigation
    const exercisesPerPage = 4;
    final pageCount = (exercises.length / exercisesPerPage).ceil();

    return _PaginatedExerciseView(
      exercises: exercises,
      exercisesPerPage: exercisesPerPage,
      pageCount: pageCount,
      isLocked: isLocked,
      buildTile: _buildExerciseTile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(lockModeProvider);
    final exercisesAsync = ref.watch(exercisesStreamProvider);

    return GestureDetector(
      onLongPress: _toggleLockMode,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Lock Status Bar
              _LockStatusBar(
                isLocked: isLocked,
                onBack: () => context.go('/'),
              ),

              // Tap Zone Control (only in unlock mode)
              if (!isLocked) const _TapZoneControl(),

              // Timer Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingLg,
                ),
                child: Column(
                  children: [
                    const WorkoutTimer(),
                    const SizedBox(height: AppConstants.spacingMd),
                    TimerControls(
                      onEndSession: _endSession,
                      isLocked: isLocked,
                    ),
                  ],
                ),
              ),

              // Exercise Tiles
              Expanded(
                child: exercisesAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return _EmptyState(
                        isLocked: isLocked,
                        onAddExercise: () => showAddExerciseModal(context),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                      ),
                      child: _buildExerciseLayout(exercises, isLocked),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),

              // Quick Add Chips (only when unlocked)
              if (!isLocked)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                  child: _QuickAddChips(
                    onChipTap: (name, reps) => showAddExerciseModal(
                      context,
                      initialName: name,
                      initialReps: reps,
                    ),
                  ),
                ),

              // Instructions
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Text(
                  isLocked ? 'Long press to unlock' : 'Long press to lock',
                  style: AppTypography.labelSmall,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: !isLocked
            ? FloatingActionButton(
                onPressed: () => showAddExerciseModal(context),
                child: const Icon(Icons.add_rounded),
              )
            : null,
      ),
    );
  }
}

class _LockStatusBar extends StatelessWidget {
  final bool isLocked;
  final VoidCallback? onBack;

  const _LockStatusBar({required this.isLocked, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingSm,
        horizontal: AppConstants.spacingMd,
      ),
      color: isLocked
          ? AppColors.primary.withOpacity( 0.2)
          : AppColors.secondary.withOpacity( 0.2),
      child: Row(
        children: [
          // Back button (only in unlocked mode)
          if (!isLocked && onBack != null)
            GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 28),

          // Center content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: isLocked ? AppColors.primary : AppColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      isLocked ? 'LOCKED' : 'UNLOCKED',
                      style: AppTypography.labelSmall.copyWith(
                        color: isLocked ? AppColors.primary : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      '(Longtap)',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (isLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Doubletap to +1',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Spacer for symmetry
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onAddExercise;

  const _EmptyState({
    required this.isLocked,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'No exercises yet',
            style: AppTypography.headline3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            isLocked
                ? 'Long press to unlock and add exercises'
                : 'Tap the + button to add an exercise',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (!isLocked) ...[
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Exercise'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick add chips for common exercises
class _QuickAddChips extends ConsumerWidget {
  final void Function(String name, int reps) onChipTap;

  const _QuickAddChips({required this.onChipTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(quickChipSettingsProvider);
    final existingExercises = ref.watch(exercisesProvider);

    // Get names of existing exercises (case-insensitive)
    final existingNames = existingExercises.maybeWhen(
      data: (exercises) => exercises.map((e) => e.name.toLowerCase()).toSet(),
      orElse: () => <String>{},
    );

    return settingsAsync.when(
      data: (settings) {
        // Filter out exercises that already exist
        final availableExercises = settings.enabledExercises
            .where((e) => !existingNames.contains(e.name.toLowerCase()))
            .toList();

        if (availableExercises.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 40,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
              scrollbars: true,
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableExercises.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final exercise = availableExercises[index];
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
                    color: AppColors.primary.withOpacity( 0.3),
                  ),
                  onPressed: () => onChipTap(exercise.name, exercise.defaultReps),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Paginated view for 5+ exercises with smooth PageView swipe
class _PaginatedExerciseView extends StatefulWidget {
  final List<Exercise> exercises;
  final int exercisesPerPage;
  final int pageCount;
  final bool isLocked;
  final Widget Function(Exercise, bool) buildTile;

  const _PaginatedExerciseView({
    required this.exercises,
    required this.exercisesPerPage,
    required this.pageCount,
    required this.isLocked,
    required this.buildTile,
  });

  @override
  State<_PaginatedExerciseView> createState() => _PaginatedExerciseViewState();
}

class _PaginatedExerciseViewState extends State<_PaginatedExerciseView> {
  late PageController _pageController;
  int _currentPage = 0;
  double _dragStartX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < widget.pageCount) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final delta = details.globalPosition.dx - _dragStartX;
    // Threshold of 50px for page change
    if (delta.abs() > 50) {
      if (delta > 0 && _currentPage > 0) {
        _goToPage(_currentPage - 1);
        _isDragging = false;
      } else if (delta < 0 && _currentPage < widget.pageCount - 1) {
        _goToPage(_currentPage + 1);
        _isDragging = false;
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
  }

  Widget _buildPage(int pageIndex) {
    final startIndex = pageIndex * widget.exercisesPerPage;
    final endIndex = (startIndex + widget.exercisesPerPage)
        .clamp(0, widget.exercises.length);
    final pageExercises = widget.exercises.sublist(startIndex, endIndex);

    return Column(
      children: pageExercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: index < pageExercises.length - 1
                  ? AppConstants.spacingSm
                  : 0,
            ),
            child: widget.buildTile(exercise, widget.isLocked),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Navigation row with arrows and page indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              onPressed: _currentPage > 0
                  ? () => _goToPage(_currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              color: AppColors.primary,
              disabledColor: AppColors.textDisabled,
            ),

            // Page indicator dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.pageCount, (index) {
                return GestureDetector(
                  onTap: () => _goToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),

            // Next button
            IconButton(
              onPressed: _currentPage < widget.pageCount - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.primary,
              disabledColor: AppColors.textDisabled,
            ),
          ],
        ),

        // PageView with gesture detection for better web support
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.pageCount,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemBuilder: (context, index) => _buildPage(index),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tap zone control for configuring +/- areas
class _TapZoneControl extends ConsumerWidget {
  const _TapZoneControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapZone = ref.watch(tapZoneProvider);
    final tapZoneNotifier = ref.read(tapZoneProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle button and noob tip
          Row(
            children: [
              GestureDetector(
                onTap: () => tapZoneNotifier.toggleOverlay(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tapZone.showZoneOverlay
                        ? AppColors.primary.withOpacity( 0.2)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tapZone.showZoneOverlay
                          ? AppColors.primary.withOpacity( 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tapZone.showZoneOverlay
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 14,
                        color: tapZone.showZoneOverlay
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tapZone.showZoneOverlay ? 'Hide Zones' : 'Show Zones',
                        style: AppTypography.labelSmall.copyWith(
                          color: tapZone.showZoneOverlay
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Tap zones define +/- areas for reps',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textDisabled,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          // Slider row - visualizes actual tile proportions
          Row(
            children: [
              // Minus indicator (left = subtract zone)
              Icon(
                Icons.remove_rounded,
                size: 18,
                color: tapZone.zonePercent > 0
                    ? AppColors.error
                    : AppColors.textDisabled,
              ),
              const SizedBox(width: 8),
              // Slider - track represents tile (0-100%), max zone is 50%
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    // Active = red (minus zone), Inactive = green (plus zone)
                    activeTrackColor: AppColors.error.withOpacity( 0.7),
                    inactiveTrackColor: AppColors.primary.withOpacity( 0.5),
                    thumbColor: AppColors.textPrimary,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: tapZone.zonePercent,
                    min: 0.0,
                    max: 1.0, // Full range for visual representation
                    onChanged: (value) {
                      // Clamp to max 50% for actual zone
                      tapZoneNotifier.setZonePercent(value.clamp(0.0, 0.5));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Plus indicator (right = add zone)
              Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppConstants.spacingMd),
              // Percentage display
              SizedBox(
                width: 32,
                child: Text(
                  '${(tapZone.zonePercent * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tapZone.zonePercent > 0
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              // Quick set buttons
              _QuickSetButton(
                label: '0',
                isSelected: tapZone.zonePercent == 0,
                onTap: () => tapZoneNotifier.setZonePercent(0),
              ),
              const SizedBox(width: 4),
              _QuickSetButton(
                label: '25',
                isSelected: (tapZone.zonePercent - 0.25).abs() < 0.01,
                onTap: () => tapZoneNotifier.setZonePercent(0.25),
              ),
              const SizedBox(width: 4),
              _QuickSetButton(
                label: '50',
                isSelected: (tapZone.zonePercent - 0.5).abs() < 0.01,
                onTap: () => tapZoneNotifier.setZonePercent(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickSetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity( 0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
