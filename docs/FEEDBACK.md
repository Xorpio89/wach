# Rückmeldungen aus der App

Wie eine Beobachtung aus dem Training bei der Weiterentwicklung ankommt.

## Das Problem

Der Einfall kommt zwischen zwei Sätzen: eine Kachel reagiert seltsam, eine
Zahl steht falsch, etwas fehlt. Wer in diesem Moment die App verlassen, einen
Browser öffnen und ein Formular ausfüllen müsste, schreibt es nicht auf — im
Keller ist zudem oft kein Netz. Bis nach dem Training ist es vergessen.

## Der Weg

Zwei Schritte, absichtlich getrennt:

1. **Notieren** — in der App, offline, ein Tippen. Art wählen (Fehler, Idee,
   Sonstiges), Text eingeben, fertig. Die Notiz liegt im Gerät.
2. **Melden** — später in Ruhe. Öffnet ein vorbereitetes Formular auf GitHub,
   Betreff und Text sind schon ausgefüllt. Abschicken muss ein Mensch.

Zu erreichen über *Einstellungen → Feedback*. Dort steht auch, wie viele
Notizen noch nicht weitergegeben wurden — sonst bleibt liegen, was
aufgeschrieben aber nie abgeschickt wurde.

## Warum über ein Formular und nicht direkt

Ein direkter Zugriff bräuchte einen Zugangsschlüssel in der App. Eine
Web-App liefert ihren gesamten Code an jeden Besucher aus — der Schlüssel
läge damit offen im Netz und könnte von jedem benutzt werden. Ein
Formular-Link braucht kein Geheimnis: Abgeschickt wird mit dem Konto dessen,
der davorsitzt.

## Was automatisch mitkommt

Jede Notiz trägt die Umstände bei sich, weil niemand beim Training
Versionsnummern abschreibt — und weil genau diese Angaben später die Suche
verkürzen:

- Version der laufenden App
- Umgebung (etwa `Web (android)` für die installierte Web-App)
- Zeitpunkt der Beobachtung

Sie stehen unter einer Trennlinie, damit oben die Sache selbst steht.

## Auswerten

```bash
bun feedback          # offene Rückmeldungen
bun feedback -- --alle  # auch die erledigten
```

Liest die Vorgänge mit dem Kennzeichen `feedback` aus dem Projekt und zeigt
Art, Betreff, Version und Umgebung. Damit ist der Kanal auch für einen
Agenten lesbar, ohne Zugriff auf das Gerät.

Kennzeichen: `feedback` an jedem Bericht, dazu `bug` oder `idee` je nach Art.

> Ein neu angelegter Vorgang erscheint über den Kennzeichen-Filter mit
> kurzem Verzug. Wer direkt nach dem Abschicken nachsieht und nichts findet,
> sollte es einen Moment später erneut versuchen.

## Aufbau

| Teil | Ort |
| --- | --- |
| Notiz und Arten | `lib/features/feedback/domain/feedback_notiz.dart` |
| Bericht und Adresse | `lib/features/feedback/domain/feedback_bericht.dart` |
| Speicherung | `lib/features/feedback/data/` |
| Zustand | `lib/features/feedback/presentation/providers/` |
| Oberfläche | `lib/features/feedback/presentation/screens/` |
| Auswertung | `tools/feedback.mjs` |

Die Adressbildung liegt bewusst getrennt von der Oberfläche: Ist sie falsch,
öffnet sich das Formular einfach leer, und die Notiz gilt trotzdem als
weitergegeben. Deshalb ist sie durch Tests abgedeckt
(`test/features/feedback/`).

## Nicht genommene Wege

**Eigener Server auf Hetzner.** Die App läuft über HTTPS; ein Aufruf an einen
Server ohne Zertifikat wird vom Browser blockiert. Für ein Zertifikat fehlt
ein Domainname — die Maschine hat nur eine IP-Adresse.

**Supabase.** Wäre technisch passend gewesen, aber das Projekt aus der
Konfiguration existiert nicht mehr: Der Name löst nicht mehr auf. Die
Zugangsdaten in `.env` sind toter Ballast.

**Google-Formular.** Für den Nutzer bequem, aber die Antworten liegen dann
außerhalb des Projekts und lassen sich nicht neben dem Code auswerten.
