# Gamification — erster Entwurf

**Stand:** 2026-08-17 · **Status:** Konzept, nicht implementiert

## Leitgedanke

Die App wirbt mit „weniger Interaktion, mehr Training". Gamification darf
das nicht umdrehen. Deshalb: **keine zusätzlichen Handgriffe im Training,
keine neuen Bildschirme, keine Währung zum Ausgeben.** Alles, was zählt,
fällt beim Trainieren ohnehin an — es wird nur sichtbar gemacht.

Das Stufensystem beantwortet eine einzige Frage: *Werde ich besser?*

## Datenbasis: nichts Neues speichern

Der entscheidende Punkt für die Umsetzung. Alles Nötige liegt schon in der
Datenbank — jede beendete Session enthält Datum und Wiederholungen je
Übung (`SessionModel.exerciseReps`, `startedAt`, `finishedAt`).

**Umgesetzt seit 2026-08-21:** Punkte, Stufen, Serie und Abzeichen sind
gebaut, der Zielbonus ebenfalls — dafür schreiben Sessions jetzt die
damals gültigen Ziele mit (`exerciseTargets`). Sessions von vorher haben
das Feld nicht; für sie entfällt der Bonus, statt ihn zu erraten.

### Ränge statt Ziffern

Eine Stufe heißt nicht „Stufe 6", sondern **S-Rang**. Eine Zahl ist kein
Ziel, auf das man zuarbeitet — ein Rang schon, und die Reihenfolge E bis S
versteht jeder ohne Erklärung.

| Stufe | Rang | ab Punkten |
| --- | --- | --- |
| 1 | E-Rang | 0 |
| 2 | D-Rang | 200 |
| 3 | C-Rang | 550 |
| 4 | B-Rang | 1.100 |
| 5 | A-Rang | 1.900 |
| 6 | S-Rang | 3.000 |
| 7 | National Level | 4.800 |
| 8 | Monarch | 7.000 |
| 9 | Schattenmonarch | 10.200 |
| 10 | Herrscher | 14.000 |

Die Schwellen sind **gestaltet, nicht gerechnet**: Die ersten Aufstiege
kommen schnell, weil sie tragen sollen, danach zieht es sich deutlich an.
Ein S-Rang, den man in zwei Wochen hat, wäre nichts wert — bei etwa 250
Punkten je gelungenem Workout dauert er rund drei Monate.

Die Stufen sind nach oben offen, die Ränge nicht. Ab dem letzten Rang zählt
es weiter: Herrscher, Herrscher II, Herrscher III. Jeder Abstand wächst
dabei um 1.000 Punkte, sodass kein Aufstieg billiger ist als der vorige —
ein Test hält das über zwanzig Stufen fest.

Punkte und Stufe werden **aus dem Verlauf berechnet, nicht
mitgeführt**. Das erspart eine Datenmigration, kann nicht doppelt zählen,
übersteht ein „Rückgängig" beim Beenden von selbst und bleibt auch dann
korrekt, wenn eine Session nachträglich gelöscht wird.

Erst wenn der Verlauf so groß wird, dass die Rechnung spürbar dauert
(realistisch: mehrere tausend Sessions), lohnt ein zwischengespeicherter
Wert.

## Punkte

| Quelle | Punkte | Begründung |
| --- | --- | --- |
| Jede Wiederholung | 1 | Direkt nachvollziehbar: 50 Reps = 50 Punkte |
| Übungsziel erreicht | +25 je Übung | Belohnt Zielstrebigkeit statt bloßer Menge |
| Alle Ziele einer Session | +50 | Belohnt das saubere Durchziehen |

Bewusst **keine** Punkte für verstrichene Zeit — sonst lohnt Herumstehen.
Und keine Punkte für Gewicht oder Schwierigkeit, solange die App das nicht
erfasst.

## Stufen

Die Abstände wachsen um jeweils 50 Punkte pro Stufe:

```
Stufe(n) ab Punkten:  25n² + 125n − 150
```

| Stufe | ab Punkten | Abstand | ~Sessions à 50 Reps |
| ---: | ---: | ---: | ---: |
| 1 | 0 | — | — |
| 2 | 200 | 200 | 4 |
| 3 | 450 | 250 | 9 |
| 4 | 750 | 300 | 15 |
| 5 | 1.100 | 350 | 22 |
| 10 | 3.600 | 600 | 72 |

Die erste Stufe kommt nach wenigen Trainings — früh genug, dass es
auffällt. Danach dehnt es sich, ohne unerreichbar zu werden.

## Serie

Anzahl der **Kalendertage in Folge mit mindestens einer beendeten
Session**. Ein Ruhetag unterbricht sie.

Bewusst schlicht: keine „Serien-Retter", kein Einfrieren, keine
Erinnerungen. Eine Serie, die man kaufen oder retten kann, misst nichts
mehr. Reißt sie, fängt sie wieder bei eins an — das ist der Preis dafür,
dass sie etwas bedeutet.

## Abzeichen

Vier Stück zum Start, alle aus dem Verlauf ableitbar:

| Abzeichen | Bedingung |
| --- | --- |
| Angefangen | erste beendete Session |
| Tausend | 1.000 Wiederholungen insgesamt |
| Eine Woche | Serie von 7 Tagen |
| Sauber durch | alle Ziele einer Session erreicht |

Keine Abzeichen für Dinge, die man nicht beeinflussen kann (Uhrzeit,
Wochentag) — die belohnen Zufall statt Leistung.

## Wo es auftaucht

Zwei Stellen, mehr nicht:

**1. Startseite** — eine Zeile über den Karten:

```
┌────────────────────────────────┐
│  Stufe 3     ▓▓▓▓▓▓░░░░  620   │
│              noch 130 Punkte   │
│  🔥 4 Tage in Folge            │
└────────────────────────────────┘
```

**2. Nach dem Beenden** — die vorhandene Meldung wird ergänzt:

```
Workout gespeichert · +75 Punkte
```

Bei einem Stufenaufstieg stattdessen ein kurzer Hinweis mit der neuen
Stufe. Kein Dialog, der weggetippt werden muss — er stünde einem zweiten
Durchgang im Weg.

## Was bewusst fehlt

- **Ranglisten und Vergleiche mit anderen.** Progressive Overload ist ein
  Vergleich mit sich selbst; fremde Zahlen verzerren die eigene Steigerung.
- **Tagesaufgaben.** Sie steuern, was trainiert wird — das soll der
  Trainingsplan tun, nicht ein Punktesystem.
- **Verlierbare Punkte.** Eine Trainingspause ist keine Strafe wert.

## Umsetzung in Schritten

1. **Rechenkern** — `GamificationStats.aus(List<SessionModel>)`: Punkte,
   Stufe, Fortschritt zur nächsten, Serie, Abzeichen. Reine Funktion ohne
   Datenbank, damit vollständig testbar.
2. **Provider** — leitet aus `sessionsStreamProvider` ab, hält keinen
   eigenen Zustand.
3. **Anzeige** — Zeile auf der Startseite, Zusatz in der Meldung.

Schritt 1 ist der ganze Aufwand; 2 und 3 sind Beiwerk. Die Punktetabelle
und die Stufenformel gehören dabei an **eine** Stelle, damit sich Anzeige
und Rechnung nie widersprechen können.

## Offene Fragen

- Zählen Challenges und Battles mit? (Eigene Datenhaltung, deshalb hier
  zunächst ausgeklammert.)
- Sollen Wiederholungen aus sehr kurzen Sessions gedeckelt werden, damit
  „10× kurz eingeloggt" nicht mehr bringt als ein Training?
