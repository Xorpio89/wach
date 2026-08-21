import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:wach_flutter/features/feedback/domain/feedback_notiz.dart';
import 'package:wach_flutter/features/feedback/presentation/providers/feedback_providers.dart';

import '../../support/test_harness.dart';

/// Der Weg einer Rueckmeldung durch die Datenbank.
///
/// Der Zweck des Ganzen ist, dass eine Notiz liegen bleibt, bis sie
/// weitergegeben wurde — auch wenn die App zwischendurch geschlossen wird.
/// Genau das wird hier geprueft, nicht die Oberflaeche.
void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestDatabase('feedback_test');
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  /// Ein frischer Behaelter, der auf der Test-Datenbank sitzt.
  Future<ProviderContainer> behaelter() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(feedbackNotizenProvider.future);
    return container;
  }

  test('am Anfang ist nichts notiert', () async {
    final container = await behaelter();
    expect(container.read(feedbackNotizenProvider).value, isEmpty);
    expect(container.read(offeneFeedbackAnzahlProvider), 0);
  });

  test('eine erfasste Notiz erscheint in der Liste', () async {
    final container = await behaelter();

    await container.read(feedbackNotizenProvider.notifier).erfasse(
          art: FeedbackArt.idee,
          text: 'Wiederholen aus dem Verlauf waere praktisch',
        );

    final liste = container.read(feedbackNotizenProvider).value!;
    expect(liste, hasLength(1));
    expect(liste.single.art, FeedbackArt.idee);
    expect(liste.single.text, 'Wiederholen aus dem Verlauf waere praktisch');
    // Die Umstaende kommen von selbst dazu, ohne Zutun.
    expect(liste.single.appVersion, isNotEmpty);
    expect(liste.single.plattform, isNotEmpty);
    expect(liste.single.istGemeldet, isFalse);
  });

  test('Leerzeichen am Rand werden abgeschnitten', () async {
    final container = await behaelter();

    await container
        .read(feedbackNotizenProvider.notifier)
        .erfasse(art: FeedbackArt.fehler, text: '  mit Rand  ');

    expect(container.read(feedbackNotizenProvider).value!.single.text,
        'mit Rand');
  });

  test('eine Notiz uebersteht einen Neustart der App', () async {
    // Erster Start: notieren.
    final erster = await behaelter();
    await erster
        .read(feedbackNotizenProvider.notifier)
        .erfasse(art: FeedbackArt.fehler, text: 'Bleibt liegen');

    // Zweiter Start: derselbe Datenbestand, neuer Behaelter.
    final zweiter = await behaelter();
    final liste = zweiter.read(feedbackNotizenProvider).value!;

    expect(liste, hasLength(1));
    expect(liste.single.text, 'Bleibt liegen');
  });

  test('weitergegebene Notizen zaehlen nicht mehr als offen', () async {
    final container = await behaelter();
    final notifier = container.read(feedbackNotizenProvider.notifier);

    final eine = await notifier.erfasse(
      art: FeedbackArt.fehler,
      text: 'Erste',
    );
    await notifier.erfasse(art: FeedbackArt.idee, text: 'Zweite');
    expect(container.read(offeneFeedbackAnzahlProvider), 2);

    await notifier.markiereGemeldet(eine);

    expect(container.read(offeneFeedbackAnzahlProvider), 1);
    // Die gemeldete bleibt erhalten — man soll nachsehen koennen, was
    // schon draussen ist.
    expect(container.read(feedbackNotizenProvider).value, hasLength(2));
    final gemeldete = container
        .read(feedbackNotizenProvider)
        .value!
        .firstWhere((n) => n.id == eine.id);
    expect(gemeldete.istGemeldet, isTrue);
  });

  test('eine Notiz laesst sich entfernen', () async {
    final container = await behaelter();
    final notifier = container.read(feedbackNotizenProvider.notifier);

    final notiz =
        await notifier.erfasse(art: FeedbackArt.sonstiges, text: 'Weg damit');
    await notifier.loesche(notiz.id);

    expect(container.read(feedbackNotizenProvider).value, isEmpty);
  });

  test('die neueste Notiz steht oben', () async {
    final container = await behaelter();
    final notifier = container.read(feedbackNotizenProvider.notifier);

    await notifier.erfasse(art: FeedbackArt.fehler, text: 'Zuerst');
    await notifier.erfasse(art: FeedbackArt.fehler, text: 'Danach');

    final liste = container.read(feedbackNotizenProvider).value!;
    expect(liste.first.text, 'Danach');
  });
}
