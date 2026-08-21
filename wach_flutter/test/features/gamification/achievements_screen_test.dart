import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/gamification/domain/gamification_stats.dart';
import 'package:wach_flutter/features/gamification/presentation/providers/gamification_provider.dart';
import 'package:wach_flutter/features/gamification/presentation/screens/achievements_screen.dart';

import '../../support/test_harness.dart';

/// Die Übersicht über Stufe, Punkte und Abzeichen.
void main() {
  Future<void> pumpMitStats(
    WidgetTester tester,
    GamificationStats stats,
  ) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(
      wrapScreenForTest(
        const AchievementsScreen(),
        overrides: [gamificationProvider.overrideWithValue(stats)],
      ),
    );
    await tester.pumpAndSettle();
  }

  const mitFortschritt = GamificationStats(
    punkte: 620,
    stufe: 3,
    punkteInStufe: 170,
    spanneDerStufe: 300,
    serie: 4,
    sessions: 12,
    abzeichen: {Abzeichen.angefangen},
  );

  testWidgets('ohne Session steht nur ein Hinweis', (tester) async {
    await pumpMitStats(tester, GamificationStats.leer);

    expect(find.text('Beende ein Workout, dann geht es los.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('zeigt Stufe, Kennzahlen und Fortschritt', (tester) async {
    await pumpMitStats(tester, mitFortschritt);

    expect(find.text('3'), findsWidgets);
    expect(find.text('Stufe 3'), findsOneWidget);
    expect(find.text('620'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4 Tage'), findsOneWidget);
    expect(find.text('noch 130 Punkte'), findsOneWidget);
  });

  testWidgets('erreichte und offene Abzeichen sind unterscheidbar',
      (tester) async {
    await pumpMitStats(tester, mitFortschritt);

    // Alle Abzeichen sind aufgefuehrt, auch die noch offenen.
    expect(find.text('Angefangen'), findsOneWidget);
    expect(find.text('Tausend'), findsOneWidget);
    expect(find.text('Eine Woche'), findsOneWidget);

    // Genau eines ist erreicht — nur dort steht ein Haken.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('die Stufenleiter beginnt bei der aktuellen Stufe',
      (tester) async {
    await pumpMitStats(tester, mitFortschritt);

    // Stufe 3 ab 450, Stufe 4 ab 750 — siehe schwelleFuer.
    expect(find.text('ab 450 Punkten'), findsOneWidget);
    expect(find.text('ab 750 Punkten'), findsOneWidget);
    // Vergangene Stufen interessieren nicht mehr.
    expect(find.text('ab 200 Punkten'), findsNothing);
  });
}
