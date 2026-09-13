import 'dart:math' as math;

import 'recovery_domain_service.dart';

/// The role a muscle plays in one recorded exercise set.
enum RecoveryMuscleRole { primary, secondary }

/// One already-qualified, muscle-specific contribution from a completed set.
///
/// Database access and exercise-catalog resolution deliberately happen before
/// this boundary so the recovery calculation stays deterministic and easy to
/// regression-test.
class RecoverySetLoadInput {
  final String workoutLogId;
  final DateTime completedAt;
  final String muscleGroup;
  final RecoveryMuscleRole role;
  final double? catalogContribution;
  final int reps;
  final int durationSeconds;
  final int? rir;
  final String setType;
  final String? movementPattern;

  const RecoverySetLoadInput({
    required this.workoutLogId,
    required this.completedAt,
    required this.muscleGroup,
    required this.role,
    this.catalogContribution,
    this.reps = 0,
    this.durationSeconds = 0,
    this.rir,
    this.setType = 'normal',
    this.movementPattern,
  });
}

/// Typed, presentation-independent result for one tracked muscle.
class RecoveryMuscleLoadResult {
  final String muscleGroup;
  final String state;
  final double readinessScore;
  final DateTime? lastSessionAt;
  final double hoursSinceLastSession;
  final double lastSessionLoad;
  final double lastSessionDirectLoad;
  final double lastSessionIndirectLoad;
  final double residualLoad;
  final double? averageLastSessionRir;
  final bool highLastSessionFatigue;
  final int eligibleSetCount;
  final int setsWithRir;
  final String dataConfidence;
  final List<String> movementPatterns;
  final int recoveringUpperHours;
  final int readyUpperHours;

  const RecoveryMuscleLoadResult({
    required this.muscleGroup,
    required this.state,
    required this.readinessScore,
    required this.lastSessionAt,
    required this.hoursSinceLastSession,
    required this.lastSessionLoad,
    required this.lastSessionDirectLoad,
    required this.lastSessionIndirectLoad,
    required this.residualLoad,
    required this.averageLastSessionRir,
    required this.highLastSessionFatigue,
    required this.eligibleSetCount,
    required this.setsWithRir,
    required this.dataConfidence,
    required this.movementPatterns,
    required this.recoveringUpperHours,
    required this.readyUpperHours,
  });

  Map<String, dynamic> toMap() => {
        'muscleGroup': muscleGroup,
        'state': state,
        'readinessScore': readinessScore,
        'hoursSinceLastSignificantLoad': hoursSinceLastSession,
        'lastSignificantLoadAt': lastSessionAt,
        // Kept for the existing payload consumers. In v2 this is strictly
        // the latest session, never a whole-lookback aggregate.
        'lastEquivalentSets': lastSessionLoad,
        'lastSessionLoad': lastSessionLoad,
        'lastSessionDirectLoad': lastSessionDirectLoad,
        'lastSessionIndirectLoad': lastSessionIndirectLoad,
        'residualLoad': residualLoad,
        'avgRir': averageLastSessionRir,
        'avgRpe': null,
        'highSessionFatigue': highLastSessionFatigue,
        'eligibleSetCount': eligibleSetCount,
        'setsWithRir': setsWithRir,
        'dataConfidence': dataConfidence,
        'movementPatterns': movementPatterns,
        'recoveringUpperHours': recoveringUpperHours,
        'readyUpperHours': readyUpperHours,
      };
}

class RecoveryLoadAnalysis {
  final bool hasData;
  final String overallState;
  final List<RecoveryMuscleLoadResult> muscles;

  const RecoveryLoadAnalysis({
    required this.hasData,
    required this.overallState,
    required this.muscles,
  });

  Map<String, dynamic> toMap() {
    final recovering = muscles
        .where(
            (muscle) => muscle.state == RecoveryDomainService.stateRecovering)
        .length;
    final ready = muscles
        .where((muscle) => muscle.state == RecoveryDomainService.stateReady)
        .length;
    final fresh = muscles
        .where((muscle) => muscle.state == RecoveryDomainService.stateFresh)
        .length;

    return {
      'hasData': hasData,
      'overallState': hasData
          ? overallState
          : RecoveryDomainService.overallInsufficientData,
      'totals': {
        RecoveryDomainService.stateRecovering: hasData ? recovering : 0,
        RecoveryDomainService.stateReady: hasData ? ready : 0,
        RecoveryDomainService.stateFresh: hasData ? fresh : 0,
        'tracked': hasData ? muscles.length : 0,
      },
      'muscles': hasData
          ? muscles.map((muscle) => muscle.toMap()).toList(growable: false)
          : <Map<String, dynamic>>[],
    };
  }
}

