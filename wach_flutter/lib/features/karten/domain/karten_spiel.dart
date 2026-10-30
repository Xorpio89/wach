import 'dart:math';

import 'deck.dart';
import 'karte.dart';

enum Schwierigkeit {
  leicht(0.5),
  normal(1.0),
  hart(1.5),
  brutal(2.0);

  const Schwierigkeit(this.faktor);
  final double faktor;
}

enum SpielModus {
  /// Ein Deck wird komplett abgearbeitet, die Zeit zählt.
  deck,

  /// So viele Karten wie möglich im Zeitlimit; leere Decks werden nachgemischt.
  zeit,
}

/// Grundwert einer 0 und einer Wahl-Karte.
const nullZaehlt = 10;
const wahlBasis = 10;

class KartenRegeln {
  final int stapel;
  final SpielModus modus;
  final Schwierigkeit schwierigkeit;

  /// Höchstwert pro Karte nach Schwierigkeit und ×2; null = keine Grenze.
  final int? obergrenze;
  final bool mitAktionen;

  /// Nur im Deck-Modus: Kartenanzahl, null = volles Deck.
  final int? deckGroesse;

  /// Nur im Zeit-Modus.
  final int zeitlimitMinuten;

  /// Spieler am selben Gerät, die abwechselnd ziehen.
  final int spieler;

  /// Pause nach jeder Karte mit Wiederholungen; 0 = keine.
  final int pauseSekunden;

  const KartenRegeln({
    required this.stapel,
    this.modus = SpielModus.deck,
    this.schwierigkeit = Schwierigkeit.normal,
    this.obergrenze = 20,
    this.mitAktionen = true,
    this.deckGroesse,
    this.zeitlimitMinuten = 10,
    this.spieler = 1,
    this.pauseSekunden = 0,
  });

  int wiederholungen(int basis, {bool doppelt = false}) {
    if (basis <= 0) return 0;
    var n = (basis * schwierigkeit.faktor).round();
    if (n < 1) n = 1;
    if (doppelt) n *= 2;
    final grenze = obergrenze;
    if (grenze != null && n > grenze) n = grenze;
    return n;
  }
}

class Aufgabe {
  final Karte karte;

  /// Stapel der Übung; bei Wahl null, bis gewählt wurde; bei Pausen null.
  final int? stapel;
  final int basis;
  final int soll;

  /// Ob ein vorheriges ×2 diese Aufgabe verdoppelt hat.
  final bool doppelt;

  const Aufgabe({
    required this.karte,
    this.stapel,
    this.basis = 0,
    this.soll = 0,
    this.doppelt = false,
  });

  bool get brauchtWahl => karte.art == KartenArt.wahl && stapel == null;
  bool get istPause => soll == 0;

  Aufgabe mitStapel(int s) => Aufgabe(
      karte: karte, stapel: s, basis: basis, soll: soll, doppelt: doppelt);
}

class ErledigteKarte {
  final Karte karte;
  final int? stapel;
  final int soll;
  final int geschafft;
  final int spieler;

  const ErledigteKarte({
    required this.karte,
    required this.stapel,
    required this.soll,
    required this.geschafft,
    this.spieler = 0,
  });
}

/// Unveränderlicher Spielstand; jeder Schritt liefert einen neuen.
class KartenSpiel {
  final KartenRegeln regeln;
  final List<Karte> karten;
  final int index;

  /// Null, wenn das Deck abgearbeitet ist.
  final Aufgabe? aktuell;

  /// Tatsächlich geschaffte Wiederholungen der aktuellen Karte.
  final int geschafft;
  final bool doppeltOffen;
  final Aufgabe? letzteUebung;
  final List<ErledigteKarte> erledigt;

  const KartenSpiel._({
    required this.regeln,
    required this.karten,
    required this.index,
    required this.aktuell,
    required this.geschafft,
    required this.doppeltOffen,
    required this.letzteUebung,
    required this.erledigt,
  });

  factory KartenSpiel.neu(KartenRegeln regeln, Random zufall) =>
      KartenSpiel.ausKarten(
        regeln,
        ziehDeck(
          stapel: regeln.stapel,
          anzahl: regeln.modus == SpielModus.deck ? regeln.deckGroesse : null,
          mitAktionen: regeln.mitAktionen,
          zufall: zufall,
        ),
      );

  /// Spiel mit vorgegebener Kartenfolge (z. B. identisches Deck für alle).
  factory KartenSpiel.ausKarten(KartenRegeln regeln, List<Karte> karten) {
    final erste = karten.isEmpty
        ? null
        : _aufgabeFuer(karten.first, regeln, doppelt: false, letzte: null);
    return KartenSpiel._(
      regeln: regeln,
      karten: karten,
      index: 0,
      aktuell: erste,
      geschafft: erste?.soll ?? 0,
      doppeltOffen: false,
      letzteUebung: null,
      erledigt: const [],
    );
  }

  bool get fertig => aktuell == null;

  /// Im Zeit-Modus endlos; dort zählt die Uhr.
  int? get kartenUebrig =>
      regeln.modus == SpielModus.zeit ? null : karten.length - index;

  int get gesamtWiederholungen =>
      erledigt.fold(0, (summe, e) => summe + e.geschafft);

