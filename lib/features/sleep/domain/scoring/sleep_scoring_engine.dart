import 'dart:math' as math;

import '../sleep_enums.dart';

class SleepScoringInput {
  const SleepScoringInput({
    this.durationMinutes,
    this.sleepEfficiencyPct,
    this.wasoMinutes,
    this.regularitySri,
    this.regularityValidDays = 0,
    this.regularityValidComparisonPairs,
    this.lightSleepPct,
    this.deepSleepPct,
    this.remSleepPct,
    this.asleepUnspecifiedPct,
    this.hasIncompleteStageCoverage = false,
    this.stageDataConfidence = SleepStageConfidence.unknown,
    this.sourcePlatform,
    this.sourceAppId,
    this.sleepOnsetHourLocal,
    this.rollingMidSleepSd,
  });

  final int? durationMinutes;
  final double? sleepEfficiencyPct;
  final int? wasoMinutes;

  /// Sleep Regularity Index on a 0..100 scale.
  final double? regularitySri;
  final int regularityValidDays;
  final int? regularityValidComparisonPairs;

  /// Sleep stage composition percentages relative to total sleep time.
  final double? lightSleepPct;
  final double? deepSleepPct;
  final double? remSleepPct;
  final double? asleepUnspecifiedPct;
  final bool hasIncompleteStageCoverage;

  /// Stage-data fidelity hint derived from source metadata where available.
  final SleepStageConfidence stageDataConfidence;
  final String? sourcePlatform;
  final String? sourceAppId;

  /// Local clock time of sleep onset (0.0 to 24.0, or >24 for past midnight).
  final double? sleepOnsetHourLocal;

  /// 7-14 day rolling standard deviation of mid-sleep time in hours.
  final double? rollingMidSleepSd;

  double? get remMinutes => (remSleepPct != null && durationMinutes != null)
      ? (remSleepPct! / 100.0) * durationMinutes!
      : null;

  double? get n3Minutes => (deepSleepPct != null && durationMinutes != null)
      ? (deepSleepPct! / 100.0) * durationMinutes!
      : null;
}

class SleepScoringConfig {
  const SleepScoringConfig({
    required this.analysisVersion,
    this.weightDuration = 0.45,
    this.weightContinuity = 0.25,
    this.weightArchitecture = 0.20,
    this.weightTiming = 0.0,
    this.weightRegularity = 0.10,
    this.regularityMinDays = 5,
    this.regularityStableDays = 7,
  });

  final String analysisVersion;
  final double weightDuration;
  final double weightContinuity;
  final double weightArchitecture;
  final double weightTiming;
  final double weightRegularity;
  final int regularityMinDays;
  final int regularityStableDays;
}

enum SleepScoreState { good, average, poor, unavailable }

class SleepScoringResult {
  const SleepScoringResult({
    required this.score,
    required this.state,
    required this.completeness,
    this.durationScore,
    this.continuityScore,
    this.seScore,
    this.wasoScore,
    this.regularityScore,
    this.architectureScore,
    this.deepScore,
    this.remScore,
    this.timingScore,
    this.stageScoreCap,
    this.durationScoreCap,
    required this.regularityValidDays,
    required this.regularityUsed,
    required this.regularityStable,
    this.dynamicMultiplier,
    this.multiplierBottleneck,
  });

  final double? score;
  final SleepScoreState state;

  /// Data completeness of the score, not scientific certainty.
  final double completeness;

