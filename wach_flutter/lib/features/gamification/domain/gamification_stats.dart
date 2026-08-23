import '../../workout/data/models/session_model.dart';

/// Auszeichnungen, die sich allein aus dem Verlauf ergeben.
enum Abzeichen {
  /// Die erste beendete Session.
  angefangen,

  /// Tausend Wiederholungen insgesamt.
  tausend,

  /// Sieben Tage in Folge trainiert.
  eineWoche,
}

/// Punkte, Stufe und Serie — berechnet aus dem Verlauf.
///
/// Bewusst ohne eigenen gespeicherten Zustand: alles Noetige steht bereits
/// in den beendeten Sessions. Dadurch kann nichts doppelt gezaehlt werden,
/// ein "Rueckgaengig" nach dem Beenden wirkt von selbst, und das Loeschen
/// einer Session zieht die Punkte korrekt ab. Ein zwischengespeicherter
/// Punktestand muesste all das nachbilden.
///
/// Gezaehlt werden Wiederholungen und Ziele, wie in
/// `docs/GAMIFICATION.md` beschrieben. Sessions von vor der
/// Schema-Erweiterung haben keine Ziele gespeichert; fuer sie entfaellt
/// der Bonus, statt ihn zu erraten.
class GamificationStats {
  /// Gesammelte Punkte insgesamt.
  final int punkte;

  /// Aktuelle Stufe, beginnend bei 1.
  final int stufe;

  /// Bereits erreichte Punkte innerhalb der aktuellen Stufe.
  final int punkteInStufe;

  /// Wie viele Punkte diese Stufe insgesamt umfasst.
  final int spanneDerStufe;

  /// Kalendertage in Folge mit mindestens einer beendeten Session.
  final int serie;

  /// Anzahl beendeter Sessions.
  final int sessions;

  final Set<Abzeichen> abzeichen;

  const GamificationStats({
    required this.punkte,
    required this.stufe,
    required this.punkteInStufe,
    required this.spanneDerStufe,
    required this.serie,
    required this.sessions,
    required this.abzeichen,
  });

  static const leer = GamificationStats(
    punkte: 0,
    stufe: 1,
    punkteInStufe: 0,
    spanneDerStufe: 200,
    serie: 0,
    sessions: 0,
    abzeichen: {},
  );

  /// Anteil der aktuellen Stufe, der geschafft ist (0 bis 1).
  double get fortschritt =>
      spanneDerStufe == 0 ? 0 : punkteInStufe / spanneDerStufe;

  /// Wie viele Punkte noch bis zur naechsten Stufe fehlen.
  int get punkteBisNaechsteStufe => spanneDerStufe - punkteInStufe;

  /// Die Schwellen der benannten Raenge, von E-Rang bis Herrscher.
  ///
  /// Gestaltet statt gerechnet: Die ersten Aufstiege kommen schnell, weil
  /// sie tragen sollen, danach zieht es sich deutlich an. Ein S-Rang, den
  /// man in zwei Wochen hat, waere nichts wert.
  ///
  /// Bei etwa 250 Punkten je gelungenem Workout heisst das: D-Rang nach
  /// dem ersten, S-Rang nach rund drei Monaten.
  static const _schwellen = <int>[
    0, // E-Rang
    200, // D-Rang
    550, // C-Rang
    1100, // B-Rang
    1900, // A-Rang
    3000, // S-Rang
    4800, // National Level
    7000, // Monarch
    10200, // Schattenmonarch
    14000, // Herrscher
  ];

  /// Abstand von der letzten Schwelle zur naechsten dahinter.
  static const _abstandDanach = 3800;

  /// Um wie viel jeder weitere Abstand jenseits der Raenge waechst.
  static const _zuwachsDanach = 1000;

  /// Punkte, ab denen [stufe] erreicht ist.
  ///
  /// Siehe `docs/GAMIFICATION.md`.
  static int schwelleFuer(int stufe) {
    if (stufe <= 1) return 0;
    if (stufe <= _schwellen.length) return _schwellen[stufe - 1];

    // Jenseits der benannten Raenge waechst jeder Abstand weiter.
    final darueber = stufe - _schwellen.length;
    return _schwellen.last +
        _abstandDanach * darueber +
        _zuwachsDanach * darueber * (darueber + 1) ~/ 2;
  }

