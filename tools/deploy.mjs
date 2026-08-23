#!/usr/bin/env bun
/**
 * Baut die Web-Version und schiebt sie zu Cloudflare Pages.
 *
 * Der Umzug von GitHub Pages hat einen Grund: Dort darf eine Seite nur aus
 * einem oeffentlichen Projekt kommen, solange man nichts bezahlt. Bei
 * Cloudflare ist die Sichtbarkeit des Projekts unerheblich, weil nicht
 * Cloudflare baut, sondern wir — hochgeladen wird nur das Ergebnis.
 *
 * Anders als bei GitHub Pages liegt die App im Wurzelverzeichnis, der
 * Basispfad bleibt also `/`.
 */
import { resolve } from 'node:path';

const wurzel = resolve(import.meta.dir, '..');
const appVerzeichnis = resolve(wurzel, 'wach_flutter');

const PROJEKT = 'wach';

async function lauf(befehl, argumente, verzeichnis) {
  const prozess = Bun.spawn([befehl, ...argumente], {
    cwd: verzeichnis,
    stdio: ['inherit', 'inherit', 'inherit'],
  });
  const code = await prozess.exited;
  if (code !== 0) process.exit(code);
}

console.log('\n  Bauen …\n');
await lauf('bun', ['run', 'build'], wurzel);

console.log('\n  Hochladen zu Cloudflare Pages …\n');
await lauf(
  'wrangler',
  [
    'pages',
    'deploy',
    'build/web',
    '--project-name',
    PROJEKT,
    '--branch',
    'main',
    // Ohne das bricht wrangler ab, wenn im Arbeitsbaum etwas offen ist —
    // beim Ausprobieren ist das der Normalfall.
    '--commit-dirty=true',
  ],
  appVerzeichnis,
);

console.log(`\n  Fertig: https://${PROJEKT}.pages.dev\n`);
