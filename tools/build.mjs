#!/usr/bin/env bun
/**
 * Baut die Web-Version und stempelt die Versionsnummer ein.
 *
 * Die Nummer entsteht aus der Anzahl der Commits: `1.0.<commits>`. Damit
 * steigt sie bei jedem Commit von selbst, ohne dass jemand eine Zahl
 * pflegen muss — und ohne dass jeder Commit eine Datei nur zum Anheben
 * der Version anfasst. Beides waere bei einem Hook der Fall, der die
 * Version in die Quellen schreibt.
 */
import { resolve } from 'node:path';

import { flutterBefehl } from './flutter-pfad.mjs';

const appVerzeichnis = resolve(import.meta.dir, '..', 'wach_flutter');

/** `1.0.<Anzahl Commits>` — oder ein Rueckfallwert ausserhalb eines Repos. */
async function version() {
  try {
    const proc = Bun.spawn(['git', 'rev-list', '--count', 'HEAD'], {
      cwd: appVerzeichnis,
      stdout: 'pipe',
      stderr: 'ignore',
    });
    const ausgabe = (await new Response(proc.stdout).text()).trim();
    if ((await proc.exited) === 0 && /^\d+$/.test(ausgabe)) {
      return `1.0.${ausgabe}`;
    }
  } catch {
    // Ohne Git bleibt es beim Rueckfallwert.
  }
  return '1.0.0-dev';
}

const appVersion = await version();
console.log(`\n  Version ${appVersion}\n`);

const prozess = Bun.spawn(
  [
    flutterBefehl(),
    'build',
    'web',
    '--release',
    `--dart-define=APP_VERSION=${appVersion}`,
    ...process.argv.slice(2),
  ],
  { cwd: appVerzeichnis, stdio: ['inherit', 'inherit', 'inherit'] },
);

process.exit(await prozess.exited);
