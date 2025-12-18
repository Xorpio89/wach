# Contributing Guidelines - W.A.C.H.

## Commit-Konventionen

Wir verwenden [Conventional Commits](https://www.conventionalcommits.org/) für eine klare und automatisierbare Git-Historie.

### Commit-Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | Beschreibung | Beispiel |
|------|--------------|----------|
| `feat` | Neues Feature | `feat(workout): add timer component` |
| `fix` | Bugfix | `fix(timer): correct countdown calculation` |
| `docs` | Dokumentation | `docs(readme): update installation guide` |
| `style` | Formatierung (kein Code-Change) | `style: fix linting errors` |
| `refactor` | Code-Refactoring | `refactor(db): simplify repository pattern` |
| `perf` | Performance-Verbesserung | `perf(timer): optimize render cycle` |
| `test` | Tests hinzufügen/ändern | `test(workout): add session unit tests` |
| `chore` | Maintenance | `chore: update dependencies` |
| `build` | Build-System | `build: configure android signing` |
| `ci` | CI/CD | `ci: add github actions workflow` |

### Scopes (Projekt-spezifisch)

| Scope | Bereich |
|-------|---------|
| `workout` | Workout/Session Feature |
| `exercise` | Übungen Feature |
| `settings` | Einstellungen Feature |
| `timer` | Timer-Komponente |
| `db` | Datenbank/sembast |
| `ui` | Allgemeine UI-Komponenten |
| `theme` | Design/Theme |
| `nav` | Navigation/GoRouter |
| `state` | State Management/Riverpod |
| `deploy` | CI/CD, GitHub Actions |

### Subject-Regeln

- Imperativ verwenden: "add" nicht "added" oder "adds"
- Kleinbuchstaben am Anfang
- Kein Punkt am Ende
- Max. 50 Zeichen
- Beschreibt WAS, nicht WIE

### Beispiele

```bash
# Feature
feat(exercise): add create exercise modal

# Bugfix
fix(timer): prevent negative countdown values

# Refactoring
refactor(workout): extract session state to provider

# Performance
perf(db): add index for session queries

# Dokumentation
docs: add architecture decision records

# Tests
test(timer): add unit tests for dual-mode logic
```

### Body (Optional)

Für komplexere Änderungen:

```
feat(workout): implement progressive overload suggestion

- Load previous session data on workout start
- Calculate suggested reps based on last performance
- Display countdown timer with previous session time
- Add visual indicator for improvement

Closes #42
```

### Breaking Changes

```
feat(db)!: migrate to Isar 4.0

BREAKING CHANGE: Database schema changed, requires migration.
Run `flutter pub run build_runner build` after update.
```

---

## Branch-Strategie

### Branch-Naming

```
<type>/<issue-number>-<short-description>
```

**Beispiele:**
- `feat/12-add-timer-component`
- `fix/45-countdown-bug`
- `refactor/23-clean-architecture`

### Haupt-Branches

| Branch | Zweck |
|--------|-------|
| `main` | Produktionsbereit, stabil |
| `develop` | Entwicklungs-Integration |
| `release/*` | Release-Vorbereitung |

### Workflow

1. Branch von `develop` erstellen
2. Feature/Fix implementieren
3. Tests schreiben
4. Pull Request erstellen
5. Code Review
6. Merge nach `develop`

---

## Pull Request Guidelines

### PR-Template

```markdown
## Beschreibung
[Was wurde geändert und warum?]

## Typ der Änderung
- [ ] Feature
- [ ] Bugfix
- [ ] Refactoring
- [ ] Dokumentation
- [ ] Anderes

## Checkliste
- [ ] Code folgt den Style-Guidelines
- [ ] Tests wurden hinzugefügt/aktualisiert
- [ ] Dokumentation wurde aktualisiert
- [ ] Keine Breaking Changes (oder dokumentiert)
- [ ] App wurde auf allen Plattformen getestet

## Screenshots (falls UI-Änderungen)
[Screenshots hier]

## Verwandte Issues
Closes #[Issue-Nummer]
```

### PR-Titel

Folgt dem Commit-Format:
```
feat(workout): implement session tracking
```

---

## Code Review Guidelines

### Reviewer Checklist

- [ ] Code ist lesbar und verständlich
- [ ] Keine offensichtlichen Bugs
- [ ] Performance-Implikationen berücksichtigt
- [ ] Tests sind sinnvoll
- [ ] Folgt Clean Architecture
- [ ] UI/UX entspricht Design-System

### Review-Kommentare

Verwende Prefixes:
- `[blocking]` - Muss vor Merge behoben werden
- `[suggestion]` - Optional, aber empfohlen
- `[nitpick]` - Kleines Detail, kann ignoriert werden
- `[question]` - Frage zum Verständnis

---

## Code-Qualität

### Vor jedem Commit

```bash
# Analyse ausführen
flutter analyze

# Tests ausführen
flutter test

# Formatierung prüfen
dart format --set-exit-if-changed .
```

### Pre-Commit Hook (empfohlen)

Erstelle `.git/hooks/pre-commit`:

```bash
#!/bin/sh
flutter analyze
if [ $? -ne 0 ]; then
  echo "Flutter analyze failed. Fix issues before committing."
  exit 1
fi

flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Fix tests before committing."
  exit 1
fi
```

---

## Versionierung

Wir verwenden [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

- **MAJOR:** Breaking Changes
- **MINOR:** Neue Features (backwards-compatible)
- **PATCH:** Bugfixes

### Version-Tags

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## Wichtige Hinweise

1. **Keine Secrets committen** - Verwende `.env` Dateien (in .gitignore)
2. **Kleine Commits** - Ein Commit = eine logische Änderung
3. **Aussagekräftige Nachrichten** - Zukunfts-Du wird dir danken
4. **Tests first** - Bei Bugfixes erst Test schreiben
5. **Review vor Merge** - Selbst bei eigenen Branches