/// v2's log-based, muscle-specific residual training-load calculation.
///
/// The constants are deliberately bounded engineering calibrations. They turn
/// completed log data into a transparent trend; they are not medical recovery
/// thresholds or claims of a universally measured biological state.
class RecoveryLoadEngine {
  static const double _primaryFallbackWeight = 1.0;
  static const double _secondaryFallbackWeight = 0.3;
  static const double _neutralMissingRirWeight = 0.7;
  static const double _readinessCapacity = 2.5;
  static const double _recoveringScoreBoundary = 60.0;
  static const double _freshScoreBoundary = 85.0;

  const RecoveryLoadEngine();

  RecoveryLoadAnalysis analyze({
    required Iterable<RecoverySetLoadInput> inputs,
    required DateTime now,
    Iterable<String> trackedMuscles = RecoveryDomainService.trackedMuscleGroups,
  }) {
    final sessionsByMuscle = <String, Map<String, _SessionLoad>>{};

    for (final input in inputs) {
      final muscle = input.muscleGroup.trim();
      final setType = input.setType.trim().toLowerCase();
      if (muscle.isEmpty ||
          input.completedAt.isAfter(now) ||
          setType == 'warmup' ||
          (input.reps <= 0 && input.durationSeconds <= 0)) {
        continue;
      }

      final bySession = sessionsByMuscle.putIfAbsent(
        muscle,
        () => <String, _SessionLoad>{},
      );
      final session = bySession.putIfAbsent(
        input.workoutLogId,
        () => _SessionLoad(completedAt: input.completedAt),
      );
      session.add(input, _setExposure(input));
    }

    final results = <RecoveryMuscleLoadResult>[];
    final allMuscles = <String>{...trackedMuscles, ...sessionsByMuscle.keys};
    for (final muscle in allMuscles) {
      results.add(_resultForMuscle(
        muscle: muscle,
        sessions: sessionsByMuscle[muscle]?.values.toList() ?? const [],
        now: now,
      ));
    }

    results.sort((a, b) {
      const stateOrder = {
        RecoveryDomainService.stateRecovering: 0,
        RecoveryDomainService.stateReady: 1,
        RecoveryDomainService.stateFresh: 2,
      };
      final stateComparison = (stateOrder[a.state] ?? 9).compareTo(
        stateOrder[b.state] ?? 9,
      );
      if (stateComparison != 0) return stateComparison;
      return a.readinessScore.compareTo(b.readinessScore);
    });

    final hasData = sessionsByMuscle.isNotEmpty;
    final recovering = results
        .where(
            (result) => result.state == RecoveryDomainService.stateRecovering)
        .length;
    return RecoveryLoadAnalysis(
      hasData: hasData,
      overallState: RecoveryDomainService.overallState(
        totalTrackedMuscles: results.length,
        recoveringCount: recovering,
      ),
      muscles: results,
    );
  }

  RecoveryMuscleLoadResult _resultForMuscle({
    required String muscle,
    required List<_SessionLoad> sessions,
    required DateTime now,
  }) {
    final profile = RecoveryDomainService.recoveryWindowProfileFor(muscle);
    final decayHours = profile.readyUpperHours.toDouble();

    if (sessions.isEmpty) {
      return RecoveryMuscleLoadResult(
        muscleGroup: muscle,
        state: RecoveryDomainService.stateFresh,
        readinessScore: 100.0,
        lastSessionAt: null,
        hoursSinceLastSession: 999.0,
        lastSessionLoad: 0.0,
        lastSessionDirectLoad: 0.0,
        lastSessionIndirectLoad: 0.0,
        residualLoad: 0.0,
        averageLastSessionRir: null,
        highLastSessionFatigue: false,
        eligibleSetCount: 0,
        setsWithRir: 0,
        dataConfidence: 'none',
        movementPatterns: const [],
        recoveringUpperHours: profile.recoveringUpperHours,
        readyUpperHours: profile.readyUpperHours,
      );
    }

    sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final latest = sessions.first;
    var residual = 0.0;
    for (final session in sessions) {
      final elapsedHours = math.max(
        0.0,
        now.difference(session.completedAt).inMinutes / 60.0,
      );
      residual += session.totalLoad * math.exp(-elapsedHours / decayHours);
    }

    final readiness = (100.0 / (1.0 + residual / _readinessCapacity))
        .clamp(0.0, 100.0)
        .toDouble();
    final state = readiness < _recoveringScoreBoundary
        ? RecoveryDomainService.stateRecovering
        : readiness < _freshScoreBoundary
            ? RecoveryDomainService.stateReady
            : RecoveryDomainService.stateFresh;
    final hoursSinceLatest =
        math.max(0.0, now.difference(latest.completedAt).inMinutes / 60.0);

    return RecoveryMuscleLoadResult(
      muscleGroup: muscle,
      state: state,
      readinessScore: readiness,
      lastSessionAt: latest.completedAt,
      hoursSinceLastSession: hoursSinceLatest,
      lastSessionLoad: latest.totalLoad,
      lastSessionDirectLoad: latest.directLoad,
      lastSessionIndirectLoad: latest.indirectLoad,
      residualLoad: residual,
      averageLastSessionRir: latest.averageRir,
      highLastSessionFatigue: latest.hasFailure ||
          (latest.averageRir != null && latest.averageRir! <= 1.0),
      eligibleSetCount: latest.eligibleSets,
      setsWithRir: latest.setsWithRir,
      dataConfidence: _confidenceFor(latest),
      movementPatterns: latest.movementPatterns.toList()..sort(),
      recoveringUpperHours: _absoluteHoursToScore(
        hoursSinceLatest: hoursSinceLatest,
        residual: residual,
        decayHours: decayHours,
        targetScore: _recoveringScoreBoundary,
      ),
      readyUpperHours: _absoluteHoursToScore(
        hoursSinceLatest: hoursSinceLatest,
        residual: residual,
        decayHours: decayHours,
        targetScore: _freshScoreBoundary,
      ),
    );
  }

