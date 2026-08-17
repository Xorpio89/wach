import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderScope.overrides` erwartet `List<Override>`, aber
// flutter_riverpod 3.0.0 exportiert diesen Typ nicht mit. Bezogen wird er
// deshalb aus `internals.dart` — die Datei, die das Paket selbst als
// Export-Flaeche benutzt ("If we export internals, that's on purpose").
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:wach_flutter/core/database/database_service.dart';
import 'package:wach_flutter/core/theme/app_theme.dart';
import 'package:wach_flutter/features/settings/data/locale_provider.dart';
import 'package:wach_flutter/l10n/app_localizations.dart';
import 'package:wach_flutter/shared/navigation/app_router.dart';

/// Gemeinsamer Unterbau fuer Widget- und Integrationstests.
///
/// Die App haengt an einer sembast-Datenbank, die auf dem Geraet ueber
/// `path_provider` gefunden wird — im Test gibt es die nicht. Statt die
/// Repositories mit Fakes nachzubauen (und damit genau die Schicht zu
/// umgehen, in der Fehler entstehen), laeuft hier die echte Kette gegen
/// eine In-Memory-Datenbank.

/// Frische, leere Datenbank fuer den naechsten Test einhaengen.
///
/// Das Loeschen vorweg ist notwendig, nicht kosmetisch: die
/// Speicher-Datenbank von sembast liegt am Namen und ueberlebt ein
/// `close()`. Ohne diesen Schritt erbt jeder Test die Uebungen und Reps
/// des vorherigen — Tests werden dann einzeln gruen und im Verbund rot.
Future<Database> setUpTestDatabase(String name) async {
  await databaseFactoryMemory.deleteDatabase('$name.db');
  final db = await databaseFactoryMemory.openDatabase('$name.db');
  DatabaseService.setDatabaseForTests(db);
  return db;
}

/// Einen gesicherten Uhr-Stand von Hand in die Datenbank legen.
///
/// Fuer Faelle, die sich ueber die Oberflaeche nicht herstellen lassen —
/// etwa ein Lauf, der vor zwei Tagen begonnen wurde.
Future<void> setUpTestDatabaseRecord(
  Database db,
  Map<String, Object?> timerRecord,
) async {
  await DatabaseService.activeTimerStore.record('current').put(db, timerRecord);
}

/// Datenbank wieder aushaengen, damit kein Test auf der eines anderen sitzt.
Future<void> tearDownTestDatabase(Database db) async {
  DatabaseService.setDatabaseForTests(null);
  await db.close();
}

/// Einen Screen in dieselbe Umgebung setzen, die auch die App aufspannt:
/// ProviderScope, Material-Theme und die deutschen Uebersetzungen.
Widget wrapForTest(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('de'),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    ),
  );
}

/// Wie [wrapForTest], aber ohne das zusaetzliche [Scaffold] — fuer Screens,
/// die ihr eigenes mitbringen.
Widget wrapScreenForTest(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('de'),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark(),
      home: child,
    ),
  );
}

/// Die komplette App mit ihrem echten Router aufbauen.
///
/// Fuer Ablaeufe, die ueber mehr als einen Screen gehen — dann wird die
/// Navigation mitgetestet statt umgangen. Die Sprache steht fest auf
/// Deutsch, damit sich Pruefungen auf sichtbaren Text verlassen koennen.
Widget wrapAppForTest({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) {
        return MaterialApp.router(
          routerConfig: ref.watch(appRouterProvider),
          locale: const Locale('de'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
        );
      },
    ),
  );
}

/// Eine schmale Handy-Flaeche einstellen: 360 x 780 dp.
///
/// Bewusst der enge Fall — 360 dp ist die Breite, auf der die meisten
/// Android-Geraete stehen. Im Test kommt erschwerend dazu, dass keine
/// echte Schrift geladen wird: Flutter zeichnet jedes Zeichen als Quadrat
/// der vollen Schriftgroesse, Texte werden also deutlich breiter als auf
/// dem Geraet. Was hier ohne Ueberlauf durchlaeuft, passt real erst recht.
void usePortraitSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Warten, bis die asynchronen Datenbank-Zugriffe durch sind.
///
/// Bewusst ohne `pumpAndSettle`: das wartet, bis kein Bild mehr
/// angefordert wird, und in dieser App gibt es zwei Dinge, die nie
/// aufhoeren zu fragen — der Ladekreisel, solange die Uebungen aus der
/// Datenbank kommen, und der Ticker der laufenden Uhr. Der Aufruf liefe
/// dann in sein eingebautes Zeitlimit von zehn Minuten, statt einen
/// brauchbaren Fehler zu melden.
Future<void> settleAsync(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Echte Zeit verstreichen lassen und die Anzeige nachziehen.
///
/// Die Uhr der App rechnet bewusst gegen `DateTime.now()`, damit eine
/// Session im Hintergrund weiterlaeuft. Im Test hilft `pump` daher nicht:
/// das spult nur die simulierte Zeit vor, die echte Uhr steht. Ohne diesen
/// Umweg bliebe die Laufzeit bei null — und alles, was daran haengt (etwa
/// der Knopf zum Beenden), taucht nie auf.
///
/// Bewusst durch Pumpen statt ueber `runAsync`: `runAsync` gibt echten
/// asynchronen Aufgaben Raum, und damit laeuft der Schriften-Nachschub von
/// `google_fonts` los, der im Test weder aus dem Netz noch aus den Assets
/// bedient werden kann. Pumpen kostet ebenfalls echte Zeit, laesst diese
/// Aufgabe aber ruhen.
Future<void> passRealTime(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 60),
]) async {
  final until = DateTime.now().add(duration);
  while (DateTime.now().isBefore(until)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Eine feste Anzahl Bilder zeichnen, ohne auf Ruhe zu warten.
///
/// Notwendig, sobald die Uhr laeuft: `pumpAndSettle` wartet darauf, dass
/// keine Animation mehr aussteht, aber der Ticker der Uhr meldet sich alle
/// 16 ms erneut — der Aufruf kaeme nie zurueck. Die Voreinstellung deckt
/// mit gut einer Drittelsekunde jede Animation der App ab; die laengste
/// ist das Umdrehen der Kachel mit 150 ms.
Future<void> pumpFrames(
  WidgetTester tester, {
  int frames = 20,
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}
