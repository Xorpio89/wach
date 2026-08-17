#!/usr/bin/env bun
/**
 * Ruft Flutter im App-Verzeichnis auf.
 *
 * Ein `cd wach_flutter && flutter ...` direkt in package.json waere von
 * der jeweiligen Shell abhaengig; hier wird das Arbeitsverzeichnis
 * ausdruecklich gesetzt und der Rueckgabewert durchgereicht, damit ein
 * fehlgeschlagener Build auch als Fehler ankommt.
 */
import { resolve } from 'node:path';

import { flutterBefehl } from './flutter-pfad.mjs';

const appVerzeichnis = resolve(import.meta.dir, '..', 'wach_flutter');
const argumente = process.argv.slice(2);

const prozess = Bun.spawn([flutterBefehl(), ...argumente], {
  cwd: appVerzeichnis,
  stdio: ['inherit', 'inherit', 'inherit'],
});

process.exit(await prozess.exited);
