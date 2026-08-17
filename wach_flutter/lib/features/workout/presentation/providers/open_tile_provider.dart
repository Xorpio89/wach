import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_tile_provider.g.dart';

/// Welche Uebungskacheln gerade aufgeklappt sind (deren Ids).
///
/// Der Zustand liegt ausserhalb der Kacheln, damit er einen Seitenwechsel
/// uebersteht: beim Blaettern nimmt der PageView die Kacheln aus dem Baum
/// und baut sie spaeter neu — ein Feld in der Kachel waere dann verloren,
/// und man fand jede Kachel wieder zugeklappt vor.
///
/// Eine Menge, weil mehrere Kacheln gleichzeitig offen stehen duerfen —
/// etwa beim Wechsel zwischen zwei Uebungen.
@Riverpod(keepAlive: true)
class OpenTiles extends _$OpenTiles {
  @override
  Set<String> build() => const {};

  void oeffne(String exerciseId) => state = {...state, exerciseId};

  void schliesse(String exerciseId) => state = {...state}..remove(exerciseId);

  void umschalten(String exerciseId) => state.contains(exerciseId)
      ? schliesse(exerciseId)
      : oeffne(exerciseId);

  bool istOffen(String exerciseId) => state.contains(exerciseId);
}
