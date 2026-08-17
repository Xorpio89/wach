import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../workout/presentation/providers/session_providers.dart';
import '../../domain/gamification_stats.dart';

part 'gamification_provider.g.dart';

/// Punkte, Stufe und Serie zum aktuellen Verlauf.
///
/// Ein reiner Ableiter ohne eigenen Zustand: er rechnet neu, sobald sich
/// die Sessions aendern. Dadurch stimmt die Anzeige auch nach einem
/// "Rueckgaengig" oder dem Loeschen einer Session, ohne dass irgendwo ein
/// Punktestand nachgefuehrt werden muesste.
@Riverpod(keepAlive: true)
GamificationStats gamification(Ref ref) {
  final sessions = ref.watch(sessionProvider);
  return sessions.maybeWhen(
    data: GamificationStats.aus,
    orElse: () => GamificationStats.leer,
  );
}
