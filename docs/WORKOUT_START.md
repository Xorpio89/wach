# Workout starten: drei Wege

**Stand:** 2026-08-18 · **Status:** Notiert, nicht umgesetzt

## Was gewünscht ist

Beim Starten soll man wählen können:

1. **Letztes Workout wiederholen** — wie heute, der gewohnte Weg
2. **Ein bestimmtes Workout aus dem Verlauf wiederholen** — etwa „200
   Liegestütze", für die man letztes Mal 15 Minuten gebraucht hat, oder
   „50 Klimmzüge" in 5:30, oder „100 Dips + 100 Klimmzüge"
3. **Frisch anfangen** — mit den Standardübungen, immer als unterste
   Option

Dazu: aus dem Verlauf heraus ein Workout direkt erneut öffnen.

## Eine Annahme, die nicht zutrifft

Es fühlt sich an, als würde „Workout starten" eine Kopie des letzten
Workouts anlegen. Das tut es nicht — und dieser Unterschied entscheidet
über den Umfang der Umsetzung.

Tatsächlich gibt es **eine einzige, dauerhafte Übungsliste** (Store
`exercises`). Der Workout-Bildschirm zeigt immer sie. Dass es wie eine
Wiederholung wirkt, liegt daran, dass die Liste zwischen zwei Trainings
unverändert bleibt. Löscht man eine Übung, ist sie überall weg; ändert man
ein Ziel, gilt das rückwirkend für die Anzeige.

Die Sessions im Verlauf sind reine Aufzeichnungen: Datum, Dauer,
Übungsnamen und geschaffte Wiederholungen (`SessionModel`). Sie enthalten
**nicht**, welches Ziel damals galt.

## Was daraus folgt

Der Wunsch verlangt eine Trennung, die es heute nicht gibt: zwischen
**Vorlage** (was trainiert werden soll) und **Durchführung** (was
geschafft wurde). Zwei Möglichkeiten:

### Weg A: Ziele in der Session mitschreiben — **umgesetzt 2026-08-21**

`SessionModel` hat neben `exerciseReps` jetzt auch `exerciseTargets`. Damit
lässt sich jede vergangene Session als Vorlage wiederverwenden, ohne ein
neues Konzept einzuführen.

Mitgeliefert wurden zwei Angaben, auf denen die Auswahlliste aufbauen kann:

* `zielErreicht` — ob alle Ziele der Session saßen. Grundlage für die
  Regel, dass ein Abbruch keine Bestzeit stellt.
* `zusammenstellung` — Kennzeichen aus Übungen und Zielen. Zwei Sessions
  mit gleichem Kennzeichen sind Durchgänge desselben Workouts.

Sessions von vor der Erweiterung haben kein Feld: sie gelten als „nicht
erreicht" und haben kein Kennzeichen, lassen sich also keiner Gruppe
zuordnen. Geraten wird nicht.

- Klein und nah am Bestehenden
- Löst zugleich den offenen Zielbonus der Gamification, der genau an
  dieser Lücke hängt (siehe [GAMIFICATION.md](GAMIFICATION.md))
- Alte Sessions haben das Feld nicht — beim Lesen muss ein Fehlen
  vorgesehen sein
- Der Verlauf wird zur Vorlagenliste, auch wenn man ihn eigentlich als
  Protokoll führt

### Weg B: Eigene Workout-Vorlagen

Ein neuer Store `workouts`: Name, Liste aus Übung und Ziel. Sessions
verweisen auf die Vorlage, mit der sie gefahren wurden.

- Sauberer getrennt; Vorlagen lassen sich benennen und pflegen
- Bestzeit je Vorlage ist direkt ableitbar
- Mehr Aufwand: neues Modell, Pflege-Oberfläche, Verknüpfung mit den
  bestehenden Übungen

**Vorschlag:** mit Weg A anfangen. Er bringt den Nutzen sofort und ist die
Voraussetzung für B, falls benannte Vorlagen später gewünscht sind.

## Gruppierung: was ist „dasselbe Workout"?

Der entscheidende Punkt für die Auswahl. Ein Beispiel aus der Praxis:

