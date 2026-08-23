# Ausliefern

Die App liegt an zwei Stellen — vorübergehend, bis der Umzug abgeschlossen
ist.

| Ziel | Adresse | Stand |
| --- | --- | --- |
| Cloudflare Pages | https://wach.pages.dev | neu, läuft |
| GitHub Pages | https://xorpio89.github.io/wach/ | alt, läuft noch |

## Warum der Umzug

GitHub Pages liefert nur aus **öffentlichen** Projekten, solange man nichts
bezahlt. Damit das Projekt privat werden kann, muss die Seite woanders
liegen.

Bei Cloudflare Pages ist die Sichtbarkeit unerheblich, weil dort nicht
gebaut wird: Gebaut wird hier beziehungsweise in GitHub Actions,
hochgeladen wird nur das Ergebnis. Kostenlos, und mit **Cloudflare Access**
ließe sich die Seite später auch hinter einer Anmeldung verstecken — was
GitHub Pages unterhalb von Enterprise gar nicht anbietet.

## Von Hand ausliefern

```bash
bun deploy
```

Baut die Web-Fassung und schiebt sie hoch. Setzt voraus, dass `wrangler`
angemeldet ist (`wrangler login`).

## Automatisch

`.github/workflows/deploy-cloudflare.yml` liefert bei jedem Push auf `main`
aus — **sobald der Zugang hinterlegt ist**. Fehlt er, läuft der Ablauf grün
durch und schreibt einen Hinweis, damit der bisherige Weg nicht bricht.

### Was dafür noch fehlt

Zwei Geheimnisse im Projekt (*Settings → Secrets and variables → Actions*):

| Name | Woher |
| --- | --- |
| `CLOUDFLARE_API_TOKEN` | Cloudflare-Dashboard → *My Profile → API Tokens → Create Token* → Vorlage **Edit Cloudflare Workers**, oder eigenes Token mit der Berechtigung *Account · Cloudflare Pages · Edit* |
| `CLOUDFLARE_ACCOUNT_ID` | `9bc2389bf909b123f558d460946d88dd` |

Das Token lässt sich nicht mit `wrangler` erzeugen — dafür ist das
Dashboard nötig.

## Reihenfolge beim Umschalten

Erst wenn der automatische Weg einmal grün gelaufen ist:

1. `CLOUDFLARE_API_TOKEN` und `CLOUDFLARE_ACCOUNT_ID` hinterlegen
2. Einen Push auf `main` abwarten und prüfen, dass `wach.pages.dev` die
   neue Versionsnummer zeigt
3. `.github/workflows/deploy.yml` entfernen und GitHub Pages im Projekt
   abschalten
4. **Dann** das Projekt auf privat stellen

Nicht umgekehrt — sonst steht die App ohne Auslieferungsweg da.

## Was beim Umschalten auf privat kippt

**Der Rückmeldeweg.** Er läuft über GitHub Issues (siehe
[FEEDBACK.md](FEEDBACK.md)). In einem privaten Projekt kann nur noch
melden, wer Zugriff hat. Für den Eigengebrauch unerheblich — sobald aber
jemand anderes die App testen soll, braucht der Kanal ein anderes Ziel.

**GitHub Actions.** Bei öffentlichen Projekten unbegrenzt, bei privaten
2.000 Minuten im Monat kostenlos. Ein Durchlauf braucht rund viereinhalb
Minuten, also etwa 440 Auslieferungen — reicht mit großem Abstand.

## Unterschiede der beiden Ziele

| | GitHub Pages | Cloudflare Pages |
| --- | --- | --- |
| Basispfad | `/wach/` | `/` |
| Tiefe Adressen | scheitern | fallen über `web/_redirects` auf die Startseite |
| Bauen | GitHub Actions | GitHub Actions oder lokal |

Der unterschiedliche Basispfad ist der Grund, warum ein Build nicht für
beide Ziele taugt.
