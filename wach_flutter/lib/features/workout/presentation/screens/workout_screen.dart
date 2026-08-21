import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercise/domain/entities/exercise.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../exercise/presentation/widgets/add_exercise_modal.dart';
import '../../../exercise/presentation/widgets/delete_exercise_dialog.dart';
import '../../../exercise/presentation/widgets/edit_exercise_modal.dart';
import '../../../exercise/presentation/widgets/exercise_tile.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../gamification/presentation/widgets/level_up_overlay.dart';
import '../../data/models/session_model.dart';
import '../../../settings/data/settings_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/session_providers.dart';
import '../providers/open_tile_provider.dart';
import '../providers/session_start_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/active_reps_provider.dart';
import '../widgets/workout_timer.dart';

/// Die Uebungskacheln einer Seite, untereinander in voller Breite.
///
/// Bewusst ohne zweite Spalte: halbierte Kacheln liessen der aufgeklappten
/// Rueckseite zu wenig Platz fuer Zaehler, Knoepfe und Zaehltasten. Passen
/// nicht alle Uebungen auf eine Seite, wird stattdessen geblaettert.
///
/// Die Hoehe ist auf [AppConstants.maxExerciseTileHeight] gedeckelt: bei
/// einer einzigen Uebung fuellte die Kachel sonst den ganzen Bildschirm,
/// ohne dass mehr darauf zu sehen waere.
Widget buildTileLayout(
  List<Exercise> exercises,
  Widget Function(Exercise) buildTile,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final luecken = AppConstants.spacingSm * (exercises.length - 1);
      final proKachel =
          (constraints.maxHeight - luecken) / exercises.length;
      final hoehe = math.min(proKachel, AppConstants.maxExerciseTileHeight);

      return Column(
        children: [
          for (var i = 0; i < exercises.length; i++)
            Padding(
              key: ValueKey(exercises[i].id),
              padding: EdgeInsets.only(
                bottom:
                    i < exercises.length - 1 ? AppConstants.spacingSm : 0,
              ),
              child: SizedBox(
                height: hoehe,
                child: buildTile(exercises[i]),
              ),
            ),
        ],
      );
    },
  );
}

class WorkoutScreen extends ConsumerStatefulWidget {
  final String? exerciseId;

