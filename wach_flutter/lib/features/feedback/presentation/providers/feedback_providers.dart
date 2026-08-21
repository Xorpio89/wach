import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart'
    show databaseServiceProvider;
import '../../data/feedback_local_datasource.dart';
import '../../domain/feedback_notiz.dart';

part 'feedback_providers.g.dart';

@Riverpod(keepAlive: true)
FeedbackLocalDataSource feedbackDataSource(Ref ref) {
  return FeedbackLocalDataSource(ref.watch(databaseServiceProvider));
}

/// Beschreibt knapp, wo die App laeuft.
///
/// Wird jeder Notiz beigelegt, damit spaeter nicht geraten werden muss, ob
/// etwas nur als installierte Web-App auftrat oder ueberall.
String erfasseUmgebung() {
  final geraet = defaultTargetPlatform.name;
  return kIsWeb ? 'Web ($geraet)' : geraet;
}

/// Die gesammelten Rueckmeldungen.
@Riverpod(keepAlive: true)
class FeedbackNotizen extends _$FeedbackNotizen {
  @override
  Future<List<FeedbackNotiz>> build() {
    return ref.watch(feedbackDataSourceProvider).getAll();
  }

  /// Nimmt eine Rueckmeldung auf und gibt sie zurueck, damit die
  /// Oberflaeche sie gleich weitergeben kann.
  Future<FeedbackNotiz> erfasse({
    required FeedbackArt art,
    required String text,
  }) async {
    final notiz = FeedbackNotiz(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      art: art,
      text: text.trim(),
      erstelltAm: DateTime.now(),
      appVersion: AppConstants.appVersion,
      plattform: erfasseUmgebung(),
    );

    await ref.read(feedbackDataSourceProvider).speichere(notiz);
    await _neuLaden();
    return notiz;
  }

  /// Haelt fest, dass eine Notiz weitergegeben wurde.
  Future<void> markiereGemeldet(FeedbackNotiz notiz) async {
    await ref
        .read(feedbackDataSourceProvider)
        .speichere(notiz.kopieMit(gemeldetAm: DateTime.now()));
    await _neuLaden();
  }

  Future<void> loesche(String id) async {
    await ref.read(feedbackDataSourceProvider).loesche(id);
    await _neuLaden();
  }

  Future<void> _neuLaden() async {
    state = AsyncValue.data(
      await ref.read(feedbackDataSourceProvider).getAll(),
    );
  }
}

/// Wie viele Notizen noch nicht weitergegeben wurden.
///
/// Dient dem Hinweis in den Einstellungen — sonst geraet in Vergessenheit,
/// was aufgeschrieben, aber nie abgeschickt wurde.
@Riverpod(keepAlive: true)
int offeneFeedbackAnzahl(Ref ref) {
  final notizen = ref.watch(feedbackNotizenProvider).value ?? const [];
  return notizen.where((n) => !n.istGemeldet).length;
}
