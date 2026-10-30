import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exercise/domain/entities/exercise.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../workout/data/models/session_model.dart';
import '../../../workout/presentation/providers/session_providers.dart';
import '../../domain/deck.dart';
import '../../domain/karte.dart';
import '../../domain/karten_spiel.dart';
import '../providers/karten_spiel_provider.dart';

/// Farben der Stapel; Schriftfarbe ergibt sich aus der Helligkeit.
const stapelFarben = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFFB8C00),
  Color(0xFFD81B60),
];

const stapelSymbole = [
  Icons.bolt_rounded,
  Icons.local_fire_department_rounded,
  Icons.star_rounded,
  Icons.favorite_rounded,
  Icons.diamond_rounded,
  Icons.terrain_rounded,
  Icons.water_drop_rounded,
  Icons.shield_rounded,
];

/// Übungen, die bevorzugt als Startstapel dienen.
const _bevorzugt = ['Push Ups', 'Pull Ups', 'Squats', 'Dips'];

Color _schriftAuf(Color c) =>
    c.computeLuminance() > 0.35 ? AppColors.background : Colors.white;

class KartenScreen extends ConsumerWidget {
  const KartenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zustand = ref.watch(kartenSpielProvider);
    final l = AppLocalizations.of(context);
    // Spürbares Signal, wenn das Spiel oder eine Pause endet — das Handy liegt
    // beim Training selten im Blick.
    ref.listen(kartenSpielProvider, (vorher, jetzt) {
      if (vorher?.phase == KartenPhase.laeuft &&
          jetzt.phase == KartenPhase.fertig) {
        HapticUtils.vibrate();
      } else if (vorher?.pauseRest != null &&
          jetzt.pauseRest == null &&
          jetzt.phase == KartenPhase.laeuft) {
        HapticUtils.heavyTap();
      }
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.kartenTitle),
        actions: [
          if (zustand.phase == KartenPhase.laeuft) ...[
            IconButton(
              tooltip: l.kartenRueckgaengig,
              icon: const Icon(Icons.undo_rounded),
              onPressed: zustand.kannRueckgaengig
                  ? () => ref.read(kartenSpielProvider.notifier).rueckgaengig()
                  : null,
            ),
            IconButton(
              tooltip: l.kartenBeenden,
              icon: const Icon(Icons.flag_rounded),
              onPressed: () => _frageBeenden(context, ref),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: switch (zustand.phase) {
          KartenPhase.einrichtung => const _Einrichtung(),
          KartenPhase.laeuft => const _Spiel(),
          KartenPhase.fertig => const _Ergebnis(),
        },
      ),
    );
  }

  Future<void> _frageBeenden(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ja = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.kartenBeendenFrage),
        content: Text(l.kartenBeendenText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.kartenBeenden),
          ),
        ],
      ),
    );
    if (ja == true) ref.read(kartenSpielProvider.notifier).beende();
  }
}

// ── Einrichtung ──────────────────────────────────────────────────────────

class _Einrichtung extends ConsumerStatefulWidget {
  const _Einrichtung();

  @override
  ConsumerState<_Einrichtung> createState() => _EinrichtungState();
}

class _EinrichtungState extends ConsumerState<_Einrichtung> {
  SpielModus _modus = SpielModus.deck;
  int _deck = 0; // 0 kurz, 1 mittel, 2 voll
  int _minuten = 10;
  Schwierigkeit _schwierigkeit = Schwierigkeit.normal;
  int? _obergrenze = 20;
  bool _aktionen = true;
  int _spieler = 1;
  int _pause = 0;
  final _namen = List.generate(4, (_) => TextEditingController());
  List<StapelWahl>? _stapel;

