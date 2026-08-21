import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../workout/presentation/providers/session_providers.dart';
import '../../domain/ziel_anhebung.dart';
import 'exercise_providers.dart';

part 'ziel_anhebung_provider.g.dart';

/// Uebungen, deren Ziel zu niedrig steht.
///
/// Reiner Ableiter aus Uebungen und Verlauf — sobald ein Ziel angehoben
/// oder eine Session gespeichert wird, rechnet er neu. Nichts wird
/// zwischengespeichert, deshalb kann der Vorschlag nicht veralten.
@Riverpod(keepAlive: true)
List<ZielAnhebung> zielAnhebungen(Ref ref) {
  final exercises = ref.watch(exercisesStreamProvider).value;
  final sessions = ref.watch(sessionProvider).value;
  if (exercises == null || sessions == null) return const [];
  return findeZielAnhebungen(exercises, sessions);
}
