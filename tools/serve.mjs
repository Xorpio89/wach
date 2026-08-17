#!/usr/bin/env bun
/**
 * Liefert den gebauten Web-Stand aus — im LAN, damit die App auch vom
 * Handy aus erreichbar ist.
 *
 * Bewusst mit Bun statt `python -m http.server`: der Weg ueber Bun kennt
 * die richtigen MIME-Typen fuer `.wasm` und `.js`, faellt fuer unbekannte
 * Pfade auf `index.html` zurueck (die App bringt ihr eigenes Routing mit)
 * und schaltet den Cache ab, damit beim Testen nicht ein alter Stand
 * haengenbleibt.
 */
import { existsSync, statSync } from 'node:fs';
import { networkInterfaces } from 'node:os';
import { join, resolve } from 'node:path';

const wurzel = resolve(import.meta.dir, '..', 'wach_flutter', 'build', 'web');
const port = Number(process.env.PORT ?? 8090);

if (!existsSync(join(wurzel, 'index.html'))) {
  console.error('Kein gebauter Stand gefunden unter:\n  ' + wurzel);
  console.error('\nErst bauen:  bun run build');
  process.exit(1);
}

/** Die Adresse, unter der das Handy den Rechner im WLAN erreicht. */
function lanAdresse() {
  for (const eintraege of Object.values(networkInterfaces())) {
    for (const e of eintraege ?? []) {
      if (e.family === 'IPv4' && !e.internal && !e.address.startsWith('172.')) {
        return e.address;
      }
    }
  }
  return null;
}

Bun.serve({
  port,
  hostname: '0.0.0.0',
  development: false,
  async fetch(req) {
    const url = new URL(req.url);
    const pfad = decodeURIComponent(url.pathname);
    let ziel = join(wurzel, pfad === '/' ? 'index.html' : pfad);

    // Verzeichnisse und unbekannte Routen gehen an die App selbst.
    if (!existsSync(ziel) || statSync(ziel).isDirectory()) {
      ziel = join(wurzel, 'index.html');
    }
    // Nichts ausserhalb des Build-Ordners ausliefern.
    if (!resolve(ziel).startsWith(wurzel)) {
      return new Response('Nicht gefunden', { status: 404 });
    }

    return new Response(Bun.file(ziel), {
      headers: {
        // Ohne das haelt der Browser beim Testen den alten Stand fest.
        'Cache-Control': 'no-store, must-revalidate',
      },
    });
  },
});

const lan = lanAdresse();
console.log('\n  W.A.C.H. laeuft\n');
console.log(`  Rechner:  http://localhost:${port}`);
if (lan) console.log(`  Handy:    http://${lan}:${port}`);
console.log('\n  Beenden mit Strg+C\n');
