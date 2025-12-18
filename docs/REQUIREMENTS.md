# W.A.C.H. - Detaillierte Anforderungsspezifikation

**Version:** 1.0.0
**Status:** MVP Implemented
**Letzte Aktualisierung:** 2025-12-17

---

## 1. Executive Summary

W.A.C.H. (Workout Awareness & Continuous Health) ist eine minimalistische Fitness-Tracking-App mit Fokus auf Progressive Overload. Der Kerngedanke: **Weniger Interaktion, mehr Training.**

### Akronym-Bedeutung
- **W**orkout - Training
- **A**wareness - Bewusstsein/Überwachung
- **C**ontinuous - Kontinuierlich
- **H**ealth - Gesundheit

---

## 2. User Stories (MVP)

### US-001: Übung erstellen ✅
**Als** Benutzer
**möchte ich** eine neue Übung anlegen können
**damit** ich meine Trainingseinheiten tracken kann.

**Akzeptanzkriterien:**
- [x] Textfeld für Übungsname
- [x] Optionales Ziel (Reps oder Zeit)
- [x] Speicherung in lokaler DB (sembast)
- [x] Validierung: Name darf nicht leer sein

### US-002: Training starten ✅
**Als** Benutzer
**möchte ich** eine Training-Session starten
**damit** der Timer automatisch läuft.

**Akzeptanzkriterien:**
- [x] Timer startet bei Session-Start
- [x] Dual-Modus: Stopuhr ODER Countdown
- [x] Countdown basiert auf vorheriger Session-Zeit
- [x] Visuelles Feedback (Timer prominent sichtbar)

### US-003: Reps tracken ✅
**Als** Benutzer im Unlock-Modus
**möchte ich** Reps/Sätze hinzufügen können
**damit** mein Fortschritt dokumentiert wird.

**Akzeptanzkriterien:**
- [x] Tap-Zonen für Reps hinzufügen/entfernen
- [x] Echtzeit-Update der Fortschrittsanzeige
- [x] Haptisches Feedback bei Tap
- [x] Große Touch-Targets (konfigurierbar)

### US-004: Progressive Overload ✅
**Als** Benutzer
**möchte ich** Vorschläge basierend auf meiner letzten Session
**damit** ich kontinuierlich Fortschritte mache.

**Akzeptanzkriterien:**
- [x] Letzte Session wird als Ziel vorgeschlagen
- [x] Countdown-Zeit = Zeit der vorherigen Session
- [x] Anzeige: "Letzte Session: X Reps in Y:ZZ"
- [x] Visueller Indikator ob aktuell besser/schlechter

### US-005: Lock/Unlock Modus ✅
**Als** Benutzer
**möchte ich** zwischen Lock und Unlock wechseln
**damit** ich während des Trainings keine Fehleingaben mache.

**Akzeptanzkriterien:**
- [x] Longtap wechselt Modus
- [x] Lock: Nur Kacheln + Timer sichtbar
- [x] Unlock: Einstellungen + Navigation sichtbar
- [x] Visuelles Feedback beim Moduswechsel (StatusBar)

---

## 3. Technische Anforderungen

### 3.1 Performance-Ziele
| Metrik | Ziel |
|--------|------|
| App-Startzeit | < 2 Sekunden |
| Screen-Wechsel | < 100ms |
| Timer-Genauigkeit | ±10ms |
| DB-Schreibzeit | < 50ms |

### 3.2 Offline-Anforderungen
- **100% Offline-Fähigkeit** für alle MVP-Features
- Keine Internet-Abhängigkeit
- Lokale Datenhaltung mit sembast (IndexedDB auf Web)
- Datenintegrität bei App-Crashes

### 3.3 Datenmodell

```dart
// Exercise Entity
class Exercise {
  int id;
  String name;
  int? targetReps;
  Duration? targetTime;
  DateTime createdAt;
}

// Session Entity
class WorkoutSession {
  int id;
  int exerciseId;
  DateTime startedAt;
  DateTime? finishedAt;
  int totalReps;
  Duration totalTime;
  List<SetRecord> sets;
}

// Set Record
class SetRecord {
  int reps;
  DateTime recordedAt;
}
```

