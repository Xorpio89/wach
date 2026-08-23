import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/gamification/domain/gamification_stats.dart';
import 'package:wach_flutter/features/gamification/presentation/providers/gamification_provider.dart';
import 'package:wach_flutter/features/gamification/presentation/widgets/gamification_bar.dart';

import '../../support/test_harness.dart';

/// Die Stufenanzeige auf der Startseite.
void main() {
  Future<void> pumpMitStats(
    WidgetTester tester,
    GamificationStats stats,
  ) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(
      wrapForTest(
        const GamificationBar(),
        overrides: [gamificationProvider.overrideWithValue(stats)],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('vor der ersten Session bleibt die Leiste verborgen',
      (tester) async {
    await pumpMitStats(tester, GamificationStats.leer);

    // Eine Leiste auf null waere ein Platzhalter ohne Aussage.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('E-Rang'), findsNothing);
  });

  testWidgets('zeigt Stufe, Punkte und verbleibende Strecke', (tester) async {
    await pumpMitStats(
      tester,
      const GamificationStats(
        punkte: 620,
        stufe: 3,
        punkteInStufe: 170,
        spanneDerStufe: 300,
        serie: 4,
        sessions: 12,
        abzeichen: {Abzeichen.angefangen},
      ),
    );

    // Auf der Startseite steht der Rang allein — er ist die Auszeichnung.
    expect(find.text('C-Rang'), findsOneWidget);
    expect(find.text('620'), findsOneWidget);
    expect(find.text('noch 130 Punkte'), findsOneWidget);
    expect(find.text('4 Tage in Folge'), findsOneWidget);

    final balken = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(balken.value, closeTo(170 / 300, 0.001));
  });

  testWidgets('ohne laufende Serie fehlt die Flamme', (tester) async {
    await pumpMitStats(
      tester,
      const GamificationStats(
        punkte: 250,
        stufe: 2,
        punkteInStufe: 50,
        spanneDerStufe: 250,
        serie: 0,
        sessions: 3,
        abzeichen: {Abzeichen.angefangen},
      ),
    );

    expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
    expect(find.text('D-Rang'), findsOneWidget);
  });

  testWidgets('ein einzelner Tag steht in der Einzahl', (tester) async {
    await pumpMitStats(
      tester,
      const GamificationStats(
        punkte: 100,
        stufe: 1,
        punkteInStufe: 100,
        spanneDerStufe: 200,
        serie: 1,
        sessions: 1,
        abzeichen: {Abzeichen.angefangen},
      ),
    );

    expect(find.text('1 Tag in Folge'), findsOneWidget);
  });
}