  @override
  void dispose() {
    for (final c in _namen) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Wie im Workout: ohne Übungen gäbe es keine Stapel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(exerciseProvider.notifier).seedDefaultExercisesIfEmpty();
      }
    });
  }

  List<StapelWahl> _vorschlag(List<Exercise> uebungen) {
    final frueher = ref.read(kartenSpielProvider).stapel;
    if (frueher.isNotEmpty) return List.of(frueher);
    final sortiert = [
      for (final name in _bevorzugt) ...uebungen.where((u) => u.name == name),
      ...uebungen.where((u) => !_bevorzugt.contains(u.name)),
    ];
    return [
      for (var i = 0; i < sortiert.length && i < 4; i++)
        StapelWahl(
          uebungId: sortiert[i].id,
          name: sortiert[i].name,
          farbe: i % stapelFarben.length,
          symbol: i % stapelSymbole.length,
        ),
    ];
  }

  int? get _deckGroesse => switch (_deck) {
        0 => deckKurz,
        1 => deckMittel,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uebungen = ref.watch(exercisesStreamProvider).value ?? const [];
    if (uebungen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Text(l.kartenKeineUebungen,
              textAlign: TextAlign.center, style: AppTypography.bodyLarge),
        ),
      );
    }
    final stapel = _stapel ??= _vorschlag(uebungen);
    final voll =
        vollesDeck(stapel: stapel.length, mitAktionen: _aktionen).length;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        _Abschnitt(l.kartenModus),
        _Auswahl<SpielModus>(
          werte: SpielModus.values,
          gewaehlt: _modus,
          text: (m) =>
              m == SpielModus.deck ? l.kartenModusDeck : l.kartenModusZeit,
          onWahl: (m) => setState(() => _modus = m),
        ),
        if (_modus == SpielModus.deck) ...[
          _Abschnitt(l.kartenDeck),
          _Auswahl<int>(
            werte: [
              if (voll > deckKurz) 0,
              if (voll > deckMittel) 1,
              2,
            ],
            gewaehlt: _deck,
            text: (d) => switch (d) {
              0 => l.kartenDeckKurz(deckKurz),
              1 => l.kartenDeckMittel(deckMittel),
              _ => l.kartenDeckVoll(voll),
            },
            onWahl: (d) => setState(() => _deck = d),
          ),
        ] else ...[
          _Abschnitt(l.kartenZeitlimit),
          _Auswahl<int>(
            werte: const [5, 10, 15, 20],
            gewaehlt: _minuten,
            text: l.kartenMinuten,
            onWahl: (m) => setState(() => _minuten = m),
          ),
        ],
        _Abschnitt(l.kartenSchwierigkeit),
        _Auswahl<Schwierigkeit>(
          werte: Schwierigkeit.values,
          gewaehlt: _schwierigkeit,
          text: (s) => switch (s) {
            Schwierigkeit.leicht => l.kartenLeicht,
            Schwierigkeit.normal => l.kartenNormal,
            Schwierigkeit.hart => l.kartenHart,
            Schwierigkeit.brutal => l.kartenBrutal,
          },
          onWahl: (s) => setState(() => _schwierigkeit = s),
        ),
        _Abschnitt(l.kartenObergrenze),
        _Auswahl<int?>(
          werte: const [10, 15, 20, 30, null],
          gewaehlt: _obergrenze,
          text: (g) => g == null ? l.kartenObergrenzeKeine : '$g',
          onWahl: (g) => setState(() => _obergrenze = g),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.kartenAktionen, style: AppTypography.bodyLarge),
          subtitle:
              Text(l.kartenAktionenHinweis, style: AppTypography.bodySmall),
          value: _aktionen,
          onChanged: (v) => setState(() => _aktionen = v),
        ),
        _Abschnitt(l.kartenPause),
        _Auswahl<int>(
          werte: const [0, 30, 60, 90],
          gewaehlt: _pause,
          text: (p) => p == 0 ? l.kartenPauseAus : l.kartenSekunden(p),
          onWahl: (p) => setState(() => _pause = p),
        ),
        _Abschnitt(l.kartenSpieler),
        _Auswahl<int>(
          werte: const [1, 2, 3, 4],
          gewaehlt: _spieler,
          text: (n) => '$n',
          onWahl: (n) => setState(() => _spieler = n),
        ),
        if (_spieler > 1)
          for (var i = 0; i < _spieler; i++)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingSm),
              child: TextField(
                controller: _namen[i],
                decoration: InputDecoration(
                  hintText: l.kartenSpielerName(i + 1),
                  isDense: true,
                ),
              ),
            ),
        _Abschnitt(l.kartenStapel),
        for (var i = 0; i < stapel.length; i++)
          _StapelZeile(
            stapel: stapel[i],
            uebungen: uebungen,
            entfernbar: stapel.length > minStapel,
            onAendern: (neu) => setState(() => stapel[i] = neu),
            onEntfernen: () => setState(() => stapel.removeAt(i)),
          ),
        if (stapel.length < maxStapel)
          TextButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(l.kartenStapelHinzufuegen),
            onPressed: () => setState(() {
              final n = stapel.length;
              final u = uebungen[n % uebungen.length];
              stapel.add(StapelWahl(
                uebungId: u.id,
                name: u.name,
                farbe: n % stapelFarben.length,
                symbol: n % stapelSymbole.length,
              ));
            }),
          ),
        const SizedBox(height: AppConstants.spacingLg),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed:
                stapel.any((s) => !uebungen.any((u) => u.id == s.uebungId))
                    ? null
                    : () {
                        HapticUtils.mediumTap();
                        ref.read(kartenSpielProvider.notifier).starte(
                              stapel: List.of(stapel),
                              spielerNamen: [
                                for (var i = 0; i < _spieler; i++)
                                  _namen[i].text.trim().isEmpty
                                      ? l.kartenSpielerName(i + 1)
                                      : _namen[i].text.trim(),
                              ],
                              regeln: KartenRegeln(
                                stapel: stapel.length,
                                modus: _modus,
                                schwierigkeit: _schwierigkeit,
                                obergrenze: _obergrenze,
                                mitAktionen: _aktionen,
                                deckGroesse: _deckGroesse,
                                zeitlimitMinuten: _minuten,
                                spieler: _spieler,
                                pauseSekunden: _pause,
                              ),
                            );
                      },
            child: Text(l.kartenStart),
          ),
        ),
      ],
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final String text;
  const _Abschnitt(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            top: AppConstants.spacingMd, bottom: AppConstants.spacingSm),
        child: Text(text, style: AppTypography.labelLarge),
      );
}

