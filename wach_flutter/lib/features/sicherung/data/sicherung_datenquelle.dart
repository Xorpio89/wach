import 'package:sembast/sembast.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../domain/sicherung.dart';

/// Liest und schreibt den Datenabzug.
class SicherungDatenquelle {
  final DatabaseService _databaseService;

  SicherungDatenquelle(this._databaseService);

  /// Die Bereiche nach Namen, damit sich der Abzug ohne Sonderfaelle
  /// aufbauen laesst.
  static final _stores = <String, StoreRef<String, Map<String, Object?>>>{
    'exercises': DatabaseService.exercisesStore,
    'sessions': DatabaseService.sessionsStore,
    'set_records': DatabaseService.setRecordsStore,
    'challenges': DatabaseService.challengesStore,
    'settings': DatabaseService.settingsStore,
    'feedback': DatabaseService.feedbackStore,
  };

  Future<Sicherung> abziehen() async {
    final db = await _databaseService.database;
    final daten = <String, Map<String, Map<String, Object?>>>{};

    for (final bereich in Sicherung.bereiche) {
      final store = _stores[bereich];
      if (store == null) continue;
      final eintraege = await store.find(db);
      daten[bereich] = {
        for (final eintrag in eintraege)
          eintrag.key: Map<String, Object?>.from(eintrag.value),
      };
    }

    return Sicherung(
      erstelltAm: DateTime.now(),
      appVersion: AppConstants.appVersion,
      daten: daten,
    );
  }

  /// Uebernimmt einen Abzug, ohne Vorhandenes zu ueberschreiben.
  ///
  /// Ergaenzen statt ersetzen, aus zwei Gruenden: Ein Abzug, der schon
  /// eingelesene Eintraege noch einmal mitbringt, richtet keinen Schaden an
  /// — man kann es also gefahrlos wiederholen. Und wer sich beim Einfuegen
  /// vertut, verliert nichts von dem, was hier schon liegt.
  Future<EinleseErgebnis> uebernehmen(Sicherung sicherung) async {
    final db = await _databaseService.database;
    var uebernommen = 0;
    var uebersprungen = 0;

    await db.transaction((txn) async {
      for (final bereich in Sicherung.bereiche) {
        final store = _stores[bereich];
        final eintraege = sicherung.daten[bereich];
        if (store == null || eintraege == null) continue;

        for (final eintrag in eintraege.entries) {
          final satz = store.record(eintrag.key);
          if (await satz.exists(txn)) {
            uebersprungen++;
            continue;
          }
          await satz.put(txn, eintrag.value);
          uebernommen++;
        }
      }
    });

    return EinleseErgebnis(
      uebernommen: uebernommen,
      uebersprungen: uebersprungen,
    );
  }
}
