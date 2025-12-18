import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lock Mode Notifier
class LockModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // Default: locked

  void toggle() {
    state = !state;
  }

  void lock() {
    state = true;
  }

  void unlock() {
    state = false;
  }
}

/// Lock Mode Provider
/// Controls whether the workout screen is in locked (training) or unlocked (edit) mode
final lockModeProvider = NotifierProvider<LockModeNotifier, bool>(
  LockModeNotifier.new,
);

/// Toggle lock mode (convenience function)
void toggleLockMode(WidgetRef ref) {
  ref.read(lockModeProvider.notifier).toggle();
}
