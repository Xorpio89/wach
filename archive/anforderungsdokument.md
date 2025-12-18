#📄 Anforderungsdokument: Progressive Lift (V1.0 MVP)
**Projektname Intern:** Project Chiron
**App-Name:** LiftFlow Focus (Vorschlag)
**Ziel:** Minimalistische, Offline-fähige App zum Tracking von Progressive Overload.

---

##1. 🎯 Projektziele und Kernwerte| Aspekt | Beschreibung |
| --- | --- |
| **Primäres Ziel** | Ermöglichen des **Tracking von Progressive Overload** (Steigerung der Leistung) mit Fokus auf Zeiteffizienz. |
| **Kernwerte** | Minimalismus, Einfachheit, Geschwindigkeit, **bestmögliche UX während des Trainings**. |
| **MVP-Scope** | Nur die Kernfunktionalität: Übung hinzufügen, Starten, Tracken (Reps/Zeit), Speichern, Nächste Session vorschlagen. |
| **Plattformen** | **iOS, Android und Web** (mit Fokus auf Code-Wiederverwendung). |
| **Offline-Fähigkeit** | **Obligatorisch.** Alle Kerndaten müssen lokal gespeichert werden. |

##2. ⚙️ Technische Architektur & Technologie-Stack###2.1. Architektur-Entscheidung (Senior-Entwickler Input)* **Design-Muster:** Clean Architecture (Präsentation, Domain, Data Layer-Trennung).
* **Grundlage:** **Flutter (Dart)**, um die Code-Wiederverwendung über Mobile und Web zu maximieren.

###2.2. Technologie-Stack| Ebene | Technologie | Zweck |
| --- | --- | --- |
| **Frontend/UI** | Flutter (Dart) | Cross-Plattform-Entwicklung. |
| **Lokale DB** | **Isar oder Hive** | Schnelle, zuverlässige, NoSQL-DB für obligatorische Offline-Fähigkeit. |
| **State Management** | Provider oder Riverpod | Für schlanke Zustandsverwaltung. |
| **Optionale API/Cloud** | Context7 (Für zukünftigen Sync/Multiplayer) | Sollte über den Data Layer integriert werden, aber **nicht Teil des MVP**. |

##3. 🎨 User Experience (UX) & Design-Spezifikationen###3.1. Design-Philosophie* **Stil:** **Minimalistisch, Dark Mode** (hoher Kontrast, augenschonend).
* **Kern-UX:** Minimale Interaktion während des Trainings; große, touch-freundliche Elemente.
* **Navigation:** Keine Scroll-Bars auf dem Haupt-Trainings-Screen. Wischen für Seitenwechsel.

###3.1 Markenintegration: Das gesamte Design, einschließlich des Logos, der Farbpalette und der Terminologie, muss auf dem Nachnamen "Wach" und dem Akronym W.A.C.H. basieren. Das Branding muss Wachheit (Überwachung) und Wachstum (Steigerung) symbolisieren. Die Akzentfarbe sollte eine Farbe sein, die Wachstum und Aktivität signalisiert.

###3.2. Der Hauptbildschirm (Training Screen)| Element | Spezifikation |
| --- | --- |
| **Kachel-Layout** | Maximal 5 große Kacheln pro Seite. Bei >5 Übungen Wisch-Navigation zur nächsten Seite. |
| **Kachel-Inhalt** | Übungsname, Ziel (50 Reps), Fortschritt (20/50), Timer. |
| **Timer-Logik** | **Dual-Modus:** 1) Zählt hoch (Stopuhr). 2) Zählt ab (Countdown basierend auf der Zeit der vorherigen Session). |

###3.3. Zwei-Modus-System (Lock / Unlock)| Modus | Aktivierung | Funktionalität |
| --- | --- | --- |
| **LOCK (Trainingsmodus)** | Aktiviert durch **Longtap** (oder automatisch beim Start). | Zeigt **nur die Kacheln und den Timer**. Deaktiviert alle Einstellungs- und Navigations-Icons. Verhindert Fehleingaben. |
| **UNLOCK (Einstellmodus)** | Aktiviert durch **Longtap**. | **Plus-Icon** zum Hinzufügen von Reps/Sätzen ist sichtbar und aktiv. Einstellungen-Icon für Session-Bearbeitung sichtbar. |

##4. ✅ MVP-Anforderungen (Minimum Viable Product)Der MVP muss die folgenden Funktionen beinhalten und schnellstmöglich umgesetzt werden:

1. **Übung Hinzufügen:** Einfaches Textfeld zur Benennung der Übung.
2. **Session Start/Stop:** Timer beginnt beim Start der Session zu laufen.
3. **Reps/Sätze Tracking:** Im **Unlock-Modus** Reps/Sätze über Plus-Icon hinzufügen. Fortschrittsanzeige auf der Kachel aktualisieren.
4. **Daten persistieren:** Speichern der Session-Daten (Übung, erreichte Reps, benötigte Gesamtzeit) in der lokalen DB.
5. **Progressive Overload Logik:** **Jede neue Session MUSS mit dem Vorschlag der vorherigen Session starten** (dieselbe Übung, Reps-Ziel) und die Zeit als Countdown vorschlagen.
6. **Geräte-Unterstützung:** Funktionierende App-Builds für iOS, Android und eine Basis-Web-Version.

##5. 💡 Zukünftige Erweiterungen (Post-MVP)Diese Punkte sind **optional** und dienen als Zukunftsplanung.

| Feature | Beschreibung |
| --- | --- |
| **Google Drive Sync** | Export/Import der lokalen DB (JSON-Datei) in Google Drive als einfache Backup-Lösung. (Keine komplexe OAuth-Integration im MVP). |
| **Multiplayer / Battle** | Hinzufügen/Wechseln zwischen mehreren "Spielern" auf demselben Gerät (Player A vs. Player B) zur Durchführung von Fitness Battles (z.B. Wer schafft 100 Dips schneller). |
| **Statistiken** | Einfache Liniendiagramme zur Visualisierung der Leistungssteigerung (z.B. Zeit vs. Reps über Wochen). |

##6. 🤝 Strategische Hinweise (Für den Entwickler)1. **Priorität: UX über Feature-Umfang:** Die Performance und die Einfachheit der UI/UX haben oberste Priorität. Jede Verzögerung oder unnötige Funktion muss vermieden werden.
2. **Design-System-Erstellung:** Erstellen Sie wiederverwendbare Flutter-Widgets (z.B. `ProgressTile`, `CustomTimer`, `RepsCounter`) und nutzen Sie die Akzentfarbe nur für aktive/wichtige Elemente.
3. **Influencer-Integration:** Der Prototyp sollte die Philosophie von Coach Andy (Zeit-Unterbieten) perfekt widerspiegeln, um ihn als Tester zu gewinnen. Das Feature des **Countdown-Timers** ist hierbei der entscheidende USP.