| Session | Ergebnis | Warum |
| --- | --- | --- |
| Mo | 50 Klimmzüge | Ziel geschafft |
| Do | 53 Klimmzüge | ein paar mehr gemacht |
| Sa | 35 Klimmzüge | abgebrochen |

Das sind **drei Durchgänge desselben Workouts**, nicht drei verschiedene.
Eine Auswahlliste, die sie einzeln aufführt, ist unbrauchbar — nach
wenigen Wochen stehen dort dreißig Einträge, die alle „Klimmzüge" heißen.

**Gruppiert wird nach dem Ziel, nicht nach dem Ergebnis.** Der Schlüssel
einer Gruppe ist die Menge der Paare aus Übung und Ziel:

```
{ (Klimmzüge, 50) }                      -> "50 Klimmzüge"
{ (Dips, 100), (Klimmzüge, 100) }        -> "100 Dips + 100 Klimmzüge"
{ (Liegestütze, 200) }                   -> "200 Liegestütze"
```

Damit landen 50, 53 und 35 in derselben Gruppe, weil das Ziel jedes Mal 50
war. Je Gruppe zeigt die Liste dann einen Eintrag mit Bestzeit und Anzahl
der Durchgänge.

Das ist zugleich das stärkste Argument dafür, die Ziele in der Session
mitzuschreiben (Weg A oben): **ohne sie ist diese Gruppierung nicht
möglich.** Man müsste die Ergebnisse zusammenfassen — 50 und 53 lägen
vielleicht noch beieinander, 35 wäre nicht mehr zuzuordnen, und die Grenze
wäre reine Willkür.

### Bestzeit: nur vollständige Durchgänge

**Entschieden (2026-08-21):** Wer das Ziel nicht erreicht hat, stellt keine
Bestzeit auf.

Ohne diese Regel gewinnt der Abbruch: 35 von 50 Klimmzügen sind schneller
geschafft als 50, und die Bestzeit einer Gruppe würde ausgerechnet von dem
Durchgang gehalten, der nicht fertig wurde.

Abgebrochene Durchgänge bleiben trotzdem in der Gruppe — sie zählen bei der
Anzahl mit und stehen im Verlauf. Nur für die Bestzeit werden sie
übersprungen.

```
50 Klimmzüge          Bestzeit 5:30 · 3 Durchgänge
  ├─ Mo  50/50  5:30  ← Bestzeit
  ├─ Do  53/50  6:12
  └─ Sa  35/50  4:05  ← zählt nicht, Ziel nicht erreicht
```

### Was in eine Gruppe gehört und was nicht

- Dieselben Übungen mit denselben Zielen — eine Gruppe, egal wie das
  Ergebnis ausfiel
- Dieselbe Übung mit anderem Ziel (50 vs. 100 Klimmzüge) — zwei Gruppen,
  denn es sind unterschiedlich schwere Vorhaben
- Eine Übung mehr oder weniger — zwei Gruppen, sonst wäre die Bestzeit
  nicht vergleichbar

## Offene Punkte

- **Was passiert mit der laufenden Übungsliste?** Wählt man eine Session
  aus dem Verlauf, muss die aktuelle Liste ersetzt oder ergänzt werden.
  Ersetzen ist eindeutig, verwirft aber Übungen, die man selbst angelegt
  hat.
- **Wie wird eine Bestzeit gebildet?** Die schnellste Session mit
  denselben Übungen und Zielen — oder die letzte? Bei „gegen mich selbst
  antreten" ist die Bestzeit die interessantere Zahl, die letzte die
  fairere.
- **Wie werden Gruppen benannt?** Aus Übungen und Zielen gebildet („200
  Liegestütze", „100 Dips + 100 Klimmzüge") oder frei benennbar.
  Automatisch gebildet ist weniger Arbeit, wird ab drei Übungen aber
  unlesbar — dann wäre ein Kurzname nötig.
- **Wie viele Gruppen zeigt die Auswahl?** Sinnvoll wären die zuletzt
  benutzten, nicht alle.

## Ziele anheben nach Übererfüllung