  /// Die zu [punkte] gehoerende Stufe.
  static int stufeFuer(int punkte) {
    if (punkte <= 0) return 1;
    // Hochzaehlen statt umkehren: Die Schwellen stehen zum Teil in einer
    // Tabelle, die sich nicht als Formel umstellen laesst. Weil sie
    // quadratisch wachsen, sind es auch bei sehr vielen Punkten nur
    // wenige Schritte.
    var stufe = 1;
    while (schwelleFuer(stufe + 1) <= punkte) {
      stufe++;
    }
    return stufe;
  }

  /// Bonus fuer eine erreichte Zielvorgabe.
  static const bonusJeZiel = 25;

  /// Bonus dafuer, alle Ziele einer Session erreicht zu haben.
  static const bonusAlleZiele = 50;

  /// Punkte einer einzelnen Session.
  ///
  /// Eine Wiederholung ist ein Punkt, dazu [bonusJeZiel] fuer jedes
  /// erreichte Ziel und [bonusAlleZiele], wenn alle sassen. Das belohnt
  /// Zielstrebigkeit statt bloszer Menge — sonst braechte es mehr, eine
  /// leichte Uebung hochzuzaehlen, als ein Vorhaben durchzuziehen.
  static int punkteFuer(SessionModel session) {
    var punkte = session.totalReps;

    final ziele = session.exerciseTargets;
    if (ziele.isEmpty) return punkte;

    var erreicht = 0;
    for (final eintrag in ziele.entries) {
      final geschafft = session.exerciseReps[eintrag.key] ?? 0;
      if (geschafft >= eintrag.value) erreicht++;
    }

    punkte += erreicht * bonusJeZiel;
    if (erreicht == ziele.length) punkte += bonusAlleZiele;
    return punkte;
  }

  /// Alles aus dem Verlauf ableiten.
  ///
  /// [heute] ist nur fuer Tests gedacht, damit die Serie nicht von der
  /// echten Uhr abhaengt.
  factory GamificationStats.aus(
    List<SessionModel> sessions, {
    DateTime? heute,
  }) {
    if (sessions.isEmpty) return leer;

    final punkte = sessions.fold<int>(0, (s, e) => s + punkteFuer(e));
    final stufe = stufeFuer(punkte);
    final untergrenze = schwelleFuer(stufe);
    final obergrenze = schwelleFuer(stufe + 1);

    final serie = _serie(sessions, heute ?? DateTime.now());

    return GamificationStats(
      punkte: punkte,
      stufe: stufe,
      punkteInStufe: punkte - untergrenze,
      spanneDerStufe: obergrenze - untergrenze,
      serie: serie,
      sessions: sessions.length,
      abzeichen: {
        Abzeichen.angefangen,
        if (punkte >= 1000) Abzeichen.tausend,
        if (serie >= 7) Abzeichen.eineWoche,
      },
    );
  }

  /// Tage in Folge, rueckwaerts gezaehlt.
  ///
  /// Wurde heute noch nicht trainiert, zaehlt die Serie ab gestern weiter —
  /// erst ein ganzer ausgelassener Tag beendet sie. Sonst stuende sie jeden
  /// Morgen auf null, bevor man dazu kommt.
  static int _serie(List<SessionModel> sessions, DateTime heute) {
    final tage = sessions.map((s) => _tag(s.finishedAt)).toSet();
    if (tage.isEmpty) return 0;

    var zaehler = _tag(heute);
    if (!tage.contains(zaehler)) {
      zaehler = zaehler.subtract(const Duration(days: 1));
      if (!tage.contains(zaehler)) return 0;
    }

    var serie = 0;
    while (tage.contains(zaehler)) {
      serie++;
      zaehler = zaehler.subtract(const Duration(days: 1));
    }
    return serie;
  }

  /// Auf den Kalendertag zuruecksetzen — die Uhrzeit stoert beim Zaehlen.
  static DateTime _tag(DateTime zeitpunkt) =>
      DateTime(zeitpunkt.year, zeitpunkt.month, zeitpunkt.day);
}
