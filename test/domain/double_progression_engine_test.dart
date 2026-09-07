import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/progression/double_progression_engine.dart';

void main() {
  final now = DateTime(2026, 9, 7, 12, 0);
  const standardRange = RepRange(8, 12);
  const barbellInc = LoadIncrement.barbellMetric; // 2.5 kg

  group('DoubleProgressionEngine - 10 Rules', () {
    test('Rule 1: RIR is optional and missing RIR does not block progression',
        () {
      final date = now.subtract(const Duration(days: 3));

      // Without RIR
      final historyNoRir = ExerciseProgressionHistory([
        ProgressionSetEntry(
          performedAt: date,
          weight: 80.0,
          reps: 12,
          setType: 'normal',
          rir: null,
        ),
        ProgressionSetEntry(
          performedAt: date,
          weight: 80.0,
          reps: 12,
          setType: 'normal',
          rir: null,
        ),
      ]);

      final resultNoRir = nextPrescription(
        history: historyNoRir,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(resultNoRir.outcome, equals(ProgressionOutcome.raise));
      expect(resultNoRir.targetWeight, equals(82.5));
      expect(resultNoRir.targetReps, equals(8));

      // With RIR
      final historyWithRir = ExerciseProgressionHistory([
        ProgressionSetEntry(
          performedAt: date,
          weight: 80.0,
          reps: 12,
          setType: 'normal',
          rir: 2,
        ),
        ProgressionSetEntry(
          performedAt: date,
          weight: 80.0,
          reps: 12,
          setType: 'normal',
          rir: 1,
        ),
      ]);

      final resultWithRir = nextPrescription(
        history: historyWithRir,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(resultWithRir.outcome, equals(ProgressionOutcome.raise));
      expect(resultWithRir.targetWeight, equals(82.5));
      expect(resultWithRir.targetReps, equals(8));
    });

    test(
        'Rule 2: Range is topped out only when ALL working sets in the same session reach upper bound',
        () {
      final date = now.subtract(const Duration(days: 2));

      // All 3 sets reach range.max (12)
      final allToppedOutHistory = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
      ]);

      final resultAll = nextPrescription(
        history: allToppedOutHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );
      expect(resultAll.outcome, equals(ProgressionOutcome.raise));
      expect(resultAll.targetWeight, equals(102.5));

      // Only 2 of 3 reach range.max (one is 10)
      final partialHistory = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 10, setType: 'normal'),
      ]);

      final resultPartial = nextPrescription(
        history: partialHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );
      expect(resultPartial.outcome, equals(ProgressionOutcome.hold));
      expect(resultPartial.targetWeight, equals(100.0));
      expect(resultPartial.reason,
          equals(ProgressionReason.repsInRangeNotToppedOut));
    });

    test('Rule 3: Warm-up sets (setType warmup) never influence progression',
        () {
      final date = now.subtract(const Duration(days: 2));

      // Warmup set with 20 reps followed by 2 working sets of 12 reps
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 40.0, reps: 20, setType: 'warmup'),
        ProgressionSetEntry(
            performedAt: date, weight: 80.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 80.0, reps: 12, setType: 'normal'),
      ]);

      final result = nextPrescription(
        history: history,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(82.5));
      expect(result.targetReps, equals(8));

      // History with ONLY warmup sets yields no suggestion
      final onlyWarmupHistory = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 40.0, reps: 20, setType: 'warmup'),
      ]);
      final warmupOnlyResult = nextPrescription(
        history: onlyWarmupHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );
      expect(warmupOnlyResult.outcome, equals(ProgressionOutcome.noSuggestion));
      expect(warmupOnlyResult.reason, equals(ProgressionReason.noHistory));
    });

    test('Rule 4: Failure sets count as working sets, drop sets never count',
        () {
      final date = now.subtract(const Duration(days: 2));

      // Normal + Failure both reaching 12 reps -> raise
      final failureSuccessHistory = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 90.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 90.0, reps: 12, setType: 'failure'),
      ]);

      final failureResult = nextPrescription(
        history: failureSuccessHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );
      expect(failureResult.outcome, equals(ProgressionOutcome.raise));
      expect(failureResult.targetWeight, equals(92.5));

      // Drop sets are ignored: 2 topped out normal sets + 1 dropset with 15 reps
      final dropSetHistory = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 90.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 90.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 60.0, reps: 15, setType: 'dropset'),
      ]);

      final dropSetResult = nextPrescription(
        history: dropSetHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );
      expect(dropSetResult.outcome, equals(ProgressionOutcome.raise));
      expect(dropSetResult.targetWeight, equals(92.5));
    });

    test(
        'Rule 5: On topping out, load raises by one increment and reps reset to range.min',
        () {
      final date = now.subtract(const Duration(days: 1));

      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 60.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 60.0, reps: 12, setType: 'normal'),
      ]);

      final result = nextPrescription(
        history: history,
        range: const RepRange(8, 12),
        increment: const LoadIncrement(2.0, unit: 'kg'), // dumbbell increment
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(62.0));
      expect(result.targetReps, equals(8));
      expect(result.reason, equals(ProgressionReason.rangeToppedOut));
      expect(result.algorithmVersion,
          equals(DoubleProgressionEngine.algorithmVersion));
    });

    test(
        'Rule 6: After a gap of more than 3 weeks (21 days), load is held at last performed value',
        () {
      // 25 days ago (more than 21 days)
      final date = now.subtract(const Duration(days: 25));

      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 100.0, reps: 12, setType: 'normal'),
      ]);

      final result = nextPrescription(
        history: history,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.hold));
      expect(result.targetWeight, equals(100.0));
      expect(result.reason, equals(ProgressionReason.breakExceededThreeWeeks));
    });

    test(
        'Rule 7: When reps fall below range.min, suggestion does not rise and does not fall automatically',
        () {
      final date = now.subtract(const Duration(days: 3));

      // Reps: 6 and 7 (both below range.min of 8)
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 80.0, reps: 6, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 80.0, reps: 7, setType: 'normal'),
      ]);

      final result = nextPrescription(
        history: history,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.hold));
      expect(result.targetWeight,
          equals(80.0)); // Remains unchanged (no automatic deload)
      expect(result.reason, equals(ProgressionReason.repsBelowRangeMin));
    });

    test('Rule 8: In assisted mode, progression reduces assistance load', () {
      final date = now.subtract(const Duration(days: 2));

      // Topped out with 30kg counter-weight assistance
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 30.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 30.0, reps: 12, setType: 'normal'),
      ]);

      final result = nextPrescription(
        history: history,
        range: standardRange,
        increment: LoadIncrement.assistedMetric, // 2.5 kg
        loadMode: LoadMode.assisted,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(27.5)); // 30.0 - 2.5 = 27.5 kg
      expect(result.targetReps, equals(8));
      expect(result.reason, equals(ProgressionReason.rangeToppedOut));

      // Floor at 0.0 kg assistance
      final historyNearZero = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 1.5, reps: 12, setType: 'normal'),
      ]);
      final resultNearZero = nextPrescription(
        history: historyNearZero,
        range: standardRange,
        increment: LoadIncrement.assistedMetric,
        loadMode: LoadMode.assisted,
        now: now,
      );
      expect(resultNearZero.targetWeight, equals(0.0));
    });

    test('Rule 9: No history yields noSuggestion with reason', () {
      final emptyHistory = const ExerciseProgressionHistory([]);

      final result = nextPrescription(
        history: emptyHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.noSuggestion));
      expect(result.targetWeight, isNull);
      expect(result.targetReps, isNull);
      expect(result.reason, equals(ProgressionReason.noHistory));
    });

    test(
        'Rule 10: Auto-filled sets do not trigger an unearned raise and hold current load',
        () {
      final date = now.subtract(const Duration(days: 2));

      // Both sets have 12 reps, but valuesAutoFilled is true
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
          performedAt: date,
          weight: 80.0,
          reps: 12,
          setType: 'normal',
          valuesAutoFilled: true,
        ),
        ProgressionSetEntry(
          performedAt: date,
          weight: 80.0,
          reps: 12,
          setType: 'normal',
          valuesAutoFilled: true,
        ),
      ]);

      final result = nextPrescription(
        history: history,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.hold));
      expect(result.targetWeight, equals(80.0));
      expect(result.reason, equals(ProgressionReason.autoFilledSets));
    });
  });

  group('DoubleProgressionEngine - Additional Required Combination Tests', () {
    test('All sets reach upper bound -> raise', () {
      final date = now.subtract(const Duration(days: 1));
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(performedAt: date, weight: 70.0, reps: 12),
        ProgressionSetEntry(performedAt: date, weight: 70.0, reps: 12),
      ]);

      final result = nextPrescription(
        history: history,
        range: const RepRange(8, 12),
        increment: LoadIncrement.barbellMetric,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(72.5));
      expect(result.targetReps, equals(8));
    });

    test('Only one set reaches upper bound, another does not -> hold', () {
      final date = now.subtract(const Duration(days: 1));
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(performedAt: date, weight: 70.0, reps: 12),
        ProgressionSetEntry(performedAt: date, weight: 70.0, reps: 9),
      ]);

      final result = nextPrescription(
        history: history,
        range: const RepRange(8, 12),
        increment: LoadIncrement.barbellMetric,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.hold));
      expect(result.targetWeight, equals(70.0));
      expect(result.reason, equals(ProgressionReason.repsInRangeNotToppedOut));
    });

    test('Mixed with warmup and dropsets correctly ignored -> raise', () {
      final date = now.subtract(const Duration(days: 2));
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 30.0, reps: 15, setType: 'warmup'),
        ProgressionSetEntry(
            performedAt: date, weight: 70.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 70.0, reps: 12, setType: 'failure'),
        ProgressionSetEntry(
            performedAt: date, weight: 50.0, reps: 10, setType: 'dropset'),
      ]);

      final result = nextPrescription(
        history: history,
        range: const RepRange(8, 12),
        increment: LoadIncrement.barbellMetric,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(72.5));
      expect(result.targetReps, equals(8));
    });

    test('History consisting only of autoFilled sets -> hold (no raise)', () {
      final date = now.subtract(const Duration(days: 1));
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
          performedAt: date,
          weight: 50.0,
          reps: 12,
          setType: 'normal',
          valuesAutoFilled: true,
        ),
      ]);

      final result = nextPrescription(
        history: history,
        range: const RepRange(8, 12),
        increment: LoadIncrement.barbellMetric,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.hold));
      expect(result.targetWeight, equals(50.0));
      expect(result.reason, equals(ProgressionReason.autoFilledSets));
    });

    test('Assisted exercise: topping out reduces load', () {
      final date = now.subtract(const Duration(days: 1));
      final history = ExerciseProgressionHistory([
        ProgressionSetEntry(
            performedAt: date, weight: 25.0, reps: 12, setType: 'normal'),
        ProgressionSetEntry(
            performedAt: date, weight: 25.0, reps: 12, setType: 'normal'),
      ]);

      final result = nextPrescription(
        history: history,
        range: const RepRange(8, 12),
        increment: LoadIncrement.assistedMetric,
        loadMode: LoadMode.assisted,
        now: now,
      );

      expect(result.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(22.5));
      expect(result.targetReps, equals(8));
    });

    test(
        'Boundary test: exactly 3 weeks (21 days) allows raise; 3 weeks and 1 day (22 days) triggers hold',
        () {
      // Exactly 21 days ago
      final exact21DaysHistory = ExerciseProgressionHistory([
        ProgressionSetEntry(
          performedAt: now.subtract(const Duration(days: 21)),
          weight: 80.0,
          reps: 12,
          setType: 'normal',
        ),
      ]);

      final exactResult = nextPrescription(
        history: exact21DaysHistory,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      // Exactly 3 weeks is NOT more than 3 weeks -> raises
      expect(exactResult.outcome, equals(ProgressionOutcome.raise));
      expect(exactResult.targetWeight, equals(82.5));

      // 21 days + 1 day = 22 days ago (more than 3 weeks)
      final day22History = ExerciseProgressionHistory([
        ProgressionSetEntry(
          performedAt: now.subtract(const Duration(days: 22)),
          weight: 80.0,
          reps: 12,
          setType: 'normal',
        ),
      ]);

      final day22Result = nextPrescription(
        history: day22History,
        range: standardRange,
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      // More than 3 weeks -> hold
      expect(day22Result.outcome, equals(ProgressionOutcome.hold));
      expect(day22Result.targetWeight, equals(80.0));
      expect(day22Result.reason,
          equals(ProgressionReason.breakExceededThreeWeeks));
    });
  });

  group('LoadIncrement static table', () {
    test('resolves metric equipment increments', () {
      expect(LoadIncrement.fromEquipment('Langhantel', isMetric: true).value,
          equals(2.5));
      expect(
          LoadIncrement.fromEquipment('Barbell Bench Press', isMetric: true)
              .value,
          equals(2.5));
      expect(LoadIncrement.fromEquipment('Kurzhantel', isMetric: true).value,
          equals(2.0));
      expect(
          LoadIncrement.fromEquipment('Dumbbell Flyes', isMetric: true).value,
          equals(2.0));
      expect(LoadIncrement.fromEquipment('Maschine', isMetric: true).value,
          equals(5.0));
      expect(
          LoadIncrement.fromEquipment('Leg Press Machine', isMetric: true)
              .value,
          equals(5.0));
      expect(LoadIncrement.fromEquipment('Kabel', isMetric: true).value,
          equals(2.5));
      expect(
          LoadIncrement.fromEquipment('Cable Crossover', isMetric: true).value,
          equals(2.5));
      expect(
          LoadIncrement.fromEquipment('Assisted Dip Machine', isMetric: true)
              .value,
          equals(2.5));
      expect(LoadIncrement.fromEquipment('Bodyweight', isMetric: true).value,
          equals(2.5));
      expect(
          LoadIncrement.fromEquipment(null, isMetric: true).value, equals(2.5));
    });

    test('resolves imperial equipment increments', () {
      expect(LoadIncrement.fromEquipment('barbell', isMetric: false).value,
          equals(5.0));
      expect(LoadIncrement.fromEquipment('dumbbell', isMetric: false).value,
          equals(5.0));
      expect(LoadIncrement.fromEquipment('machine', isMetric: false).value,
          equals(10.0));
      expect(LoadIncrement.fromEquipment('cable', isMetric: false).value,
          equals(5.0));
      expect(LoadIncrement.fromEquipment('assisted', isMetric: false).value,
          equals(5.0));
      expect(LoadIncrement.fromEquipment(null, isMetric: false).value,
          equals(5.0));
    });
  });

  group('Position-aware prescriptions', () {
    List<WorkingSetPosition> positions() => const [
          WorkingSetPosition(id: 'top', range: RepRange(8, 12)),
          WorkingSetPosition(id: 'backoff', range: RepRange(8, 12)),
        ];

    test('preserves an ascending or top-set/back-off structure while holding',
        () {
      final suggestions = nextPrescriptions(
        history: ExerciseProgressionHistory([
          ProgressionSetEntry(
            performedAt: now.subtract(const Duration(days: 2)),
            weight: 30,
            reps: 12,
            order: 1,
          ),
          ProgressionSetEntry(
            performedAt: now.subtract(const Duration(days: 2)),
            weight: 35,
            reps: 8,
            order: 2,
          ),
        ]),
        positions: positions(),
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(suggestions.map((suggestion) => suggestion.targetWeight),
          equals([30, 35]));
      expect(suggestions.map((suggestion) => suggestion.targetReps),
          equals([12, 9]));
      expect(suggestions.every((s) => s.outcome == ProgressionOutcome.hold),
          isTrue);
    });

    test('raises every corresponding position only after all are topped out',
        () {
      final suggestions = nextPrescriptions(
        history: ExerciseProgressionHistory([
          ProgressionSetEntry(
            performedAt: now.subtract(const Duration(days: 2)),
            weight: 35,
            reps: 12,
            order: 1,
          ),
          ProgressionSetEntry(
            performedAt: now.subtract(const Duration(days: 2)),
            weight: 30,
            reps: 12,
            order: 2,
          ),
        ]),
        positions: positions(),
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(suggestions.map((suggestion) => suggestion.targetWeight),
          equals([37.5, 32.5]));
      expect(suggestions.map((suggestion) => suggestion.targetReps),
          equals([8, 8]));
    });

    test('a position without a range repeats its load but never raises it', () {
      final suggestions = nextPrescriptions(
        history: ExerciseProgressionHistory([
          ProgressionSetEntry(
            performedAt: now.subtract(const Duration(days: 2)),
            weight: 35,
            reps: 12,
          ),
        ]),
        positions: const [WorkingSetPosition(id: 'one')],
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(suggestions.single.targetWeight, equals(35));
      expect(suggestions.single.targetReps, equals(12));
      expect(suggestions.single.outcome, equals(ProgressionOutcome.hold));
      expect(suggestions.single.reason, equals(ProgressionReason.noRepRange));
    });

    test('does not offer an initial value after the history window', () {
      final suggestions = nextPrescriptions(
        history: ExerciseProgressionHistory([
          ProgressionSetEntry(
            performedAt: now.subtract(const Duration(days: 22)),
            weight: 35,
            reps: 12,
          ),
        ]),
        positions: const [
          WorkingSetPosition(id: 'one', range: RepRange(8, 12)),
        ],
        increment: barbellInc,
        loadMode: LoadMode.external,
        now: now,
      );

      expect(
          suggestions.single.outcome, equals(ProgressionOutcome.noSuggestion));
      expect(suggestions.single.targetWeight, isNull);
      expect(suggestions.single.reason,
          equals(ProgressionReason.breakExceededThreeWeeks));
    });
  });
}
