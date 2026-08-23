import 'installation_dienst.dart';
import 'installation_zustand.dart';

/// Fassung fuer Android, iOS und Desktop.
///
/// Dort ist die App bereits als App vorhanden — es gibt nichts
/// hinzuzufuegen, also verschwindet der Hinweis von selbst.
class InstallationDienstImpl implements InstallationDienst {
  @override
  InstallationZustand zustand() => InstallationZustand.installiert;

  @override
  Future<bool> anbieten() async => false;
}
