import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Ohne die Erweiterungsmethoden des Pakets gibt es kein `put`; nur
// `Finder` bleibt draussen, weil die Testbibliothek einen eigenen hat.
import 'package:sembast/sembast.dart' hide Finder;
import 'package:wach_flutter/core/database/database_service.dart';
import 'package:wach_flutter/features/sicherung/domain/sicherung.dart';
import 'package:wach_flutter/features/sicherung/presentation/sicherung_provider.dart';

import '../../support/test_harness.dart';

/// Daten mitnehmen.
///
/// Der Anlass ist ein Umzug: Der Browser bindet gespeicherte Daten an die
/// Adresse der Seite. Wechselt die Adresse, ist die Trainingshistorie dort
/// nicht vorhanden — ohne diesen Weg waere sie verloren. Entsprechend geht
/// es hier nicht um Bequemlichkeit, sondern um Datenverlust.
void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('sicherung_test');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Future<ProviderContainer> behaelter() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  /// Legt eine Session und eine Uebung von Hand ab — so wie sie nach einem
  /// Workout in der Datenbank stehen.
  Future<void> lageAnBestand() async {
    await DatabaseService.sessionsStore.record('s1').put(db, {
      'started_at': DateTime(2026, 8, 1, 17).millisecondsSinceEpoch,
      'finished_at': DateTime(2026, 8, 1, 18).millisecondsSinceEpoch,
      'duration_seconds': 3600,
      'exercise_reps': {'kz': 50},
      'exercise_names': {'kz': 'Klimmzüge'},
      'exercise_targets': {'kz': 50},
    });
    await DatabaseService.exercisesStore.record('kz').put(db, {
      'name': 'Klimmzüge',
      'target_reps': 50,
      'created_at': DateTime(2026, 7, 1).millisecondsSinceEpoch,
    });
  }

  group('Abziehen', () {
    test('nimmt Sessions und Uebungen mit', () async {
      await lageAnBestand();
      final container = await behaelter();

      final abzug = await container.read(abzugProvider.future);

      expect(abzug.anzahlIn('sessions'), 1);
      expect(abzug.anzahlIn('exercises'), 1);
      expect(abzug.istLeer, isFalse);
    });

    test('laesst den laufenden Durchgang und die Uhr aussen vor', () async {
      // Beides gehoert zu diesem Geraet und diesem Augenblick. Eingelesen
      // wuerden sie eine Uhr starten, die niemand gestartet hat.
      expect(Sicherung.bereiche, isNot(contains('active_workout')));
      expect(Sicherung.bereiche, isNot(contains('active_timer')));
    });

    test('ein leerer Bestand ergibt einen leeren Abzug', () async {
      final container = await behaelter();
      final abzug = await container.read(abzugProvider.future);
      expect(abzug.istLeer, isTrue);
    });
  });

  group('Der Text', () {
    test('ueberlebt den Weg durch Zwischenablage und Einfuegen', () async {
      await lageAnBestand();
      final container = await behaelter();
      final abzug = await container.read(abzugProvider.future);

      final gelesen = Sicherung.ausText(abzug.alsText());

      expect(gelesen.anzahlIn('sessions'), 1);
      expect(gelesen.daten['sessions']!['s1']!['duration_seconds'], 3600);
      // Umlaute in Uebungsnamen dürfen nicht verstümmeln.
      expect(
        gelesen.daten['exercises']!['kz']!['name'],
        'Klimmzüge',
      );
    });

    test('ueberlebt Leerzeichen am Rand', () {
      // Beim Einfuegen von Hand kommt fast immer etwas mit.
      const text = '{"format":1,"daten":{"sessions":{}}}';
      expect(() => Sicherung.ausText('\n  $text  \n'), returnsNormally);
    });

    test('etwas anderes als ein Abzug wird abgewiesen', () {
      // Eingelesen wird, was jemand eingefuegt hat — da landet auch mal
      // die falsche Zwischenablage im Feld.
      for (final murks in ['', 'Hallo', '{}', '[1,2,3]', '{"format":"x"}']) {
        expect(
          () => Sicherung.ausText(murks),
          throwsA(
            isA<SicherungFehler>().having(
              (f) => f.art,
              'art',
              SicherungFehlerArt.keinAbzug,
            ),
          ),
          reason: 'sollte abgewiesen werden: "$murks"',
        );
      }
    });

    test('ein Abzug aus einer neueren Fassung wird erkannt', () {
      // Raten waere schlimmer als ein klarer Hinweis.
      expect(
        () => Sicherung.ausText('{"format":99,"daten":{}}'),
        throwsA(
          isA<SicherungFehler>().having(
            (f) => f.art,
            'art',
            SicherungFehlerArt.zuNeu,
          ),
        ),
      );
    });
  });

  group('Einlesen', () {
    test('holt Daten in einen leeren Bestand', () async {
      // Genau der Umzugsfall: druesben ist noch nichts.
      await lageAnBestand();
      final quelle = await behaelter();
      final text = (await quelle.read(abzugProvider.future)).alsText();

      // Ziel: eine frische Datenbank.
      await tearDownTestDatabase(db);
      db = await setUpTestDatabase('sicherung_ziel');
      final ziel = await behaelter();

      final ergebnis =
          await ziel.read(einlesenProvider.notifier).ausText(text);

      expect(ergebnis.uebernommen, 2);
      expect(ergebnis.uebersprungen, 0);
      final danach = await ziel.read(abzugProvider.future);
      expect(danach.anzahlIn('sessions'), 1);
      expect(danach.anzahlIn('exercises'), 1);
    });

    test('zweimal Einlesen legt nichts doppelt an', () async {
      // Wer unsicher ist, ob es geklappt hat, soll es gefahrlos wiederholen
      // koennen.
      await lageAnBestand();
      final container = await behaelter();
      final text = (await container.read(abzugProvider.future)).alsText();

      final ergebnis =
          await container.read(einlesenProvider.notifier).ausText(text);

      expect(ergebnis.uebernommen, 0);
      expect(ergebnis.uebersprungen, 2);
      final danach = await container.read(abzugProvider.future);
      expect(danach.anzahlIn('sessions'), 1);
    });

    test('Vorhandenes wird nicht ueberschrieben', () async {
      // Wer sich beim Einfuegen vertut, darf nichts verlieren.
      await lageAnBestand();
      final container = await behaelter();

      const fremd = '{"format":1,"daten":{"sessions":{"s1":'
          '{"duration_seconds":1,"exercise_reps":{},"exercise_names":{},'
          '"started_at":0,"finished_at":0}}}}';
      final ergebnis =
          await container.read(einlesenProvider.notifier).ausText(fremd);

      expect(ergebnis.uebernommen, 0);
      final danach = await container.read(abzugProvider.future);
      expect(
        danach.daten['sessions']!['s1']!['duration_seconds'],
        3600,
        reason: 'Die vorhandene Session muss unberuehrt bleiben',
      );
    });
  });
}
