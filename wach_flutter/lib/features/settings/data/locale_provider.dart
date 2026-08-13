import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// get()/put() auf RecordRef kommen als Extension aus sembast.
import 'package:sembast/sembast.dart';

import '../../../core/database/database_service.dart';

/// Von der App unterstuetzte Sprachen.
///
/// Deutsch steht bewusst vorn: es ist die Vorlage der ARB-Dateien und
/// zugleich die Rueckfallsprache, wenn die Geraetesprache unbekannt ist.
const supportedLocales = [
  Locale('de'),
  Locale('en'),
];

/// Aktuell gewaehlte Sprache, in sembast gespeichert.
///
/// Der Wert wird synchron mit Deutsch initialisiert und danach aus der
/// Datenbank nachgeladen — so rendert der erste Frame nie in der
/// falschen Sprache und blockiert trotzdem nicht auf der DB.
class LocaleNotifier extends Notifier<Locale> {
  static const _recordKey = 'app_locale';

  @override
  Locale build() {
    _restore();
    return const Locale('de');
  }

  Future<void> _restore() async {
    try {
      final db = await DatabaseService().database;
      final record =
          await DatabaseService.settingsStore.record(_recordKey).get(db);
      final code = record?['languageCode'] as String?;
      if (code == null) return;

      final match = supportedLocales
          .where((l) => l.languageCode == code)
          .firstOrNull;
      if (match != null) state = match;
    } catch (e) {
      debugPrint('[Locale] Laden fehlgeschlagen: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    state = locale;
    try {
      final db = await DatabaseService().database;
      await DatabaseService.settingsStore.record(_recordKey).put(db, {
        'languageCode': locale.languageCode,
      });
    } catch (e) {
      debugPrint('[Locale] Speichern fehlgeschlagen: $e');
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
