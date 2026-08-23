import 'installation_zustand.dart';
import 'installation_dienst_stub.dart'
    if (dart.library.js_interop) 'installation_dienst_web.dart';

/// Auskunft darueber, ob die App zum Startbildschirm hinzugefuegt werden
/// kann — und der Weg, es anzubieten.
///
/// Die Antwort kommt nur im Browser von echten Angaben; auf Android und iOS
/// als eigene App ist die Frage sinnlos, dort gilt sie als installiert.
/// Deshalb zwei Fassungen, die anhand der Plattform gewaehlt werden.
abstract interface class InstallationDienst {
  InstallationZustand zustand();

  /// Zeigt das Angebot des Browsers. Gibt zurueck, ob zugesagt wurde.
  Future<bool> anbieten();

  factory InstallationDienst() = InstallationDienstImpl;
}
