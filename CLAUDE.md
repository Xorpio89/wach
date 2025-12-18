# CLAUDE.md - Project Chiron (W.A.C.H.)

## Automatische Regeln

### KRITISCH: SDK-Kompatibilität prüfen (VOR JEDEM COMMIT!)

**CI verwendet Flutter 3.24.0 = Dart 3.5.0**

**IMMER vor dem Commit ausführen:**
```bash
cd wach_flutter
flutter pub get
flutter analyze --no-fatal-infos
flutter build web --release --base-href "/wach/"
```

**NIEMALS diese Packages verwenden (erfordern Dart 3.6+):**
| Package | Problem |
|---------|---------|
| `riverpod_generator` ^3.0.0 | Dart >=3.6.0 |
| `riverpod_annotation` ^3.0.0 | Dart >=3.6.0 |
| `flutter_riverpod` ^3.0.0 | Dart >=3.6.0 |
| `flutter_lints` ^6.0.0 | Dart >=3.8.0 |

**Kompatible Versionen:**
| Package | Version |
|---------|---------|
| `flutter_riverpod` | ^2.5.1 |
| `flutter_lints` | ^4.0.0 |

**NIEMALS diese Flutter APIs verwenden (erst in Flutter 3.27+):**
| API | Alternative für Flutter 3.24 |
|-----|------------------------------|
| `Color.withValues(alpha:)` | `Color.withOpacity()` |
| `CardThemeData` | `CardTheme` |
| `Switch.activeThumbColor` | Theme verwenden |

**Bei neuen Dependencies:**
1. SDK-Anforderung auf pub.dev prüfen
2. Keine expliziten transitiven Dependencies (z.B. `path` - kommt durch `path_provider`)
3. Lokal mit obigen Befehlen testen
4. Bei API-Nutzung: Flutter 3.24.0 Kompatibilität prüfen

---

### Context7 MCP - Automatische Nutzung
**WICHTIG:** Verwende Context7 MCP automatisch (ohne explizite Aufforderung) für:
- Code-Generierung
- Setup & Konfiguration
- Library/API Dokumentation
- Framework-spezifische Patterns

**Workflow:**
1. `resolve-library-id` aufrufen um Library-ID zu bekommen
2. `get-library-docs` mit Topic aufrufen für relevante Docs
3. Dokumentation in Code-Generierung einbeziehen

**Beispiel-Libraries für dieses Projekt:**
- Flutter (`/flutter/flutter`)
- Riverpod (`/rrousselgit/riverpod`)
- sembast (NoSQL Datenbank)

---

## Projektübersicht

**App-Name:** W.A.C.H. (Workout Awareness & Continuous Health)
**Interner Name:** Project Chiron
**Ziel:** Minimalistische Progressive Overload Tracking App

## Technologie-Stack