  /// Wer die aktuelle Karte macht; die Spieler ziehen reihum.
  int get amZug => erledigt.length % regeln.spieler;

  Map<int, int> get wiederholungenJeStapel => wiederholungenJeStapelFuer(null);

  /// Wiederholungen je Stapel, auf Wunsch nur eines Spielers.
  Map<int, int> wiederholungenJeStapelFuer(int? spieler) {
    final summe = <int, int>{};
    for (final e in erledigt) {
      final s = e.stapel;
      if (s == null || e.geschafft == 0) continue;
      if (spieler != null && e.spieler != spieler) continue;
      summe[s] = (summe[s] ?? 0) + e.geschafft;
    }
    return summe;
  }

  Map<int, int> get wiederholungenJeSpieler {
    final summe = <int, int>{};
    for (final e in erledigt) {
      summe[e.spieler] = (summe[e.spieler] ?? 0) + e.geschafft;
    }
    return summe;
  }

  KartenSpiel waehle(int stapel) {
    final a = aktuell;
    if (a == null || !a.brauchtWahl) return this;
    return _mit(aktuell: a.mitStapel(stapel), geschafft: geschafft);
  }

  KartenSpiel passe(int delta) {
    final a = aktuell;
    if (a == null || a.istPause || a.brauchtWahl) return this;
    final neu = geschafft + delta;
    return _mit(aktuell: a, geschafft: neu < 0 ? 0 : neu);
  }

  /// Bei Spielende: angefangene Karte mit dem bisher Geschafften verbuchen.
  KartenSpiel schliesseAb() {
    final a = aktuell;
    if (a == null || a.istPause || a.brauchtWahl || geschafft == 0) return this;
    return KartenSpiel._(
      regeln: regeln,
      karten: karten,
      index: index,
      aktuell: a,
      geschafft: 0,
      doppeltOffen: doppeltOffen,
      letzteUebung: letzteUebung,
      erledigt: [
        ...erledigt,
        ErledigteKarte(
            karte: a.karte,
            stapel: a.stapel,
            soll: a.soll,
            geschafft: geschafft,
            spieler: amZug),
      ],
    );
  }

  /// Aktuelle Karte abschließen und die nächste aufdecken.
  KartenSpiel erledige(Random zufall) {
    final a = aktuell;
    if (a == null || a.brauchtWahl) return this;

    final eintrag = ErledigteKarte(
      karte: a.karte,
      stapel: a.stapel,
      soll: a.soll,
      geschafft: a.istPause ? 0 : geschafft,
      spieler: amZug,
    );

    final zaehltAlsUebung = !a.istPause && a.stapel != null;
    final letzte = zaehltAlsUebung ? a : letzteUebung;
    final bool doppelt;
    if (a.karte.art == KartenArt.doppelt) {
      doppelt = true;
    } else if (a.doppelt) {
      doppelt = false;
    } else {
      doppelt = doppeltOffen;
    }

    var karten = this.karten;
    final naechster = index + 1;
    if (naechster >= karten.length && regeln.modus == SpielModus.zeit) {
      karten = [
        ...karten,
        ...ziehDeck(
          stapel: regeln.stapel,
          mitAktionen: regeln.mitAktionen,
          zufall: zufall,
        ),
      ];
    }
    final next = naechster < karten.length
        ? _aufgabeFuer(karten[naechster], regeln,
            doppelt: doppelt, letzte: letzte)
        : null;

    return KartenSpiel._(
      regeln: regeln,
      karten: karten,
      index: naechster,
      aktuell: next,
      geschafft: next?.soll ?? 0,
      doppeltOffen: doppelt,
      letzteUebung: letzte,
      erledigt: [...erledigt, eintrag],
    );
  }

  KartenSpiel _mit({required Aufgabe aktuell, required int geschafft}) =>
      KartenSpiel._(
        regeln: regeln,
        karten: karten,
        index: index,
        aktuell: aktuell,
        geschafft: aktuell.brauchtWahl
            ? 0
            : (aktuell == this.aktuell ? geschafft : aktuell.soll),
        doppeltOffen: doppeltOffen,
        letzteUebung: letzteUebung,
        erledigt: erledigt,
      );
}

Aufgabe _aufgabeFuer(
  Karte karte,
  KartenRegeln regeln, {
  required bool doppelt,
  required Aufgabe? letzte,
}) {
  switch (karte.art) {
    case KartenArt.zahl:
      final basis = karte.zahl == 0 ? nullZaehlt : karte.zahl;
      return Aufgabe(
        karte: karte,
        stapel: karte.stapel,
        basis: basis,
        soll: regeln.wiederholungen(basis, doppelt: doppelt),
        doppelt: doppelt,
      );
    case KartenArt.joker:
    case KartenArt.doppelt:
      return Aufgabe(karte: karte);
    case KartenArt.nochmal:
      if (letzte == null) return Aufgabe(karte: karte);
      return Aufgabe(
        karte: karte,
        stapel: letzte.stapel,
        basis: letzte.basis,
        soll: regeln.wiederholungen(letzte.basis, doppelt: doppelt),
        doppelt: doppelt,
      );
    case KartenArt.wahl:
      return Aufgabe(
        karte: karte,
        basis: wahlBasis,
        soll: regeln.wiederholungen(wahlBasis, doppelt: doppelt),
        doppelt: doppelt,
      );
  }
}
