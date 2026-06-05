import '../sleep_enums.dart';

/// Derived nightly aggregate.
///
/// Ownership is in `domain/derived` because this model is not a canonical
/// ingestion artifact and is expected to evolve with analysis versions.
class NightlySleepAnalysis {
  const NightlySleepAnalysis({
    required this.id,
    required this.sessionId,
    required this.nightDate,
    required this.analysisVersion,
    required this.normalizationVersion,
    required this.analyzedAtUtc,
    this.score,
    this.totalSleepMinutes,
    this.sleepEfficiencyPct,
    this.restingHeartRateBpm,
    this.interruptionsCount,
    this.interruptionsWakeMinutes,
    this.scoreCompleteness,
    this.regularitySri,
    this.regularityValidDays,
    this.regularityStable,
    this.sleepQuality = SleepQualityBucket.unavailable,
    this.sessionStartAtUtc,
    this.sessionEndAtUtc,
    this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
    this.scoreBreakdownJson,
  });

  final String id;
  final String sessionId;
  final DateTime nightDate;
  final String analysisVersion;
  final String normalizationVersion;
  final DateTime analyzedAtUtc;
  final double? score;
  final int? totalSleepMinutes;
  final double? sleepEfficiencyPct;
  final double? restingHeartRateBpm;
  final int? interruptionsCount;
  final int? interruptionsWakeMinutes;
  final double? scoreCompleteness;
  final double? regularitySri;
  final int? regularityValidDays;
  final bool? regularityStable;
  final SleepQualityBucket sleepQuality;
  final DateTime? sessionStartAtUtc;
  final DateTime? sessionEndAtUtc;
  final String? sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;
  final Map<String, dynamic>? scoreBreakdownJson;

  NightlySleepAnalysis copyWith({
    String? id,
    String? sessionId,
    DateTime? nightDate,
    String? analysisVersion,
    String? normalizationVersion,
    DateTime? analyzedAtUtc,
    double? score,
    int? totalSleepMinutes,
    double? sleepEfficiencyPct,
    double? restingHeartRateBpm,
    int? interruptionsCount,
    int? interruptionsWakeMinutes,
    double? scoreCompleteness,
    double? regularitySri,
    int? regularityValidDays,
    bool? regularityStable,
    SleepQualityBucket? sleepQuality,
    DateTime? sessionStartAtUtc,
    DateTime? sessionEndAtUtc,
    String? sourcePlatform,
    String? sourceAppId,
    String? sourceRecordHash,
    Map<String, dynamic>? scoreBreakdownJson,
  }) {
    return NightlySleepAnalysis(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      nightDate: nightDate ?? this.nightDate,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      normalizationVersion: normalizationVersion ?? this.normalizationVersion,
      analyzedAtUtc: analyzedAtUtc ?? this.analyzedAtUtc,
      score: score ?? this.score,
      totalSleepMinutes: totalSleepMinutes ?? this.totalSleepMinutes,
      sleepEfficiencyPct: sleepEfficiencyPct ?? this.sleepEfficiencyPct,
      restingHeartRateBpm: restingHeartRateBpm ?? this.restingHeartRateBpm,
      interruptionsCount: interruptionsCount ?? this.interruptionsCount,
      interruptionsWakeMinutes: interruptionsWakeMinutes ?? this.interruptionsWakeMinutes,
      scoreCompleteness: scoreCompleteness ?? this.scoreCompleteness,
      regularitySri: regularitySri ?? this.regularitySri,
      regularityValidDays: regularityValidDays ?? this.regularityValidDays,
      regularityStable: regularityStable ?? this.regularityStable,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sessionStartAtUtc: sessionStartAtUtc ?? this.sessionStartAtUtc,
      sessionEndAtUtc: sessionEndAtUtc ?? this.sessionEndAtUtc,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      sourceAppId: sourceAppId ?? this.sourceAppId,
      sourceRecordHash: sourceRecordHash ?? this.sourceRecordHash,
      scoreBreakdownJson: scoreBreakdownJson ?? this.scoreBreakdownJson,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'nightDate': nightDate.toIso8601String(),
        'analysisVersion': analysisVersion,
        'normalizationVersion': normalizationVersion,
        'analyzedAtUtc': analyzedAtUtc.toIso8601String(),
        'score': score,
        'totalSleepMinutes': totalSleepMinutes,
        'sleepEfficiencyPct': sleepEfficiencyPct,
        'restingHeartRateBpm': restingHeartRateBpm,
        'interruptionsCount': interruptionsCount,
        'interruptionsWakeMinutes': interruptionsWakeMinutes,
        'scoreCompleteness': scoreCompleteness,
        'regularitySri': regularitySri,
        'regularityValidDays': regularityValidDays,
        'regularityStable': regularityStable,
        'sleepQuality': sleepQuality.name,
        'sessionStartAtUtc': sessionStartAtUtc?.toIso8601String(),
        'sessionEndAtUtc': sessionEndAtUtc?.toIso8601String(),
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
        'scoreBreakdownJson': scoreBreakdownJson,
      };
}
