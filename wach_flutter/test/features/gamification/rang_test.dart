import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/gamification/domain/rang.dart';

/// Welcher Rang zu welcher Stufe gehoert.
void main() {
  group('Zuordnung', () {
    test('die erste Stufe ist der niedrigste Rang', () {
      expect(rangFuer(1), const RangStufe(Rang.e));
    });

    test('jede Stufe hat ihren Rang', () {
      expect(rangFuer(2).rang, Rang.d);
      expect(rangFuer(6).rang, Rang.s);
      expect(rangFuer(8).rang, Rang.monarch);
      expect(rangFuer(10).rang, Rang.herrscher);
    });

    test('ungueltige Stufen fallen auf den Anfang zurueck', () {
      // Statt abzustuerzen: Eine Stufe unter eins kann es nicht geben.
      expect(rangFuer(0).rang, Rang.e);
      expect(rangFuer(-5).rang, Rang.e);
    });
  });

  group('Jenseits der Raenge', () {
    test('der letzte Rang wiederholt sich mit Zaehlung', () {
      // Die Raenge enden bei zehn, die Stufen nicht — jeder weitere
      // Aufstieg muss trotzdem einen Namen haben.
      expect(rangFuer(11), const RangStufe(Rang.herrscher, 2));
      expect(rangFuer(12), const RangStufe(Rang.herrscher, 3));
    });

    test('der erste Durchlauf traegt keine Ziffer', () {
      // "Herrscher" statt "Herrscher I" — beim ersten Mal waere die Ziffer
      // nur Ballast.
      final erster = rangFuer(10);
      expect(erster.istWiederholung, isFalse);
      expect(erster.ziffer, isEmpty);
    });

    test('die Ziffern sind roemisch', () {
      expect(rangFuer(11).ziffer, 'II');
      expect(rangFuer(12).ziffer, 'III');
      expect(rangFuer(13).ziffer, 'IV');
      expect(rangFuer(14).ziffer, 'V');
      expect(rangFuer(18).ziffer, 'IX');
      expect(rangFuer(19).ziffer, 'X');
    });

    test('auch weit oben bleibt es lesbar', () {
      // Kein leerer Text und keine Kette aus dreissig Strichen.
      final weitOben = rangFuer(60);
      expect(weitOben.rang, Rang.herrscher);
      expect(weitOben.ziffer, isNotEmpty);
      expect(weitOben.ziffer.length, lessThan(8));
    });
  });

  test('gleiche Stufe ergibt gleichen Rang', () {
    // Wird zum Vergleichen gebraucht, etwa um einen Aufstieg zu erkennen.
    expect(rangFuer(6), rangFuer(6));
    expect(rangFuer(6), isNot(rangFuer(7)));
    expect(rangFuer(11), isNot(rangFuer(12)));
  });
}
