// Eigene Startdatei — sie ersetzt die von Flutter erzeugte.
//
// Grund: Flutter registriert hier sonst einen Service Worker, der sich beim
// Aktivieren sofort selbst abmeldet und nichts zwischenspeichert. Er ist
// laut Flutter selbst veraltet und soll verschwinden. Fuer uns hatte er
// zwei Folgen:
//
//   1. Kein Offline-Start. Ohne Netz laedt die App nicht.
//   2. Keine Installierbarkeit. Chrome haelt eine Seite ohne
//      Zwischenspeicher-Behandlung nicht fuer installierbar und bietet
//      deshalb nie an, sie zum Startbildschirm hinzuzufuegen.
//
// Statt seiner registriert `index.html` unseren eigenen Worker (`sw.js`).
// Die beiden Platzhalter unten werden beim Bauen ersetzt.

{{flutter_js}}
{{flutter_build_config}}

// Ohne `serviceWorkerSettings` laesst der Lader den Worker in Ruhe.
_flutter.loader.load();
