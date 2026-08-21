/// Was fuer eine Rueckmeldung es ist.
///
/// Bewusst nur drei Faelle: Beim Training soll die Einordnung ein Tippen
/// sein, keine Entscheidung.
enum FeedbackArt {
  fehler,
  idee,
  sonstiges;

  static FeedbackArt vonName(String? name) {
    return FeedbackArt.values.firstWhere(
      (a) => a.name == name,
      orElse: () => FeedbackArt.sonstiges,
    );
  }
}

/// Eine Rueckmeldung, wie sie in der App erfasst wird.
///
/// Sie wird zuerst im Geraet gespeichert und erst danach weitergegeben.
/// Grund: Der Einfall kommt zwischen zwei Saetzen, oft ohne Netz im
/// Keller — wer dann erst ein Formular im Browser ausfuellen muesste,
/// schreibt es nicht auf.
class FeedbackNotiz {
  final String id;
  final FeedbackArt art;
  final String text;
  final DateTime erstelltAm;

  /// Die Umstaende, unter denen es auffiel. Automatisch erfasst, weil
  /// niemand beim Training Versionsnummern tippt — und weil genau das
  /// spaeter die Suche verkuerzt.
  final String appVersion;
  final String plattform;

  /// Wann die Notiz weitergegeben wurde; `null`, solange sie nur hier liegt.
  ///
  /// Es heisst "weitergegeben", nicht "angekommen": Die App kann nur das
  /// Formular oeffnen, abschicken muss ein Mensch.
  final DateTime? gemeldetAm;

  const FeedbackNotiz({
    required this.id,
    required this.art,
    required this.text,
    required this.erstelltAm,
    required this.appVersion,
    required this.plattform,
    this.gemeldetAm,
  });

  bool get istGemeldet => gemeldetAm != null;

  /// Die erste Zeile, gekuerzt — dient als Betreff.
  String get betreff {
    final ersteZeile = text.trim().split('\n').first.trim();
    if (ersteZeile.length <= 70) return ersteZeile;
    return '${ersteZeile.substring(0, 67)}...';
  }

  FeedbackNotiz kopieMit({DateTime? gemeldetAm}) {
    return FeedbackNotiz(
      id: id,
      art: art,
      text: text,
      erstelltAm: erstelltAm,
      appVersion: appVersion,
      plattform: plattform,
      gemeldetAm: gemeldetAm ?? this.gemeldetAm,
    );
  }

  factory FeedbackNotiz.fromMap(Map<String, dynamic> map) {
    final gemeldet = map['gemeldet_am'] as int?;
    return FeedbackNotiz(
      id: map['id'] as String,
      art: FeedbackArt.vonName(map['art'] as String?),
      text: map['text'] as String,
      erstelltAm:
          DateTime.fromMillisecondsSinceEpoch(map['erstellt_am'] as int),
      appVersion: map['app_version'] as String? ?? '',
      plattform: map['plattform'] as String? ?? '',
      gemeldetAm: gemeldet == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(gemeldet),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'art': art.name,
      'text': text,
      'erstellt_am': erstelltAm.millisecondsSinceEpoch,
      'app_version': appVersion,
      'plattform': plattform,
      'gemeldet_am': gemeldetAm?.millisecondsSinceEpoch,
    };
  }
}