  final double? durationScore;
  final double? continuityScore;
  final double? seScore;
  final double? wasoScore;
  final double? regularityScore;
  final double? architectureScore;
  final double? deepScore;
  final double? remScore;
  final double? timingScore;
  final double? stageScoreCap;
  final double? durationScoreCap;
  final int regularityValidDays;
  final bool regularityUsed;
  final bool regularityStable;
  final double? dynamicMultiplier;
  final String? multiplierBottleneck;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'score': score,
    'state': state.name,
    'completeness': completeness,
    'durationScore': durationScore,
    'continuityScore': continuityScore,
    'seScore': seScore,
    'wasoScore': wasoScore,
    'regularityScore': regularityScore,
    'architectureScore': architectureScore,
    'deepScore': deepScore,
    'remScore': remScore,
    'timingScore': timingScore,
    'stageScoreCap': stageScoreCap,
    'durationScoreCap': durationScoreCap,
    'regularityValidDays': regularityValidDays,
    'regularityUsed': regularityUsed,
    'regularityStable': regularityStable,
    'dynamicMultiplier': dynamicMultiplier,
    'multiplierBottleneck': multiplierBottleneck,
  };

  factory SleepScoringResult.fromJson(Map<String, dynamic> json) {
    return SleepScoringResult(
      score: (json['score'] as num?)?.toDouble(),
      state: SleepScoreState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SleepScoreState.unavailable,
      ),
      completeness: (json['completeness'] as num?)?.toDouble() ?? 0.0,
      durationScore: (json['durationScore'] as num?)?.toDouble(),
      continuityScore: (json['continuityScore'] as num?)?.toDouble(),
      seScore: (json['seScore'] as num?)?.toDouble(),
      wasoScore: (json['wasoScore'] as num?)?.toDouble(),
      regularityScore: (json['regularityScore'] as num?)?.toDouble(),
      architectureScore: (json['architectureScore'] as num?)?.toDouble(),
      deepScore: (json['deepScore'] as num?)?.toDouble(),
      remScore: (json['remScore'] as num?)?.toDouble(),
      timingScore: (json['timingScore'] as num?)?.toDouble(),
      stageScoreCap: (json['stageScoreCap'] as num?)?.toDouble(),
      durationScoreCap: (json['durationScoreCap'] as num?)?.toDouble(),
      regularityValidDays: json['regularityValidDays'] as int? ?? 0,
      regularityUsed: json['regularityUsed'] as bool? ?? false,
      regularityStable: json['regularityStable'] as bool? ?? false,
      dynamicMultiplier: (json['dynamicMultiplier'] as num?)?.toDouble(),
      multiplierBottleneck: json['multiplierBottleneck'] as String?,
    );
  }
}