### 3.4 State Management (Riverpod)

```dart
// Haupt-Provider
final workoutSessionProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutState>();
final exercisesProvider = FutureProvider<List<Exercise>>();
final timerProvider = StreamProvider<Duration>();
final lockModeProvider = StateProvider<bool>((ref) => true);
```

---

## 4. UI/UX Spezifikationen

### 4.1 Kachel-Design (ProgressTile)

```
┌─────────────────────────────┐
│  PUSH-UPS                   │
│  ───────────────            │
│                             │
│       20 / 50               │
│       ████████░░░░          │
│                             │
│       02:45                 │
│       ↓ (Countdown)         │
└─────────────────────────────┘
```

### 4.2 Screen-Flow

```
[Splash] → [Home/Dashboard]
              │
              ├── [Übung hinzufügen] (Modal)
              │
              └── [Training] ←→ [Lock/Unlock Toggle]
                     │
                     └── [Session Ende] → [Zusammenfassung]
```

### 4.3 Gesten-Interaktionen
| Geste | Aktion |
|-------|--------|
| Longtap (500ms) | Lock/Unlock wechseln |
| Tap (Unlock) | Rep hinzufügen |
| Swipe Links/Rechts | Seite wechseln (>5 Übungen) |
| Double-Tap | Timer Start/Pause |

---

## 5. Claude's Analyse & Empfehlungen

### 5.1 Technologie-Empfehlungen

**sembast über Isar/sqflite:**
- Web-Kompatibilität (IndexedDB)
- Einfaches NoSQL-Format (JSON-basiert)
- Keine WASM-Dependencies
- Plattformübergreifend (Web, Mobile, Desktop)

**Riverpod 3.x über Provider:**
- Compile-time Safety
- Bessere Code-Organisation
- DevTools Integration
- Einfacheres Testing

### 5.2 Architektur-Risiken

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Web-Performance | Mittel | Hoch | CanvasKit vs HTML Renderer evaluieren |
| Timer-Genauigkeit | Niedrig | Hoch | Isolate für Timer verwenden |
| State-Verlust | Mittel | Mittel | Persistente State-Hydration |

### 5.3 MVP-Scope Empfehlung

**Phase 1 (Woche 1-2):**
- Grundstruktur + Navigation
- Übung CRUD
- Basis-Timer

**Phase 2 (Woche 3-4):**
- Session-Tracking
- Reps-Logik
- Lock/Unlock

**Phase 3 (Woche 5-6):**
- Progressive Overload
- Polish & Testing
- Platform Builds

### 5.4 USP-Fokus: Countdown-Timer

Der Countdown-Timer ist das Alleinstellungsmerkmal:
- Zeigt Zeit der vorherigen Session
- Motiviert zum "Unterbieten"
- Muss extrem präzise sein
- Visuelles Feedback wenn Zeit überboten wird

**Empfehlung:** Spezielle Animation/Farbe wenn aktuelle Zeit < vorherige Zeit

---

## 6. Abnahmekriterien MVP

- [x] App startet auf iOS, Android, Web und Desktop
- [x] Übungen können erstellt werden
- [x] Timer funktioniert in beiden Modi
- [x] Reps werden korrekt gezählt
- [x] Daten bleiben nach App-Neustart erhalten
- [x] Lock/Unlock Modus funktioniert
- [x] Progressive Overload Vorschlag funktioniert
- [x] Dark Mode ist aktiviert
- [x] Keine Abstürze bei normalem Gebrauch
- [x] GitHub Pages Deployment funktioniert

---

## 7. Glossar

| Begriff | Definition |
|---------|------------|
| Progressive Overload | Trainingsmethode zur kontinuierlichen Steigerung |
| Rep(etition) | Eine Wiederholung einer Übung |
| Set | Eine Gruppe von Reps |
| Session | Eine vollständige Trainingseinheit |
| Lock-Modus | Modus ohne Bearbeitungsmöglichkeit |
