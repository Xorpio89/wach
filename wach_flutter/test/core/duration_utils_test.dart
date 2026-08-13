import 'package:flutter_test/flutter_test.dart';
import 'package:wach_flutter/core/utils/duration_utils.dart';

/// Regressionstest fuer den Anzeige-Ueberlauf ab einer Stunde.
///
/// Gemeldet 2026-08-12: der Timer sprang nach 60 Minuten sichtbar auf
/// 00:00 zurueck, und ein Zielwert von 60 min wurde als "00:00"
/// angezeigt. Ursache war `inMinutes.remainder(60)` ohne Stundenanteil.
void main() {
  group('toMinutesSeconds', () {
    test('zeigt unter einer Stunde MM:SS', () {
      expect(const Duration(seconds: 5).toMinutesSeconds(), '00:05');
      expect(const Duration(minutes: 7).toMinutesSeconds(), '07:00');
      expect(
        const Duration(minutes: 59, seconds: 59).toMinutesSeconds(),
        '59:59',
      );
    });

    test('rollt bei exakt 60 Minuten nicht auf 00:00 zurueck', () {
      expect(const Duration(minutes: 60).toMinutesSeconds(), '1:00:00');
    });

    test('zeigt ab einer Stunde H:MM:SS', () {
      expect(
        const Duration(hours: 1, minutes: 23, seconds: 45)
            .toMinutesSeconds(),
        '1:23:45',
      );
      expect(
        const Duration(hours: 12, minutes: 5, seconds: 9)
            .toMinutesSeconds(),
        '12:05:09',
      );
    });
  });

  group('toMinutesSecondsCentis', () {
    test('zeigt unter einer Stunde MM:SS.cc', () {
      expect(
        const Duration(minutes: 2, seconds: 3, milliseconds: 450)
            .toMinutesSecondsCentis(),
        '02:03.45',
      );
    });

    test('laesst ab einer Stunde die Hundertstel weg', () {
      expect(
        const Duration(hours: 1, seconds: 30, milliseconds: 990)
            .toMinutesSecondsCentis(),
        '1:00:30',
      );
    });
  });

  group('toHoursMinutesSeconds', () {
    test('fuellt Stunden auf zwei Stellen auf', () {
      expect(
        const Duration(hours: 2, minutes: 3, seconds: 4)
            .toHoursMinutesSeconds(),
        '02:03:04',
      );
    });
  });
}
