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
import '../../../../l10n/app_localizations.dart';
import '../providers/lock_mode_provider.dart';
import '../providers/session_providers.dart';
import '../providers/timer_provider.dart';
import '../providers/active_reps_provider.dart';
import '../widgets/workout_timer.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String? exerciseId;

  const WorkoutScreen({super.key, this.exerciseId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  // 2026-08-07 Bugfix: Reps liegen jetzt im app-weiten activeRepsProvider
  // (vorher Widget-State -> beim Verlassen des Screens verloren).
  Map<String, int> get _repsMap => ref.read(activeRepsProvider);
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

  /// Reps um [delta] ändern (negativ = abziehen).
  ///
  /// Die Kachel liefert die Schrittweite (-1/+1/+5/+10), das Haptik-Feedback
  /// gibt sie selbst — hier wird nur der Zustand geführt.
  void _changeReps(String exerciseId, int delta) {
    if (delta == 0) return;

    // Check if this is the first rep and auto-start timer if enabled
    if (delta > 0) {
      final isFirstRep =
          _repsMap.values.every((r) => r == 0) || _repsMap.isEmpty;
      if (isFirstRep) {
        final workoutSettings = ref.read(workoutSettingsProvider).value;
        final timerState = ref.read(timerProvider);
        if (workoutSettings?.autoStartTimerOnFirstRep == true &&
            !timerState.isRunning &&
            timerState.elapsed == Duration.zero) {
          ref.read(timerProvider.notifier).startStopwatch();
        }
      }
    }

    setState(() {
      // Track session start on first rep
      if (delta > 0) _sessionStartTime ??= DateTime.now();
      ref.read(activeRepsProvider.notifier).addDelta(exerciseId, delta);
    });
  }

  void _resetReps(String exerciseId) {
    setState(() {
      ref.read(activeRepsProvider.notifier).reset(exerciseId);
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
        ref.read(activeRepsProvider.notifier).remove(exercise.id);
      });
    }
    // For updated: the stream will auto-refresh
  }

  /// Session beenden — ohne Rueckfrage.
  ///
  /// Der Bestaetigungsdialog kompensierte frueher ein mehrdeutiges
  /// Stop-Icon. Der Knopf heisst jetzt "Workout beenden", sitzt nur im
  /// pausierten Zustand und braucht deshalb keine Rueckfrage mehr — als
  /// Netz dient ein "Rueckgaengig" in der Snackbar.
  Future<void> _endSession() async {
    final timerState = ref.read(timerProvider);
    final hasData = timerState.elapsed.inSeconds > 0 || _repsMap.isNotEmpty;

    // Zustand fuer das Rueckgaengig-Machen sichern, bevor er faellt.
    final previousReps = Map<String, int>.from(_repsMap);
    final previousElapsed = timerState.elapsed;
    final previousTarget = timerState.target;
    final previousStart = _sessionStartTime;

    String? savedSessionId;
    if (hasData && _repsMap.values.any((reps) => reps > 0)) {
      savedSessionId = await _saveSession();
    }

    // Reset timer and reps
    ref.read(timerProvider.notifier).reset();
    setState(() {
      ref.read(activeRepsProvider.notifier).clear();
      _sessionStartTime = null;
    });

    if (!mounted) return;

    // Messenger vor der Navigation holen — danach ist dieser Screen weg.
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    context.go('/');

    if (!hasData) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceVariant,
        duration: const Duration(seconds: 6),
        content: Text(
          savedSessionId != null
              ? l10n.workoutSaved
              : l10n.workoutEnded,
          style: AppTypography.bodyMedium,
        ),
        action: SnackBarAction(
          label: l10n.commonUndo,
          textColor: AppColors.primary,
          onPressed: () => _undoEndSession(
            sessionId: savedSessionId,
            reps: previousReps,
            elapsed: previousElapsed,
            target: previousTarget,
            startedAt: previousStart,
          ),
        ),
      ),
    );
  }

  /// Ein beendetes Workout zurueckholen: gespeicherte Session wieder
  /// loeschen, Reps und Timer-Stand wiederherstellen.
  Future<void> _undoEndSession({
    required String? sessionId,
    required Map<String, int> reps,
    required Duration elapsed,
    required Duration? target,
    required DateTime? startedAt,
  }) async {
    if (sessionId != null) {
      try {
        await ref
            .read(sessionNotifierProvider.notifier)
            .deleteSession(sessionId);
      } catch (e) {
        debugPrint('Failed to undo session save: $e');
      }
    }

    ref.read(activeRepsProvider.notifier).restoreAll(reps);
    ref
        .read(timerProvider.notifier)
        .restore(elapsed: elapsed, target: target);
    _sessionStartTime = startedAt;
  }

  Future<String?> _saveSession() async {
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

    if (repsWithData.isEmpty) return null;

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
      return session.id;
    } catch (e) {
      // Silently fail - don't block ending the session
      debugPrint('Failed to save session: $e');
      return null;
    }
  }

  Widget _buildExerciseTile(Exercise exercise, bool isLocked) {
    return ExerciseTile(
      exercise: exercise,
      currentReps: _repsMap[exercise.id] ?? 0,
      isLocked: isLocked,
      onRepsDelta: (delta) => _changeReps(exercise.id, delta),
      onLongPress: _toggleLockMode,
      onEdit: () => _editExercise(exercise),
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
    // 2026-08-07: Reps liegen im app-weiten Provider — hier BEOBACHTEN, damit die UI
    // bei Aenderungen neu baut. Vorher erledigte das setState(); darauf darf sich der
    // Screen nicht mehr verlassen, sonst haengt die Anzeige nach dem Zurueckkehren.
    ref.watch(activeRepsProvider);

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
                    child: Text(AppLocalizations.of(context).commonError(error.toString())),
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
                      isLocked
                          ? AppLocalizations.of(context).workoutLocked
                          : AppLocalizations.of(context).workoutUnlocked,
                      style: AppTypography.labelSmall.copyWith(
                        color: isLocked ? AppColors.primary : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      AppLocalizations.of(context).workoutLockHintGesture,
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
                      AppLocalizations.of(context).workoutTapHint,
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
              label: Text(AppLocalizations.of(context).workoutAddExercise),
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
