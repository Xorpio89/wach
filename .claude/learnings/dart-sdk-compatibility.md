# Dart SDK Kompatibilität

**Datum:** 2025-12-17
**Problem:** CI-Pipeline fehlgeschlagen wegen inkompatiblen Dependencies

## Flutter 3.24.0 = Dart 3.5.0

Die GitHub Actions CI verwendet Flutter 3.24.0, welches Dart 3.5.0 enthält.

## Inkompatible Packages (erfordern Dart 3.6+)

| Package | Version | Benötigt Dart |
|---------|---------|---------------|
| `riverpod_generator` | ^3.0.0 | >=3.6.0 |
| `riverpod_annotation` | ^3.0.0 | >=3.6.0 |
| `flutter_riverpod` | ^3.0.0 | >=3.6.0 |
| `flutter_lints` | ^6.0.0 | >=3.8.0 |

## Kompatible Versionen für Dart 3.5.0

| Package | Kompatible Version |
|---------|-------------------|
| `flutter_riverpod` | ^2.5.1 |
| `flutter_lints` | ^4.0.0 |

## Checkliste vor dem Commit

**IMMER vor dem Commit ausführen:**

```bash
cd wach_flutter

# 1. Dependencies prüfen
flutter pub get

# 2. Code analysieren
flutter analyze --no-fatal-infos

# 3. Build testen (wie CI)
flutter build web --release --base-href "/wach/"
```

## Wie man SDK-Anforderungen prüft

Auf pub.dev die "SDK" Anforderung des Packages prüfen:
- https://pub.dev/packages/[package_name]/versions

Oder in der `pubspec.yaml` des Packages nachschauen.

## Lessons Learned

1. **Nicht blind die neueste Version verwenden** - Immer SDK-Kompatibilität prüfen
2. **Lokale CI-Simulation** - Build lokal mit gleichen Parametern wie CI testen
3. **Dependencies einzeln prüfen** - Alle dev_dependencies UND dependencies checken
4. **pub.dev Changelog lesen** - Breaking changes bei Major-Versionen

## Referenz: Flutter/Dart Version Mapping

| Flutter | Dart |
|---------|------|
| 3.24.x | 3.5.x |
| 3.27.x | 3.6.x |
| 3.29.x+ | 3.8.x |

Aktuelle Flutter-Releases: https://docs.flutter.dev/release/archive
