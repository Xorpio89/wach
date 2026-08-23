/// Wie die App gerade laeuft — und ob sich das aendern laesst.
enum InstallationZustand {
  /// Als eigene App gestartet, vom Startbildschirm. Nichts zu tun.
  installiert,

  /// Im Browser, und das Hinzufuegen laesst sich direkt anbieten.
  angebotDa,

  /// Im Browser, aber es gibt nichts anzubieten — auf dem iPhone fuehrt
  /// der Weg nur ueber "Teilen" und "Zum Home-Bildschirm".
  nurAnleitung,

  /// Im Browser, und der Browser hat noch nichts angeboten. Kann sich
  /// wenige Sekunden nach dem Laden noch aendern.
  unbekannt;

  bool get kannHinzufuegen =>
      this == InstallationZustand.angebotDa ||
      this == InstallationZustand.nurAnleitung;
}
