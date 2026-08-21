import 'feedback_notiz.dart';

/// Bildet aus einer Notiz die Adresse eines vorbereiteten Berichts.
///
/// Der Weg fuehrt ueber ein vorbefuelltes Formular statt ueber einen
/// direkten Zugriff: Dafuer braeuchte die App einen Zugangsschluessel, und
/// der liegt in einer Web-App offen fuer jeden lesbar im Netz. Ein
/// Formular-Link braucht kein Geheimnis — abgeschickt wird mit dem Konto
/// dessen, der davorsitzt.
///
/// Getrennt von der Oberflaeche, damit sich die Adressbildung pruefen
/// laesst, ohne einen Bildschirm zu bauen.
abstract final class FeedbackBericht {
  /// Das Projekt, in dem die Berichte landen.
  static const projekt = 'Xorpio89/wach';

  /// Kennzeichen, an denen sich Berichte spaeter filtern lassen.
  static const grundKennzeichen = 'feedback';

  static String kennzeichenFuer(FeedbackArt art) {
    return switch (art) {
      FeedbackArt.fehler => '$grundKennzeichen,bug',
      FeedbackArt.idee => '$grundKennzeichen,idee',
      FeedbackArt.sonstiges => grundKennzeichen,
    };
  }

  /// Der Meldetext mit den Umstaenden darunter.
  ///
  /// Die Angaben stehen unter einer Trennlinie, damit oben die Sache
  /// selbst steht und darunter, was zum Nachvollziehen gebraucht wird.
  static String rumpf(FeedbackNotiz notiz) {
    final zeit = _zeitstempel(notiz.erstelltAm);
    return '${notiz.text.trim()}\n\n'
        '---\n'
        '- Erfasst: $zeit\n'
        '- Version: ${notiz.appVersion}\n'
        '- Umgebung: ${notiz.plattform}\n'
        '- Aus der App gemeldet';
  }

  /// Die vollstaendige Adresse des vorbereiteten Formulars.
  static Uri adresse(FeedbackNotiz notiz) {
    return Uri.https('github.com', '/$projekt/issues/new', {
      'title': notiz.betreff,
      'body': rumpf(notiz),
      'labels': kennzeichenFuer(notiz.art),
    });
  }

  /// Alle Notizen als ein Text — fuer den Fall, dass der Weg ueber das
  /// Formular gerade nicht passt und jemand sie irgendwo einfuegen will.
  static String alsText(List<FeedbackNotiz> notizen) {
    return notizen
        .map((n) => '## ${n.art.name}: ${n.betreff}\n\n${rumpf(n)}')
        .join('\n\n');
  }

  static String _zeitstempel(DateTime zeit) {
    String zwei(int n) => n.toString().padLeft(2, '0');
    return '${zeit.year}-${zwei(zeit.month)}-${zwei(zeit.day)} '
        '${zwei(zeit.hour)}:${zwei(zeit.minute)}';
  }
}
