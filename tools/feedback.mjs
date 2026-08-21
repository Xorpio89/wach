/**
 * Zeigt die Rueckmeldungen aus der App.
 *
 * Die App sammelt sie im Geraet und gibt sie ueber ein vorbereitetes
 * Formular an das Projekt weiter (siehe FeedbackBericht). Dort landen sie
 * als Vorgang mit dem Kennzeichen `feedback` — und damit an einer Stelle,
 * die auch ein Agent lesen kann, ohne Zugriff auf das Handy zu haben.
 *
 *   bun feedback           offene Rueckmeldungen
 *   bun feedback -- --alle auch die abgeschlossenen
 */
import { spawnSync } from 'node:child_process';

const PROJEKT = 'Xorpio89/wach';
const KENNZEICHEN = 'feedback';

const alle = process.argv.includes('--alle');

const ergebnis = spawnSync(
  'gh',
  [
    'issue',
    'list',
    '--repo',
    PROJEKT,
    '--label',
    KENNZEICHEN,
    '--state',
    alle ? 'all' : 'open',
    '--limit',
    '50',
    '--json',
    'number,title,labels,createdAt,state,body,url',
  ],
  { encoding: 'utf8', shell: true },
);

if (ergebnis.status !== 0) {
  console.error(ergebnis.stderr?.trim() || 'gh konnte nicht gelesen werden.');
  console.error('\nIst die GitHub-Befehlszeile angemeldet? `gh auth status`');
  process.exit(1);
}

const vorgaenge = JSON.parse(ergebnis.stdout || '[]');

if (vorgaenge.length === 0) {
  console.log(
    alle
      ? 'Keine Rueckmeldungen vorhanden.'
      : 'Keine offenen Rueckmeldungen. (`bun feedback -- --alle` zeigt auch erledigte)',
  );
  process.exit(0);
}

/** Holt eine Angabe aus dem Fussteil, den die App anhaengt. */
function angabe(rumpf, name) {
  const treffer = new RegExp(`^- ${name}: (.+)$`, 'm').exec(rumpf ?? '');
  return treffer ? treffer[1].trim() : '—';
}

function art(labels) {
  const namen = (labels ?? []).map((l) => l.name);
  if (namen.includes('bug')) return 'Fehler';
  if (namen.includes('idee')) return 'Idee';
  return 'Sonstiges';
}

console.log(
  `${vorgaenge.length} Rueckmeldung${vorgaenge.length === 1 ? '' : 'en'}` +
    `${alle ? '' : ' (offen)'} — ${PROJEKT}\n`,
);

for (const v of vorgaenge) {
  const zustand = v.state === 'OPEN' ? '' : ' [erledigt]';
  console.log(`#${v.number} · ${art(v.labels)}${zustand}`);
  console.log(`  ${v.title}`);
  console.log(
    `  Version ${angabe(v.body, 'Version')} · ${angabe(v.body, 'Umgebung')}` +
      ` · erfasst ${angabe(v.body, 'Erfasst')}`,
  );
  console.log(`  ${v.url}\n`);
}
