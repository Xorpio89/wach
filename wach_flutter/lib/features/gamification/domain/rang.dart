/// Die Raenge, in denen eine Stufe ausgedrueckt wird.
///
/// Eine blosse Zahl sagt nichts: "Stufe 6" ist kein Ziel, auf das man
/// zuarbeitet. Ein Rang schon — und die Reihenfolge E bis S versteht man
/// ohne Erklaerung.
enum Rang {
  e,
  d,
  c,
  b,
  a,
  s,
  national,
  monarch,
  schattenmonarch,
  herrscher,
}

/// Ein Rang samt Durchlauf.
///
/// Die Stufen sind nach oben offen, die Raenge nicht. Ab dem letzten Rang
/// zaehlt [durchlauf] weiter: Herrscher, Herrscher II, Herrscher III. So
/// bleibt jeder Aufstieg benennbar, ohne Namen zu erfinden, die keiner
/// mehr auseinanderhaelt.
class RangStufe {
  final Rang rang;

  /// 1 beim ersten Erreichen, danach aufwaerts.
  final int durchlauf;

  const RangStufe(this.rang, [this.durchlauf = 1]);

  /// Ob eine Ziffer hinter den Namen gehoert.
  bool get istWiederholung => durchlauf > 1;

  /// Der Durchlauf als roemische Ziffer — leer beim ersten Mal.
  String get ziffer => istWiederholung ? _roemisch(durchlauf) : '';

  @override
  bool operator ==(Object other) =>
      other is RangStufe &&
      other.rang == rang &&
      other.durchlauf == durchlauf;

  @override
  int get hashCode => Object.hash(rang, durchlauf);

  @override
  String toString() => 'RangStufe(${rang.name}, $durchlauf)';
}

/// Der Rang, der zu [stufe] gehoert.
RangStufe rangFuer(int stufe) {
  final versetzt = (stufe < 1 ? 1 : stufe) - 1;
  if (versetzt < Rang.values.length) {
    return RangStufe(Rang.values[versetzt]);
  }
  // Jenseits des letzten Rangs beginnt die Zaehlung.
  return RangStufe(
    Rang.values.last,
    versetzt - Rang.values.length + 2,
  );
}

/// Roemische Ziffern, soweit sie hier vorkommen koennen.
///
/// Bewusst knapp gehalten: Wer bei Herrscher XL angekommen ist, hat andere
/// Sorgen als die Schreibweise.
String _roemisch(int zahl) {
  const zeichen = <int, String>{
    50: 'L',
    40: 'XL',
    10: 'X',
    9: 'IX',
    5: 'V',
    4: 'IV',
    1: 'I',
  };

  var rest = zahl;
  final gebaut = StringBuffer();
  for (final eintrag in zeichen.entries) {
    while (rest >= eintrag.key) {
      gebaut.write(eintrag.value);
      rest -= eintrag.key;
    }
  }
  return gebaut.toString();
}
