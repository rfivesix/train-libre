class RecoveryTotalsPayload {
  final int recovering;
  final int ready;
  final int fresh;
  final int tracked;

  const RecoveryTotalsPayload({
    required this.recovering,
    required this.ready,
    required this.fresh,
    required this.tracked,
  });

  factory RecoveryTotalsPayload.fromMap(Map<String, dynamic> data) {
    return RecoveryTotalsPayload(
      recovering: (data['recovering'] as num?)?.toInt() ?? 0,
      ready: (data['ready'] as num?)?.toInt() ?? 0,
      fresh: (data['fresh'] as num?)?.toInt() ?? 0,
      tracked: (data['tracked'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecoveryMusclePayload {
  final String muscleGroup;
  final String state;
  final double hoursSinceLastSignificantLoad;
  final DateTime? lastSignificantLoadAt;
  final double lastEquivalentSets;
  final double? avgRir;
  final double? avgRpe;
  final bool highSessionFatigue;
  final int recoveringUpperHours;
  final int readyUpperHours;
  final double? readinessScore;
  final double? lastSessionLoad;
  final double? lastSessionDirectLoad;
  final double? lastSessionIndirectLoad;
  final double? residualLoad;
  final int eligibleSetCount;
  final int setsWithRir;
  final String dataConfidence;
  final List<String> movementPatterns;

  const RecoveryMusclePayload({
    required this.muscleGroup,
    required this.state,
    required this.hoursSinceLastSignificantLoad,
    required this.lastSignificantLoadAt,
    required this.lastEquivalentSets,
    required this.avgRir,
    required this.avgRpe,
    required this.highSessionFatigue,
    required this.recoveringUpperHours,
    required this.readyUpperHours,
    this.readinessScore,
    this.lastSessionLoad,
    this.lastSessionDirectLoad,
    this.lastSessionIndirectLoad,
    this.residualLoad,
    this.eligibleSetCount = 0,
    this.setsWithRir = 0,
    this.dataConfidence = 'none',
    this.movementPatterns = const [],
  });

  factory RecoveryMusclePayload.fromMap(Map<String, dynamic> data) {
    return RecoveryMusclePayload(
      muscleGroup: data['muscleGroup'] as String? ?? '',
      state: data['state'] as String? ?? '',
      hoursSinceLastSignificantLoad:
          (data['hoursSinceLastSignificantLoad'] as num?)?.toDouble() ?? 0.0,
      lastSignificantLoadAt: _parseDateTime(data['lastSignificantLoadAt']),
      lastEquivalentSets: (data['lastEquivalentSets'] as num?)?.toDouble() ?? 0,
      avgRir: (data['avgRir'] as num?)?.toDouble(),
      avgRpe: (data['avgRpe'] as num?)?.toDouble(),
      highSessionFatigue: (data['highSessionFatigue'] as bool?) ?? false,
      recoveringUpperHours:
          (data['recoveringUpperHours'] as num?)?.toInt() ?? 48,
      readyUpperHours: (data['readyUpperHours'] as num?)?.toInt() ?? 72,
      readinessScore: (data['readinessScore'] as num?)?.toDouble(),
      lastSessionLoad: (data['lastSessionLoad'] as num?)?.toDouble(),
      lastSessionDirectLoad:
          (data['lastSessionDirectLoad'] as num?)?.toDouble(),
      lastSessionIndirectLoad:
          (data['lastSessionIndirectLoad'] as num?)?.toDouble(),
      residualLoad: (data['residualLoad'] as num?)?.toDouble(),
      eligibleSetCount: (data['eligibleSetCount'] as num?)?.toInt() ?? 0,
      setsWithRir: (data['setsWithRir'] as num?)?.toInt() ?? 0,
      dataConfidence: data['dataConfidence'] as String? ?? 'none',
      movementPatterns: (data['movementPatterns'] as List<dynamic>? ?? const [])
          .map((pattern) => pattern.toString())
          .toList(growable: false),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      final milliseconds = value.abs() < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    return null;
  }
}

class RecoveryAnalyticsPayload {
  final bool hasData;
  final String overallState;
  final RecoveryTotalsPayload totals;
  final List<RecoveryMusclePayload> muscles;

  const RecoveryAnalyticsPayload({
    required this.hasData,
    required this.overallState,
    required this.totals,
    required this.muscles,
  });

  factory RecoveryAnalyticsPayload.fromMap(Map<String, dynamic> data) {
    final totalsMap = (data['totals'] as Map<String, dynamic>?) ?? const {};
    final musclesList = (data['muscles'] as List<dynamic>? ?? const []);
    return RecoveryAnalyticsPayload(
      hasData: (data['hasData'] as bool?) ?? false,
      overallState: data['overallState'] as String? ?? '',
      totals: RecoveryTotalsPayload.fromMap(totalsMap),
      muscles: musclesList
          .whereType<Map<String, dynamic>>()
          .map(RecoveryMusclePayload.fromMap)
          .toList(),
    );
  }
}