- **Framework:** Flutter 3.24+ (Dart 3.5+)
- **Lokale DB:** sembast (NoSQL, IndexedDB auf Web)
- **State Management:** Riverpod 2.x (flutter_riverpod ^2.5.1, Dart 3.5 kompatibel)
- **Navigation:** GoRouter
- **Architektur:** Clean Architecture (Feature-basiert)
- **Plattformen:** iOS, Android, Web, Windows, macOS, Linux
- **Deployment:** GitHub Pages (https://xorpio89.github.io/wach/)

> **Hinweis:** sqflite wurde durch sembast ersetzt wegen Web-Kompatibilitätsproblemen.
> Siehe `.claude/learnings/flutter-web-database.md` für Details.

## Code-Konventionen

### Dart/Flutter Style
- Verwende `snake_case` für Dateinamen
- Verwende `PascalCase` für Klassen
- Verwende `camelCase` für Variablen und Funktionen
- Maximale Zeilenlänge: 80 Zeichen
- Immer `const` Konstruktoren wo möglich

### Ordnerstruktur
```
lib/
├── core/                 # Gemeinsame Utilities, Themes, Constants
│   ├── theme/
│   ├── utils/
│   └── constants/
├── features/             # Feature-Module
│   ├── workout/          # Workout/Session Feature
│   │   ├── data/         # Repositories, Models, Data Sources
│   │   ├── domain/       # Entities, Use Cases
│   │   └── presentation/ # Screens, Widgets, Controllers
│   └── exercises/        # Übungen Feature
├── shared/               # Gemeinsame Widgets
└── main.dart
```

### Widget-Namenskonventionen
- Screens: `*Screen` (z.B. `WorkoutScreen`)
- Wiederverwendbare Widgets: `*Widget` oder beschreibender Name (z.B. `ProgressTile`)
- Controller/Provider: `*Controller` oder `*Notifier`

## Design-System

### Farben (Dark Mode)
- **Background:** #121212
- **Surface:** #1E1E1E
- **Primary/Accent:** #4CAF50 (Grün - symbolisiert Wachstum)
- **Secondary:** #FF9800 (Orange - Aktivität/Energie)
- **Text Primary:** #FFFFFF
- **Text Secondary:** #B0B0B0

### Typografie
- Headlines: Bold, große Schrift für Zahlen/Timer
- Body: Regular, gut lesbar
- Zahlen: Monospace für Timer/Reps

### Interaktionen
- **Longtap:** Lock/Unlock Modus wechseln
- **Tap:** Aktion ausführen (im Unlock-Modus)
- **Swipe:** Seiten wechseln

## MVP-Prioritäten

1. **P0 (Must Have):**
   - Übung hinzufügen
   - Session starten/stoppen
   - Reps tracken
   - Lokale Speicherung
   - Progressive Overload Vorschlag

2. **P1 (Should Have):**
   - Lock/Unlock Modus
   - Countdown Timer
   - Kachel-Layout

3. **P2 (Nice to Have):**
   - Statistiken
   - Export/Backup

## Wichtige Befehle

### App starten

```powershell
# Windows PowerShell
.\scripts\start.ps1              # Standard: Chrome
.\scripts\start.ps1 android      # Android Emulator
.\scripts\start.ps1 web          # Web Server (Port 8080)
.\scripts\start.ps1 windows      # Windows Desktop
```

```bash
# Unix/macOS/Linux
./scripts/start.sh               # Standard: Chrome
./scripts/start.sh android       # Android
./scripts/start.sh ios           # iOS Simulator
```

### Flutter Befehle

```bash
# Im wach_flutter/ Verzeichnis ausführen
flutter pub get          # Dependencies installieren
flutter run -d chrome    # Chrome Browser
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter build apk        # Android APK
flutter build web        # Web Build
flutter test             # Tests ausführen
flutter analyze          # Code analysieren
```

### Slash Commands (Claude Code)

```
/start-app [platform]    # App starten (chrome, android, ios, web, windows)
/stop-app                # App und Backends stoppen
/review-flutter          # Code Review
/implement-feature       # Feature implementieren
/fix-bug                 # Bug fixen
/write-tests             # Tests schreiben
/tdd                     # TDD Workflow (Red-Green-Refactor)
/run-tests               # Tests ausführen
```

## Testing-Strategie

> **Status:** Tests sind aktuell deaktiviert. CI führt nur Build aus (deploy.yml).

- **Unit Tests:** Domain Logic, Models, Utils (test/core/, test/features/*/data/)
- **Widget Tests:** Einzelne Widgets, Provider (test/features/*/presentation/)
- **Integration Tests:** User Flows (integration_test/)

### Test-Infrastruktur (wenn aktiviert)
- **mocktail** für Mocking (kein Code-Gen nötig)
- **sembast_memory** für In-Memory DB Tests
- **ProviderContainer** für isolierte Riverpod Tests
- **GitHub Actions:** nur deploy.yml (Build + Deploy)

## Wichtige Hinweise für Claude

- UX hat höchste Priorität - keine unnötigen Features
- Immer Offline-Fähigkeit beachten
- Große, touch-freundliche Elemente
- Dark Mode ist Standard
- W.A.C.H. Branding konsistent verwenden
- Countdown-Timer ist der USP - muss perfekt funktionieren

## Learnings & Known Issues

Dokumentierte Erkenntnisse und Problemlösungen befinden sich in:

```
.claude/learnings/
├── dart-sdk-compatibility.md  # KRITISCH: SDK-Versionen & Package-Kompatibilität
├── flutter-web-database.md    # sqflite vs sembast für Web
└── ...                        # Weitere Learnings
```

**Vor der Verwendung neuer Packages prüfen:**
1. **SDK-Anforderung auf pub.dev** (Dart >=3.5.0 erforderlich!)
2. Web-Kompatibilität (kIsWeb)
3. WASM/WebWorker Dependencies
4. IndexedDB Support für persistente Daten
5. Keine transitiven Dependencies explizit hinzufügen