  double _setExposure(RecoverySetLoadInput input) {
    final contribution = input.catalogContribution;
    final roleWeight = contribution != null && contribution.isFinite
        ? contribution.clamp(0.0, 1.0).toDouble()
        : input.role == RecoveryMuscleRole.primary
            ? _primaryFallbackWeight
            : _secondaryFallbackWeight;
    return roleWeight * _effortWeight(input) * _repetitionWeight(input);
  }

  double _effortWeight(RecoverySetLoadInput input) {
    if (input.setType.trim().toLowerCase() == 'failure') return 1.0;
    final rir = input.rir;
    if (rir == null || rir < 0 || rir > 5) return _neutralMissingRirWeight;
    return (1.0 - rir * 0.1).clamp(0.5, 1.0).toDouble();
  }

  double _repetitionWeight(RecoverySetLoadInput input) {
    if (input.reps <= 0 && input.durationSeconds > 0) return 0.8;
    if (input.reps <= 4) return 0.8;
    if (input.reps <= 8) return 0.9;
    if (input.reps <= 15) return 1.0;
    if (input.reps <= 30) return 1.05;
    return 1.1;
  }

  int _absoluteHoursToScore({
    required double hoursSinceLatest,
    required double residual,
    required double decayHours,
    required double targetScore,
  }) {
    final residualAtTarget = _readinessCapacity * (100.0 / targetScore - 1.0);
    final extraHours = residual <= residualAtTarget
        ? 0.0
        : decayHours * math.log(residual / residualAtTarget);
    return (hoursSinceLatest + extraHours).ceil();
  }

  String _confidenceFor(_SessionLoad session) {
    if (session.eligibleSets == 0) return 'none';
    final coverage = session.setsWithRir / session.eligibleSets;
    if (coverage >= 0.8) return 'high';
    if (coverage >= 0.4) return 'medium';
    return 'low';
  }
}

class _SessionLoad {
  final DateTime completedAt;
  double totalLoad = 0.0;
  double directLoad = 0.0;
  double indirectLoad = 0.0;
  int eligibleSets = 0;
  int setsWithRir = 0;
  double _rirSum = 0.0;
  bool hasFailure = false;
  final Set<String> movementPatterns = <String>{};

  _SessionLoad({required this.completedAt});

  double? get averageRir => setsWithRir == 0 ? null : _rirSum / setsWithRir;

  void add(RecoverySetLoadInput input, double exposure) {
    totalLoad += exposure;
    if (input.role == RecoveryMuscleRole.primary) {
      directLoad += exposure;
    } else {
      indirectLoad += exposure;
    }
    eligibleSets++;
    final rir = input.rir;
    if (rir != null && rir >= 0 && rir <= 5) {
      setsWithRir++;
      _rirSum += rir;
    }
    if (input.setType.trim().toLowerCase() == 'failure') {
      hasFailure = true;
    }
    final pattern = input.movementPattern?.trim();
    if (pattern != null && pattern.isNotEmpty) movementPatterns.add(pattern);
  }
}
