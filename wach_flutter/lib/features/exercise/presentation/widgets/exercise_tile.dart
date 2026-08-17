import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/exercise.dart';

/// Large exercise tile for workout screen.
///
/// Tapping the tile flips it over to a keypad with -1 / +1 / +5 / +10
/// buttons. This replaces the earlier double-tap-with-zones interaction,
/// which needed two taps per single rep and had no visible affordance.
///
/// The front side is for reading only, the back side holds every control:
/// that split is what made the separate locked/unlocked mode unnecessary.
class ExerciseTile extends StatefulWidget {
  final Exercise exercise;
  final int currentReps;
  final int? targetReps;
  final Duration elapsedTime;
  final Duration? targetTime;

  /// Called with the amount to add (may be negative).
  final void Function(int delta)? onRepsDelta;
  final VoidCallback? onEdit;

  /// Loeschen sitzt auf der Rueckseite direkt neben dem Bearbeiten — es
  /// gehoert zu den Handgriffen an der Uebung selbst, nicht in ein Fenster
  /// dahinter.
  final VoidCallback? onDelete;

  /// Ob die Rueckseite mit dem Tastenfeld gezeigt wird.
  ///
  /// Der Zustand liegt ausserhalb der Kachel, damit er einen Seitenwechsel
  /// uebersteht: beim Blaettern wird die Kachel aus dem Baum genommen und
  /// spaeter neu gebaut — ein Feld in dieser Klasse waere dann verloren.
  final bool istOffen;

  /// Wunsch, die Kachel umzudrehen. Ob das geschieht, entscheidet die
  /// Stelle, die [istOffen] fuehrt.
  final VoidCallback? onToggle;

  const ExerciseTile({
    super.key,
    required this.exercise,
    this.currentReps = 0,
    this.targetReps,
    this.elapsedTime = Duration.zero,
    this.targetTime,
    this.onRepsDelta,
    this.onEdit,
    this.onDelete,
    this.istOffen = false,
    this.onToggle,
  });

  @override
  State<ExerciseTile> createState() => _ExerciseTileState();
}

/// Ab dieser Breite passt die volle Kopfzeile (Name, Zaehler, alle
/// Knoepfe) nebeneinander. Darunter stehen zwei Kacheln nebeneinander.
const double _schmaleKachel = 200;

/// Darunter bleibt nur noch der Haken stehen.
///
/// So schmal wird eine Kachel, wenn nebenan eine aufgeklappte den groesseren
/// Anteil bekommt. Bearbeiten und Loeschen weichen dann — auf gut 100 dp
/// waeren drei Knoepfe ohnehin nicht mehr sicher zu treffen, und beide sind
/// erreichbar, sobald die Kachel wieder Platz hat.
const double _sehrSchmaleKachel = 150;

