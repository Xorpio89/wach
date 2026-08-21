import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/features/feedback/domain/feedback_bericht.dart';
import 'package:wach_flutter/features/feedback/domain/feedback_notiz.dart';

/// Wie aus einer Notiz ein abschickbarer Bericht wird.
///
/// Reine Rechnung, absichtlich ohne Oberflaeche: Wenn die Adresse falsch
/// gebaut ist, merkt es sonst niemand — das Formular oeffnet sich einfach
/// leer, und die Notiz gilt trotzdem als weitergegeben.
void main() {
  FeedbackNotiz notiz({
    String text = 'Kachel reagiert nicht',
    FeedbackArt art = FeedbackArt.fehler,
    String version = '1.0.30',
    String plattform = 'Web (android)',
  }) {
    return FeedbackNotiz(
      id: '1',
      art: art,
      text: text,
      erstelltAm: DateTime(2026, 8, 21, 18, 5),
      appVersion: version,
      plattform: plattform,
    );
  }

  group('Betreff', () {
    test('nimmt die erste Zeile', () {
      final b = notiz(text: 'Erste Zeile\nZweite Zeile').betreff;
      expect(b, 'Erste Zeile');
    });

    test('kuerzt sehr lange Zeilen', () {
      final lang = 'a' * 200;
      final b = notiz(text: lang).betreff;

      expect(b.length, lessThanOrEqualTo(70));
      expect(b, endsWith('...'));
    });

    test('laesst kurze Zeilen unangetastet', () {
      expect(notiz(text: 'Kurz').betreff, 'Kurz');
    });
  });

  group('Rumpf', () {
    test('enthaelt Text und Umstaende', () {
      final rumpf = FeedbackBericht.rumpf(notiz());

      expect(rumpf, contains('Kachel reagiert nicht'));
      expect(rumpf, contains('1.0.30'));
      expect(rumpf, contains('Web (android)'));
      // Der Zeitpunkt in lesbarer Form, nicht als Zahlenkolonne.
      expect(rumpf, contains('2026-08-21 18:05'));
    });

    test('trennt die Sache von den Umstaenden', () {
      // Oben steht, worum es geht; darunter, was zum Nachvollziehen
      // gebraucht wird.
      final rumpf = FeedbackBericht.rumpf(notiz());
      final trenner = rumpf.indexOf('---');

      expect(trenner, greaterThan(0));
      expect(rumpf.substring(0, trenner), contains('Kachel reagiert nicht'));
      expect(rumpf.substring(trenner), contains('Version:'));
    });
  });

  group('Adresse', () {
    test('zeigt auf das Formular des Projekts', () {
      final adresse = FeedbackBericht.adresse(notiz());

      expect(adresse.scheme, 'https');
      expect(adresse.host, 'github.com');
      expect(adresse.path, '/Xorpio89/wach/issues/new');
    });

    test('gibt Betreff und Rumpf mit', () {
      final adresse = FeedbackBericht.adresse(notiz());

      expect(adresse.queryParameters['title'], 'Kachel reagiert nicht');
      expect(adresse.queryParameters['body'], contains('1.0.30'));
    });

    test('Umlaute und Zeilenumbrueche ueberleben', () {
      // Ohne richtige Kodierung bricht die Adresse ab und der Bericht
      // kommt halb an.
      final adresse = FeedbackBericht.adresse(
        notiz(text: 'Übung lässt sich nicht löschen\nZweite Zeile'),
      );

      expect(adresse.queryParameters['title'],
          'Übung lässt sich nicht löschen');
      expect(adresse.queryParameters['body'], contains('Zweite Zeile'));
      // In der Adresse selbst darf kein rohes Sonderzeichen stehen.
      expect(adresse.toString(), isNot(contains('ü')));
      expect(adresse.toString(), isNot(contains('\n')));
    });

    test('die Art bestimmt das Kennzeichen', () {
      String kennzeichen(FeedbackArt art) =>
          FeedbackBericht.adresse(notiz(art: art)).queryParameters['labels']!;

      expect(kennzeichen(FeedbackArt.fehler), contains('bug'));
      expect(kennzeichen(FeedbackArt.idee), contains('idee'));
      // Jeder Bericht traegt das Grundkennzeichen, damit er auffindbar ist.
      for (final art in FeedbackArt.values) {
        expect(kennzeichen(art), contains('feedback'));
      }
    });
  });

  test('mehrere Notizen ergeben einen zusammenhaengenden Text', () {
    final text = FeedbackBericht.alsText([
      notiz(text: 'Erstes'),
      notiz(text: 'Zweites', art: FeedbackArt.idee),
    ]);

    expect(text, contains('Erstes'));
    expect(text, contains('Zweites'));
    expect(text, contains('idee'));
  });

  group('Speichern und Lesen', () {
    test('eine Notiz uebersteht den Weg durch die Datenbank', () {
      final vorher = notiz(art: FeedbackArt.idee);
      final nachher = FeedbackNotiz.fromMap(vorher.toMap());

      expect(nachher.art, FeedbackArt.idee);
      expect(nachher.text, vorher.text);
      expect(nachher.appVersion, '1.0.30');
      expect(nachher.istGemeldet, isFalse);
    });

    test('der Meldezeitpunkt bleibt erhalten', () {
      final gemeldet = notiz().kopieMit(gemeldetAm: DateTime(2026, 8, 21, 19));
      final nachher = FeedbackNotiz.fromMap(gemeldet.toMap());

      expect(nachher.istGemeldet, isTrue);
      expect(nachher.gemeldetAm, DateTime(2026, 8, 21, 19));
    });

    test('eine unbekannte Art faellt auf Sonstiges zurueck', () {
      // Sonst liesse ein spaeter entfernter Eintrag die Liste abstuerzen.
      expect(FeedbackArt.vonName('gibtsnicht'), FeedbackArt.sonstiges);
      expect(FeedbackArt.vonName(null), FeedbackArt.sonstiges);
    });
  });
}
