import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Waechter gegen Sprach-Mix.
///
/// Fehlt ein Schluessel in app_en.arb, faellt Flutter still auf die
/// deutsche Vorlage zurueck — die Oberflaeche waere dann teilweise
/// deutsch, ohne dass der Build meckert. Genau das soll hier auffliegen.
void main() {
  Map<String, dynamic> load(String path) {
    return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  }

  /// Nur echte Texte, ohne die @-Metadateneintraege.
  Set<String> messageKeys(Map<String, dynamic> arb) {
    return arb.keys.where((k) => !k.startsWith('@')).toSet();
  }

  late Map<String, dynamic> de;
  late Map<String, dynamic> en;

  setUpAll(() {
    de = load('lib/l10n/app_de.arb');
    en = load('lib/l10n/app_en.arb');
  });

  test('englische Datei deckt alle deutschen Schluessel ab', () {
    final missing = messageKeys(de).difference(messageKeys(en)).toList()
      ..sort();
    expect(
      missing,
      isEmpty,
      reason: 'Ohne Uebersetzung erscheinen diese Texte auf Deutsch, '
          'auch wenn Englisch gewaehlt ist: $missing',
    );
  });

  test('englische Datei enthaelt keine unbekannten Schluessel', () {
    final extra = messageKeys(en).difference(messageKeys(de)).toList()..sort();
    expect(
      extra,
      isEmpty,
      reason: 'Diese Schluessel gibt es nur auf Englisch — vermutlich in '
          'app_de.arb vergessen oder ein Tippfehler: $extra',
    );
  });

  test('kein Text ist leer', () {
    for (final arb in [de, en]) {
      final locale = arb['@@locale'];
      for (final key in messageKeys(arb)) {
        if (key == '@@locale') continue;
        expect(
          (arb[key] as String).trim(),
          isNotEmpty,
          reason: '$locale: "$key" ist leer',
        );
      }
    }
  });

  test('Platzhalter stimmen zwischen den Sprachen ueberein', () {
    final placeholder = RegExp(r'\{(\w+)');

    for (final key in messageKeys(de)) {
      if (key == '@@locale' || !en.containsKey(key)) continue;

      final inDe = placeholder
          .allMatches(de[key] as String)
          .map((m) => m.group(1))
          .toSet();
      final inEn = placeholder
          .allMatches(en[key] as String)
          .map((m) => m.group(1))
          .toSet();

      expect(
        inEn,
        equals(inDe),
        reason: '"$key": unterschiedliche Platzhalter — '
            'de=$inDe, en=$inEn. Ein fehlender Platzhalter '
            'verschluckt den Wert zur Laufzeit.',
      );
    }
  });
}