class _ExerciseTileState extends State<ExerciseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: AppConstants.quickAnimationDuration,
      // Eine bereits offene Kachel steht sofort auf der Rueckseite, statt
      // sich nach dem Blaettern noch einmal sichtbar umzudrehen.
      value: widget.istOffen ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(ExerciseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.istOffen == oldWidget.istOffen) return;
    widget.istOffen ? _flipController.forward() : _flipController.reverse();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  double get _progress {
    final target = widget.targetReps ?? widget.exercise.targetReps;
    if (target == null || target == 0) return 0;
    return (widget.currentReps / target).clamp(0.0, 1.0);
  }

  bool get _isCompleted => _progress >= 1.0;

  /// Umdrehen anfordern.
  ///
  /// Waagerechtes Wischen loeste das frueher ebenfalls aus. Das ist
  /// entfallen, weil auf derselben Achse jetzt der Seitenwechsel liegt —
  /// zwei Gesten am selben Ort schliessen sich aus, und im Wettstreit
  /// gewann immer die Kachel, sodass sich keine Seite mehr wechseln liess.
  void _toggleKeypad() {
    HapticUtils.lightTap();
    widget.onToggle?.call();
  }

  void _applyDelta(int delta) {
    // Never count below zero: a -1 on an empty tile should do nothing
    // rather than push the counter negative.
    if (delta < 0 && widget.currentReps <= 0) return;
    HapticUtils.mediumTap();
    widget.onRepsDelta?.call(delta);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque so the whole tile area is tappable, including the padding
      // between the counter and the border. With the default
      // `deferToChild` a tap that landed on a gap — or mid-flip, when the
      // rotated child is only a few pixels wide — hit nothing at all.
      behavior: HitTestBehavior.opaque,
      // Ein Tipp auf freie Flaeche dreht die Kachel — auf der Vorderseite
      // auf, auf der Rueckseite wieder zu. Die Zaehltasten und die beiden
      // Knoepfe liegen tiefer und bekommen ihren Tipp weiterhin zuerst,
      // hier landet nur, was daneben geht.
      onTap: _toggleKeypad,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, _) {
          final angle = _flipController.value * math.pi;
          final isBack = _flipController.value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                // Counter-rotate so the back side is not mirrored.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildKeypadSide(),
                  )
                : _buildFrontSide(),
          );
        },
      ),
    );
  }

  BoxDecoration _tileDecoration({required bool highlighted}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      border: Border.all(
        color: highlighted
            ? AppColors.secondary.withValues(alpha: 0.6)
            : _isCompleted
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.surfaceVariant,
        width: _isCompleted || highlighted ? 2 : 1,
      ),
    );
  }

  Widget _buildRepCounter({required bool compact}) {
    final target = widget.targetReps ?? widget.exercise.targetReps;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${widget.currentReps}',
            style: (compact ? AppTypography.headline2 : AppTypography.repCount)
                .copyWith(
              color: _isCompleted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (target != null)
            Text(
              ' / $target',
              style: compact
                  ? AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    )
                  : AppTypography.repTarget,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 4,
        backgroundColor: AppColors.progressBackground,
        valueColor: AlwaysStoppedAnimation(
          _isCompleted ? AppColors.primary : AppColors.primaryLight,
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: _tileDecoration(highlighted: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
          Expanded(
            child: Center(child: _buildRepCounter(compact: false)),
          ),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildKeypadSide() {
    return LayoutBuilder(
      builder: (context, kachel) {
        // Bezugsgroesse fuer die Tastenhoehe ist die ganze Kachel, nicht
        // der Rest unter der Kopfzeile — sonst haengt die Hoehe daran, wie
        // hoch die Kopfzeile gerade ausfaellt.
        final halbeKachel = kachel.maxHeight / 2;
        return _buildKeypadBody(context, halbeKachel, kachel.maxWidth);
      },
    );
  }

  /// Die vier Zaehltasten nebeneinander.
  ///
  /// Auch auf halbbreiten Kacheln bleibt es bei einer Reihe: rund 28 dp je
  /// Taste reichen hier aus, weil die Tasten hoch sind und dicht
  /// beieinanderliegen — die Hand bleibt zwischen zwei Zaehlern ohnehin an
  /// derselben Stelle.
  Widget _buildKeypadButtons() {
    Widget taste(String label, int delta) => _RepButton(
          label: label,
          isSubtract: delta < 0,
          enabled: delta > 0 || widget.currentReps > 0,
          onTap: () => _applyDelta(delta),
        );

    return Row(
      children: [
        Expanded(child: taste('-1', -1)),
        const SizedBox(width: AppConstants.spacingXs),
        Expanded(child: taste('+1', 1)),
        const SizedBox(width: AppConstants.spacingXs),
        Expanded(child: taste('+5', 5)),
        const SizedBox(width: AppConstants.spacingXs),
        Expanded(child: taste('+10', 10)),
      ],
    );
  }

  Widget _buildKeypadBody(
    BuildContext context,
    double halbeKachel,
    double breite,
  ) {
    // Stehen zwei Kacheln nebeneinander, bleiben nur rund 140 dp Breite.
    // Name, Zaehler und zwei Knoepfe passen dann nicht mehr in eine Zeile;
    // der Name weicht, weil die Vorderseite ihn ohnehin traegt und man die
    // Kachel gerade selbst angetippt hat.
    final schmal = breite < _schmaleKachel;
    final sehrSchmal = breite < _sehrSchmaleKachel;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: _tileDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: name, live counter, close button.
          Row(
            children: [
              if (schmal)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildRepCounter(compact: true),
                  ),
                )
              else ...[
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                // Darf schrumpfen: mit dreistelligen Zielen ("100 / 100")
                // und drei Knoepfen daneben wird die Zeile sonst zu breit.
                Flexible(child: _buildRepCounter(compact: true)),
              ],
              const SizedBox(width: AppConstants.spacingXs),
              // Bearbeiten und Loeschen liegen nur auf der Rueckseite: die
              // Vorderseite bleibt ein reiner Zaehler, damit neben der
              // Zaehlflaeche nichts sitzt, was man mitten im Satz
              // versehentlich trifft.
              if (widget.onDelete != null && !sehrSchmal) ...[
                _TileIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  tooltip: AppLocalizations.of(context).exerciseDeleteTooltip,
                  onTap: widget.onDelete!,
                  schmal: schmal,
                ),
                const SizedBox(width: AppConstants.spacingXs),
              ],
              if (widget.onEdit != null && !sehrSchmal) ...[
                _TileIconButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.secondary,
                  tooltip: AppLocalizations.of(context).exerciseEdit,
                  onTap: widget.onEdit!,
                  schmal: schmal,
                ),
                const SizedBox(width: AppConstants.spacingXs),
              ],
              _TileIconButton(
                icon: Icons.check_rounded,
                color: AppColors.primary,
                tooltip: AppLocalizations.of(context).commonDone,
                onTap: _toggleKeypad,
                schmal: schmal,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          // Die Tasten nehmen hoechstens die halbe Kachel ein. Vorher
          // fuellten sie den ganzen Rest — auf breiten Anzeigen wurden
          // daraus riesige Flaechen, die nichts gewinnen: getroffen wird
          // eine Taste ab etwa Fingerbreite ohnehin sicher.
          Expanded(
            child: LayoutBuilder(
              builder: (context, rest) {
                final hoehe = math.min(halbeKachel, rest.maxHeight);
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: hoehe,
                    child: _buildKeypadButtons(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single rep button on the keypad side of the tile.
class _RepButton extends StatelessWidget {
  final String label;
  final bool isSubtract;
  final bool enabled;
  final VoidCallback onTap;

  const _RepButton({
    required this.label,
    required this.onTap,
    this.isSubtract = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSubtract ? AppColors.error : AppColors.primary;
    final effectiveColor = enabled ? color : AppColors.textDisabled;

    return Material(
      color: effectiveColor.withValues(alpha: enabled ? 0.15 : 0.05),
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTargetSize,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: effectiveColor.withValues(alpha: enabled ? 0.5 : 0.2),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.headline3.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small icon button with a full-size touch target and a visible outline.
class _TileIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  /// Auf halbbreiten Kacheln schmaler, damit Zaehler und die drei Knoepfe
  /// nebeneinander bleiben. Die Hoehe bleibt unangetastet — in der
  /// Wischrichtung des Daumens aendert sich also nichts.
  final bool schmal;

  const _TileIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.schmal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: schmal ? 36 : AppConstants.minTouchTargetSize,
            height: 44,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
