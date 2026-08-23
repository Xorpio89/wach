'use strict';

// Service Worker der App.
//
// Zwei Aufgaben: Die App soll ohne Netz starten, und sie soll sich zum
// Startbildschirm hinzufuegen lassen. Beides haengt an dieser Datei —
// Chrome haelt eine Seite ohne Zwischenspeicher-Behandlung nicht fuer
// installierbar.
//
// Vorgehen: **Netz zuerst, Zwischenspeicher als Rueckfall.** Das ist
// bewusst nicht der schnellste Weg, aber der verlaesslichste. Der
// umgekehrte Weg (Zwischenspeicher zuerst) laesst Nutzer auf alten
// Fassungen sitzen — bei Flutter besonders leicht, weil die Dateinamen
// keine Kennung tragen: `main.dart.js` heisst nach jedem Bauen gleich.
// Deshalb gilt hier: Was das Netz liefert, gewinnt immer.

const SPEICHER = 'wach-v1';

// Was beim Einrichten schon hineingelegt wird, damit der erste Start ohne
// Netz gelingt. Der Rest sammelt sich beim ersten Besuch von selbst an.
const GRUNDGERUEST = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
];

self.addEventListener('install', (ereignis) => {
  ereignis.waitUntil(
    (async () => {
      const speicher = await caches.open(SPEICHER);
      // Einzeln, damit eine fehlende Datei nicht alles scheitern laesst.
      await Promise.all(
        GRUNDGERUEST.map((pfad) =>
          speicher.add(pfad).catch(() => {
            /* Nicht schlimm: kommt beim ersten Abruf nach. */
          }),
        ),
      );
      // Nicht warten, bis alle Fenster zu sind — sonst laeuft nach einem
      // Update tagelang die alte Fassung weiter.
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (ereignis) => {
  ereignis.waitUntil(
    (async () => {
      // Speicher fruehrerer Fassungen wegräumen.
      const namen = await caches.keys();
      await Promise.all(
        namen.filter((name) => name !== SPEICHER).map((name) => caches.delete(name)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (ereignis) => {
  const anfrage = ereignis.request;

  // Nur eigene Dateien und nur Abrufe. Schriften von Google und andere
  // fremde Adressen bleiben unberuehrt.
  if (anfrage.method !== 'GET') return;
  if (new URL(anfrage.url).origin !== self.location.origin) return;

  ereignis.respondWith(netzZuerst(anfrage));
});

async function netzZuerst(anfrage) {
  const speicher = await caches.open(SPEICHER);

  try {
    const antwort = await fetch(anfrage);
    // Nur brauchbare Antworten ablegen — eine Fehlerseite waere als
    // Rueckfall schlimmer als nichts.
    if (antwort && antwort.ok) {
      speicher.put(anfrage, antwort.clone()).catch(() => {});
    }
    return antwort;
  } catch (fehler) {
    const abgelegt = await speicher.match(anfrage);
    if (abgelegt) return abgelegt;

    // Beim Aufruf einer Seite lieber die Startseite zeigen als einen
    // Browser-Fehler — die App findet ihren Weg dann selbst.
    if (anfrage.mode === 'navigate') {
      const start = await speicher.match('index.html');
      if (start) return start;
    }
    throw fehler;
  }
}

// Erlaubt der Seite, ein Update sofort zu uebernehmen.
self.addEventListener('message', (ereignis) => {
  if (ereignis.data === 'uebernehmen') self.skipWaiting();
});
