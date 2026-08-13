/// Utility functions for Duration formatting
extension DurationUtils on Duration {
  /// Format as MM:SS, switching to H:MM:SS past the first hour.
  ///
  /// Without the hour part the display would roll over back to 00:00
  /// after 60 minutes, which reads like the timer was reset.
  String toMinutesSeconds() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) {
      return '$inHours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Format as MM:SS.ms (with centiseconds).
  ///
  /// Past the first hour the centiseconds are dropped: H:MM:SS.cc is too
  /// wide for the timer display, and hundredths stop being meaningful in
  /// sessions that long.
  String toMinutesSecondsCentis() {
    if (inHours > 0) {
      return toMinutesSeconds();
    }
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    final centis =
        (inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centis';
  }

  /// Format as HH:MM:SS for long sessions
  String toHoursMinutesSeconds() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Human readable format (e.g., "2m 30s")
  String toReadable() {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    } else {
      return '${inSeconds}s';
    }
  }
}
