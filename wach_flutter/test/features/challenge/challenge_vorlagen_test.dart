import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/challenge/domain/challenge_vorlagen.dart';

/// Die bekannten Challenges.
///
/// Die Zahlen sind der Kern: Wer "Murph" sagt, meint ueberall dasselbe.
/// Verrutscht hier etwas, stimmt die Vorlage nicht mehr mit dem ueberein,
/// was draussen darunter verstanden wird — und das faellt niemandem auf.
void main() {
  group('Die Zahlen der Richtwerte', () {
    test('Murph sind 100, 200 und 300', () {
      final murph = vorlageMitId('murph')!;
      expect(murph.uebungen.map((u) => u.ziel), [100, 200, 300]);
      expect(murph.gesamtReps, 600);
      expect(murph.tage, 1);
    });

    test('Half Murph ist genau die Haelfte', () {
      final ganz = vorlageMitId('murph')!;
      final halb = vorlageMitId('halbMurph')!;

      expect(halb.gesamtReps * 2, ganz.gesamtReps);
      for (var i = 0; i < ganz.uebungen.length; i++) {
        expect(halb.uebungen[i].ziel * 2, ganz.uebungen[i].ziel,
            reason: '${halb.uebungen[i].name} passt nicht');
      }
    });

    test('Angie ist vier mal hundert', () {
      final angie = vorlageMitId('angie')!;
      expect(angie.uebungen, hasLength(4));
      expect(angie.uebungen.every((u) => u.ziel == 100), isTrue);
      expect(angie.gesamtReps, 400);
    });

    test('die Monatszahlen stimmen', () {
      expect(vorlageMitId('tausendKlimmzuege')!.gesamtReps, 1000);
      expect(vorlageMitId('hundertAmTag')!.gesamtReps, 3000);
      expect(vorlageMitId('fuenftausend')!.gesamtReps, 5000);
    });
  });

  group('Tagespensum', () {
    test('tausend Klimmzuege sind rund dreiunddreissig am Tag', () {
      expect(vorlageMitId('tausendKlimmzuege')!.repsProTag, 34);
    });

    test('hundert am Tag sind hundert am Tag', () {
      expect(vorlageMitId('hundertAmTag')!.repsProTag, 100);
    });

    test('bei einem Tag gibt es kein Pensum', () {
      // "600 an einem Tag" ist die Aussage — "600/Tag" waere sinnlos.
      expect(vorlageMitId('murph')!.repsProTag, isNull);
    });

    test('ohne Frist gibt es kein Pensum', () {
      expect(vorlageMitId('ersteHundert')!.repsProTag, isNull);
    });
  });

  group('Der Katalog als Ganzes', () {
    test('jede Vorlage hat eine eigene Kennung', () {
      final kennungen = challengeVorlagen.map((v) => v.id).toList();
      expect(kennungen.toSet(), hasLength(kennungen.length));
    });

    test('keine Vorlage ist leer', () {
      for (final vorlage in challengeVorlagen) {
        expect(vorlage.uebungen, isNotEmpty, reason: vorlage.id);
        expect(vorlage.gesamtReps, greaterThan(0), reason: vorlage.id);
      }
    });

    test('die Kaestchen bleiben ueberschaubar', () {
      // 3.000 Liegestuetze in Zehnerschritten waeren dreihundert Kaestchen
      // — eine Wand, auf der man nichts mehr erkennt.
      for (final vorlage in challengeVorlagen) {
        for (final uebung in vorlage.uebungen) {
          final kaestchen = (uebung.ziel / uebung.blockGroesse).ceil();
          expect(
            kaestchen,
            lessThanOrEqualTo(40),
            reason: '${vorlage.id}/${uebung.name}: $kaestchen Kaestchen',
          );
          expect(kaestchen, greaterThanOrEqualTo(5),
              reason: '${vorlage.id}/${uebung.name}: zu grobe Schritte');
        }
      }
    });

    test('der Katalog steigt in der Anforderung', () {
      // Oben das Leichte, unten das Schwere — sonst schreckt die Liste ab.
      final ohneFrist = challengeVorlagen
          .indexWhere((v) => v.art == VorlagenArt.ohneFrist);
      expect(ohneFrist, 0, reason: 'Der Einstieg gehoert nach oben');
      expect(challengeVorlagen.last.gesamtReps,
          greaterThan(challengeVorlagen.first.gesamtReps));
    });

    test('eine unbekannte Kennung ergibt nichts', () {
      expect(vorlageMitId('gibtsnicht'), isNull);
    });
  });
}
