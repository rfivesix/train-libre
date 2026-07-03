import 'sleep_enums.dart';

/// Canonical, platform-agnostic sleep session entity.
class SleepSession {
  const SleepSession({
    required this.id,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.sessionType,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
    this.sourceConfidence,
    this.stageConfidence = SleepStageConfidence.unknown,
    this.overallConfidence = SleepOverallConfidence.unknown,
    this.normalizationVersion,
  });

  final String id;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final SleepSessionType sessionType;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;
  final String? sourceConfidence;
  final SleepStageConfidence stageConfidence;
  final SleepOverallConfidence overallConfidence;
  final String? normalizationVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'startAtUtc': startAtUtc.toIso8601String(),
        'endAtUtc': endAtUtc.toIso8601String(),
        'sessionType': sessionType.name,
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
        'sourceConfidence': sourceConfidence,
        'stageConfidence': stageConfidence.name,
        'overallConfidence': overallConfidence.name,
        'normalizationVersion': normalizationVersion,
      };
}

typedef SleepInterval = SleepSession;

/// Merges overlapping or continuously connecting sleep intervals.
List<SleepInterval> mergeOverlappingIntervals(List<SleepInterval> intervals) {
  if (intervals.isEmpty) return [];

  // Sort by startAtUtc (onset time)
  final sorted = List<SleepInterval>.from(intervals)
    ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));

  final merged = <SleepInterval>[];
  var current = sorted.first;

  for (var i = 1; i < sorted.length; i++) {
    final next = sorted[i];

    // Overlap or connect continuously: next.startAtUtc <= current.endAtUtc
    if (next.startAtUtc.isBefore(current.endAtUtc) ||
        next.startAtUtc.isAtSameMomentAs(current.endAtUtc)) {
      final latestEnd = next.endAtUtc.isAfter(current.endAtUtc)
          ? next.endAtUtc
          : current.endAtUtc;

      current = SleepSession(
        id: current.id,
        startAtUtc: current.startAtUtc,
        endAtUtc: latestEnd,
        sessionType: current.sessionType,
        sourcePlatform: current.sourcePlatform,
        sourceAppId: current.sourceAppId,
        sourceRecordHash: current.sourceRecordHash,
        sourceConfidence: current.sourceConfidence,
        stageConfidence: current.stageConfidence,
        overallConfidence: current.overallConfidence,
        normalizationVersion: current.normalizationVersion,
      );
    } else {
      merged.add(current);
      current = next;
    }
  }
  merged.add(current);

  // Update classification logic: merged intervals exceeding >= 3 hours
  // are correctly categorized as mainSleep, else nap.
  return merged.map((s) {
    final duration = s.endAtUtc.difference(s.startAtUtc);
    final newType = duration >= const Duration(hours: 3)
        ? SleepSessionType.mainSleep
        : SleepSessionType.nap;

    return SleepSession(
      id: s.id,
      startAtUtc: s.startAtUtc,
      endAtUtc: s.endAtUtc,
      sessionType: newType,
      sourcePlatform: s.sourcePlatform,
      sourceAppId: s.sourceAppId,
      sourceRecordHash: s.sourceRecordHash,
      sourceConfidence: s.sourceConfidence,
      stageConfidence: s.stageConfidence,
      overallConfidence: s.overallConfidence,
      normalizationVersion: s.normalizationVersion,
    );
  }).toList();
}
