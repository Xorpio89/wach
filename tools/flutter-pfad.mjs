/**
 * Findet das Flutter-SDK.
 *
 * Auf diesem Rechner liegt Flutter unter C:\flutter, steht aber nicht im
 * PATH — ein blosses `flutter build` scheitert deshalb mit "command not
 * found". Die Skripte suchen es sich stattdessen selbst.
 */
import { existsSync } from 'node:fs';

const kandidaten = [
  'C:/flutter/bin/flutter.bat',
  'C:/src/flutter/bin/flutter.bat',
  `${process.env.LOCALAPPDATA ?? ''}/flutter/bin/flutter.bat`,
  `${process.env.USERPROFILE ?? ''}/flutter/bin/flutter.bat`,
];

/** Pfad zum Flutter-Befehl — aus dem PATH, sonst von den ueblichen Orten. */
export function flutterBefehl() {
  // Steht Flutter im PATH, hat das Vorrang: dann stimmt auch die Version,
  // die der Entwickler sonst benutzt.
  const imPfad = Bun.which('flutter');
  if (imPfad) return imPfad;

  for (const pfad of kandidaten) {
    if (pfad && existsSync(pfad)) return pfad;
  }

  console.error('Flutter nicht gefunden.');
  console.error('Gesucht im PATH und unter:');
  for (const p of kandidaten) console.error('  ' + p);
  process.exit(1);
}
