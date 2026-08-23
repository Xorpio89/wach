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

  /// Formt eine Rueckmeldung, ohne sie schon abzulegen.
  ///
  /// Getrennt vom Ablegen, weil das Ablegen wartet und im Browser dabei
  /// der Bezug zum Antippen verloren geht: Ein Fenster, das erst danach
  /// aufgeht, gilt als ungefragt und wird unterdrueckt. Die Oberflaeche
  /// braucht die Notiz deshalb vorher — zum Oeffnen im selben Zug.
  FeedbackNotiz baue({
    required FeedbackArt art,
    required String text,
  }) {
    return FeedbackNotiz(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      art: art,
      text: text.trim(),
      erstelltAm: DateTime.now(),
      appVersion: AppConstants.appVersion,
      plattform: erfasseUmgebung(),
    );
  }

  /// Legt eine geformte Rueckmeldung ab.
  Future<void> lege(FeedbackNotiz notiz) async {
    await ref.read(feedbackDataSourceProvider).speichere(notiz);
    await _neuLaden();
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
