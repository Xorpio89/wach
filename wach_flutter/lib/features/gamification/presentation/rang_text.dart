import '../../../l10n/app_localizations.dart';
import '../domain/rang.dart';

/// Der lesbare Name eines Rangs.
///
/// Die Uebersetzung liegt in den Sprachdateien, die Zaehlung dahinter kommt
/// aus [RangStufe] — so bleibt "Herrscher II" in jeder Sprache richtig
/// aufgebaut, ohne fuer jeden Durchlauf einen eigenen Eintrag zu brauchen.
String rangText(AppLocalizations l10n, int stufe) {
  final rangStufe = rangFuer(stufe);
  final name = switch (rangStufe.rang) {
    Rang.e => l10n.rangE,
    Rang.d => l10n.rangD,
    Rang.c => l10n.rangC,
    Rang.b => l10n.rangB,
    Rang.a => l10n.rangA,
    Rang.s => l10n.rangS,
    Rang.national => l10n.rangNational,
    Rang.monarch => l10n.rangMonarch,
    Rang.schattenmonarch => l10n.rangSchattenmonarch,
    Rang.herrscher => l10n.rangHerrscher,
  };

  return rangStufe.istWiederholung ? '$name ${rangStufe.ziffer}' : name;
}
