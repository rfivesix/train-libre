import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/statistics/domain/recovery_domain_service.dart';
import 'package:train_libre/features/statistics/domain/recovery_load_engine.dart';

void main() {
  const engine = RecoveryLoadEngine();
  final now = DateTime.utc(2026, 9, 13, 12);

  RecoverySetLoadInput set({
    required String session,
    required String muscle,
    RecoveryMuscleRole role = RecoveryMuscleRole.primary,
    DateTime? completedAt,
    int reps = 10,
    int? rir = 2,
    String setType = 'normal',
    String? pattern,
    double? catalogContribution,
  }) {
    return RecoverySetLoadInput(
      workoutLogId: session,
      completedAt: completedAt ?? now,
      muscleGroup: muscle,
      role: role,
      reps: reps,
      rir: rir,
      setType: setType,
      movementPattern: pattern,
      catalogContribution: catalogContribution,
    );
  }

  RecoveryMuscleLoadResult muscle(
    Iterable<RecoverySetLoadInput> inputs,
    String group,
  ) {
    return engine
        .analyze(inputs: inputs, now: now)
        .muscles
        .singleWhere((result) => result.muscleGroup == group);
  }

  group('RecoveryLoadEngine', () {
    test('has no data when every input is a warm-up or incomplete', () {
      final result = engine.analyze(
        now: now,
        inputs: [
          set(session: 'warmup', muscle: 'chest', setType: 'warmup'),
          set(session: 'empty', muscle: 'back', reps: 0),
        ],
      );

      expect(result.hasData, isFalse);
      expect(result.muscles,
          hasLength(RecoveryDomainService.trackedMuscleGroups.length));
    });

    test('uses the latest session load rather than the whole history sum', () {
      final latest = set(session: 'latest', muscle: 'chest', rir: 3);
      final oldFailure = set(
        session: 'old-failure',
        muscle: 'chest',
        rir: 0,
        setType: 'failure',
        completedAt: now.subtract(const Duration(days: 13)),
      );

      final latestOnly = muscle([latest], 'chest');
      final withOldFailure = muscle([oldFailure, latest], 'chest');

      expect(withOldFailure.lastSessionLoad,
          closeTo(latestOnly.lastSessionLoad, 0.0001));
      expect(withOldFailure.highLastSessionFatigue, isFalse);
      expect(withOldFailure.residualLoad - latestOnly.residualLoad,
          lessThan(0.02));
    });

    test('weights primary exposure above otherwise equal secondary exposure',
        () {
      final direct = muscle(
        [set(session: 'direct', muscle: 'chest', rir: 2)],
        'chest',
      );
      final indirect = muscle(
        [
          set(
            session: 'indirect',
            muscle: 'triceps',
            role: RecoveryMuscleRole.secondary,
            rir: 2,
          ),
        ],
        'triceps',
      );

      expect(direct.lastSessionLoad, greaterThan(indirect.lastSessionLoad));
      expect(direct.readinessScore, lessThan(indirect.readinessScore));
    });

    test('uses an explicit catalog contribution when one is supplied', () {
      final fallback = muscle(
        [
          set(
            session: 'fallback-secondary',
            muscle: 'triceps',
            role: RecoveryMuscleRole.secondary,
          ),
        ],
        'triceps',
      );
      final catalogWeighted = muscle(
        [
          set(
            session: 'catalog-secondary',
            muscle: 'triceps',
            role: RecoveryMuscleRole.secondary,
            catalogContribution: 0.5,
          ),
        ],
        'triceps',
      );

      expect(
        catalogWeighted.lastSessionLoad,
        greaterThan(fallback.lastSessionLoad),
      );
      expect(catalogWeighted.lastSessionLoad, closeTo(0.4, 0.0001));
    });

    test('retains several small secondary exposures instead of discarding them',
        () {
      final inputs = List.generate(
        3,
        (index) => set(
          session: 'compound',
          muscle: 'triceps',
          role: RecoveryMuscleRole.secondary,
          rir: 2,
        ),
      );

      final result = muscle(inputs, 'triceps');

      expect(result.lastSessionLoad, closeTo(0.72, 0.0001));
      expect(result.residualLoad, closeTo(0.72, 0.0001));
    });

    test('scales effort smoothly by RIR and treats failure as RIR zero', () {
      final rirZero =
          muscle([set(session: 'r0', muscle: 'chest', rir: 0)], 'chest');
      final rirTwo =
          muscle([set(session: 'r2', muscle: 'chest', rir: 2)], 'chest');
      final rirFive =
          muscle([set(session: 'r5', muscle: 'chest', rir: 5)], 'chest');
      final failure = muscle(
        [set(session: 'failure', muscle: 'chest', rir: 5, setType: 'failure')],
        'chest',
      );

      expect(rirZero.lastSessionLoad, greaterThan(rirTwo.lastSessionLoad));
      expect(rirTwo.lastSessionLoad, greaterThan(rirFive.lastSessionLoad));
      expect(failure.lastSessionLoad, closeTo(rirZero.lastSessionLoad, 0.0001));
    });

    test(
        'uses a neutral fallback and reports low confidence when RIR is absent',
        () {
      final result = muscle(
        [set(session: 'unknown-rir', muscle: 'chest', rir: null)],
        'chest',
      );

      expect(result.lastSessionLoad, closeTo(0.7, 0.0001));
      expect(result.setsWithRir, 0);
      expect(result.dataConfidence, 'low');
    });

    test('uses the workout completion time as the recovery clock', () {
      final result = muscle(
        [
          set(
            session: 'finished-two-hours-ago',
            muscle: 'chest',
            completedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        'chest',
      );

      expect(result.hoursSinceLastSession, closeTo(2.0, 0.001));
    });

    test(
        'keeps slower muscle profiles under more residual load at the same time',
        () {
      final completedAt = now.subtract(const Duration(hours: 72));
      final chest = muscle(
        [set(session: 'chest', muscle: 'chest', completedAt: completedAt)],
        'chest',
      );
      final quads = muscle(
        [set(session: 'quads', muscle: 'quads', completedAt: completedAt)],
        'quads',
      );

      expect(quads.residualLoad, greaterThan(chest.residualLoad));
      expect(quads.readinessScore, lessThan(chest.readinessScore));
    });

    test('derives state from the same score returned to presentation', () {
      final recovering = muscle(
        List.generate(
            8, (index) => set(session: 'hard', muscle: 'chest', rir: 0)),
        'chest',
      );
      final ready = muscle(
        [
          set(
            session: 'moderate-old',
            muscle: 'chest',
            completedAt: now.subtract(const Duration(hours: 40)),
          ),
        ],
        'chest',
      );

      expect(recovering.readinessScore, lessThan(60));
      expect(recovering.state, RecoveryDomainService.stateRecovering);
      expect(ready.readinessScore, inInclusiveRange(60, 85));
      expect(ready.state, RecoveryDomainService.stateReady);
    });

    test(
        'keeps movement patterns as explanation metadata without double counting',
        () {
      final result = muscle(
        [
          set(
            session: 'push',
            muscle: 'chest',
            rir: 2,
            pattern: 'horizontal_push',
          ),
        ],
        'chest',
      );

      expect(result.movementPatterns, ['horizontal_push']);
      expect(result.lastSessionDirectLoad,
          closeTo(result.lastSessionLoad, 0.0001));
    });
  });
}