class _Auswahl<T> extends StatelessWidget {
  final List<T> werte;
  final T gewaehlt;
  final String Function(T) text;
  final ValueChanged<T> onWahl;

  const _Auswahl({
    required this.werte,
    required this.gewaehlt,
    required this.text,
    required this.onWahl,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppConstants.spacingSm,
        runSpacing: AppConstants.spacingSm,
        children: [
          for (final w in werte)
            ChoiceChip(
              label: Text(text(w)),
              selected: w == gewaehlt,
              onSelected: (_) => onWahl(w),
            ),
        ],
      );
}

class _StapelZeile extends StatelessWidget {
  final StapelWahl stapel;
  final List<Exercise> uebungen;
  final bool entfernbar;
  final ValueChanged<StapelWahl> onAendern;
  final VoidCallback onEntfernen;

  const _StapelZeile({
    required this.stapel,
    required this.uebungen,
    required this.entfernbar,
    required this.onAendern,
    required this.onEntfernen,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final farbe = stapelFarben[stapel.farbe];
    final vorhanden = uebungen.any((u) => u.id == stapel.uebungId);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        children: [
          Tooltip(
            message: l.kartenStapelGestalten,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              onTap: () => _gestalten(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: farbe,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Icon(stapelSymbole[stapel.symbol],
                    color: _schriftAuf(farbe)),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(l.kartenUebungWaehlen),
              value: vorhanden ? stapel.uebungId : null,
              items: [
                for (final u in uebungen)
                  DropdownMenuItem(value: u.id, child: Text(u.name)),
              ],
              onChanged: (id) {
                if (id == null) return;
                final u = uebungen.firstWhere((u) => u.id == id);
                onAendern(stapel.copyWith(uebungId: u.id, name: u.name));
              },
            ),
          ),
          if (entfernbar)
            IconButton(
              tooltip: l.kartenStapelEntfernen,
              icon: const Icon(Icons.close_rounded),
              onPressed: onEntfernen,
            ),
        ],
      ),
    );
  }

