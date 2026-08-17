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

### Weg A: Ziele in der Session mitschreiben

`SessionModel` bekommt neben `exerciseReps` auch `exerciseTargets`. Dann
lässt sich jede vergangene Session als Vorlage wiederverwenden, ohne ein
neues Konzept einzuführen.

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

## Offene Punkte

- **Was passiert mit der laufenden Übungsliste?** Wählt man eine Session
  aus dem Verlauf, muss die aktuelle Liste ersetzt oder ergänzt werden.
  Ersetzen ist eindeutig, verwirft aber Übungen, die man selbst angelegt
  hat.
- **Wie wird eine Bestzeit gebildet?** Die schnellste Session mit
  denselben Übungen und Zielen — oder die letzte? Bei „gegen mich selbst
  antreten" ist die Bestzeit die interessantere Zahl, die letzte die
  fairere.
- **Wie werden Sessions in der Auswahl benannt?** Aus den Übungen
  gebildet („200 Liegestütze", „100 Dips + 100 Klimmzüge") oder frei
  benennbar. Automatisch gebildet ist weniger Arbeit, wird bei vielen
  Übungen aber unlesbar.
- **Wie viele Einträge zeigt die Auswahl?** Der Verlauf wächst; sinnvoll
  wäre eine Zusammenfassung gleicher Zusammenstellungen mit ihrer
  Bestzeit statt jeder einzelnen Session.

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
