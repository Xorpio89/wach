import 'dart:js_interop';

import 'installation_dienst.dart';
import 'installation_zustand.dart';

/// Die Bruecke zu `window.wachInstallation` aus der `index.html`.
///
/// Das Angebot des Browsers kann nicht aus Dart heraus erzeugt werden: Es
/// kommt als Ereignis (`beforeinstallprompt`), das die Seite abfangen muss,
/// bevor Flutter ueberhaupt laeuft. Dort wird es festgehalten, hier
/// abgeholt.
@JS('wachInstallation')
external _Bruecke? get _bruecke;

@JS()
@staticInterop
class _Bruecke {}

extension on _Bruecke {
  external bool istInstalliert();
  external bool istAngebotDa();
  external bool brauchtAnleitung();
  external JSPromise<JSBoolean> anbieten();
}

class InstallationDienstImpl implements InstallationDienst {
  @override
  InstallationZustand zustand() {
    final bruecke = _bruecke;
    // Fehlt die Bruecke, laeuft eine aeltere Fassung der Seite — dann
    // lieber nichts anbieten als einen Knopf, der ins Leere fuehrt.
    if (bruecke == null) return InstallationZustand.installiert;

    if (bruecke.istInstalliert()) return InstallationZustand.installiert;
    if (bruecke.istAngebotDa()) return InstallationZustand.angebotDa;
    if (bruecke.brauchtAnleitung()) return InstallationZustand.nurAnleitung;
    return InstallationZustand.unbekannt;
  }

  @override
  Future<bool> anbieten() async {
    final bruecke = _bruecke;
    if (bruecke == null) return false;
    final zugesagt = await bruecke.anbieten().toDart;
    return zugesagt.toDart;
  }
}
