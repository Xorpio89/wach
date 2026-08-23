import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../exercise/presentation/providers/exercise_providers.dart'
    show databaseServiceProvider, exercisesProvider, exercisesStreamProvider;
import '../../workout/presentation/providers/session_providers.dart';
import '../data/sicherung_datenquelle.dart';
import '../domain/sicherung.dart';

part 'sicherung_provider.g.dart';

@Riverpod(keepAlive: true)
SicherungDatenquelle sicherungDatenquelle(Ref ref) {
  return SicherungDatenquelle(ref.watch(databaseServiceProvider));
}

/// Zieht einen Abzug aller Daten.
@Riverpod(keepAlive: true)
Future<Sicherung> abzug(Ref ref) {
  return ref.watch(sicherungDatenquelleProvider).abziehen();
}

/// Liest einen Abzug ein und laesst die Oberflaeche neu laden.
@Riverpod(keepAlive: true)
class Einlesen extends _$Einlesen {
  @override
  void build() {}

  Future<EinleseErgebnis> ausText(String text) async {
    final sicherung = Sicherung.ausText(text);
    final ergebnis =
        await ref.read(sicherungDatenquelleProvider).uebernehmen(sicherung);

    // Ohne das zeigt die App weiter den Stand von vor dem Einlesen.
    ref.invalidate(exercisesProvider);
    ref.invalidate(exercisesStreamProvider);
    ref.invalidate(sessionsStreamProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(abzugProvider);
    await ref.read(sessionProvider.notifier).refresh();

    return ergebnis;
  }
}
