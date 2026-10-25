import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/karten_spiel.dart';

part 'karten_spiel_provider.g.dart';

enum KartenPhase { einrichtung, laeuft, fertig }

/// Wie viele Schritte sich zurücknehmen lassen.
const maxRueckgaengig = 50;

/// Ein Stapel, wie er eingerichtet wurde: Übung plus Aussehen.
class StapelWahl {
  final String uebungId;
  final String name;

  /// Index in die Farb- bzw. Symbolpalette des Screens.
  final int farbe;
  final int symbol;

  const StapelWahl({
    required this.uebungId,
    required this.name,
    required this.farbe,
    required this.symbol,
  });

  StapelWahl copyWith(
          {String? uebungId, String? name, int? farbe, int? symbol}) =>
      StapelWahl(
        uebungId: uebungId ?? this.uebungId,
        name: name ?? this.name,
        farbe: farbe ?? this.farbe,
        symbol: symbol ?? this.symbol,
      );
}

class KartenZustand {
  final KartenPhase phase;
  final List<StapelWahl> stapel;
  final List<String> spielerNamen;
  final KartenSpiel? spiel;
  final int sekunden;
  final DateTime? start;
  final bool kannRueckgaengig;
  final bool gespeichert;

  /// Verbleibende Pausensekunden; null, wenn keine Pause läuft.
  final int? pauseRest;

  const KartenZustand({
    this.phase = KartenPhase.einrichtung,
    this.stapel = const [],
    this.spielerNamen = const [],
    this.spiel,
    this.sekunden = 0,
    this.start,
    this.kannRueckgaengig = false,
    this.gespeichert = false,
    this.pauseRest,
  });

  /// Im Zeit-Modus die verbleibenden Sekunden, sonst null.
  int? get restSekunden {
    final s = spiel;
    if (s == null || s.regeln.modus != SpielModus.zeit) return null;
    final rest = s.regeln.zeitlimitMinuten * 60 - sekunden;
    return rest < 0 ? 0 : rest;
  }

  String spielerName(int index) =>
      index < spielerNamen.length ? spielerNamen[index] : '${index + 1}';
}

@Riverpod(keepAlive: true)
class KartenSpielNotifier extends _$KartenSpielNotifier {
  Timer? _uhr;
  final List<KartenSpiel> _verlauf = [];
  Random _zufall = Random();

  @override
  KartenZustand build() {
    ref.onDispose(() => _uhr?.cancel());
    return const KartenZustand();
  }

  void starte({
    required List<StapelWahl> stapel,
    required KartenRegeln regeln,
    List<String> spielerNamen = const [],
    Random? zufall,
  }) {
    if (zufall != null) _zufall = zufall;
    starteMit(
      stapel: stapel,
      spiel: KartenSpiel.neu(regeln, _zufall),
      spielerNamen: spielerNamen,
    );
  }

  /// Start mit vorgegebenem Spiel, etwa einer festen Kartenfolge.
  void starteMit({
    required List<StapelWahl> stapel,
    required KartenSpiel spiel,
    List<String> spielerNamen = const [],
  }) {
    _verlauf.clear();
    _uhr?.cancel();
    state = KartenZustand(
      phase: KartenPhase.laeuft,
      stapel: List.unmodifiable(stapel),
      spielerNamen: List.unmodifiable(spielerNamen),
      spiel: spiel,
      start: DateTime.now(),
    );
    _uhr = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.phase != KartenPhase.laeuft) return;
    // Echte Zeit seit dem Start, mindestens die gezählten Ticks: im
    // Hintergrund gedrosselte Timer holen so beim nächsten Tick auf.
    final start = state.start;
    final echt = start == null ? 0 : DateTime.now().difference(start).inSeconds;
    final sekunden = max(state.sekunden + 1, echt);
    final vergangen = sekunden - state.sekunden;
    final pause = state.pauseRest;
    final rest = pause == null ? null : pause - vergangen;
    state = _mit(
      sekunden: sekunden,
      pauseRest: rest == null || rest <= 0 ? null : rest,
    );
    if (state.restSekunden == 0) {
      // Die angefangene Karte zählt mit dem, was bis hierhin geschafft ist.
      final spiel = state.spiel;
      if (spiel != null) state = _mit(spiel: spiel.schliesseAb());
      beende();
    }
  }

  /// Karte abschließen; danach läuft, falls eingestellt, die Pause.
  void erledige() {
    if (state.pauseRest != null) return;
    final vorher = state.spiel?.aktuell;
    _schritt((s) => s.erledige(_zufall));
    final sekunden = state.spiel?.regeln.pauseSekunden ?? 0;
    final hatteUebung = vorher != null && !vorher.istPause;
    if (state.phase == KartenPhase.laeuft && sekunden > 0 && hatteUebung) {
      state = _mit(pauseRest: sekunden);
    }
  }

  void ueberspringePause() => state = _mit(pauseRest: null);

  void waehle(int stapel) => _ersetze((s) => s.waehle(stapel));

  void passe(int delta) => _ersetze((s) => s.passe(delta));

  void rueckgaengig() {
    if (state.phase != KartenPhase.laeuft || _verlauf.isEmpty) return;
    state = _mit(spiel: _verlauf.removeLast(), pauseRest: null);
  }

  /// Vorzeitig beenden; bisherige Karten bleiben im Ergebnis.
  void beende() {
    _uhr?.cancel();
    if (state.spiel == null) return;
    state = _mit(phase: KartenPhase.fertig, pauseRest: null);
  }

  void nochmal() {
    final spiel = state.spiel;
    if (spiel == null) return;
    starte(
      stapel: state.stapel,
      regeln: spiel.regeln,
      spielerNamen: state.spielerNamen,
    );
  }

  void zurEinrichtung() {
    _uhr?.cancel();
    _verlauf.clear();
    state =
        KartenZustand(stapel: state.stapel, spielerNamen: state.spielerNamen);
  }

  void merkeGespeichert() => state = _mit(gespeichert: true);

  /// Schritt mit Rückgängig-Punkt; endet das Deck, ist das Spiel fertig.
  void _schritt(KartenSpiel Function(KartenSpiel) f) {
    final alt = state.spiel;
    if (state.phase != KartenPhase.laeuft || alt == null) return;
    final neu = f(alt);
    if (identical(neu, alt)) return;
    _verlauf.add(alt);
    if (_verlauf.length > maxRueckgaengig) _verlauf.removeAt(0);
    state = _mit(spiel: neu);
    if (neu.fertig) beende();
  }

  /// Änderung an der aktuellen Karte, ohne eigenen Rückgängig-Punkt.
  void _ersetze(KartenSpiel Function(KartenSpiel) f) {
    final alt = state.spiel;
    if (state.phase != KartenPhase.laeuft || alt == null) return;
    state = _mit(spiel: f(alt));
  }

  static const _gleich = Object();

  /// Kopie des Zustands; `pauseRest` darf ausdrücklich null werden.
  KartenZustand _mit({
    KartenPhase? phase,
    KartenSpiel? spiel,
    int? sekunden,
    bool? gespeichert,
    Object? pauseRest = _gleich,
  }) =>
      KartenZustand(
        phase: phase ?? state.phase,
        stapel: state.stapel,
        spielerNamen: state.spielerNamen,
        spiel: spiel ?? state.spiel,
        sekunden: sekunden ?? state.sekunden,
        start: state.start,
        kannRueckgaengig: _verlauf.isNotEmpty,
        gespeichert: gespeichert ?? state.gespeichert,
        pauseRest:
            identical(pauseRest, _gleich) ? state.pauseRest : pauseRest as int?,
      );
}
