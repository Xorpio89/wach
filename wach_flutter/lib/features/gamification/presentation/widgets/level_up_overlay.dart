import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Kurze Feier beim Stufenaufstieg.
///
/// Bewusst ein Overlay und kein Dialog: ein Dialog müsste weggetippt
/// werden und stünde einem zweiten Durchgang im Weg. Das hier verschwindet
/// von selbst, lässt sich aber auch antippen.
Future<void> zeigeStufenaufstieg(BuildContext context, int stufe) async {
  HapticUtils.heavyTap();
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      // Durchsichtig, damit die Startseite dahinter stehen bleibt.
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => _StufenaufstiegSeite(stufe: stufe),
    ),
  );
}

class _StufenaufstiegSeite extends StatefulWidget {
  final int stufe;

  const _StufenaufstiegSeite({required this.stufe});

  @override
  State<_StufenaufstiegSeite> createState() => _StufenaufstiegSeiteState();
}

class _StufenaufstiegSeiteState extends State<_StufenaufstiegSeite>
    with SingleTickerProviderStateMixin {
  /// Lang genug, um die Bewegung zu sehen, kurz genug, um nicht zu warten.
  static const _dauer = Duration(milliseconds: 2600);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _dauer,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      // Antippen beendet die Feier sofort.
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Strahlen nach aussen, hinter der Zahl.
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: CustomPaint(
                      painter: _StrahlenMaler(fortschritt: t),
                    ),
                  ),
                  Opacity(
                    opacity: _einblenden(t),
                    child: Transform.scale(
                      scale: _skalieren(t),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.stufe}',
                            style: AppTypography.timerLarge.copyWith(
                              color: AppColors.primary,
                              fontSize: 96,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          Text(
                            l10n.gamificationLevelUp(widget.stufe),
                            textAlign: TextAlign.center,
                            style: AppTypography.headline3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Schnell da, am Ende weich weg.
  double _einblenden(double t) {
    if (t < 0.12) return t / 0.12;
    if (t > 0.85) return (1 - t) / 0.15;
    return 1;
  }

  /// Ein kurzes Ueberschwingen, damit die Zahl "landet".
  double _skalieren(double t) {
    if (t >= 0.35) return 1;
    final x = t / 0.35;
    return 0.6 + 0.5 * Curves.easeOutBack.transform(x) * 0.8;
  }
}

/// Strahlen, die aus der Mitte nach aussen laufen und verblassen.
///
/// Von Hand gezeichnet statt mit einem Paket: es sind zwoelf Linien, und
/// eine zusaetzliche Abhaengigkeit dafuer waere unverhaeltnismaessig.
class _StrahlenMaler extends CustomPainter {
  final double fortschritt;

  const _StrahlenMaler({required this.fortschritt});

  static const _anzahl = 12;

  @override
  void paint(Canvas canvas, Size size) {
    // Die Strahlen laufen in der ersten Haelfte los und verblassen danach.
    final t = Curves.easeOut.transform(math.min(1, fortschritt / 0.7));
    if (t <= 0) return;

    final mitte = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final deckkraft = (1 - fortschritt).clamp(0.0, 1.0);

    final stift = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary.withValues(alpha: 0.7 * deckkraft);

    for (var i = 0; i < _anzahl; i++) {
      final winkel = 2 * math.pi * i / _anzahl;
      final richtung = Offset(math.cos(winkel), math.sin(winkel));
      // Innen beginnt der Strahl spaeter als aussen — das streckt ihn.
      final von = mitte + richtung * (maxRadius * t * 0.55);
      final bis = mitte + richtung * (maxRadius * t);
      canvas.drawLine(von, bis, stift);
    }
  }

  @override
  bool shouldRepaint(_StrahlenMaler alt) => alt.fortschritt != fortschritt;
}