  const WorkoutScreen({super.key, this.exerciseId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

/// Wie lange die Meldung nach dem Beenden stehen bleibt.
const Duration _meldungsdauer = Duration(seconds: 6);

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  // 2026-08-07 Bugfix: Reps liegen jetzt im app-weiten activeRepsProvider
  // (vorher Widget-State -> beim Verlassen des Screens verloren).
  Map<String, int> get _repsMap => ref.read(activeRepsProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Seed default exercises if empty
      ref.read(exerciseProvider.notifier).seedDefaultExercisesIfEmpty();
      // Timer starts via play button, not automatically
    });
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
        final timerState = ref.read(sessionTimerProvider);
        if (workoutSettings?.autoStartTimerOnFirstRep == true &&
            !timerState.isRunning &&
            timerState.elapsed == Duration.zero) {
          ref.read(sessionTimerProvider.notifier).startStopwatch();
        }
      }
    }

    // Kein setState: `build` beobachtet `activeRepsProvider`, die Anzeige
    // zieht dadurch von selbst nach. Ein zusaetzliches setState wuerde nur
    // verschleiern, woher die Aktualisierung kommt.
    if (delta > 0) ref.read(sessionStartProvider.notifier).startIfUnset();
    ref.read(activeRepsProvider.notifier).addDelta(exerciseId, delta);
  }

  void _resetReps(String exerciseId) {
    ref.read(activeRepsProvider.notifier).reset(exerciseId);
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
      ref.read(activeRepsProvider.notifier).remove(exercise.id);
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
    final timerState = ref.read(sessionTimerProvider);
    final hasData = timerState.elapsed.inSeconds > 0 || _repsMap.isNotEmpty;

    // Zustand fuer das Rueckgaengig-Machen sichern, bevor er faellt.
    final previousReps = Map<String, int>.from(_repsMap);
    final previousElapsed = timerState.elapsed;
    final previousTarget = timerState.target;
    final previousStart = ref.read(sessionStartProvider);
    // Vor dem Leeren merken: danach steht der Zaehler wieder auf null.
    final verdientePunkte =
        previousReps.values.fold<int>(0, (summe, reps) => summe + reps);
    // Die Stufe vor dieser Session — nachher wird verglichen.
    final stufeVorher = ref.read(gamificationProvider).stufe;

    String? savedSessionId;
    if (hasData && _repsMap.values.any((reps) => reps > 0)) {
      savedSessionId = await _saveSession();
    }

    // Reset timer and reps
    ref.read(sessionTimerProvider.notifier).reset();
    ref.read(activeRepsProvider.notifier).clear();
    ref.read(sessionStartProvider.notifier).clear();

    if (!mounted) return;

    // Messenger vor der Navigation holen — danach ist dieser Screen weg.
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Und den Provider-Container gleich mit: die Meldung ueberlebt den
    // Screen, ihr "Rueckgaengig" darf deshalb nicht ueber `ref` dieses
    // Widgets laufen. Genau daran scheiterte es vorher lautlos — der
    // Fehler landete im try/catch beim Loeschen und die Session blieb
    // gespeichert.
    final container = ProviderScope.containerOf(context, listen: false);
    context.go('/');

    if (!hasData) return;

    // Stufenaufstieg feiern, bevor die Meldung kommt — sonst liegt die
    // Meldung hinter dem Overlay.
    final stufeNachher = ref.read(gamificationProvider).stufe;
    if (stufeNachher > stufeVorher && mounted) {
      await zeigeStufenaufstieg(context, stufeNachher);
    }

    // Die Meldung folgt dem Wechsel auf die Startseite.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zeigeAbschlussMeldung(
        messenger,
        l10n,
        savedSessionId: savedSessionId,
        verdientePunkte: verdientePunkte,
        container: container,
        previousReps: previousReps,
        previousElapsed: previousElapsed,
        previousTarget: previousTarget,
        previousStart: previousStart,
      );
    });
  }

  /// Die Meldung nach dem Beenden, samt "Rueckgaengig".
  static void _zeigeAbschlussMeldung(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n, {
    required String? savedSessionId,
    required int verdientePunkte,
    required ProviderContainer container,
    required Map<String, int> previousReps,
    required Duration previousElapsed,
    required Duration? previousTarget,
    required DateTime? previousStart,
  }) {
    messenger.hideCurrentSnackBar();
    final gezeigt = messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceVariant,
        duration: _meldungsdauer,
        content: Text(
          savedSessionId != null
              // Die verdienten Punkte gleich mitnennen — sonst muesste man
              // auf der Startseite nachrechnen, was das Training gebracht
              // hat.
              ? '${l10n.workoutSaved} · '
                  '${l10n.gamificationPointsEarned(verdientePunkte)}'
              : l10n.workoutEnded,
          style: AppTypography.bodyMedium,
        ),
        action: SnackBarAction(
          label: l10n.commonUndo,
          textColor: AppColors.primary,
          onPressed: () => _undoEndSession(
            container,
            sessionId: savedSessionId,
            reps: previousReps,
            elapsed: previousElapsed,
            target: previousTarget,
            startedAt: previousStart,
          ),
        ),
      ),
    );

    // Selbst schliessen, statt sich auf den eingebauten Zeitgeber zu
    // verlassen.
    //
    // Der startet in Flutter erst, wenn die Einblend-Bewegung durch ist.
    // Weil hier gleichzeitig der Bildschirm wechselt und dabei das
    // Scaffold ausgetauscht wird, an dem die Meldung haengt, kam die
    // Bewegung nie zum Abschluss — die Meldung blieb dauerhaft stehen. Ein
    // Vorsprung von einem Bild oder von der Dauer des Uebergangs hat daran
    // nichts geaendert, deshalb dieser Weg.
    //
    // Der Zeitgeber wird abgeraeumt, sobald die Meldung weg ist — durch
    // "Rueckgaengig", durch Wegtippen oder durch ihn selbst. Sonst laeuft
    // er ins Leere weiter und wuerde eine spaetere Meldung schliessen.
    final zeitgeber = Timer(_meldungsdauer, messenger.hideCurrentSnackBar);
    gezeigt.closed.whenComplete(zeitgeber.cancel);
  }

  /// Ein beendetes Workout zurueckholen: gespeicherte Session wieder
  /// loeschen, Reps und Timer-Stand wiederherstellen.
  ///
  /// Bekommt den Container ausdruecklich uebergeben und ist `static`, damit
  /// hier gar nicht erst auf `ref` dieses Widgets zugegriffen werden kann —
  /// das Widget ist zu diesem Zeitpunkt bereits weg.
  static Future<void> _undoEndSession(
    ProviderContainer container, {
    required String? sessionId,
    required Map<String, int> reps,
    required Duration elapsed,
    required Duration? target,
    required DateTime? startedAt,
  }) async {
    // Zuerst das Zurueckholen, dann das Loeschen: schlaegt das Loeschen
    // fehl, steht die Session wenigstens wieder da, wo sie war.
    container.read(activeRepsProvider.notifier).restoreAll(reps);
    container
        .read(sessionTimerProvider.notifier)
        .restore(elapsed: elapsed, target: target);
    container.read(sessionStartProvider.notifier).restore(startedAt);

    if (sessionId != null) {
      try {
        await container
            .read(sessionProvider.notifier)
            .deleteSession(sessionId);
      } catch (e) {
        debugPrint('Failed to undo session save: $e');
      }
    }
  }

  Future<String?> _saveSession() async {
    final timerState = ref.read(sessionTimerProvider);
    final exercisesAsync = ref.read(exercisesStreamProvider);
    final exercises = exercisesAsync.value ?? [];

    // Filter to only exercises with reps > 0
    final repsWithData = Map<String, int>.fromEntries(
      _repsMap.entries.where((e) => e.value > 0),
    );

    if (repsWithData.isEmpty) return null;

    // Namen und Ziele, wie sie jetzt gelten. Die Ziele gehoeren
    // ausdruecklich mit in die Session: spaeter laesst sich sonst nicht
    // mehr sagen, ob 35 Klimmzuege das Vorhaben waren oder ein Abbruch bei
    // einem Ziel von 50.
    final exerciseNames = <String, String>{};
    final exerciseTargets = <String, int>{};
    for (final exercise in exercises) {
      if (!repsWithData.containsKey(exercise.id)) continue;
      exerciseNames[exercise.id] = exercise.name;
      final ziel = exercise.targetReps;
      if (ziel != null && ziel > 0) exerciseTargets[exercise.id] = ziel;
    }

    final session = SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: ref.read(sessionStartProvider) ?? DateTime.now(),
      finishedAt: DateTime.now(),
      durationSeconds: timerState.elapsed.inSeconds,
      exerciseReps: repsWithData,
      exerciseNames: exerciseNames,
      exerciseTargets: exerciseTargets,
    );

    try {
      await ref.read(sessionProvider.notifier).saveSession(session);
      return session.id;
    } catch (e) {
      // Silently fail - don't block ending the session
      debugPrint('Failed to save session: $e');
      return null;
    }
  }

  Widget _buildExerciseTile(Exercise exercise) {
    return ExerciseTile(
      // Ohne Schluessel haengt der Zustand einer Kachel an ihrer Position:
      // wird eine Uebung geloescht, ruecken die folgenden auf und erben,
      // ob die Kachel gerade aufgeklappt war.
      key: ValueKey(exercise.id),
      exercise: exercise,
      currentReps: _repsMap[exercise.id] ?? 0,
      onRepsDelta: (delta) => _changeReps(exercise.id, delta),
      onEdit: () => _editExercise(exercise),
      onDelete: () => _deleteExercise(exercise),
      // Auf- und zugeklappt wird im Provider gefuehrt, nicht in der
      // Kachel: beim Blaettern verlaesst sie den Baum, ein Feld in ihr
      // waere danach vergessen.
      istOffen: ref.watch(openTilesProvider).contains(exercise.id),
      onToggle: () =>
          ref.read(openTilesProvider.notifier).umschalten(exercise.id),
    );
  }

  /// Uebung loeschen — mit Rueckfrage, weil der Knopf jetzt direkt neben
  /// den Zaehltasten sitzt.
  Future<void> _deleteExercise(Exercise exercise) async {
    if (!await zeigeLoeschRueckfrage(context, exercise)) return;

    HapticUtils.heavyTap();
    final erfolg = await ref
        .read(exerciseProvider.notifier)
        .deleteExercise(exercise.id);

    if (erfolg) {
      ref.read(activeRepsProvider.notifier).remove(exercise.id);
    }
  }

  Widget _buildExerciseLayout(List<Exercise> exercises) {
    if (exercises.length <= AppConstants.maxExercisesPerPage) {
      return buildTileLayout(exercises, _buildExerciseTile);
    }
    return _PagedExercises(
      exercises: exercises,
      buildTile: _buildExerciseTile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesStreamProvider);
    // 2026-08-07: Reps liegen im app-weiten Provider — hier BEOBACHTEN, damit die UI
    // bei Aenderungen neu baut. Vorher erledigte das setState(); darauf darf sich der
    // Screen nicht mehr verlassen, sonst haengt die Anzeige nach dem Zurueckkehren.
    ref.watch(activeRepsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _WorkoutHeader(
              onBack: () => context.go('/'),
              onAddExercise: () => showAddExerciseModal(context),
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
                  TimerControls(onEndSession: _endSession),
                ],
              ),
            ),

            // Exercise Tiles
            Expanded(
              child: exercisesAsync.when(
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return _EmptyState(
                      onAddExercise: () => showAddExerciseModal(context),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                    ),
                    child: _buildExerciseLayout(exercises),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(AppLocalizations.of(context)
                      .commonError(error.toString())),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),
          ],
        ),
      ),
    );
  }
}

