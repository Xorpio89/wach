# W.A.C.H.

**W**orkout **A**wareness & **C**ontinuous **H**ealth

> Minimalistische Progressive Overload Tracking App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Projektübersicht

W.A.C.H. ist eine minimalistische Fitness-Tracking-App mit Fokus auf **Progressive Overload**. Der Kerngedanke: **Weniger Interaktion, mehr Training.**

### Kernfeatures (MVP)

- Übungen erstellen und verwalten
- Training-Sessions mit Timer tracken
- Reps/Sätze aufzeichnen
- Progressive Overload Vorschläge (basierend auf vorheriger Session)
- Lock/Unlock Modus für fehlerfreies Training
- 100% Offline-fähig

### Design-Prinzipien

- Dark Mode (augenschonend)
- Große, touch-freundliche Elemente
- Minimale Interaktion während des Trainings
- Countdown-Timer als USP (Zeit der vorherigen Session unterbieten)

---

## Tech Stack

| Komponente | Technologie |
|------------|-------------|
| Framework | Flutter 3.24+ |
| Sprache | Dart 3.5+ |
| Lokale DB | sembast (IndexedDB auf Web) |
| State Management | Riverpod 3.x |
| Navigation | GoRouter |
| Architektur | Clean Architecture |
| Plattformen | iOS, Android, Web, Windows, macOS, Linux |
| Deployment | GitHub Pages |

---

## Projektstruktur

```
lib/
├── core/                 # Gemeinsame Utilities, Themes, Constants
│   ├── theme/            # Design System (Farben, Typography)
│   ├── utils/            # Hilfsfunktionen
│   ├── constants/        # App-Konstanten
│   └── database/         # sembast Database Service
├── features/             # Feature-Module (Clean Architecture)
│   ├── workout/          # Workout/Session Feature
│   ├── exercise/         # Übungen Feature
│   ├── settings/         # App-Einstellungen
│   └── home/             # Home Screen
├── shared/               # Gemeinsame Widgets
│   ├── widgets/          # EmptyState, StatusBar, ChipButton, etc.
│   └── navigation/       # GoRouter Setup
└── main.dart
```

---

## Entwicklung

### Voraussetzungen

- Flutter SDK 3.x
- Dart SDK 3.x
- IDE (VS Code / Android Studio empfohlen)

### Setup

```bash
# In das Flutter-Verzeichnis wechseln
cd wach_flutter

# Dependencies installieren
flutter pub get

# App starten
flutter run -d chrome    # Web (Chrome)
flutter run -d windows   # Windows Desktop
flutter run              # Standard-Gerät
```

### Befehle

```bash
flutter run              # App starten (Debug)
flutter run --release    # App starten (Release)
flutter test             # Tests ausführen
flutter analyze          # Code analysieren
flutter build apk        # Android APK bauen
flutter build ios        # iOS Build
flutter build web        # Web Build
```

---

## Live Demo

**GitHub Pages:** https://xorpio89.github.io/wach/

## Dokumentation

- [APP_STATUS.md](docs/APP_STATUS.md) - Aktueller Projekt-Status
- [ROADMAP.md](docs/ROADMAP.md) - Feature Roadmap & Zukunftspläne
- [REQUIREMENTS.md](docs/REQUIREMENTS.md) - Detaillierte Anforderungen
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architektur & Struktur
- [CONTRIBUTING.md](docs/CONTRIBUTING.md) - Commit-Richtlinien & Workflow
- [REMOTE_ACCESS.md](docs/REMOTE_ACCESS.md) - Webhook Server & ngrok Setup
- [CLAUDE.md](CLAUDE.md) - KI-Assistenz Kontext

---

## KI-Agenten (Slash Commands)

Dieses Projekt verwendet Claude Code Slash Commands für KI-gestützte Entwicklung:

| Command | Beschreibung |
|---------|--------------|
| `/review-flutter` | Flutter Code Review |
| `/implement-feature` | Feature Implementation |
| `/fix-bug` | Bug-Analyse und Fix |
| `/write-tests` | Test-Generierung |
| `/analyze-architecture` | Architektur-Analyse |
| `/optimize-performance` | Performance-Optimierung |

---

## Roadmap

> Detaillierte Roadmap: [ROADMAP.md](ROADMAP.md)

### Phase 1-2: MVP ✅
- [x] Übungen CRUD, Timer, Session-Tracking
- [x] Lock/Unlock, Progressive Overload
- [x] Dark Mode, GitHub Pages Deployment

### Phase 3: Training Plans
- [ ] Custom Training Plan Builder
- [ ] Plan Sharing (QR Code / Link)
- [ ] Skill Progressions für Calisthenics

### Phase 4: Social Features
- [ ] Gym Buddy Mode (Live Sync)
- [ ] Session Sharing (Post-Workout Cards)

### Phase 5: Battle Mode
- [ ] 1v1 Challenges (Speed Run, Max Reps)
- [ ] Group Battles (2-5 Personen)
- [ ] Live Leaderboard

### Phase 6+: Gamification & Analytics
- [ ] Skill Tree System
- [ ] Achievements & Badges
- [ ] Progress Charts & Insights

---

## Branding

Das Branding basiert auf dem Akronym **W.A.C.H.**:
- **Wachheit** (Awareness/Monitoring)
- **Wachstum** (Growth/Progress)

Akzentfarbe: Grün (#4CAF50) - symbolisiert Wachstum

---

## Lizenz

MIT License - siehe [LICENSE](LICENSE)

---

## Autor

Entwickelt mit Claude Code
