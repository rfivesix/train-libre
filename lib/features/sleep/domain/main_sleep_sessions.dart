import 'sleep_session.dart';

/// Selects the longest episode and any connected fragments separated by at
/// most 90 minutes. More distant episodes are kept separate as naps.
List<SleepSession> selectMainSleepFragments(List<SleepSession> sessions) {
  if (sessions.isEmpty) return const [];
  final ordered = List<SleepSession>.of(sessions)
    ..sort(
      (a, b) => b.endAtUtc
          .difference(b.startAtUtc)
          .compareTo(a.endAtUtc.difference(a.startAtUtc)),
    );
  final main = <SleepSession>[ordered.first];
  var changed = true;
  while (changed) {
    changed = false;
    for (final candidate in ordered) {
      if (main.contains(candidate)) continue;
      final adjacent = main.any((part) {
        final gap = candidate.startAtUtc.isAfter(part.endAtUtc)
            ? candidate.startAtUtc.difference(part.endAtUtc)
            : part.startAtUtc.isAfter(candidate.endAtUtc)
            ? part.startAtUtc.difference(candidate.endAtUtc)
            : Duration.zero;
        return gap <= const Duration(minutes: 90);
      });
      if (adjacent) {
        main.add(candidate);
        changed = true;
      }
    }
  }
  return main;
}
