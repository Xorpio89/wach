/// Bekannte Challenges als Vorlage.
///
/// Bisher musste jede Challenge von Hand zusammengestellt werden — Name,
/// Uebungen, Zielzahlen. Das ist die Huerde: Wer nicht ohnehin weiss, was
/// eine sinnvolle Zahl ist, faengt gar nicht erst an.
///
/// Die Vorlagen hier sind keine erfundenen Zahlen, sondern die, die in der
/// Calisthenics- und CrossFit-Welt tatsaechlich kursieren. Wer "Murph"
/// sagt, meint ueberall dasselbe.
library;

/// Eine Uebung innerhalb einer Vorlage.
class VorlagenUebung {
  final String name;
  final int ziel;

  /// Wie viele Wiederholungen ein Kaestchen umfasst.
  ///
  /// Wird mit dem Ziel groesser: 3.000 Liegestuetze in Zehnerschritten
  /// waeren dreihundert Kaestchen — eine Wand, auf der man nichts mehr
  /// erkennt. Angestrebt sind zwanzig bis vierzig.
  final int blockGroesse;

  const VorlagenUebung(this.name, this.ziel, {this.blockGroesse = 10});
}

/// Woher eine Vorlage stammt — bestimmt, wie sie beschrieben wird.
enum VorlagenArt {
  /// An einem Tag durchzuziehen.
  einTag,

  /// Ueber Wochen oder einen Monat.
  ueberZeit,

  /// Ohne Frist, zum Hineinfinden.
  ohneFrist,
}

class ChallengeVorlage {
  /// Kennung fuer die Uebersetzung und zum Wiedererkennen.
  final String id;
  final VorlagenArt art;

  /// Zeitraum in Tagen; `null` heisst ohne Frist.
  final int? tage;

  final List<VorlagenUebung> uebungen;

  const ChallengeVorlage({
    required this.id,
    required this.art,
    required this.tage,
    required this.uebungen,
  });

  int get gesamtReps =>
      uebungen.fold(0, (summe, uebung) => summe + uebung.ziel);

  /// Wie viele Wiederholungen im Schnitt auf einen Tag entfallen.
  ///
  /// Macht den Unterschied zwischen "1.000 Klimmzuege" und "33 am Tag"
  /// sichtbar — dieselbe Zahl, zwei ganz verschiedene Eindruecke.
  int? get repsProTag {
    final zeitraum = tage;
    if (zeitraum == null || zeitraum <= 1) return null;
    return (gesamtReps / zeitraum).ceil();
  }
}

/// Der Katalog, von leicht nach schwer.
const challengeVorlagen = <ChallengeVorlage>[
  // Zum Hineinfinden: eine einzige Uebung, kein Zeitdruck.
  ChallengeVorlage(
    id: 'ersteHundert',
    art: VorlagenArt.ohneFrist,
    tage: null,
    uebungen: [VorlagenUebung('Klimmzüge', 100)],
  ),

  // Der Einstiegswert schlechthin: hundert am Tag, einen Monat lang.
  ChallengeVorlage(
    id: 'hundertAmTag',
    art: VorlagenArt.ueberZeit,
    tage: 30,
    uebungen: [VorlagenUebung('Liegestütze', 3000, blockGroesse: 100)],
  ),

  // Halbe Dosis des Gedenk-Workouts — der uebliche Weg, sich heranzutasten.
  ChallengeVorlage(
    id: 'halbMurph',
    art: VorlagenArt.einTag,
    tage: 1,
    uebungen: [
      VorlagenUebung('Klimmzüge', 50, blockGroesse: 5),
      VorlagenUebung('Liegestütze', 100, blockGroesse: 10),
      VorlagenUebung('Kniebeugen', 150, blockGroesse: 10),
    ],
  ),

  // Vier mal hundert, jede Uebung am Stueck.
  ChallengeVorlage(
    id: 'angie',
    art: VorlagenArt.einTag,
    tage: 1,
    uebungen: [
      VorlagenUebung('Klimmzüge', 100),
      VorlagenUebung('Liegestütze', 100),
      VorlagenUebung('Sit-ups', 100),
      VorlagenUebung('Kniebeugen', 100),
    ],
  ),

  // Das Gedenk-Workout in voller Laenge.
  ChallengeVorlage(
    id: 'murph',
    art: VorlagenArt.einTag,
    tage: 1,
    uebungen: [
      VorlagenUebung('Klimmzüge', 100),
      VorlagenUebung('Liegestütze', 200, blockGroesse: 10),
      VorlagenUebung('Kniebeugen', 300, blockGroesse: 15),
    ],
  ),

  // Die meistgenannte Monatszahl fuer Klimmzuege.
  ChallengeVorlage(
    id: 'tausendKlimmzuege',
    art: VorlagenArt.ueberZeit,
    tage: 30,
    uebungen: [VorlagenUebung('Klimmzüge', 1000, blockGroesse: 25)],
  ),

  // Die bisherige Vorlage der App, jetzt eine unter mehreren.
  ChallengeVorlage(
    id: 'wochenvolumen',
    art: VorlagenArt.ueberZeit,
    tage: 7,
    uebungen: [
      VorlagenUebung('Klimmzüge', 700, blockGroesse: 25),
      VorlagenUebung('Liegestütze', 1200, blockGroesse: 50),
      VorlagenUebung('Dips', 1000, blockGroesse: 25),
    ],
  ),

  // Ganzkoerper, fuenftausend Wiederholungen in einem Monat.
  ChallengeVorlage(
    id: 'fuenftausend',
    art: VorlagenArt.ueberZeit,
    tage: 30,
    uebungen: [
      VorlagenUebung('Klimmzüge', 1000, blockGroesse: 25),
      VorlagenUebung('Liegestütze', 2000, blockGroesse: 50),
      VorlagenUebung('Kniebeugen', 2000, blockGroesse: 50),
    ],
  ),
];

/// Die Vorlage zu einer Kennung — `null`, wenn es sie nicht gibt.
ChallengeVorlage? vorlageMitId(String id) {
  for (final vorlage in challengeVorlagen) {
    if (vorlage.id == id) return vorlage;
  }
  return null;
}
