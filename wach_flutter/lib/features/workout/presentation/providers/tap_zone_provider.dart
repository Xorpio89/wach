import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tap zone configuration for exercise tiles
/// Defines where + and - zones are on the tile (left/right split)
class TapZoneState {
  /// Percentage of tile width for each zone (left = +, right = -)
  /// 0.0 = no zones (tap anywhere = add), 0.5 = max (50% each side)
  final double zonePercent;

  /// Whether to show the zone overlay in unlock mode
  final bool showZoneOverlay;

  const TapZoneState({
    this.zonePercent = 0.0,
    this.showZoneOverlay = false, // Hidden by default
  });

  TapZoneState copyWith({
    double? zonePercent,
    bool? showZoneOverlay,
  }) {
    return TapZoneState(
      zonePercent: zonePercent ?? this.zonePercent,
      showZoneOverlay: showZoneOverlay ?? this.showZoneOverlay,
    );
  }

  /// Determine tap action based on horizontal position (0.0 = left, 1.0 = right)
  /// Left side = subtract (-), Right side = add (+)
  TapAction getTapAction(double relativeX) {
    if (zonePercent == 0) {
      // No minus zone - entire tile is plus zone
      return TapAction.add;
    }
    // Left X% is minus zone, rest is plus zone
    if (relativeX <= zonePercent) {
      return TapAction.subtract;
    }
    return TapAction.add;
  }
}

enum TapAction { add, subtract, none }

/// Tap zone notifier
class TapZoneNotifier extends Notifier<TapZoneState> {
  @override
  TapZoneState build() {
    return const TapZoneState();
  }

  void setZonePercent(double percent) {
    state = state.copyWith(zonePercent: percent.clamp(0.0, 0.5));
  }

  void toggleOverlay() {
    state = state.copyWith(showZoneOverlay: !state.showZoneOverlay);
  }

  void setShowOverlay(bool show) {
    state = state.copyWith(showZoneOverlay: show);
  }
}

final tapZoneProvider = NotifierProvider<TapZoneNotifier, TapZoneState>(
  TapZoneNotifier.new,
);
