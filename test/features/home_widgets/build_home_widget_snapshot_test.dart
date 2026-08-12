import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/diary/domain/models/daily_nutrition.dart';
import 'package:train_libre/features/home_widgets/domain/build_home_widget_snapshot.dart';
import 'package:train_libre/features/home_widgets/domain/models/home_widget_snapshot.dart';
import 'package:train_libre/features/profile/domain/models/measurement.dart';
import 'package:train_libre/features/profile/domain/models/measurement_session.dart';
import 'package:train_libre/features/statistics/domain/recovery_payload_models.dart';
import 'package:train_libre/features/steps/domain/steps_models.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/generated/app_localizations_de.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/util/design_constants.dart';
import 'package:train_libre/util/l10n_ext.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final AppLocalizations l10n = AppLocalizationsDe();

  late UnitService metricUnits;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    metricUnits = UnitService();
  });

  DailyNutrition sampleNutrition() => DailyNutrition(
        calories: 1234,
        water: 1500,
        protein: 98,
        carbs: 180,
        fat: 55,
        fiber: 12.5,
        sugar: 40.25,
        salt: 3.5,
        caffeine: 90,
        targetCalories: 2000,
        targetWater: 2500,
        targetProtein: 150,
        targetCarbs: 200,
        targetFat: 60,
        targetSugar: 50,
        targetFiber: 30,
        targetSalt: 6,
        targetCaffeine: 400,
      );

  HomeWidgetSnapshot build({
    DailyNutrition? nutrition,
    String extraNutrient = 'fiber',
    UnitService? units,
    bool isAiEnabled = true,
    DateTime? now,
  }) =>
      buildHomeWidgetSnapshot(
        nutrition: nutrition ?? sampleNutrition(),
        extraNutrient: extraNutrient,
        l10n: l10n,
        unitService: units ?? metricUnits,
        isAiEnabled: isAiEnabled,
        now: now ?? DateTime(2026, 8, 10, 12, 0),
      );

  HomeWidgetTile tileOf(HomeWidgetSnapshot s, String slot) =>
      s.tiles.firstWhere((t) => t.slot == slot);

  group('logical day key', () {
    test('before 03:00 reports the previous day, matching the diary', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 8, 10, 2, 59)),
        '2026-08-09',
      );
    });

    test('at 03:00 the day has rolled over', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 8, 10, 3, 0)),
        '2026-08-10',
      );
    });

    test('midday reports the calendar day', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 8, 10, 12, 0)),
        '2026-08-10',
      );
    });

    test('rolls back across a month boundary', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 9, 1, 1, 30)),
        '2026-08-31',
      );
    });

    test('rolls back across a year boundary', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 1, 1, 0, 5)),
        '2025-12-31',
      );
    });

    test('pads single-digit months and days', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 3, 7, 12, 0)),
        '2026-03-07',
      );
    });
  });

  group('grid composition', () {
    test('produces the diary\'s six tiles in column order', () {
      expect(
        build().tiles.map((t) => t.slot).toList(),
        [
          HomeWidgetSlot.calories,
          HomeWidgetSlot.water,
          HomeWidgetSlot.extra,
          HomeWidgetSlot.protein,
          HomeWidgetSlot.carbs,
          HomeWidgetSlot.fat,
        ],
      );
    });

    test('carries localized labels rather than keys', () {
      final snapshot = build();
      expect(tileOf(snapshot, HomeWidgetSlot.calories).label, 'Kalorien');
      expect(tileOf(snapshot, HomeWidgetSlot.carbs).label, 'Kohlenhydrate');
    });

    test('reports the values and targets the diary shows', () {
      final calories = tileOf(build(), HomeWidgetSlot.calories);
      expect(calories.value, 1234);
      expect(calories.target, 2000);
      expect(calories.unit, 'kcal');
    });
  });

  group('extra nutrient slot', () {
    test('sugar', () {
      final tile = tileOf(build(extraNutrient: 'sugar'), HomeWidgetSlot.extra);
      expect(tile.label, 'Zucker');
      expect(tile.value, 40.25);
      expect(tile.target, 50);
      expect(tile.colorHex, homeWidgetColorHex(Colors.pink.shade200));
    });

    test('salt', () {
      final tile = tileOf(build(extraNutrient: 'salt'), HomeWidgetSlot.extra);
      expect(tile.label, 'Salz');
      expect(tile.value, 3.5);
      expect(tile.target, 6);
      expect(tile.colorHex, homeWidgetColorHex(Colors.grey.shade500));
    });

    test('fiber', () {
      final tile = tileOf(build(extraNutrient: 'fiber'), HomeWidgetSlot.extra);
      expect(tile.label, 'Ballaststoffe');
      expect(tile.value, 12.5);
      expect(tile.target, 30);
    });

    test('is case insensitive, like the diary widget', () {
      expect(
        tileOf(build(extraNutrient: 'SUGAR'), HomeWidgetSlot.extra).label,
        'Zucker',
      );
    });

    test('falls back to fiber for an unknown value', () {
      expect(
        tileOf(build(extraNutrient: 'nonsense'), HomeWidgetSlot.extra).label,
        'Ballaststoffe',
      );
    });
  });

  group('units', () {
    test('metric keeps millilitres', () {
      final water = tileOf(build(), HomeWidgetSlot.water);
      expect(water.unit, 'ml');
      expect(water.value, 1500);
      expect(water.target, 2500);
    });

    test('imperial converts both value and target to fluid ounces', () async {
      SharedPreferences.setMockInitialValues({'unit_system': 'imperial'});
      final imperial = UnitService();
      await imperial.setUnitSystem(UnitSystem.imperial);

      final water = tileOf(build(units: imperial), HomeWidgetSlot.water);
      expect(water.unit, 'fl oz');
      // Converted, not raw millilitres — the widget must not do this itself.
      expect(water.value, lessThan(1500));
      expect(water.value, closeTo(50.7, 0.5));
      expect(water.target, closeTo(84.5, 0.5));
    });
  });

  group('colours', () {
    test('are emitted as #RRGGBB', () {
      for (final tile in build().tiles) {
        expect(tile.colorHex, matches(RegExp(r'^#[0-9A-F]{6}$')));
      }
    });

    test('match the diary bars exactly', () {
      final snapshot = build();
      expect(
        tileOf(snapshot, HomeWidgetSlot.calories).colorHex,
        homeWidgetColorHex(Colors.orange),
      );
      expect(
        tileOf(snapshot, HomeWidgetSlot.protein).colorHex,
        homeWidgetColorHex(DesignConstants.brandRedColor),
      );
      expect(
        tileOf(snapshot, HomeWidgetSlot.fat).colorHex,
        homeWidgetColorHex(Colors.purple.shade300),
      );
    });

    test('drops the alpha channel', () {
      expect(homeWidgetColorHex(const Color(0xFF66BB6A)), '#66BB6A');
      expect(homeWidgetColorHex(const Color(0x0066BB6A)), '#66BB6A');
    });

    test('pads a colour with leading zero components', () {
      expect(homeWidgetColorHex(const Color(0xFF000102)), '#000102');
    });
  });

  group('edge cases', () {
    test('a zero target survives without dividing by zero downstream', () {
      final snapshot = build(
        nutrition: DailyNutrition(calories: 500),
      );
      final calories = tileOf(snapshot, HomeWidgetSlot.calories);
      expect(calories.target, 0);
      expect(calories.value, 500);
    });

    test('an empty day reports zeros against real targets', () {
      final snapshot = build(
        nutrition: DailyNutrition(targetCalories: 2000, targetProtein: 150),
      );
      expect(tileOf(snapshot, HomeWidgetSlot.calories).value, 0);
      expect(tileOf(snapshot, HomeWidgetSlot.calories).target, 2000);
    });

    test('carries the AI flag through for quick-action gating', () {
      expect(build(isAiEnabled: false).isAiEnabled, isFalse);
      expect(build(isAiEnabled: true).isAiEnabled, isTrue);
    });

    test('pins the rollover hour the widget must use', () {
      expect(build().rolloverHour, 3);
    });
  });

  group('json round trip', () {
    test('survives encode and decode unchanged', () {
      final original = build(extraNutrient: 'salt');
      final restored = HomeWidgetSnapshot.decode(original.encode());

      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.logicalDayKey, original.logicalDayKey);
      expect(restored.rolloverHour, original.rolloverHour);
      expect(restored.isAiEnabled, original.isAiEnabled);
      expect(restored.tiles, original.tiles);
    });

    test('declares the schema version the Swift decoder expects', () {
      expect(build().schemaVersion, 2);
    });

    test('omits the statistics sections it was not given', () {
      final json = build().toJson();

      // A section that is absent must stay absent rather than travel as null:
      // the Swift side distinguishes "no data yet" from "an empty section", and
      // the widgets render different things for the two.
      expect(json.containsKey('recovery'), isFalse);
      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('measurements'), isFalse);
      expect(json.containsKey('lastWorkout'), isFalse);
    });

    test('round trips the statistics sections', () {
      final original = buildHomeWidgetSnapshot(
        nutrition: sampleNutrition(),
        extraNutrient: 'fiber',
        l10n: l10n,
        unitService: metricUnits,
        isAiEnabled: true,
        now: DateTime(2026, 8, 10, 12, 0),
        recovery: buildHomeWidgetRecovery(
          payload: samplePayload(recovering: 6, ready: 2, fresh: 5),
          l10n: l10n,
        ),
        steps: buildHomeWidgetSteps(
          dailyTotals: [
            StepsBucket(start: DateTime(2026, 8, 9), steps: 12300),
          ],
          todaySteps: 8432,
          dailyGoal: 10000,
          isTrackingEnabled: true,
          now: DateTime(2026, 8, 10, 12, 0),
        ),
        measurements: buildHomeWidgetMeasurements(
          sessions: [
            MeasurementSession(
              id: 1,
              timestamp: DateTime(2026, 8, 1),
              measurements: [
                Measurement(
                    sessionId: 1, type: 'weight', value: 82.2, unit: 'kg'),
              ],
            ),
          ],
          l10n: l10n,
          unitService: metricUnits,
        ),
      );

      final restored = HomeWidgetSnapshot.decode(original.encode());

      expect(restored.recovery, original.recovery);
      expect(restored.steps, original.steps);
      expect(restored.measurements, original.measurements);
    });
  });

  group('recovery section', () {
    test('mirrors the card: three pills with counts and rounded shares', () {
      final recovery = buildHomeWidgetRecovery(
        payload: samplePayload(recovering: 6, ready: 2, fresh: 5),
        l10n: l10n,
      );

      expect(recovery.hasData, isTrue);
      expect(recovery.states.map((s) => s.state), [
        'recovering',
        'ready',
        'fresh',
      ]);
      expect(recovery.states.map((s) => s.count), [6, 2, 5]);
      // 6/13, 2/13, 5/13 rounded — the card's own arithmetic.
      expect(recovery.states.map((s) => s.percent), [46, 15, 38]);
      expect(recovery.states.first.label, l10n.recoveryStateRecovering);
    });

    test('carries the headline colour only when the app has one', () {
      expect(
        buildHomeWidgetRecovery(
          payload: samplePayload(
            recovering: 6,
            ready: 2,
            fresh: 5,
            overallState: 'severalRecovering',
          ),
          l10n: l10n,
        ).headlineColorHex,
        '#FF9800',
      );

      // `insufficientData` falls back to `colorScheme.outline` in the app,
      // which is a theme value the widget has to resolve for itself.
      expect(
        buildHomeWidgetRecovery(
          payload: samplePayload(
            recovering: 0,
            ready: 0,
            fresh: 0,
            hasData: false,
            overallState: 'insufficientData',
          ),
          l10n: l10n,
        ).headlineColorHex,
        isNull,
      );
    });

    test('drops the pills when there is no data to put in them', () {
      final recovery = buildHomeWidgetRecovery(
        payload: samplePayload(
          recovering: 0,
          ready: 0,
          fresh: 0,
          hasData: false,
        ),
        l10n: l10n,
      );

      expect(recovery.hasData, isFalse);
      expect(recovery.states, isEmpty);
    });
  });

  group('steps section', () {
    final now = DateTime(2026, 8, 10, 12, 0);

    test('materialises seven days, filling the gaps with zero', () {
      final steps = buildHomeWidgetSteps(
        dailyTotals: [
          StepsBucket(start: DateTime(2026, 8, 4), steps: 9100),
          // 5th–8th missing: the phone was off, or was not carried.
          StepsBucket(start: DateTime(2026, 8, 9), steps: 12300),
        ],
        todaySteps: 8432,
        dailyGoal: 10000,
        isTrackingEnabled: true,
        now: now,
      );

      expect(steps.days.length, 7);
      expect(steps.days.first.dayKey, '2026-08-04');
      expect(steps.days.last.dayKey, '2026-08-10');
      expect(steps.days.map((d) => d.steps), [9100, 0, 0, 0, 0, 12300, 8432]);
    });

    test('takes today from the live counter, not from the aggregation', () {
      final steps = buildHomeWidgetSteps(
        // A stale stored total for today — the app's own card overrides this
        // with the live count, and so does the widget.
        dailyTotals: [StepsBucket(start: DateTime(2026, 8, 10), steps: 12)],
        todaySteps: 8432,
        dailyGoal: 10000,
        isTrackingEnabled: true,
        now: now,
      );

      expect(steps.days.last.steps, 8432);
    });
  });

  group('measurements section', () {
    test('groups by type, converts units and localizes the name', () {
      final metrics = buildHomeWidgetMeasurements(
        sessions: [
          MeasurementSession(
            id: 2,
            timestamp: DateTime(2026, 8, 5),
            measurements: [
              Measurement(
                  sessionId: 2, type: 'weight', value: 81.4, unit: 'kg'),
              Measurement(sessionId: 2, type: 'waist', value: 88, unit: 'cm'),
            ],
          ),
          MeasurementSession(
            id: 1,
            timestamp: DateTime(2026, 8, 1),
            measurements: [
              Measurement(
                  sessionId: 1, type: 'weight', value: 82.2, unit: 'kg'),
            ],
          ),
        ],
        l10n: l10n,
        unitService: metricUnits,
      );

      // Weight leads regardless of the alphabet — it is the screen's own
      // default metric.
      expect(metrics.map((m) => m.id), ['weight', 'waist']);
      expect(metrics.first.name, l10n.getLocalizedMeasurementName('weight'));
      expect(metrics.first.unit, 'kg');
      // Oldest first, whatever order the sessions arrived in.
      expect(metrics.first.points.map((p) => p.value), [82.2, 81.4]);
    });

    test('keeps the recent tail whole when a series has to be thinned', () {
      final sessions = List.generate(
        400,
        (i) => MeasurementSession(
          id: i,
          timestamp: DateTime(2020, 1, 1).add(Duration(days: i)),
          measurements: [
            Measurement(
                sessionId: i, type: 'weight', value: 80 + i / 100, unit: 'kg'),
          ],
        ),
      );

      final points = buildHomeWidgetMeasurements(
        sessions: sessions,
        l10n: l10n,
        unitService: metricUnits,
      ).single.points;

      expect(
        points.length,
        homeWidgetRecentMeasurementPoints + homeWidgetHistoricMeasurementPoints,
      );
      // The newest reading must survive the thinning — it is the one the widget
      // prints as the current value.
      expect(points.last.value, closeTo(80 + 399 / 100, 1e-9));
      expect(
        points.map((p) => p.epochMs).toList(),
        orderedEquals(points.map((p) => p.epochMs).toList()..sort()),
      );
    });
  });

  group('last workout section', () {
    WorkoutLog log({
      int? id = 42,
      DateTime? endTime,
      List<SetLog> sets = const [],
      String? routineName = 'Push Day',
    }) =>
        WorkoutLog(
          id: id,
          routineName: routineName,
          startTime: DateTime(2026, 8, 9, 18, 0),
          endTime: endTime ?? DateTime(2026, 8, 9, 19, 14),
          sets: sets,
        );

    SetLog set({double? weightKg, int? reps}) => SetLog(
          workoutLogId: 42,
          exerciseName: 'Bench Press',
          setType: 'normal',
          weightKg: weightKg,
          reps: reps,
        );

    test('sums volume, reps and sets and keeps the duration', () {
      final workout = buildHomeWidgetLastWorkout(
        log: log(sets: [
          set(weightKg: 100, reps: 10),
          set(weightKg: 80, reps: 8),
        ]),
        l10n: l10n,
        unitService: metricUnits,
      )!;

      expect(workout.id, 42);
      expect(workout.title, 'Push Day');
      expect(workout.durationSeconds, 74 * 60);
      expect(workout.totalVolume, closeTo(1640, 1e-9));
      expect(workout.volumeUnit, 'kg');
      expect(workout.totalReps, 18);
      expect(workout.totalSets, 2);
    });

    test('reports no volume for a bodyweight session', () {
      final workout = buildHomeWidgetLastWorkout(
        log: log(sets: [set(reps: 12), set(weightKg: 0, reps: 15)]),
        l10n: l10n,
        unitService: metricUnits,
      )!;

      // Not 0.0: the widget swaps the tile for a rep count rather than printing
      // a bold zero at somebody who trained without weights.
      expect(workout.totalVolume, isNull);
      expect(workout.totalReps, 27);
    });

    test('falls back to the free-workout title', () {
      expect(
        buildHomeWidgetLastWorkout(
          log: log(routineName: null),
          l10n: l10n,
          unitService: metricUnits,
        )!
            .title,
        l10n.freeWorkoutTitle,
      );
    });

    test('refuses a log that cannot be linked to or timed', () {
      expect(
        buildHomeWidgetLastWorkout(
          log: log(id: null),
          l10n: l10n,
          unitService: metricUnits,
        ),
        isNull,
      );
      expect(
        buildHomeWidgetLastWorkout(
          log:
              WorkoutLog(id: 1, startTime: DateTime(2026, 8, 9), endTime: null),
          l10n: l10n,
          unitService: metricUnits,
        ),
        isNull,
      );
      expect(
        buildHomeWidgetLastWorkout(
          log: null,
          l10n: l10n,
          unitService: metricUnits,
        ),
        isNull,
      );
    });
  });
}

/// A recovery payload in the shape `getRecoveryAnalytics` returns.
RecoveryAnalyticsPayload samplePayload({
  required int recovering,
  required int ready,
  required int fresh,
  bool hasData = true,
  String overallState = 'severalRecovering',
}) =>
    RecoveryAnalyticsPayload.fromMap({
      'hasData': hasData,
      'overallState': overallState,
      'totals': {
        'recovering': recovering,
        'ready': ready,
        'fresh': fresh,
        'tracked': recovering + ready + fresh,
      },
      'muscles': const <Map<String, dynamic>>[],
    });
