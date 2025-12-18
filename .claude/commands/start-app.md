# Start W.A.C.H. App

Starte die W.A.C.H. App auf der angegebenen Plattform.

## Verwendung

```
/start-app [platform]
```

**Plattformen:**
- `chrome` (Standard) - Chrome Browser
- `web` - Web Server auf Port 8080
- `android` - Android Emulator/Device
- `ios` - iOS Simulator/Device
- `windows` - Windows Desktop
- `macos` - macOS Desktop
- `linux` - Linux Desktop

## Aktion

Führe folgende Schritte aus:

1. Wechsle in das Flutter-Projektverzeichnis: `wach_flutter/`
2. Führe `flutter pub get` aus (falls Dependencies fehlen)
3. Starte die App mit `flutter run -d [platform]`

**Argument:** $ARGUMENTS (Standard: chrome)

## Beispiel

```bash
cd C:/Sources/wach/wach_flutter && C:/Sources/Flutter/flutter/bin/flutter run -d chrome
```

## Backends

Aktuell keine Backends erforderlich (Offline-First App).

Zukünftig hier hinzufügen:
- API Server
- Database Server
- Auth Service
