import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/karten/domain/deck.dart';
import 'package:wach_flutter/features/karten/domain/karte.dart';
import 'package:wach_flutter/features/karten/domain/karten_spiel.dart';

void main() {
  group('Deck', () {
    test('vier Stapel mit Aktionen ergeben 108 Karten', () {
      final deck = vollesDeck(stapel: 4);
      expect(deck, hasLength(108));
      expect(deck.where((k) => k.art == KartenArt.zahl), hasLength(76));
      expect(deck.where((k) => k.art == KartenArt.wahl), hasLength(8));
      for (final art in [
        KartenArt.joker,
        KartenArt.nochmal,
        KartenArt.doppelt
      ]) {
        expect(deck.where((k) => k.art == art), hasLength(8));
      }
    });

    test('ohne Aktionen nur Zahlkarten, 19 je Stapel', () {
      for (var s = minStapel; s <= maxStapel; s++) {
        final deck = vollesDeck(stapel: s, mitAktionen: false);
        expect(deck, hasLength(19 * s));
        expect(deck.every((k) => k.art == KartenArt.zahl), isTrue);
      }
    });

    test('ein Teildeck hat genau die verlangte Größe', () {
      for (final n in [1, 7, 28, 56, 107]) {
        final deck = ziehDeck(stapel: 4, anzahl: n, zufall: Random(1));
        expect(deck, hasLength(n), reason: 'Größe $n');
      }
    });

    test('Teildecks verteilen die Stapel gleichmäßig', () {
      for (var seed = 0; seed < 30; seed++) {
        final deck = ziehDeck(stapel: 4, anzahl: 28, zufall: Random(seed));
        final jeStapel = <int, int>{};
        for (final k in deck.where((k) => k.stapel != null)) {
          jeStapel[k.stapel!] = (jeStapel[k.stapel!] ?? 0) + 1;
        }
        final werte = jeStapel.values.toList()..sort();
        expect(werte.last - werte.first, lessThanOrEqualTo(1),
            reason: 'Seed $seed: $jeStapel');
      }
    });

    test('nie drei Karten desselben Stapels hintereinander', () {
      for (var seed = 0; seed < 50; seed++) {
        final deck = ziehDeck(stapel: 4, zufall: Random(seed));
        // Wahl-Karten (ohne Stapel) zählen als eigener Stapel.
        int stapelVon(Karte k) => k.stapel ?? -1;
        for (var i = 2; i < deck.length; i++) {
          final s = stapelVon(deck[i]);
          final lauf =
              stapelVon(deck[i - 1]) == s && stapelVon(deck[i - 2]) == s;
          expect(lauf, isFalse, reason: 'Seed $seed, Position $i');
        }
      }
    });

    test('gleicher Seed, gleiches Deck', () {
      expect(ziehDeck(stapel: 3, zufall: Random(42)),
          ziehDeck(stapel: 3, zufall: Random(42)));
    });
  });

  group('Wiederholungen', () {
    test('Schwierigkeit skaliert, mindestens eine', () {
      const leicht =
          KartenRegeln(stapel: 4, schwierigkeit: Schwierigkeit.leicht);
      expect(leicht.wiederholungen(1), 1);
      expect(leicht.wiederholungen(9), 5);
      const brutal =
          KartenRegeln(stapel: 4, schwierigkeit: Schwierigkeit.brutal);
      expect(brutal.wiederholungen(9), 18);
    });

    test('die Obergrenze gilt nach ×2', () {
      const regeln = KartenRegeln(stapel: 4, obergrenze: 15);
      expect(regeln.wiederholungen(9, doppelt: true), 15);
      const ohne = KartenRegeln(stapel: 4, obergrenze: null);
      expect(ohne.wiederholungen(9, doppelt: true), 18);
    });
  });

  group('Spielablauf', () {
    KartenSpiel spielMit(List<Karte> karten,
        {KartenRegeln regeln = const KartenRegeln(stapel: 4)}) {
      return KartenSpiel.ausKarten(regeln, karten);
    }

    test('eine 0 zählt als zehn', () {
      final spiel = spielMit([const Karte.zahl(0, 0)]);
      expect(spiel.aktuell!.soll, 10);
    });

    test('×2 verdoppelt die nächste Karte mit Wiederholungen, nicht länger',
        () {
      final spiel = spielMit([
        const Karte.aktion(KartenArt.doppelt, 0),
        const Karte.aktion(KartenArt.joker, 1),
        const Karte.zahl(2, 4),
        const Karte.zahl(3, 4),
      ]);
      final nachDoppelt = spiel.erledige(Random(0));
      expect(nachDoppelt.aktuell!.istPause, isTrue, reason: 'Joker');
      final nachJoker = nachDoppelt.erledige(Random(0));
      expect(nachJoker.aktuell!.soll, 8, reason: '×2 wartet über den Joker');
      final danach = nachJoker.erledige(Random(0));
      expect(danach.aktuell!.soll, 4, reason: '×2 ist verbraucht');
    });

    test('Nochmal wiederholt die letzte Übung, ohne Vorgänger ist es Pause',
        () {
      final spiel = spielMit([
        const Karte.aktion(KartenArt.nochmal, 0),
        const Karte.zahl(1, 7),
        const Karte.aktion(KartenArt.nochmal, 2),
      ]);
      expect(spiel.aktuell!.istPause, isTrue);
      final zahl = spiel.erledige(Random(0));
      final nochmal = zahl.erledige(Random(0));
      expect(nochmal.aktuell!.stapel, 1);
      expect(nochmal.aktuell!.soll, 7);
    });

    test('Wahl braucht erst eine Übung, dann zählt sie für diesen Stapel', () {
      final spiel = spielMit([const Karte.wahl(), const Karte.zahl(0, 1)]);
      expect(spiel.aktuell!.brauchtWahl, isTrue);
      expect(spiel.erledige(Random(0)).index, 0,
          reason: 'ohne Wahl geht es nicht weiter');
      final gewaehlt = spiel.waehle(3);
      final weiter = gewaehlt.erledige(Random(0));
      expect(weiter.wiederholungenJeStapel, {3: 10});
    });

    test('gezählt wird das tatsächlich Geschaffte', () {
      final spiel = spielMit([const Karte.zahl(0, 9), const Karte.zahl(1, 1)]);
      final weniger = spiel.passe(-3);
      expect(weniger.geschafft, 6);
      expect(weniger.passe(-20).geschafft, 0, reason: 'nicht unter null');
      expect(weniger.erledige(Random(0)).gesamtWiederholungen, 6);
    });

    test('im Deck-Modus ist nach der letzten Karte Schluss', () {
      final spiel = spielMit([const Karte.zahl(0, 2)]);
      final ende = spiel.erledige(Random(0));
      expect(ende.fertig, isTrue);
      expect(ende.kartenUebrig, 0);
    });

    test('bei Spielende zählt die angefangene Karte mit', () {
      final spiel = spielMit([const Karte.zahl(0, 9), const Karte.zahl(1, 1)]);
      final abgeschlossen = spiel.passe(-4).schliesseAb();
      expect(abgeschlossen.gesamtWiederholungen, 5);
      expect(abgeschlossen.fertig, isFalse,
          reason: 'das Deck ist nicht überlebt, nur die Zeit vorbei');
      final pause = spielMit([const Karte.aktion(KartenArt.joker, 0)]);
      expect(pause.schliesseAb().erledigt, isEmpty);
    });

    test('Spieler ziehen reihum, Summen je Spieler', () {
      var spiel = spielMit(
        [
          const Karte.zahl(0, 3),
          const Karte.zahl(1, 5),
          const Karte.zahl(2, 7),
        ],
        regeln: const KartenRegeln(stapel: 4, spieler: 2),
      );
      expect(spiel.amZug, 0);
      spiel = spiel.erledige(Random(0));
      expect(spiel.amZug, 1);
      spiel = spiel.erledige(Random(0)).erledige(Random(0));
      expect(spiel.wiederholungenJeSpieler, {0: 10, 1: 5});
      expect(spiel.wiederholungenJeStapelFuer(0), {0: 3, 2: 7});
    });

    test('im Zeit-Modus wird ein leeres Deck nachgemischt', () {
      final spiel = spielMit(
        [const Karte.zahl(0, 2)],
        regeln: const KartenRegeln(stapel: 2, modus: SpielModus.zeit),
      );
      final weiter = spiel.erledige(Random(0));
      expect(weiter.fertig, isFalse);
      expect(weiter.kartenUebrig, isNull);
    });
  });
}
