import 'dart:convert';

/// Ein Abzug aller Daten, die es wert sind, erhalten zu bleiben.
///
/// Es gibt einen konkreten Anlass: Der Browser bindet gespeicherte Daten an
/// die Adresse, unter der eine Seite liegt. Zieht die App auf eine andere
/// Adresse um, ist die Trainingshistorie dort **nicht** vorhanden — sie
/// liegt weiter unter der alten, auch wenn dort nichts mehr ausgeliefert
/// wird. Ohne einen Weg, sie mitzunehmen, waere sie mit dem Umzug verloren.
///
/// Deshalb ein Format, das ein Mensch lesen und weiterreichen kann, statt
/// eines Abzugs der Datenbank: Wer ihn in einer Notiz aufbewahrt, kann ihn
/// auch in Jahren noch einlesen.
class Sicherung {
  /// Fassung des Formats. Steigt nur, wenn sich der Aufbau so aendert, dass
  /// aeltere Abzuege anders gelesen werden muessen.
  static const formatFassung = 1;

  /// Was mitgenommen wird — und was bewusst nicht.
  ///
  /// Der laufende Durchgang und der Stand der Uhr fehlen absichtlich: Sie
  /// gehoeren zu diesem Geraet und diesem Augenblick. Eingelesen wuerden
  /// sie eine Uhr starten, die niemand gestartet hat.
  static const bereiche = <String>[
    'exercises',
    'sessions',
    'set_records',
    'challenges',
    'settings',
    'feedback',
  ];

  final DateTime erstelltAm;
  final String appVersion;

  /// Bereich → (Kennung → Eintrag).
  final Map<String, Map<String, Map<String, Object?>>> daten;

  const Sicherung({
    required this.erstelltAm,
    required this.appVersion,
    required this.daten,
  });

  int anzahlIn(String bereich) => daten[bereich]?.length ?? 0;

  /// Wie viele Eintraege insgesamt drinstehen.
  int get gesamt => daten.values.fold(0, (summe, e) => summe + e.length);

  bool get istLeer => gesamt == 0;

  Map<String, Object?> toJson() {
    return {
      'format': formatFassung,
      'erstellt_am': erstelltAm.toIso8601String(),
      'app_version': appVersion,
      'daten': daten,
    };
  }

  /// Als Text, den man weiterreichen kann.
  ///
  /// Mit Einrueckung: Der Abzug soll sich auch von Hand ansehen lassen —
  /// wer wissen will, was er da herumtraegt, soll es lesen koennen.
  String alsText() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Liest einen Abzug aus Text.
  ///
  /// Wirft [SicherungFehler], wenn der Text keiner ist. Das ist wichtiger
  /// als es klingt: Eingelesen wird, was jemand von Hand eingefuegt hat —
  /// da landet auch mal die falsche Zwischenablage im Feld.
  factory Sicherung.ausText(String text) {
    final Object? gelesen;
    try {
      gelesen = jsonDecode(text.trim());
    } catch (_) {
      throw const SicherungFehler(SicherungFehlerArt.keinAbzug);
    }

    if (gelesen is! Map) {
      throw const SicherungFehler(SicherungFehlerArt.keinAbzug);
    }

    final format = gelesen['format'];
    if (format is! int) {
      throw const SicherungFehler(SicherungFehlerArt.keinAbzug);
    }
    if (format > formatFassung) {
      // Aus einer neueren Fassung der App. Raten waere schlimmer als ein
      // klarer Hinweis.
      throw const SicherungFehler(SicherungFehlerArt.zuNeu);
    }

    final rohdaten = gelesen['daten'];
    if (rohdaten is! Map) {
      throw const SicherungFehler(SicherungFehlerArt.keinAbzug);
    }

    final daten = <String, Map<String, Map<String, Object?>>>{};
    for (final bereich in bereiche) {
      final eintraege = rohdaten[bereich];
      if (eintraege is! Map) continue;
      daten[bereich] = {
        for (final eintrag in eintraege.entries)
          if (eintrag.value is Map)
            '${eintrag.key}': Map<String, Object?>.from(
              eintrag.value as Map,
            ),
      };
    }

    return Sicherung(
      erstelltAm:
          DateTime.tryParse('${gelesen['erstellt_am']}') ?? DateTime(2026),
      appVersion: '${gelesen['app_version'] ?? ''}',
      daten: daten,
    );
  }
}

enum SicherungFehlerArt {
  /// Der Text ist kein Abzug — oder unterwegs beschaedigt worden.
  keinAbzug,

  /// Aus einer neueren Fassung der App als dieser.
  zuNeu,
}

class SicherungFehler implements Exception {
  final SicherungFehlerArt art;

  const SicherungFehler(this.art);

  @override
  String toString() => 'SicherungFehler(${art.name})';
}

/// Was beim Einlesen geschehen ist.
class EinleseErgebnis {
  /// Neu hinzugekommen.
  final int uebernommen;

  /// Schon vorhanden und deshalb uebersprungen.
  final int uebersprungen;

  const EinleseErgebnis({
    required this.uebernommen,
    required this.uebersprungen,
  });

  int get gesehen => uebernommen + uebersprungen;
}
