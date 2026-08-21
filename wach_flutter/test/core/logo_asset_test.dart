import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/core/constants/app_constants.dart';

/// Sichert das Logo-Bild ab.
///
/// `Image.asset` mit falschem Pfad faellt nicht beim Uebersetzen auf,
/// sondern erst in der laufenden App — und dort als grauer Kasten. Diese
/// Tests halten Pfad, Registrierung und Auflösungen zusammen.
void main() {
  const pfad = 'assets/logo/wach-icon.png';

  test('das Logo liegt an der Stelle, die der Code angibt', () {
    expect(File(pfad).existsSync(), isTrue,
        reason: 'Fehlt — mit `python design/make_ui_logo.py` erzeugen.');
  });

  test('das Logo ist in pubspec.yaml eingetragen', () {
    // Ohne Eintrag wird die Datei nicht mitgeliefert, obwohl sie im
    // Projekt liegt.
    expect(File('pubspec.yaml').readAsStringSync(), contains(pfad));
  });

  test('es gibt die Fassungen fuer hohe Pixeldichte', () {
    // Flutter waehlt anhand der Geraetedichte aus. Fehlen sie, wirkt das
    // Logo auf heutigen Handys unscharf.
    for (final ordner in ['2.0x', '3.0x']) {
      expect(File('assets/logo/$ordner/wach-icon.png').existsSync(), isTrue,
          reason: '$ordner fehlt');
    }
  });

  test('die Bildgroesse passt zur Darstellung', () {
    // Das Bild wird mit logoSize dargestellt; die Grundfassung sollte
    // genau so gross sein, sonst wird gerechnet statt gezeichnet.
    final kopf = File(pfad).readAsBytesSync().sublist(16, 24);
    final breite = kopf[0] << 24 | kopf[1] << 16 | kopf[2] << 8 | kopf[3];
    final hoehe = kopf[4] << 24 | kopf[5] << 16 | kopf[6] << 8 | kopf[7];

    expect(breite, AppConstants.logoSize.toInt());
    expect(hoehe, AppConstants.logoSize.toInt());
  });
}
