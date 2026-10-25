# Karten-Workout — Plan

Stand 25.10.2026. Anlass: eine viral gegangene Challenge, bei der mit UNO-Karten trainiert wird —
gezogene Zahl = Wiederholungen. Die App „EndureReps“ und das konkrete Video waren per Websuche nicht
auffindbar; die Mechanik ist als „UNO-Workout“ seit Jahren verbreitet (Sportunterricht, Bootcamps).

Vorbild am Markt: **ENDUREPS Play** („Game of Reps — Draw a card. Do the reps. Survive the deck.“,
Google Play `com.endureps.endureps`), mit mehreren Spielmodi, Schwierigkeitsstufen, solo und Mehrspieler.

## Ziel

Ein neuer Modus neben Challenge und Battle: Karte ziehen, Übung machen, nächste Karte. Der **Stapel**
bestimmt die Übung, die Zahl die Wiederholungen. Bewusst **nicht** auf vier Farben oder die vier
Kartensymbole festgelegt: 1 bis 8 Stapel, jeder mit eigener Übung, Farbe und eigenem Symbol. Kein
Markenname in der App. Der Modus heißt **Karten-Workout** (englisch *Card Deck Workout*).

## Spielregeln (nach Review, so umgesetzt)

**Das Deck** je Stapel, mit eigenen Kartennamen (keine UNO-Begriffe, keine UNO-Optik); vier Stapel = 108 Karten:

| Karte | je Stapel | bei 4 Stapeln | Aufgabe |
|---|---|---|---|
| 0 | 1 | 4 | 10 Wiederholungen der Farbübung |
| 1–9 | je 2 | 72 | so viele Wiederholungen der Farbübung |
| Joker | 2 | 8 | durchatmen, nichts tun |
| Nochmal | 2 | 8 | die letzte Zahl- oder Wahl-Aufgabe noch einmal; ohne Vorgänger wie Joker |
| ×2 | 2 | 8 | die nächste Karte zählt doppelt (nicht stapelbar) |
| Wahl | 2 | 8 | 10 Wiederholungen, Übung aus allen Stapeln frei wählen |

**Stapel**: Standard sind die vier Startübungen (Push Ups, Pull Ups, Squats, Dips). Stapel lassen sich
hinzufügen und entfernen (1–8); Übung, Farbe (8 zur Wahl) und Symbol (8 zur Wahl) frei änderbar.

**Spielmodi**
- **Deck überleben:** ein Deck komplett abarbeiten, die Zeit zählt.
- **Gegen die Uhr:** so viele Karten wie möglich in 5 · 10 · 15 · 20 Minuten; leere Decks werden nachgemischt.

**Einstellungen vor dem Start**

- Deck (nur „Deck überleben“): Kurz (28) · Mittel (56) · Voll (alle). Teildecks werden **ausgewogen** gezogen — jeder Stapel und
  jede Kartenart anteilig —, nicht vom gemischten Stapel abgeschnitten.
- Schwierigkeit: Leicht ×0,5 · Normal ×1 · Hart ×1,5 · Brutal ×2 (gerundet, mindestens 1).
- **Obergrenze pro Karte:** 10 · 15 · 20 (Standard) · 30 · keine. Gilt nach Schwierigkeit und ×2.
- Aktionskarten: an · aus (aus = nur Zahlkarten, 19 je Stapel).
- **Pause zwischen Karten:** aus · 30 · 60 · 90 s; nach jeder Übung ein Countdown, überspringbar.
- **Spieler:** 1–4 am selben Gerät, mit Namen; sie ziehen reihum aus demselben Deck. Das Ergebnis zeigt
  die Wiederholungen je Spieler; gespeichert wird für Spieler 1.

**Mischen:** höchstens zwei Karten desselben Stapels hintereinander (gewichteter Aufbau).

**Umfang** (Voll, Normal, Obergrenze 20): 100 Wiederholungen je Farbübung aus den Zahlkarten, dazu rund
150 aus Wahl, ×2 und Nochmal.

## Review durch externe Agenten (Gemini 3.8 Flash, GPT-OSS 120B)