/// An exploratory, non-clinical sleep estimate. Component weights and curves
/// are product heuristics, not a validated instrument. Missing components are
/// excluded rather than imputed; duration is required.
SleepScoringResult calculateSleepScore(
  SleepScoringInput input, {
  SleepScoringConfig config = const SleepScoringConfig(
    analysisVersion: 'sleep-health-score-v4',
  ),
}) {
  final duration = input.durationMinutes;
  final durationScore = duration != null && duration > 0
      ? (duration / 480.0).clamp(0.0, 1.0).toDouble()
      : null;
  final efficiency = input.sleepEfficiencyPct;
  final waso = input.wasoMinutes;
  final seScore =
      efficiency != null &&
          efficiency.isFinite &&
          efficiency >= 0 &&
          efficiency <= 100
      ? (efficiency / 90.0).clamp(0.0, 1.0).toDouble()
      : null;
  final wasoScore = waso != null && waso >= 0 ? scoreWasoV3(waso) : null;
  final double? continuityScore = seScore != null && wasoScore != null
      ? (seScore + wasoScore) / 2
      : seScore ?? wasoScore;
  // A largely unspecified timeline cannot reliably estimate individual stages.
  final stagesUsable =
      !input.hasIncompleteStageCoverage &&
      (input.asleepUnspecifiedPct == null || input.asleepUnspecifiedPct! <= 5);
  double? stageScore(double? minutes, double target) =>
      durationScore != null &&
          stagesUsable &&
          minutes != null &&
          minutes.isFinite &&
          minutes >= 0
      ? (minutes / target).clamp(0.0, 1.0).toDouble()
      : null;
  final deep = stageScore(input.n3Minutes, 90);
  final rem = stageScore(input.remMinutes, 100);
  final sd = input.rollingMidSleepSd;
  final regularityUsed =
      sd != null &&
      sd.isFinite &&
      sd >= 0 &&
      input.regularityValidDays >= config.regularityMinDays;
  final regularityStable =
      regularityUsed &&
      input.regularityValidDays >= config.regularityStableDays;
  final regularity = regularityUsed ? scoreRegularityV3(sd) : null;
  final components = <(double, double?)>[
    (config.weightDuration, durationScore),
    (config.weightContinuity, continuityScore),
    (config.weightArchitecture / 2, deep),
    (config.weightArchitecture / 2, rem),
    (config.weightRegularity, regularity),
  ];
  final completeness = _activeWeight(weightedComponents: components)
      .clamp(0.0, 1.0)
      .toDouble();
  final combined = _renormalizedWeightedScore(scoredComponents: components);
  // A continuous duration-dependent ceiling prevents ancillary data from
  // turning a very short night into a high score; there is no multiplier.
  final score = durationScore == null || combined == null
      ? null
      : math
            .min(combined * 100, durationScore * 100 + 15)
            .clamp(0.0, 100.0)
            .toDouble();
  return SleepScoringResult(
    score: score,
    state: score == null ? SleepScoreState.unavailable : _scoreState(score),
    completeness: completeness,
    durationScore: durationScore == null ? null : durationScore * 100,
    continuityScore: continuityScore == null ? null : continuityScore * 100,
    seScore: seScore == null ? null : seScore * 100,
    wasoScore: wasoScore == null ? null : wasoScore * 100,
    deepScore: deep == null ? null : deep * 100,
    remScore: rem == null ? null : rem * 100,
    regularityScore: regularity == null ? null : regularity * 100,
    durationScoreCap: score != null && combined! * 100 > score + 0.000001
        ? score
        : null,
    regularityValidDays: input.regularityValidDays,
    regularityUsed: regularityUsed,
    regularityStable: regularityStable,
  );
}

/// Duration Score (D): Gaussian distribution centered around mu_T = 7.5 hours
/// with spread sigma_T = 1.0. Plateaus in the 7-9 hour anabolic sweet spot.
/// Clips extremes (<5h or >10.5h -> 0).
/// Returns a [0, 1] continuous score.
double scoreDurationV3(int durationMinutes) {
  final double hours = durationMinutes / 60.0;
  if (hours > 10.5) return 0.0;

  if (hours >= 7.0 && hours <= 9.0) {
    return 1.0; // Plateau
  }

  final double mu = hours < 7.0 ? 7.0 : 9.0;
  return math.exp(-math.pow(hours - mu, 2) / (2 * math.pow(1.0, 2)));
}

/// Continuity Score (C_SE): Logistic curve.
/// Returns a [0, 1] continuous score.
double scoreSleepEfficiencyV3(double sleepEfficiencyPct) {
  final double seFraction = sleepEfficiencyPct / 100.0;
  return 1.0 / (1.0 + math.exp(-50.0 * (seFraction - 0.90)));
}

/// Continuity Score (C_WASO): Rational penalty decaying quadratically.
/// Returns a [0, 1] continuous score.
double scoreWasoV3(int wasoMinutes) {
  final double waso = math.max(wasoMinutes - 20.0, 0.0);
  return 1.0 / (1.0 + math.pow(waso / 30.0, 2));
}

