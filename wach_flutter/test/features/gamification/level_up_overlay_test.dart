import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/gamification/presentation/widgets/level_up_overlay.dart';

import '../../support/test_harness.dart';

/// Die Feier des Aufstiegs.
///
/// Der Kern dieser Tests ist der Zeitpunkt, nicht das Aussehen: Gefeiert
/// wird beim Beenden eines Workouts, und da ist der Workout-Screen bereits
/// dem Wechsel zur Startseite zum Opfer gefallen. Genau daran scheiterte es
/// vorher lautlos — die Bedingung hing an einem `mounted`, das nach dem
/// Wechsel nie mehr wahr war.
void main() {
  testWidgets('erscheint, obwohl der ausloesende Screen schon weg ist',
      (tester) async {
    usePortraitSurface(tester);
    late OverlayState overlay;

    await tester.pumpWidget(
      wrapScreenForTest(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Genau wie beim Beenden: den Navigator holen, den
                  // Screen verlassen, danach feiern.
                  overlay = Overlay.of(context, rootOverlay: true);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Startseite')),
                      ),
                    ),
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    zeigeStufenaufstieg(overlay, 6);
                  });
                },
                child: const Text('Beenden'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Beenden'));
    await settleAsync(tester);

    // Der ausloesende Screen ist fort — die Feier trotzdem da.
    expect(find.text('Beenden'), findsNothing);
    expect(find.text('Startseite'), findsOneWidget);
    expect(find.text('S-RANG'), findsOneWidget);
  });

  testWidgets('nennt den Rang, nicht die Nummer', (tester) async {
    usePortraitSurface(tester);
    late OverlayState overlay;

    await tester.pumpWidget(
      wrapScreenForTest(
        Builder(
          builder: (context) {
            overlay = Overlay.of(context);
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    zeigeStufenaufstieg(overlay, 3);
    await settleAsync(tester);

    expect(find.text('C-RANG'), findsOneWidget);
    expect(find.text('C-Rang erreicht!'), findsOneWidget);
    // Die blosse Ziffer hat hier nichts mehr zu suchen.
    expect(find.text('3'), findsNothing);
  });

  testWidgets('verschwindet von selbst', (tester) async {
    // Ein Dialog muesste weggetippt werden und stuende einem zweiten
    // Durchgang im Weg.
    usePortraitSurface(tester);
    late OverlayState overlay;

    await tester.pumpWidget(
      wrapScreenForTest(
        Builder(
          builder: (context) {
            overlay = Overlay.of(context);
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    zeigeStufenaufstieg(overlay, 6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('S-RANG'), findsOneWidget);

    await passRealTime(tester, const Duration(seconds: 4));
    expect(find.text('S-RANG'), findsNothing);
  });
}
