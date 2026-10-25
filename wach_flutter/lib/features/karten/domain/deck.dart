import 'dart:math';

import 'karte.dart';

/// Wählbare Teildeck-Größen; `null` beim Ziehen heißt: alle Karten.
const deckKurz = 28;
const deckMittel = 56;

/// Karten je Stapel: eine 0, je zwei 1–9; mit Aktionen je zwei Joker,
/// Nochmal und ×2 plus zwei Wahl-Karten. Vier Stapel ergeben 108 Karten.
List<Karte> vollesDeck({required int stapel, bool mitAktionen = true}) {
  assert(stapel >= minStapel && stapel <= maxStapel);
  final karten = <Karte>[];
  for (var s = 0; s < stapel; s++) {
    karten.add(Karte.zahl(s, 0));
    for (var zahl = 1; zahl <= 9; zahl++) {
      karten
        ..add(Karte.zahl(s, zahl))
        ..add(Karte.zahl(s, zahl));
    }
    if (mitAktionen) {
      for (final art in [
        KartenArt.joker,
        KartenArt.nochmal,
        KartenArt.doppelt
      ]) {
        karten
          ..add(Karte.aktion(art, s))
          ..add(Karte.aktion(art, s));
      }
      karten
        ..add(const Karte.wahl())
        ..add(const Karte.wahl());
    }
  }
  return karten;
}

/// Gemischtes Deck mit [anzahl] Karten (`null` = alle); jede Gruppe
/// (Art × Stapel) bekommt ihren Anteil, Reste gehen an die größten Bruchteile.
List<Karte> ziehDeck({
  required int stapel,
  int? anzahl,
  bool mitAktionen = true,
  required Random zufall,
}) {
  final voll = vollesDeck(stapel: stapel, mitAktionen: mitAktionen);
  if (anzahl == null || anzahl >= voll.length) return mische(voll, zufall);
  if (anzahl <= 0) return const [];

  final gruppen = <String, List<Karte>>{};
  for (final karte in voll) {
    gruppen
        .putIfAbsent('${karte.art.name}-${karte.stapel}', () => [])
        .add(karte);
  }

  final schluessel = gruppen.keys.toList()..sort();
  final anteile = <String, double>{
    for (final s in schluessel) s: gruppen[s]!.length * anzahl / voll.length,
  };
  final menge = {for (final s in schluessel) s: anteile[s]!.floor()};
  var rest = anzahl - menge.values.fold(0, (a, b) => a + b);
  final nachRest = [...schluessel]..sort((a, b) {
      final d = (anteile[b]! - menge[b]!).compareTo(anteile[a]! - menge[a]!);
      return d != 0 ? d : a.compareTo(b);
    });
  for (final s in nachRest) {
    if (rest == 0) break;
    menge[s] = menge[s]! + 1;
    rest--;
  }

  final gezogen = <Karte>[];
  for (final s in schluessel) {
    final gruppe = [...gruppen[s]!]..shuffle(zufall);
    gezogen.addAll(gruppe.take(menge[s]!));
  }
  return mische(gezogen, zufall);
}

/// Mischt so, dass höchstens zwei Karten desselben Stapels aufeinander
/// folgen; volle Stapel werden bevorzugt, damit am Ende kein Lauf übrig bleibt.
List<Karte> mische(List<Karte> karten, Random zufall) {
  final rest = [...karten]..shuffle(zufall);
  final ergebnis = <Karte>[];
  while (rest.isNotEmpty) {
    final n = ergebnis.length;
    // Wahl-Karten zählen als eigener Stapel (-1), damit auch sie nicht
    // dreimal in Folge kommen.
    int stapelVon(Karte k) => k.stapel ?? -1;
    final gesperrt =
        n >= 2 && stapelVon(ergebnis[n - 1]) == stapelVon(ergebnis[n - 2])
            ? stapelVon(ergebnis[n - 1])
            : null;

    final anzahl = <int, int>{};
    for (final k in rest) {
      anzahl[stapelVon(k)] = (anzahl[stapelVon(k)] ?? 0) + 1;
    }
    bool erlaubt(Karte k) => gesperrt == null || stapelVon(k) != gesperrt;

    var gesamt = 0;
    for (final k in rest) {
      if (erlaubt(k)) gesamt += anzahl[stapelVon(k)]!;
    }
    if (gesamt == 0) {
      ergebnis.add(rest.removeAt(0));
      continue;
    }
    var los = zufall.nextInt(gesamt);
    for (var i = 0; i < rest.length; i++) {
      if (!erlaubt(rest[i])) continue;
      los -= anzahl[stapelVon(rest[i])]!;
      if (los < 0) {
        ergebnis.add(rest.removeAt(i));
        break;
      }
    }
  }
  return ergebnis;
}
