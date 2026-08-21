import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/feedback_bericht.dart';
import '../../domain/feedback_notiz.dart';
import '../providers/feedback_providers.dart';

/// Rueckmeldungen erfassen und weitergeben.
///
/// Zwei Schritte, absichtlich getrennt: aufschreiben geht sofort und ohne
/// Netz, weitergeben spaeter in Ruhe. Wer beides erzwingt, verliert die
/// Beobachtung, die zwischen zwei Saetzen kommt.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _eingabe = TextEditingController();
  FeedbackArt _art = FeedbackArt.fehler;

  @override
  void dispose() {
    _eingabe.dispose();
    super.dispose();
  }

  String _artName(AppLocalizations l10n, FeedbackArt art) {
    return switch (art) {
      FeedbackArt.fehler => l10n.feedbackArtFehler,
      FeedbackArt.idee => l10n.feedbackArtIdee,
      FeedbackArt.sonstiges => l10n.feedbackArtSonstiges,
    };
  }

  IconData _artZeichen(FeedbackArt art) {
    return switch (art) {
      FeedbackArt.fehler => Icons.bug_report_outlined,
      FeedbackArt.idee => Icons.lightbulb_outline_rounded,
      FeedbackArt.sonstiges => Icons.chat_bubble_outline_rounded,
    };
  }

  Future<void> _notieren({required bool undMelden}) async {
    final text = _eingabe.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final notiz = await ref
        .read(feedbackNotizenProvider.notifier)
        .erfasse(art: _art, text: text);

    _eingabe.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    if (undMelden) {
      await _melden(notiz);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.feedbackNotiertMeldung)),
    );
  }

  Future<void> _melden(FeedbackNotiz notiz) async {
    final l10n = AppLocalizations.of(context);
    final geoeffnet = await launchUrl(
      FeedbackBericht.adresse(notiz),
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;
    if (!geoeffnet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackOeffnenFehler)),
      );
      return;
    }
    await ref.read(feedbackNotizenProvider.notifier).markiereGemeldet(notiz);
  }

  Future<void> _kopieren(List<FeedbackNotiz> notizen) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: FeedbackBericht.alsText(notizen)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.feedbackKopiert)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notizen = ref.watch(feedbackNotizenProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.feedbackTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (notizen.isNotEmpty)
            IconButton(
              tooltip: l10n.feedbackKopieren,
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: () => _kopieren(notizen),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          _Eingabe(
            eingabe: _eingabe,
            art: _art,
            artName: (a) => _artName(l10n, a),
            artZeichen: _artZeichen,
            onArt: (a) => setState(() => _art = a),
            onNotieren: () => _notieren(undMelden: false),
            onNotierenUndMelden: () => _notieren(undMelden: true),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            l10n.feedbackMeldenHinweis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          if (notizen.isEmpty)
            _Leer(l10n: l10n)
          else ...[
            Text(l10n.feedbackListeTitel, style: AppTypography.labelSmall),
            const SizedBox(height: AppConstants.spacingSm),
            for (final notiz in notizen)
              _NotizZeile(
                key: ValueKey(notiz.id),
                notiz: notiz,
                l10n: l10n,
                zeichen: _artZeichen(notiz.art),
                onMelden: () => _melden(notiz),
                onLoeschen: () => ref
                    .read(feedbackNotizenProvider.notifier)
                    .loesche(notiz.id),
              ),
          ],
        ],
      ),
    );
  }
}

class _Eingabe extends StatelessWidget {
  final TextEditingController eingabe;
  final FeedbackArt art;
  final String Function(FeedbackArt) artName;
  final IconData Function(FeedbackArt) artZeichen;
  final ValueChanged<FeedbackArt> onArt;
  final VoidCallback onNotieren;
  final VoidCallback onNotierenUndMelden;

  const _Eingabe({
    required this.eingabe,
    required this.art,
    required this.artName,
    required this.artZeichen,
    required this.onArt,
    required this.onNotieren,
    required this.onNotierenUndMelden,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.feedbackNeuLabel, style: AppTypography.labelSmall),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            children: [
              for (final wahl in FeedbackArt.values)
                ChoiceChip(
                  selected: wahl == art,
                  onSelected: (_) => onArt(wahl),
                  avatar: Icon(artZeichen(wahl), size: 16),
                  label: Text(artName(wahl)),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TextField(
            controller: eingabe,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.feedbackNeuHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onNotieren,
                child: Text(l10n.feedbackNotieren),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              FilledButton.icon(
                onPressed: onNotierenUndMelden,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l10n.feedbackMelden),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotizZeile extends StatelessWidget {
  final FeedbackNotiz notiz;
  final AppLocalizations l10n;
  final IconData zeichen;
  final VoidCallback onMelden;
  final VoidCallback onLoeschen;

  const _NotizZeile({
    super.key,
    required this.notiz,
    required this.l10n,
    required this.zeichen,
    required this.onMelden,
    required this.onLoeschen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: ListTile(
        leading: Icon(zeichen, color: AppColors.textSecondary),
        title: Text(notiz.betreff, maxLines: 2),
        subtitle: Text(
          notiz.istGemeldet
              ? l10n.feedbackGemeldet
              : '${notiz.appVersion} · ${notiz.plattform}',
          style: AppTypography.bodySmall.copyWith(
            color: notiz.istGemeldet
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notiz.istGemeldet)
              IconButton(
                tooltip: l10n.feedbackMelden,
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: onMelden,
              ),
            IconButton(
              tooltip: l10n.feedbackLoeschen,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onLoeschen,
            ),
          ],
        ),
      ),
    );
  }
}

class _Leer extends StatelessWidget {
  final AppLocalizations l10n;

  const _Leer({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXl),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(l10n.feedbackLeerTitel, style: AppTypography.bodyMedium),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            l10n.feedbackLeerText,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
