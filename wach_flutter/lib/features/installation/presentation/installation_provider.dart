import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/installation_dienst.dart';
import '../domain/installation_zustand.dart';

part 'installation_provider.g.dart';

@Riverpod(keepAlive: true)
InstallationDienst installationDienst(Ref ref) => InstallationDienst();

/// Ob die App zum Startbildschirm hinzugefuegt werden kann.
///
/// Wird mehrfach nachgesehen: Der Browser meldet erst einige Augenblicke
/// nach dem Laden, dass die App installierbar ist. Wer nur einmal beim
/// Aufbau fragt, erfaehrt es nie.
@Riverpod(keepAlive: true)
class Installation extends _$Installation {
  Timer? _nachfragen;

  @override
  InstallationZustand build() {
    final dienst = ref.watch(installationDienstProvider);
    var versuche = 0;

    _nachfragen?.cancel();
    _nachfragen = Timer.periodic(const Duration(seconds: 1), (zeitgeber) {
      versuche++;
      final jetzt = dienst.zustand();
      if (jetzt != state) state = jetzt;

      // Nach fuenf Sekunden kommt nichts mehr.
      if (versuche >= 5 || jetzt == InstallationZustand.angebotDa) {
        zeitgeber.cancel();
      }
    });
    ref.onDispose(() => _nachfragen?.cancel());

    return dienst.zustand();
  }

  /// Zeigt das Angebot des Browsers.
  Future<bool> hinzufuegen() async {
    final zugesagt = await ref.read(installationDienstProvider).anbieten();
    state = ref.read(installationDienstProvider).zustand();
    return zugesagt;
  }
}

/// Ob der Hinweis auf der Startseite noch gezeigt wird.
///
/// Nur fuer die laufende Sitzung: Wer ihn wegwischt, soll ihn nicht gleich
/// wieder sehen — dauerhaft verschwinden soll er aber nicht, sonst waere
/// der Weg ohne das Browsermenue endgueltig verbaut. In den Einstellungen
/// steht er ohnehin immer bereit.
@Riverpod(keepAlive: true)
class HinweisSichtbar extends _$HinweisSichtbar {
  @override
  bool build() => true;

  void wegwischen() => state = false;
}