/// Kopfzeile des Workout-Screens: zurueck, Hinweis, Uebung hinzufuegen.
///
/// Ersetzt die frueherer Sperr-Statusleiste. Der Sperrmodus existierte, um
/// im Training Fehleingaben zu verhindern — das erledigt jetzt die
/// Kachel-Rueckseite: die Vorderseite ist eine reine Anzeige, jede Aktion
/// sitzt eine Drehung tiefer.
class _WorkoutHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAddExercise;

  const _WorkoutHeader({
    required this.onBack,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingXs,
        horizontal: AppConstants.spacingSm,
      ),
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            color: AppColors.textSecondary,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            constraints: const BoxConstraints(
              minWidth: AppConstants.minTouchTargetSize,
              minHeight: AppConstants.minTouchTargetSize,
            ),
          ),
          Expanded(
            child: Text(
              l10n.workoutTapHint,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
          // Mit Umrandung: ohne sie schwebte das Plus frei in der Kopfzeile
          // und war als Schaltflaeche kaum zu erkennen.
          IconButton(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: l10n.workoutAddExercise,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              minimumSize: const Size(
                AppConstants.minTouchTargetSize,
                AppConstants.minTouchTargetSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddExercise;

  const _EmptyState({
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            l10n.exerciseEmptyTitle,
            style: AppTypography.headline3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            l10n.exerciseEmptySubtitle,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add_rounded),
            label: Text(AppLocalizations.of(context).workoutAddExercise),
          ),
        ],
      ),
    );
  }
}