  Future<void> _gestalten(BuildContext context) async {
    final ergebnis = await showModalBottomSheet<StapelWahl>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (c) {
        var auswahl = stapel;
        return StatefulBuilder(
          builder: (c, setSheet) => Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppConstants.spacingSm,
                  runSpacing: AppConstants.spacingSm,
                  children: [
                    for (var i = 0; i < stapelFarben.length; i++)
                      _Kreis(
                        farbe: stapelFarben[i],
                        nummer: i + 1,
                        gewaehlt: auswahl.farbe == i,
                        onTap: () => setSheet(
                            () => auswahl = auswahl.copyWith(farbe: i)),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Wrap(
                  spacing: AppConstants.spacingSm,
                  runSpacing: AppConstants.spacingSm,
                  children: [
                    for (var i = 0; i < stapelSymbole.length; i++)
                      IconButton.filledTonal(
                        isSelected: auswahl.symbol == i,
                        icon: Icon(stapelSymbole[i]),
                        onPressed: () => setSheet(
                            () => auswahl = auswahl.copyWith(symbol: i)),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                IconButton(
                  icon: const Icon(Icons.check_rounded),
                  onPressed: () => Navigator.pop(c, auswahl),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ergebnis != null) onAendern(ergebnis);
  }
}

class _Kreis extends StatelessWidget {
  final Color farbe;
  final int nummer;
  final bool gewaehlt;
  final VoidCallback onTap;

  const _Kreis({
    required this.farbe,
    required this.nummer,
    required this.gewaehlt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: gewaehlt,
        label: AppLocalizations.of(context).kartenFarbe(nummer),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: farbe,
              shape: BoxShape.circle,
              border: Border.all(
                color: gewaehlt ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        ),
      );
}

// ── Spiel ────────────────────────────────────────────────────────────────

class _Spiel extends ConsumerStatefulWidget {
  const _Spiel();

  @override
  ConsumerState<_Spiel> createState() => _SpielState();
}

class _SpielState extends ConsumerState<_Spiel> {
  DateTime _letzterTipp = DateTime(0);

  /// Schutz gegen Doppeltipps mit nassen Händen.
  void _erledige() {
    final jetzt = DateTime.now();
    if (jetzt.difference(_letzterTipp).inMilliseconds < 450) return;
    _letzterTipp = jetzt;
    HapticUtils.lightTap();
    ref.read(kartenSpielProvider.notifier).erledige();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final zustand = ref.watch(kartenSpielProvider);
    final spiel = zustand.spiel;
    final aufgabe = spiel?.aktuell;
    if (spiel == null || aufgabe == null) return const SizedBox.shrink();

    final notifier = ref.read(kartenSpielProvider.notifier);
    final stapel =
        aufgabe.stapel == null ? null : zustand.stapel[aufgabe.stapel!];
    final grund =
        stapel == null ? AppColors.surfaceVariant : stapelFarben[stapel.farbe];
    final schrift = _schriftAuf(grund);
    final uebrig = spiel.kartenUebrig;
    final nummer = spiel.index + 1;
    final uhr = zustand.restSekunden ?? zustand.sekunden;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  uebrig == null
                      ? l.kartenKarteNummer(nummer)
                      : l.kartenKarteVon(nummer, spiel.index + uebrig),
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(_mmss(uhr), style: AppTypography.timerSmall),
            ],
          ),
          if (spiel.regeln.spieler > 1)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingSm),
              child: Text(
                l.kartenAmZug(zustand.spielerName(spiel.amZug)),
                style: AppTypography.headline3,
              ),
            ),
          const SizedBox(height: AppConstants.spacingMd),
          if (zustand.pauseRest != null)
            Expanded(
              child: _Pause(
                sekunden: zustand.pauseRest!,
                onUeberspringen: notifier.ueberspringePause,
              ),
            )
          else
            Expanded(
              child: Semantics(
                button: !aufgabe.brauchtWahl,
                label: aufgabe.brauchtWahl
                    ? null
                    : (aufgabe.istPause ? l.kartenWeiter : l.kartenTippen),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: aufgabe.brauchtWahl ? null : _erledige,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    decoration: BoxDecoration(
                      color: grund,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusXl),
                    ),
                    child: _Kartenseite(
                      aufgabe: aufgabe,
                      stapel: stapel,
                      alleStapel: zustand.stapel,
                      geschafft: spiel.geschafft,
                      doppeltOffen: spiel.doppeltOffen,
                      schrift: schrift,
                      onWahl: notifier.waehle,
                      onPasse: notifier.passe,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(l.kartenGesamt(spiel.gesamtWiederholungen),
              style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _Pause extends StatelessWidget {
  final int sekunden;
  final VoidCallback onUeberspringen;

  const _Pause({required this.sekunden, required this.onUeberspringen});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.kartenPauseLaeuft, style: AppTypography.headline2),
          Text(_mmss(sekunden), style: AppTypography.timerLarge),
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton(
            onPressed: onUeberspringen,
            child: Text(l.kartenPauseUeberspringen),
          ),
        ],
      ),
    );
  }
}

class _Kartenseite extends StatelessWidget {
  final Aufgabe aufgabe;
  final StapelWahl? stapel;
  final List<StapelWahl> alleStapel;
  final int geschafft;
  final bool doppeltOffen;
  final Color schrift;
  final ValueChanged<int> onWahl;
  final ValueChanged<int> onPasse;

  const _Kartenseite({
    required this.aufgabe,
    required this.stapel,
    required this.alleStapel,
    required this.geschafft,
    required this.doppeltOffen,
    required this.schrift,
    required this.onWahl,
    required this.onPasse,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final karte = aufgabe.karte;
    final titel = switch (karte.art) {
      KartenArt.zahl => '${karte.zahl == 0 ? nullZaehlt : karte.zahl}',
      KartenArt.joker => l.kartenJoker,
      KartenArt.nochmal => l.kartenNochmal,
      KartenArt.doppelt => l.kartenDoppelt,
      KartenArt.wahl => l.kartenWahl,
    };
    final hinweis = switch (karte.art) {
      KartenArt.zahl => null,
      KartenArt.joker => l.kartenJokerText,
      KartenArt.nochmal =>
        aufgabe.istPause ? l.kartenNochmalLeer : l.kartenNochmalText,
      KartenArt.doppelt => l.kartenDoppeltText,
      KartenArt.wahl => aufgabe.brauchtWahl ? l.kartenWahlText : null,
    };
    final stil = AppTypography.bodyLarge.copyWith(color: schrift);

    if (aufgabe.brauchtWahl) {
      return Column(
        children: [
          Text(titel, style: AppTypography.headline1.copyWith(color: schrift)),
          if (hinweis != null) Text(hinweis, style: stil),
          const SizedBox(height: AppConstants.spacingMd),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.spacingSm,
              crossAxisSpacing: AppConstants.spacingSm,
              childAspectRatio: 2,
              children: [
                for (var i = 0; i < alleStapel.length; i++)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stapelFarben[alleStapel[i].farbe],
                      foregroundColor:
                          _schriftAuf(stapelFarben[alleStapel[i].farbe]),
                    ),
                    icon: Icon(stapelSymbole[alleStapel[i].symbol]),
                    label: Text(alleStapel[i].name,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onPressed: () => onWahl(i),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            if (stapel != null)
              Icon(stapelSymbole[stapel!.symbol], color: schrift, size: 32),
            const Spacer(),
            if (aufgabe.doppelt || (aufgabe.istPause && doppeltOffen))
              Text(l.kartenDoppeltAktiv,
                  style: AppTypography.labelLarge.copyWith(color: schrift)),
          ],
        ),
        const Spacer(),
        Text(
          titel,
          textAlign: TextAlign.center,
          style: AppTypography.timerLarge.copyWith(color: schrift),
        ),
        if (hinweis != null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.spacingSm),
            child: Text(hinweis, textAlign: TextAlign.center, style: stil),
          ),
        if (stapel != null && !aufgabe.istPause) ...[
          const SizedBox(height: AppConstants.spacingMd),
          Text(stapel!.name,
              style: AppTypography.headline2.copyWith(color: schrift)),
          const SizedBox(height: AppConstants.spacingSm),
          // Fehltipps neben −/+ sollen die Karte nicht abschließen.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l.kartenWeniger,
                  iconSize: 40,
                  color: schrift,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () => onPasse(-1),
                ),
                SizedBox(
                  width: 96,
                  child: Text('$geschafft',
                      textAlign: TextAlign.center,
                      style: AppTypography.repCount.copyWith(color: schrift)),
                ),
                IconButton(
                  tooltip: l.kartenMehr,
                  iconSize: 40,
                  color: schrift,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => onPasse(1),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        Text(aufgabe.istPause ? l.kartenWeiter : l.kartenTippen, style: stil),
      ],
    );
  }
}

String _mmss(int sekunden) {
  final m = (sekunden ~/ 60).toString().padLeft(2, '0');
  final s = (sekunden % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

// ── Ergebnis ─────────────────────────────────────────────────────────────

class _Ergebnis extends ConsumerWidget {
  const _Ergebnis();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final zustand = ref.watch(kartenSpielProvider);
    final spiel = zustand.spiel;
    if (spiel == null) return const SizedBox.shrink();
    final notifier = ref.read(kartenSpielProvider.notifier);
    final jeStapel = spiel.wiederholungenJeStapel;
    final titel = spiel.fertig
        ? l.kartenFertig
        : (zustand.restSekunden == 0
            ? l.kartenZeitAbgelaufen
            : l.kartenBeendet);

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      children: [
        Text(titel,
            style: AppTypography.headline1, textAlign: TextAlign.center),
        const SizedBox(height: AppConstants.spacingSm),
        Text(_mmss(zustand.sekunden),
            style: AppTypography.timerMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          '${l.kartenErgebnisKarten(spiel.erledigt.length)} · '
          '${l.kartenErgebnisReps(spiel.gesamtWiederholungen)}',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        const SizedBox(height: AppConstants.spacingLg),
        if (spiel.regeln.spieler > 1)
          for (final e
              in (spiel.wiederholungenJeSpieler.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value))))
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(zustand.spielerName(e.key)),
              trailing: Text('${e.value}', style: AppTypography.headline3),
            ),
        for (var i = 0; i < zustand.stapel.length; i++)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: stapelFarben[zustand.stapel[i].farbe],
              child: Icon(stapelSymbole[zustand.stapel[i].symbol],
                  color: _schriftAuf(stapelFarben[zustand.stapel[i].farbe])),
            ),
            title: Text(zustand.stapel[i].name),
            trailing:
                Text('${jeStapel[i] ?? 0}', style: AppTypography.headline3),
          ),
        const SizedBox(height: AppConstants.spacingLg),
        ElevatedButton.icon(
          icon: Icon(zustand.gespeichert
              ? Icons.check_rounded
              : Icons.save_alt_rounded),
          label: Text(zustand.gespeichert
              ? l.kartenGespeichert
              : (spiel.regeln.spieler > 1
                  ? l.kartenSpeichernFuer(zustand.spielerName(0))
                  : l.kartenSpeichern)),
          onPressed:
              zustand.gespeichert || spiel.wiederholungenJeStapelFuer(0).isEmpty
                  ? null
                  : () => _speichern(ref, zustand),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        OutlinedButton(
          onPressed: notifier.nochmal,
          child: Text(l.kartenNochmalSpielen),
        ),
        TextButton(
          onPressed: notifier.zurEinrichtung,
          child: Text(l.kartenEinstellungen),
        ),
        TextButton(
          onPressed: () {
            notifier.zurEinrichtung();
            context.go('/');
          },
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }

  Future<void> _speichern(WidgetRef ref, KartenZustand zustand) async {
    final spiel = zustand.spiel!;
    final reps = <String, int>{};
    final namen = <String, String>{};
    // Gespeichert wird für den Besitzer des Geräts, Spieler 1.
    spiel.wiederholungenJeStapelFuer(0).forEach((index, anzahl) {
      final s = zustand.stapel[index];
      reps[s.uebungId] = (reps[s.uebungId] ?? 0) + anzahl;
      namen[s.uebungId] = s.name;
    });
    // Erst sperren, dann speichern: ein zweiter Tipp legt sonst eine zweite
    // Session an.
    ref.read(kartenSpielProvider.notifier).merkeGespeichert();
    final ende = DateTime.now();
    await ref.read(sessionProvider.notifier).saveSession(SessionModel(
          id: ende.millisecondsSinceEpoch.toString(),
          startedAt: zustand.start ?? ende,
          finishedAt: ende,
          durationSeconds: zustand.sekunden,
          exerciseReps: reps,
          exerciseNames: namen,
        ));
  }
}
