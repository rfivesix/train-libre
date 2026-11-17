import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/sleep/domain/scoring/sleep_scoring_engine.dart';

void main() {
  group('Sleep score v4', () {
    test('requires duration; missing values are not zeroes', () {
      final result = calculateSleepScore(const SleepScoringInput());
      expect(result.score, isNull);
      expect(result.state, SleepScoreState.unavailable);
      expect(result.continuityScore, isNull);
      expect(result.deepScore, isNull);
      expect(result.remScore, isNull);
      expect(result.completeness, 0);
      expect(
        calculateSleepScore(const SleepScoringInput(durationMinutes: 0)).score,
        isNull,
      );
    });

    test('duration-only score is a partial-data estimate', () {
      final result = calculateSleepScore(
        const SleepScoringInput(durationMinutes: 360),
      );
      expect(result.score, 75);
      expect(result.completeness, closeTo(.45, .00001));
      expect(result.continuityScore, isNull);
      expect(result.regularityScore, isNull);
    });

    test('short sleep cannot be rescued by excellent secondary values', () {
      final result = calculateSleepScore(
        const SleepScoringInput(
          durationMinutes: 240,
          sleepEfficiencyPct: 100,
          wasoMinutes: 0,
          deepSleepPct: 50,
          remSleepPct: 50,
          rollingMidSleepSd: 0,
          regularityValidDays: 7,
        ),
      );
      expect(result.score, 65);
      expect(result.durationScoreCap, 65);
      expect(result.dynamicMultiplier, isNull);
      expect(result.completeness, closeTo(1, .00001));
    });

    test('clock time is not a penalty and long sleep has no cliff', () {
      SleepScoringResult score(int minutes, double onset) =>
          calculateSleepScore(
            SleepScoringInput(
              durationMinutes: minutes,
              sleepOnsetHourLocal: onset,
            ),
          );
      expect(score(480, 23).score, score(480, 3).score);
      expect(score(630, 23).score, score(631, 23).score);
      expect(score(631, 23).score, 100);
    });

    test(
      'stages are independent and unspecified sleep does not invent phases',
      () {
        final known = calculateSleepScore(
          const SleepScoringInput(
            durationMinutes: 480,
            deepSleepPct: 0,
            remSleepPct: 20,
          ),
        );
        expect(known.deepScore, 0);
        expect(known.remScore, 96);
        final partial = calculateSleepScore(
          const SleepScoringInput(
            durationMinutes: 480,
            deepSleepPct: 10,
            remSleepPct: 20,
            asleepUnspecifiedPct: 50,
          ),
        );
        expect(partial.deepScore, isNull);
        expect(partial.remScore, isNull);
        expect(partial.completeness, closeTo(.45, .00001));
        final unknown = calculateSleepScore(
          const SleepScoringInput(
            durationMinutes: 480,
            deepSleepPct: 10,
            hasIncompleteStageCoverage: true,
          ),
        );
        expect(unknown.deepScore, isNull);
      },
    );

    test(
      'regularity needs enough days; serialized result remains readable',
      () {
        final early = calculateSleepScore(
          const SleepScoringInput(
            durationMinutes: 480,
            rollingMidSleepSd: 1,
            regularityValidDays: 4,
          ),
        );
        expect(early.regularityScore, isNull);
        final ready = calculateSleepScore(
          const SleepScoringInput(
            durationMinutes: 480,
            rollingMidSleepSd: 1,
            regularityValidDays: 5,
          ),
        );
        expect(ready.regularityScore, 50);
        expect(ready.regularityUsed, isTrue);
        expect(ready.regularityStable, isFalse);
        expect(SleepScoringResult.fromJson(ready.toJson()).score, ready.score);
      },
    );
  });
}