**Entschieden (2026-08-21) und umgesetzt:** Vorgeschlagen wird erst nach
drei Durchgängen in Folge, und zwar als antippbarer Hinweis auf der
Startseite — nicht als Dialog beim Beenden.

Idee: Hat man das Ziel übertroffen (50 vorgegeben, 55 geschafft), beim
Beenden anbieten, das Ziel auf 55 zu setzen. Bei mehreren Übungen kompakt
als Liste, mit „alle anheben" als Sammelaktion.

Das passt zum Kern der App — Progressive Overload heißt, Ziele anzuheben —
und der Moment ist der beste: gerade jetzt weiß man, dass mehr ging.

### Warum es nicht einfach dazukommen kann

**Es zersplittert die Gruppierung.** Wandert das Ziel von 50 auf 55, ist
der nächste Durchgang eine andere Gruppe. Nach ein paar Anhebungen stehen
dort fünf Gruppen mit je einem Durchgang, und keine hat eine belastbare
Bestzeit — genau die Vergleichbarkeit, für die nach Zielen gruppiert wird,
geht verloren.

Das verschiebt die Abwägung oben zu **Weg B**: eine benannte Vorlage
(„Klimmzüge"), deren Ziel sich über die Zeit entwickelt. Dann bleibt die
Historie zusammen, und die Zielentwicklung wird sogar sichtbar — aus
„50 → 55 → 60" liest man Fortschritt ab, aus drei getrennten Gruppen
nicht.

### Und nicht als Dialog beim Beenden

Beim Beenden steht bewusst nichts im Weg: die frühere Rückfrage ist
entfallen, die Level-Up-Feier ist ein Overlay und kein Dialog. Ein
Auswahldialog wäre ein Rückschritt — besonders bei einer Wiederholung
Unterschied.

Dazu: Übererfüllung ist oft Zufall. 53 statt 50, weil der letzte Satz voll
gemacht wurde. Das ist kein Signal.

**So umgesetzt:** Vorgeschlagen wird, wenn die letzten drei Durchgänge mit
dieser Übung das Ziel erreicht oder übertroffen haben. Vorgeschlagen wird
das **schwächste** der drei Ergebnisse — es ist das Niveau, das
zuverlässig geschafft wird; das beste wäre ein Ausrutscher nach oben.

Durchgänge ohne die Übung werden übersprungen: wer Klimmzüge jedes zweite
Mal macht, soll nicht benachteiligt werden, weil zwischendurch etwas
anderes trainiert wurde.

Verglichen wird gegen das **aktuelle** Ziel, nicht gegen das damals
gültige. Das ist hier kein Mangel, sondern richtig: nach einer Anhebung
beginnt die Zählung von selbst neu, weil die alten Durchgänge das neue Ziel
nicht mehr übertreffen.

Die Zersplitterung der Gruppierung bleibt damit bestehen und ist weiter zu
klären — sie tritt nur seltener ein, weil nicht mehr bei jedem Ausrutscher
angehoben wird.

Bei mehreren Übungen dann eine Liste mit Schaltern:

```
┌────────────────────────────────────┐
│  Ziele anheben?                    │
│                                    │
│  Klimmzüge      50 → 55      [✓]   │
│  Dips          100 → 105     [✓]   │
│  Liegestütze   100 → 100     [ ]   │
│                                    │
│  [ Übernehmen ]      [ Später ]    │
└────────────────────────────────────┘
```

## Reihenfolge auf dem Startbildschirm

Frisch anfangen steht unten — es ist der seltenste Fall und der einzige,
der Fortschritt verwirft.

```
┌──────────────────────────────────┐
│  ▶  Letztes Workout              │
│     4 Übungen · zuletzt gestern  │
├──────────────────────────────────┤
│  ⟳  200 Liegestütze              │
│     Bestzeit 15:02               │
├──────────────────────────────────┤
│  ⟳  50 Klimmzüge                 │
│     Bestzeit 5:30                │
├──────────────────────────────────┤
│  ✚  Neu mit Standardübungen      │
└──────────────────────────────────┘
```