| Befund | Umgang |
|---|---|
| Überlastung bei Klimmzügen (+2 = 20, ×2 = 40 am Stück) | Obergrenze pro Karte, „+2“ wird „×2 auf die nächste Karte“ |
| Teildecks durch Abschneiden können eine Übung übergewichten | ausgewogene Teildecks, max. zwei gleiche Stapel in Folge |
| 1:1-Nachbildung des UNO-Decks | eigene Kartennamen, kein Markenname, keine UNO-Optik |
| Richtungswechsel-Ketten undefiniert | „Nochmal“ bezieht sich nur auf die letzte Zahl-/Wahl-Aufgabe |
| Bedienung mit nassen Händen | ganze Karte ist Tippfläche, Doppeltipp-Schutz |
| Muskelversagen nicht erfassbar | −/+ auf der Karte, gezählt wird das tatsächlich Geschaffte |
| Ergebnis erst in Phase 2 speichern widerspricht der App | Speichern als Workout im MVP |
| Kontrast weißer Text auf Gelb | dunkle Schrift auf Gelb und Grün |
| Paging-Änderung gehört nicht in diesen PR | eigener PR (#8) |
| Pausen-Timer, Bildschirm wach halten | Phase 2 |
| „Nur die Phase wird gespeichert“ (GPT-OSS) | steht nicht im Plan, verworfen |

## Ablauf in der App

1. **Startseite:** neue Karte „Karten-Workout“ neben Challenge und Battle.
2. **Einrichtung:** Deckgröße, Faktor, Aktionskarten, Zuordnung. Vorbelegt mit dem letzten Stand.
3. **Spiel:** Die gezogene Karte füllt den Bildschirm in der Farbe ihres Stapels; groß die Zahl, darunter die Übung
   und die Wiederholungen. Tippen auf „Erledigt“ zieht die nächste Karte. Oben: Karten übrig, Uhr.
   Farbwahl-Karten fragen nach der Übung. „Rückgängig“ für die letzte Karte.
4. **Ende:** Gesamtzeit, Wiederholungen je Übung, Karten. „Nochmal“ mit denselben Einstellungen.

**Barrierefreiheit:** Die Farbe steht nie allein — jede Karte zeigt Übungsname und Stapelsymbol
(Rot-Grün-Schwäche); Schrift dunkel auf hellen Farben.

## Architektur

Neues Feature-Modul nach dem Muster von `battle/`:

```
lib/features/karten/
├── domain/
│   ├── karte.dart          # KartenArt, Karte (Stapel-Index statt fester Farbe)
│   ├── deck.dart           # vollesDeck, ziehDeck (ausgewogen), mische (max. 2 in Folge)
│   └── karten_spiel.dart   # Regeln, Aufgabe, unveränderlicher Spielstand mit Übergängen
└── presentation/
    ├── providers/karten_spiel_provider.dart   # Phasen, Uhr, Rückgängig
    └── screens/karten_screen.dart              # Einrichtung · Karte · Ergebnis
```

- **Domain ohne Flutter-Import** — reine Logik, voll per Unit-Test prüfbar (Deck = 108 Karten,
  Verteilung, Aufgaben je Karte, Richtungswechsel, Faktor-Rundung, Mischen mit festem Seed).
- **Zustand im Speicher** wie beim Battle. Fortsetzen nach App-Neustart ist Phase 2.
- **Uhr:** eigener Ticker im Notifier wie `BattleNotifier`.
- **Texte:** alle über `app_de.arb` / `app_en.arb`.
- **Route** `/karten`, Eintrag in `Routes`.

## Speichern

„Speichern“ am Ende legt eine normale Session an (`sessionProvider.saveSession`): Wiederholungen je Übung
und die Dauer. **Ohne Ziele** — eine Karten-Session zählt also nicht als „Ziel erreicht“ und setzt keine
Bestzeit, fließt aber in Verlauf und Punkte ein.

## Code-Review des PR (Gemini 3.8 Flash, GPT-OSS 120B)

| Befund | Umgang |
|---|---|
| Uhr bleibt stehen, wenn das Handy sperrt | Zeit seit Start, mindestens die gezählten Ticks |
| Tipp auf die Zahl zwischen −/+ schließt die Karte ab | Zählbereich fängt Tipps ab (Test mit Mutant geprüft) |
| Karte 0 zeigt 0, verlangt 10 | Karte zeigt 10 |
| Doppeltipp auf Speichern legt zwei Sessions an | Sperre vor dem Speichern |
| Start mit gelöschter Übung möglich | Start gesperrt, Dropdown zeigt Hinweis |
| Einrichtung verändert die Stapel im Provider | Kopie, Zustand unveränderlich |
| Drei Wahl-Karten in Folge | Wahl zählt beim Mischen als eigener Stapel |
| Kein Signal bei Zeitablauf | Vibration bei Spiel- und Pausenende |
| „Schließen“ ließ das alte Ergebnis stehen | setzt auf die Einrichtung zurück |
| Rückgängig-Verlauf unbegrenzt | höchstens 50 Schritte |
| Angefangene Karte bei Zeitablauf verloren | zählt mit dem bisher Geschafften |
| Farbwahl ohne Screenreader-Label | beschriftet |
| null-`basis`, Timer-Sekunde zu viel, Doppelstart u. a. (GPT-OSS) | am Code geprüft, trifft nicht zu |

## Phase 2 (nicht in diesem Schritt)

- Halteübungen (Plank, L-Sit): Sekunden statt Wiederholungen; `Exercise.targetTime` gibt es schon.
- Spiel anhalten (Pause-Knopf), Bildschirm wach halten (betrifft auch das normale Workout).
- Fortsetzen eines laufenden Spiels nach Neustart (sembast), Bestzeiten je Modus.
- Bestzeiten je Deckgröße.

## Nebenbefund

`CLAUDE.md` nennt Flutter 3.24.0 / Dart 3.5 und verbietet Riverpod 3. Tatsächlich baut die CI mit
**Flutter 3.47.0** (`deploy.yml`), und `pubspec.yaml` nutzt Riverpod 3.0.0. Die Regel ist veraltet und
sollte in einem eigenen Commit korrigiert werden.
