import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// Nur Database — sembast bringt ebenfalls einen `Finder` mit, der sonst
// mit dem der Testbibliothek kollidiert.
import 'package:sembast/sembast.dart' show Database;
// LinkDelegate liegt nicht im Haupt-Export des Pakets.
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:wach_flutter/features/feedback/presentation/screens/feedback_screen.dart';

import '../../support/test_harness.dart';

/// Eine Attrappe fuer das Oeffnen von Adressen.
///
/// Im Test darf sich kein Browser oeffnen — es soll aber nachweisbar sein,
/// *welche* Adresse aufgerufen wurde und was passiert, wenn das scheitert.
class _LauncherAttrappe extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> aufrufe = [];

  /// Ob das Oeffnen gelingt. Auf `false` gesetzt spielt es den Fall durch,
  /// dass kein Browser bereitsteht.
  bool gelingt = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    aufrufe.add(url);
    return gelingt;
  }
}

/// Der Bildschirm zum Erfassen und Weitergeben von Rueckmeldungen.
///
/// Geprueft wird der Weg, den ein Mensch nimmt: tippen, notieren, melden.
/// Die Rechnung dahinter deckt `feedback_bericht_test.dart` ab.
void main() {
  late Database db;
  late _LauncherAttrappe launcher;

  setUp(() async {
    db = await setUpTestDatabase('feedback_screen_test');
    launcher = _LauncherAttrappe();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  Future<void> oeffne(WidgetTester tester) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(wrapScreenForTest(const FeedbackScreen()));
    await settleAsync(tester);
  }

  Future<void> schreibe(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  testWidgets('am Anfang steht der Hinweis, dass nichts notiert ist',
      (tester) async {
    await oeffne(tester);

    expect(find.text('Noch keine Rückmeldungen'), findsOneWidget);
  });

  testWidgets('eine Notiz erscheint nach dem Notieren in der Liste',
      (tester) async {
    await oeffne(tester);
    await schreibe(tester, 'Die Kachel reagiert nicht');

    await tester.tap(find.widgetWithText(TextButton, 'Notieren'));
    await settleAsync(tester);

    // Der Hinweis verschwindet, die Notiz steht da.
    expect(find.text('Noch keine Rückmeldungen'), findsNothing);
    expect(find.text('Die Kachel reagiert nicht'), findsOneWidget);
    // Das Eingabefeld ist wieder frei fuer die naechste Beobachtung.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    // Ohne Zutun wird nichts nach draussen gegeben.
    expect(launcher.aufrufe, isEmpty);
  });

  testWidgets('leerer Text wird nicht notiert', (tester) async {
    await oeffne(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Notieren'));
    await settleAsync(tester);

    expect(find.text('Noch keine Rückmeldungen'), findsOneWidget);
  });

  testWidgets('Melden ruft das Formular mit dem Text auf', (tester) async {
    await oeffne(tester);
    await schreibe(tester, 'Ziel liess sich nicht anheben');

    await tester.tap(find.widgetWithText(FilledButton, 'Melden'));
    await settleAsync(tester);

    expect(launcher.aufrufe, hasLength(1));
    final adresse = launcher.aufrufe.single;
    expect(adresse, startsWith('https://github.com/Xorpio89/wach/issues/new'));
    // Der Betreff steckt kodiert in der Adresse.
    expect(adresse, contains(Uri.encodeQueryComponent('Ziel liess sich')));
    expect(adresse, contains('labels=feedback%2Cbug'));

    // Danach gilt sie als weitergegeben.
    expect(find.text('Gemeldet'), findsOneWidget);
  });

  testWidgets('scheitert das Oeffnen, gilt die Notiz nicht als gemeldet',
      (tester) async {
    // Der gefaehrlichste Fall: Ohne diese Unterscheidung waere die Notiz
    // als erledigt abgehakt, obwohl nie ein Formular aufging.
    launcher.gelingt = false;

    await oeffne(tester);
    await schreibe(tester, 'Geht nicht raus');
    await tester.tap(find.widgetWithText(FilledButton, 'Melden'));
    await settleAsync(tester);

    expect(find.text('Das Formular ließ sich nicht öffnen'), findsOneWidget);
    expect(find.text('Gemeldet'), findsNothing);
    // Die Notiz ist aber erfasst — sie darf nicht verloren gehen.
    expect(find.text('Geht nicht raus'), findsOneWidget);
  });

  testWidgets('eine gemeldete Notiz laesst sich nicht erneut melden',
      (tester) async {
    await oeffne(tester);
    await schreibe(tester, 'Einmal genuegt');
    await tester.tap(find.widgetWithText(FilledButton, 'Melden'));
    await settleAsync(tester);

    // In der Zeile bleibt nur noch das Entfernen. Gesucht wird innerhalb
    // der Karte — dasselbe Zeichen sitzt auch im Knopf der Eingabe.
    Finder inDerZeile(IconData zeichen) => find.descendant(
          of: find.byType(Card),
          matching: find.byIcon(zeichen),
        );

    expect(inDerZeile(Icons.delete_outline_rounded), findsOneWidget);
    expect(inDerZeile(Icons.open_in_new_rounded), findsNothing);
  });

  testWidgets('eine Notiz laesst sich entfernen', (tester) async {
    await oeffne(tester);
    await schreibe(tester, 'Weg damit');
    await tester.tap(find.widgetWithText(TextButton, 'Notieren'));
    await settleAsync(tester);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await settleAsync(tester);

    expect(find.text('Weg damit'), findsNothing);
    expect(find.text('Noch keine Rückmeldungen'), findsOneWidget);
  });

  testWidgets('die Art bestimmt das Kennzeichen des Berichts', (tester) async {
    await oeffne(tester);

    await tester.tap(find.text('Idee'));
    await tester.pump();
    await schreibe(tester, 'Verlauf wiederholen');
    await tester.tap(find.widgetWithText(FilledButton, 'Melden'));
    await settleAsync(tester);

    expect(launcher.aufrufe.single, contains('labels=feedback%2Cidee'));
  });
}
