import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../domain/entities/battle.dart';
import '../providers/battle_provider.dart';

/// Format milliseconds as mm:ss.d
String _formatMs(int ms) {
  final totalSeconds = ms ~/ 1000;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  final tenths = ((ms % 1000) ~/ 100).toString();
  return '$minutes:$seconds.$tenths';
}

/// Same-device battle: setup -> run (per player) -> result.
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
        actions: [
          if (state.phase != BattlePhase.setup)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Battle beenden',
              onPressed: () => ref.read(battleProvider.notifier).reset(),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state.phase) {
          BattlePhase.setup => const _BattleSetup(),
          BattlePhase.running => _BattleRun(state: state),
          BattlePhase.finished => _BattleResult(state: state),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

class _StageDraft {
  final TextEditingController exercise;
  final TextEditingController target;
  _StageDraft({String? exercise, String? target})
      : exercise = TextEditingController(text: exercise ?? ''),
        target = TextEditingController(text: target ?? '');
  void dispose() {
    exercise.dispose();
    target.dispose();
  }
}

class _BattleSetup extends ConsumerStatefulWidget {
  const _BattleSetup();

  @override
  ConsumerState<_BattleSetup> createState() => _BattleSetupState();
}

class _BattleSetupState extends ConsumerState<_BattleSetup> {
  final _p1 = TextEditingController(text: 'Spieler 1');
  final _p2 = TextEditingController(text: 'Spieler 2');
  final _capMin = TextEditingController();
  late List<_StageDraft> _stages;
  String _title = 'Battle';

  @override
  void initState() {
    super.initState();
    _stages = [_StageDraft(exercise: 'Dips', target: '100')];
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    _capMin.dispose();
    for (final stage in _stages) {
      stage.dispose();
    }
    super.dispose();
  }

  void _applyMelvinPreset() {
    HapticUtils.lightTap();
    setState(() {
      _title = 'Melvin Elite';
      for (final stage in _stages) {
        stage.dispose();
      }
      _stages = [
        _StageDraft(exercise: 'Klimmzüge', target: '50'),
        _StageDraft(exercise: 'Liegestütze', target: '100'),
      ];
      _capMin.text = '5';
    });
  }

  void _applyDipsPreset() {
    HapticUtils.lightTap();
    setState(() {
      _title = '100 Dips Sprint';
      for (final stage in _stages) {
        stage.dispose();
      }
      _stages = [_StageDraft(exercise: 'Dips', target: '100')];
      _capMin.clear();
    });
  }

  void _addStage() {
    HapticUtils.lightTap();
    setState(() => _stages.add(_StageDraft()));
  }

  void _removeStage(_StageDraft draft) {
    HapticUtils.lightTap();
    setState(() {
      _stages.remove(draft);
      draft.dispose();
    });
  }

  void _start() {
    final stages = <BattleStage>[];
    for (final draft in _stages) {
      final name = draft.exercise.text.trim();
      final target = int.tryParse(draft.target.text.trim());
      if (name.isEmpty || target == null || target <= 0) continue;
      stages.add(BattleStage(exercise: name, targetReps: target));
    }
    if (stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens eine Übung mit Ziel angeben')),
      );
      return;
    }

    final players = [
      _p1.text.trim().isEmpty ? 'Spieler 1' : _p1.text.trim(),
      _p2.text.trim().isEmpty ? 'Spieler 2' : _p2.text.trim(),
    ];
    final capMin = double.tryParse(_capMin.text.trim().replaceAll(',', '.'));
    final capMs = (capMin != null && capMin > 0)
        ? (capMin * 60 * 1000).round()
        : null;

    HapticUtils.heavyTap();
    ref.read(battleProvider.notifier).configure(
          title: _title.trim().isEmpty ? 'Battle' : _title.trim(),
          stages: stages,
          players: players,
          timeCapMs: capMs,
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        Text('Same-Device Battle', style: AppTypography.headline2),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          'Zwei Spieler, ein Gerät. Nacheinander gegen die Uhr — '
          'wer die Aufgabe schneller schafft, gewinnt.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppConstants.spacingLg),

        // Presets
        Text('Vorlagen', style: AppTypography.labelLarge),
        const SizedBox(height: AppConstants.spacingSm),
        Wrap(
          spacing: AppConstants.spacingSm,
          runSpacing: AppConstants.spacingSm,
          children: [
            ActionChip(
              label: const Text('Melvin Elite'),
              backgroundColor: AppColors.surfaceVariant,
              onPressed: _applyMelvinPreset,
            ),
            ActionChip(
              label: const Text('100 Dips Sprint'),
              backgroundColor: AppColors.surfaceVariant,
              onPressed: _applyDipsPreset,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingLg),

        // Players
        Text('Spieler', style: AppTypography.labelLarge),
        const SizedBox(height: AppConstants.spacingSm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _p1,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(hintText: 'Spieler 1'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: TextField(
                controller: _p2,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(hintText: 'Spieler 2'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingLg),

        // Task
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Aufgabe: $_title', style: AppTypography.labelLarge),
            Text('Reihenfolge zählt', style: AppTypography.labelSmall),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        ..._stages.asMap().entries.map((entry) {
          final index = entry.key;
          final draft = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text('${index + 1}',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary)),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: draft.exercise,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(hintText: 'Übung'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: draft.target,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(hintText: 'Reps'),
                  ),
                ),
                IconButton(
                  onPressed:
                      _stages.length > 1 ? () => _removeStage(draft) : null,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addStage,
          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          label: Text('Stufe hinzufügen',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.primary)),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Optional cap
        TextField(
          controller: _capMin,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Zeitlimit in Minuten (optional, z.B. 5)',
            prefixIcon: Icon(Icons.timer_outlined),
          ),
        ),
        const SizedBox(height: AppConstants.spacingLg),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.sports_kabaddi_rounded),
            label: const Text('Battle starten'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

class _BattleRun extends ConsumerWidget {
  final BattleState state;

  const _BattleRun({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(battleProvider.notifier);
    final stage = state.activeStage;
    final remaining = state.remainingMs;
    final displayMs = remaining ?? state.elapsedMs;
    final timeIsLow = remaining != null && remaining <= 30000;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        children: [
          // Player + round indicator
          Text(
            state.currentPlayerName,
            style: AppTypography.headline2.copyWith(color: AppColors.primary),
          ),
          Text(
            'Spieler ${state.currentPlayer + 1} von ${state.players.length}'
            '  •  ${state.title}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Stopwatch / countdown
          Text(
            _formatMs(displayMs),
            style: AppTypography.timerLarge.copyWith(
              color: timeIsLow ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          Text(
            remaining != null ? 'verbleibend' : 'gelaufen',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Current stage
          if (stage != null) ...[
            Text(stage.exercise, style: AppTypography.headline3),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              '${state.currentStageReps} / ${stage.targetReps}',
              style: AppTypography.repCount,
            ),
            if (state.stages.length > 1)
              Text(
                'Stufe ${state.currentStage + 1} von ${state.stages.length}',
                style: AppTypography.labelSmall,
              ),
          ],
          const Spacer(),

          // Big tap-to-count button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                HapticUtils.mediumTap();
                notifier.addRep();
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          color: AppColors.primary, size: 48),
                      const SizedBox(height: AppConstants.spacingSm),
                      Text('+1 Rep',
                          style: AppTypography.headline3
                              .copyWith(color: AppColors.primary)),
                      Text('tippen zum Zählen',
                          style: AppTypography.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticUtils.lightTap();
                    notifier.removeRep();
                  },
                  child: const Text('-1'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticUtils.lightTap();
                    notifier.addRep(5);
                  },
                  child: const Text('+5'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmSurrender(context, notifier),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Aufgeben'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSurrender(
      BuildContext context, BattleNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Aufgeben?', style: AppTypography.headline3),
        content: Text(
          'Der aktuelle Versuch zählt dann als nicht geschafft.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Weiter'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Aufgeben',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) notifier.surrender();
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

class _BattleResult extends ConsumerWidget {
  final BattleState state;

  const _BattleResult({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rank: completed players first (fastest time), then non-completers.
    final ranked = [...state.scores]..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? -1 : 1;
        if (a.completed) return a.elapsedMs.compareTo(b.elapsedMs);
        return b.totalReps.compareTo(a.totalReps);
      });
    final winner = ranked.isNotEmpty && ranked.first.completed
        ? ranked.first
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.spacingLg),
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.accent, size: 64),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            winner != null ? '${winner.player} gewinnt!' : 'Kein Sieger',
            style: AppTypography.headline2,
            textAlign: TextAlign.center,
          ),
          Text(state.title, style: AppTypography.bodySmall),
          const SizedBox(height: AppConstants.spacingLg),
          Expanded(
            child: ListView.separated(
              itemCount: ranked.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final score = ranked[index];
                final isWinner = index == 0 && score.completed;
                return Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: isWinner
                          ? AppColors.accent
                          : AppColors.surfaceVariant,
                      width: isWinner ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('${index + 1}',
                          style: AppTypography.headline3.copyWith(
                            color: isWinner
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          )),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(score.player,
                                style: AppTypography.bodyLarge),
                            Text(
                              score.completed
                                  ? 'geschafft'
                                  : 'aufgegeben • ${score.totalReps} Reps',
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        score.completed ? _formatMs(score.elapsedMs) : '—',
                        style: AppTypography.timerSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(battleProvider.notifier).reset(),
                  child: const Text('Neues Battle'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(battleProvider.notifier).rematch(),
                  child: const Text('Revanche'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
