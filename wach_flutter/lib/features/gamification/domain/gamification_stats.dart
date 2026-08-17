import 'dart:math' as math;

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
/// Der Zielbonus aus dem Konzept (`docs/GAMIFICATION.md`) fehlt hier noch:
/// eine Session haelt nur fest, wie viele Wiederholungen geschafft wurden,
/// nicht, welches Ziel damals galt. Das braucht zuerst ein erweitertes
/// Schema — bis dahin zaehlen ausschliesslich Wiederholungen.
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

  /// Punkte, ab denen [stufe] erreicht ist.
  ///
  /// Die Abstaende wachsen um 50 Punkte je Stufe: 200, 250, 300, …
  /// Siehe `docs/GAMIFICATION.md`.
  static int schwelleFuer(int stufe) {
    if (stufe <= 1) return 0;
    return 25 * stufe * stufe + 125 * stufe - 150;
  }

  /// Die zu [punkte] gehoerende Stufe.
  static int stufeFuer(int punkte) {
    if (punkte <= 0) return 1;
    // Umkehrung von `schwelleFuer`. Der anschliessende Abgleich faengt
    // Rundungsfehler der Wurzel ab, statt sich auf sie zu verlassen.
    final geschaetzt =
        ((-125 + math.sqrt(100.0 * punkte + 30625)) / 50).floor();
    var stufe = math.max(1, geschaetzt);
    while (schwelleFuer(stufe + 1) <= punkte) {
      stufe++;
    }
    while (stufe > 1 && schwelleFuer(stufe) > punkte) {
      stufe--;
    }
    return stufe;
  }

  /// Punkte einer einzelnen Session.
  static int punkteFuer(SessionModel session) => session.totalReps;

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
