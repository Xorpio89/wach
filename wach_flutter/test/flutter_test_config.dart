import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Wird von `flutter test` automatisch vor allen Tests ausgefuehrt.
///
/// Die App holt ihre Schriften (Inter, RobotoMono) zur Laufzeit von
/// Google. Im Test gibt es kein Netz — sobald ein Test echte Zeit
/// verstreichen laesst, laeuft der Abruf los und die Ausnahme reisst den
/// Test mit sich, obwohl mit der App nichts verkehrt ist. Hier wird das
/// Nachladen einmal zentral abgeschaltet; Flutter nimmt dann die
/// eingebaute Ersatzschrift.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
