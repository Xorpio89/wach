/// Karten des Karten-Workouts: Stapel = Übung, Zahl = Wiederholungen.
library;

/// Wie viele Stapel (Übungen) ein Spiel haben kann.
const minStapel = 1;
const maxStapel = 8;

enum KartenArt {
  /// 0–9 Wiederholungen der Stapelübung, 0 zählt als 10.
  zahl,

  /// Nichts tun.
  joker,

  /// Letzte Zahl- oder Wahl-Aufgabe noch einmal.
  nochmal,

  /// Nächste Karte mit Wiederholungen zählt doppelt.
  doppelt,

  /// Zehn Wiederholungen einer frei gewählten Übung; gehört zu keinem Stapel.
  wahl,
}

class Karte {
  final KartenArt art;

  /// Index des Stapels; null nur bei [KartenArt.wahl].
  final int? stapel;

  /// Nur bei [KartenArt.zahl] belegt.
  final int zahl;

  const Karte.zahl(int this.stapel, this.zahl) : art = KartenArt.zahl;

  const Karte.aktion(this.art, int this.stapel) : zahl = 0;

  const Karte.wahl()
      : art = KartenArt.wahl,
        stapel = null,
        zahl = 0;

  @override
  bool operator ==(Object other) =>
      other is Karte &&
      other.art == art &&
      other.stapel == stapel &&
      other.zahl == zahl;

  @override
  int get hashCode => Object.hash(art, stapel, zahl);

  @override
  String toString() => art == KartenArt.zahl
      ? 'Karte(S$stapel $zahl)'
      : 'Karte(${art.name} ${stapel == null ? '' : 'S$stapel'})';
}