/// Architecture Score (A): Based on absolute minutes.
/// Returns a [0, 1] continuous score.
double? scoreArchitectureV3({
  int? durationMinutes,
  double? lightSleepPct,
  double? deepSleepPct,
  double? remSleepPct,
}) {
  if (durationMinutes == null || deepSleepPct == null || remSleepPct == null) {
    return null;
  }

  final double n3Min = (deepSleepPct / 100.0) * durationMinutes;
  final double remMin = (remSleepPct / 100.0) * durationMinutes;
  final double lightSleepPctVal = lightSleepPct ?? 0.0;

  final double aN3 =
      math.min(1.0, n3Min / 90.0) *
      math.exp(-math.pow(n3Min - 90.0, 2) / (2.0 * math.pow(40.0, 2)));
  final double aRem =
      math.min(1.0, remMin / 100.0) *
      math.exp(-math.pow(remMin - 100.0, 2) / (2.0 * math.pow(40.0, 2)));

  double pLight = 1.0;
  if (lightSleepPctVal > 65.0) {
    pLight = math.exp(
      -math.pow(lightSleepPctVal - 65.0, 2) / (2.0 * math.pow(7.0, 2)),
    );
  }

  double score = (0.45 * aN3 + 0.45 * aRem) * pLight + 0.10;
  return score.clamp(0.0, 1.0);
}

/// Timing Score (T_circ): Uses Mid-Sleep clock time.
/// Base Gaussian centered at 03:30 (3.5).
/// Returns a [0, 1] continuous score.
double scoreTimingV3(double onsetHourLocal, int durationMinutes) {
  final double ms = _calculateMidSleep(onsetHourLocal, durationMinutes);

  // Gaussian centered at 03:30 (3.5), sigma = 1.0
  double baseScore = math.exp(
    -math.pow(ms - 3.5, 2) / (2.0 * math.pow(1.0, 2)),
  );

  // Exponential late-phase penalty drop
  if (ms > 5.5) {
    double pLate = math.exp(-math.pow(ms - 5.5, 2) / (2.0 * math.pow(0.5, 2)));
    baseScore *= pLate;
  }

  return baseScore.clamp(0.0, 1.0);
}

/// Regularity Score (R): Inverse-quadratic decay based on standard deviation.
/// Returns a [0, 1] continuous score.
double scoreRegularityV3(double rollingMidSleepSd) {
  return 1.0 / (1.0 + math.pow(rollingMidSleepSd / 1.0, 2));
}

/// Normalizes mid-sleep time to handle midnight crossing properly.
/// Returns the hour [0-24] typically, shifting into a continuous scale.
double _calculateMidSleep(double onsetHourLocal, int durationMinutes) {
  double onset = onsetHourLocal;
  // If onset is early in the evening (e.g., 20:00), we want mid sleep to cross midnight cleanly.
  // We'll anchor around noon.
  // If onset is between 12:00 and 24:00, subtract 24 or just treat 00:00 as 24:00.
  if (onset > 12.0) {
    onset -= 24.0;
  }
  // Now onset is usually negative (e.g., 23:00 -> -1.0) or early morning (01:00 -> 1.0)

  double ms = onset + ((durationMinutes / 60.0) / 2.0);

  // Shift back if needed so 03:30 is 3.5
  while (ms < 0) {
    ms += 24.0;
  }
  while (ms >= 24.0) {
    ms -= 24.0;
  }
  return ms;
}

double? _renormalizedWeightedScore({
  required List<(double weight, double? score)> scoredComponents,
}) {
  var activeWeight = 0.0;
  var weightedSum = 0.0;
  for (final entry in scoredComponents) {
    final score = entry.$2;
    if (score == null) continue;
    activeWeight += entry.$1;
    weightedSum += entry.$1 * score;
  }
  if (activeWeight <= 0) return null;
  return weightedSum / activeWeight;
}

double _activeWeight({
  required List<(double weight, double? score)> weightedComponents,
}) {
  var weight = 0.0;
  for (final entry in weightedComponents) {
    if (entry.$2 == null) continue;
    weight += entry.$1;
  }
  return weight;
}

SleepScoreState _scoreState(double score) {
  if (score >= 80) return SleepScoreState.good;
  if (score >= 60) return SleepScoreState.average;
  return SleepScoreState.poor;
}
