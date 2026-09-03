import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/classification/set_load.dart';

/// How much a set actually loaded the muscle.
///
/// The number in the weight column is not the answer for two of the six
/// tracking types: a pull-up moves the user's own body, and an assistance
/// machine's number is subtracted from it rather than added to it.
void main() {
  BodyweightHistory history(List<(String, double)> entries) =>
      BodyweightHistory.fromRows(
        entries.map((e) => (date: DateTime.parse(e.$1), kg: e.$2)),
      );

  group('body weight over time', () {
    final recorded = history([
      ('2026-01-01', 82),
      ('2026-04-01', 78),
      ('2026-08-01', 75),
    ]);

    test('a set is valued at the weight recorded on its own day', () {
      expect(recorded.at(DateTime.parse('2026-02-15')), 82);
      expect(recorded.at(DateTime.parse('2026-05-15')), 78);
      expect(recorded.at(DateTime.parse('2026-09-01')), 75);
    });

    test('the measurement day itself counts', () {
      expect(recorded.at(DateTime.parse('2026-04-01')), 78);
    });

    test('a set from before the first measurement has no body weight', () {
      // Deliberately not extrapolated backwards. Guessing here would be
      // invisible in the result and would only ever affect the oldest data,
      // which is the hardest place to notice it being wrong.
      expect(recorded.at(DateTime.parse('2025-12-31')), isNull);
    });

    test('no measurements at all yields null, never a default', () {
      expect(BodyweightHistory.empty.at(DateTime.now()), isNull);
    });

    test('losing weight does not rewrite older sessions', () {
      // The whole reason for dating this. A user who drops seven kilos must
      // not see every past pull-up session shrink.
      final januarySet = setTonnageKg(
        trackingType: 'bodyweight_reps',
        loadMode: 'bodyweight',
        loggedWeightKg: null,
        reps: 10,
        bodyweightKg: recorded.at(DateTime.parse('2026-01-15')),
      );
      expect(januarySet, 820);

      final withMoreMeasurements = history([
        ('2026-01-01', 82),
        ('2026-04-01', 78),
        ('2026-08-01', 75),
        ('2026-09-01', 70),
      ]);
      expect(
        setTonnageKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: null,
          reps: 10,
          bodyweightKg: withMoreMeasurements.at(DateTime.parse('2026-01-15')),
        ),
        januarySet,
      );
    });

    test('entries are sorted and zero weights ignored', () {
      final messy = history([
        ('2026-08-01', 75),
        ('2026-01-01', 82),
        ('2026-04-01', 0),
      ]);
      expect(messy.at(DateTime.parse('2026-05-01')), 82);
    });
  });

  group('effective load', () {
    test('an ordinary lift is the number entered', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'weight_reps',
          loadMode: 'external',
          loggedWeightKg: 60,
          bodyweightKg: 80,
        ),
        60,
      );
    });

    test('a body-weight set is the user, plus anything added', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: null,
          bodyweightKg: 80,
        ),
        80,
      );
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: 20,
          bodyweightKg: 80,
        ),
        100,
      );
    });

    test('an empty added-weight field is not a zero-kilogram lift', () {
      final unweighted = effectiveSetLoadKg(
        trackingType: 'bodyweight_reps',
        loadMode: 'bodyweight',
        loggedWeightKg: null,
        bodyweightKg: 80,
      );
      expect(unweighted, isNot(0));
      expect(unweighted, greaterThan(0));
    });

    test('with no recorded body weight only the added weight counts', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: 20,
          bodyweightKg: null,
        ),
        20,
      );
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: null,
          bodyweightKg: null,
        ),
        isNull,
        reason: 'nothing to count, and nothing to guess from',
      );
    });

    test('an assistance machine subtracts', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'assisted',
          loggedWeightKg: 30,
          bodyweightKg: 80,
        ),
        50,
      );
    });

    test('more assistance means less load, not more', () {
      final light = effectiveSetLoadKg(
        trackingType: 'bodyweight_reps',
        loadMode: 'assisted',
        loggedWeightKg: 20,
        bodyweightKg: 80,
      )!;
      final heavy = effectiveSetLoadKg(
        trackingType: 'bodyweight_reps',
        loadMode: 'assisted',
        loggedWeightKg: 40,
        bodyweightKg: 80,
      )!;
      expect(heavy, lessThan(light),
          reason: 'this is the sign error the whole field exists to prevent');
    });

    test('assistance beyond body weight is not negative load', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'assisted',
          loggedWeightKg: 90,
          bodyweightKg: 80,
        ),
        isNull,
      );
    });

    test('an assisted set without a recorded body weight is uncountable', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'assisted',
          loggedWeightKg: 30,
          bodyweightKg: null,
        ),
        isNull,
      );
    });

    test('a plank has no load figure', () {
      expect(
        effectiveSetLoadKg(
          trackingType: 'time',
          loadMode: 'bodyweight',
          loggedWeightKg: null,
          bodyweightKg: 80,
        ),
        80,
        reason: 'load_mode bodyweight still means the body is the load',
      );
      expect(
        effectiveSetLoadKg(
          trackingType: 'time',
          loadMode: 'external',
          loggedWeightKg: null,
          bodyweightKg: 80,
        ),
        isNull,
      );
    });
  });

  group('tonnage', () {
    test('a pull-up is body weight times reps', () {
      expect(
        setTonnageKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: null,
          reps: 10,
          bodyweightKg: 80,
        ),
        800,
      );
    });

    test('a weighted pull-up adds the belt', () {
      expect(
        setTonnageKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: 20,
          reps: 10,
          bodyweightKg: 80,
        ),
        1000,
      );
    });

    test('an assisted set counts what was left to lift', () {
      expect(
        setTonnageKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'assisted',
          loggedWeightKg: 30,
          reps: 10,
          bodyweightKg: 80,
        ),
        500,
      );
    });

    test('no reps means no tonnage', () {
      for (final reps in [null, 0]) {
        expect(
          setTonnageKg(
            trackingType: 'weight_reps',
            loadMode: 'external',
            loggedWeightKg: 60,
            reps: reps,
            bodyweightKg: 80,
          ),
          0,
        );
      }
    });

    test('an uncountable set is zero, not an exception', () {
      expect(
        setTonnageKg(
          trackingType: 'bodyweight_reps',
          loadMode: 'bodyweight',
          loggedWeightKg: null,
          reps: 10,
          bodyweightKg: null,
        ),
        0,
      );
    });
  });
}