// Die Schnellauswahl-Chips sind ins Hinzufuegen-Modal gewandert
// (add_exercise_modal.dart). Frueher sassen sie unter den Kacheln und waren
// nur im entsperrten Modus sichtbar — ohne diesen Modus kosten sie im
// Workout-Screen nur Hoehe, im Modal stehen sie genau dort, wo man eine
// Uebung aussucht.

/// Blaettern, wenn zu viele Uebungen fuer eine Seite da sind.
///
/// Erst ab [AppConstants.maxExercisesPerPage] — bis dahin steht alles
/// untereinander, denn Umblaettern mitten im Satz ist ein Griff zu viel.
/// Darueber hinaus waeren die Kacheln aber so flach, dass auf der
/// Rueckseite nichts mehr zu treffen ist; dann ist Blaettern das kleinere
/// Uebel.
class _PagedExercises extends StatefulWidget {
  final List<Exercise> exercises;
  final Widget Function(Exercise) buildTile;

  const _PagedExercises({
    required this.exercises,
    required this.buildTile,
  });

  @override
  State<_PagedExercises> createState() => _PagedExercisesState();
}

class _PagedExercisesState extends State<_PagedExercises> {
  late final PageController _controller = PageController();
  int _seite = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _seitenzahl =>
      (widget.exercises.length / AppConstants.maxExercisesPerPage).ceil();

  void _zuSeite(int seite) {
    if (seite < 0 || seite >= _seitenzahl) return;
    _controller.animateToPage(
      seite,
      duration: AppConstants.defaultAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  List<Exercise> _uebungenDerSeite(int seite) {
    const proSeite = AppConstants.maxExercisesPerPage;
    final von = seite * proSeite;
    final bis = math.min(von + proSeite, widget.exercises.length);
    return widget.exercises.sublist(von, bis);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            // Wischen wechselt die Seite. Die Kacheln reagieren nur noch
            // auf Tippen, damit sich die beiden Gesten nicht mehr im Weg
            // stehen.
            itemCount: _seitenzahl,
            onPageChanged: (seite) => setState(() => _seite = seite),
            itemBuilder: (context, seite) => buildTileLayout(
              _uebungenDerSeite(seite),
              widget.buildTile,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppConstants.spacingXs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _seite > 0 ? () => _zuSeite(_seite - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.primary,
                disabledColor: AppColors.textDisabled,
                visualDensity: VisualDensity.compact,
              ),
              // Punkte sind ebenfalls antippbar — bei zwei oder drei Seiten
              // ist das der kuerzeste Weg.
              for (var i = 0; i < _seitenzahl; i++)
                GestureDetector(
                  onTap: () => _zuSeite(i),
                  child: Padding(
                    // Grosszuegig gepolstert: der Punkt selbst waere ein zu
                    // kleines Ziel.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: AnimatedContainer(
                      duration: AppConstants.quickAnimationDuration,
                      width: i == _seite ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _seite
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              IconButton(
                onPressed: _seite < _seitenzahl - 1
                    ? () => _zuSeite(_seite + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.primary,
                disabledColor: AppColors.textDisabled,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

