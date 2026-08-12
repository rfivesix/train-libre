import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../util/l10n_ext.dart';
import '../../diary/domain/models/daily_nutrition.dart';
import '../../profile/domain/models/measurement_session.dart';
import '../../statistics/domain/recovery_domain_service.dart';
import '../../statistics/domain/recovery_payload_models.dart';
import '../../steps/domain/steps_models.dart';
import '../../workout/domain/models/workout_log.dart';
import 'models/home_widget_snapshot.dart';

/// `#RRGGBB` for the widget payload.
///
/// The widget receives the colour rather than owning a copy, so the six bars
/// cannot drift away from `NutritionSummaryWidget`.
String homeWidgetColorHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// The diary day [now] belongs to, as `yyyy-MM-dd`.
///
/// Same rule as `resolveDiaryInitialDate`: before 03:00 the diary still shows
/// the previous day.
String homeWidgetLogicalDayKey(DateTime now) {
  final base = now.hour < HomeWidgetSnapshot.diaryRolloverHour
      ? now.subtract(const Duration(days: 1))
      : now;
  final month = base.month.toString().padLeft(2, '0');
  final day = base.day.toString().padLeft(2, '0');
  return '${base.year.toString().padLeft(4, '0')}-$month-$day';
}

/// A plain calendar day as `yyyy-MM-dd`.
///
/// Distinct from [homeWidgetLogicalDayKey]: steps are counted by the calendar,
/// not by the diary's 03:00 rollover.
String homeWidgetCalendarDayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

/// Builds the payload for the "Heute im Blick" widget.
///
/// Pure: no repositories, no channels, no platform calls — everything it needs
/// arrives as an argument, which is what makes the day, unit and label logic
/// testable without a running app.
///
/// Mirrors `NutritionSummaryWidget` with `isExpandedView: false`: six tiles,
/// left column calories/water/extra, right column protein/carbs/fat.
///
/// The four statistics sections arrive already built (see [buildHomeWidgetRecovery]
/// and friends) rather than being computed here, because each of them comes from
/// a different repository and this function stays pure.
HomeWidgetSnapshot buildHomeWidgetSnapshot({
  required DailyNutrition nutrition,
  required String extraNutrient,
  required AppLocalizations l10n,
  required UnitService unitService,
  required bool isAiEnabled,
  required DateTime now,
  HomeWidgetRecovery? recovery,
  HomeWidgetSteps? steps,
  List<HomeWidgetMeasurementMetric> measurements = const [],
  HomeWidgetLastWorkout? lastWorkout,
}) {
  final liquidSuffix = unitService.suffixFor(UnitDimension.liquid);

  return HomeWidgetSnapshot(
    schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
    generatedAtEpochMs: now.millisecondsSinceEpoch.toDouble(),
    logicalDayKey: homeWidgetLogicalDayKey(now),
    rolloverHour: HomeWidgetSnapshot.diaryRolloverHour,
    isAiEnabled: isAiEnabled,
    recovery: recovery,
    steps: steps,
    measurements: measurements,
    lastWorkout: lastWorkout,
    tiles: [
      HomeWidgetTile(
        slot: HomeWidgetSlot.calories,
        label: l10n.calories,
        unit: 'kcal',
        value: nutrition.calories.toDouble(),
        target: nutrition.targetCalories.toDouble(),
        colorHex: homeWidgetColorHex(Colors.orange),
      ),
      HomeWidgetTile(
        slot: HomeWidgetSlot.water,
        label: l10n.water,
        unit: liquidSuffix,
        value: unitService.convertDisplayValue(
          nutrition.water.toDouble(),
          UnitDimension.liquid,
        ),
        target: unitService.convertDisplayValue(
          nutrition.targetWater.toDouble(),
          UnitDimension.liquid,
        ),
        colorHex: homeWidgetColorHex(Colors.blue),
      ),
      _buildExtraTile(l10n, nutrition, extraNutrient),
      HomeWidgetTile(
        slot: HomeWidgetSlot.protein,
        label: l10n.protein,
        unit: 'g',
        value: nutrition.protein.toDouble(),
        target: nutrition.targetProtein.toDouble(),
        colorHex: homeWidgetColorHex(DesignConstants.brandRedColor),
      ),
      HomeWidgetTile(
        slot: HomeWidgetSlot.carbs,
        label: l10n.carbs,
        unit: 'g',
        value: nutrition.carbs.toDouble(),
        target: nutrition.targetCarbs.toDouble(),
        colorHex: homeWidgetColorHex(Colors.green.shade400),
      ),
      HomeWidgetTile(
        slot: HomeWidgetSlot.fat,
        label: l10n.fat,
        unit: 'g',
        value: nutrition.fat.toDouble(),
        target: nutrition.targetFat.toDouble(),
        colorHex: homeWidgetColorHex(Colors.purple.shade300),
      ),
    ],
  );
}

/// The configurable third tile, matching `NutritionSummaryWidget`'s
/// `_buildExtraNutrientBar` — including its "anything else means fiber"
/// fallback.
HomeWidgetTile _buildExtraTile(
  AppLocalizations l10n,
  DailyNutrition nutrition,
  String extraNutrient,
) {
  switch (extraNutrient.toLowerCase()) {
    case 'sugar':
      return HomeWidgetTile(
        slot: HomeWidgetSlot.extra,
        label: l10n.sugar,
        unit: 'g',
        value: nutrition.sugar,
        target: nutrition.targetSugar.toDouble(),
        colorHex: homeWidgetColorHex(Colors.pink.shade200),
      );
    case 'salt':
      return HomeWidgetTile(
        slot: HomeWidgetSlot.extra,
        label: l10n.salt,
        unit: 'g',
        value: nutrition.salt,
        target: nutrition.targetSalt.toDouble(),
        colorHex: homeWidgetColorHex(Colors.grey.shade500),
      );
    default:
      return HomeWidgetTile(
        slot: HomeWidgetSlot.extra,
        label: l10n.fiber,
        unit: 'g',
        value: nutrition.fiber,
        target: nutrition.targetFiber.toDouble(),
        colorHex: homeWidgetColorHex(Colors.brown.shade400),
      );
  }
}

// ---------------------------------------------------------------------------
// Muscle Readiness
// ---------------------------------------------------------------------------

/// Flattens a [RecoveryAnalyticsPayload] into what the widget draws.
///
/// The three pills, their labels, counts, percentages and colours are all
/// resolved the same way `RecoverySectionCard` resolves them, so the widget and
/// the card can never disagree about a number.
HomeWidgetRecovery buildHomeWidgetRecovery({
  required RecoveryAnalyticsPayload payload,
  required AppLocalizations l10n,
}) {
  final totals = payload.totals;
  final total = totals.recovering + totals.ready + totals.fresh;

  HomeWidgetRecoveryState pill(String state, int count) {
    return HomeWidgetRecoveryState(
      state: state,
      label: _recoveryStateLabel(l10n, state),
      count: count,
      // Same rounding as the card's `(count / total * 100).round()`.
      percent: total > 0 ? (count / total * 100).round() : 0,
      colorHex: homeWidgetColorHex(_recoveryStateColor(state)),
    );
  }

  final overallColor = _recoveryOverallColor(payload.overallState);

  return HomeWidgetRecovery(
    hasData: payload.hasData,
    headline: _recoveryOverallLabel(l10n, payload.overallState),
    headlineColorHex:
        overallColor == null ? null : homeWidgetColorHex(overallColor),
    states: payload.hasData
        ? [
            pill(RecoveryDomainService.stateRecovering, totals.recovering),
            pill(RecoveryDomainService.stateReady, totals.ready),
            pill(RecoveryDomainService.stateFresh, totals.fresh),
          ]
        : const [],
  );
}

/// Mirrors `StatisticsPresentationFormatter.recoveryOverallLabel`.
String _recoveryOverallLabel(AppLocalizations l10n, String? state) {
  return switch (state) {
    RecoveryDomainService.overallMostlyRecovered =>
      l10n.recoveryOverallMostlyRecovered,
    RecoveryDomainService.overallMixedRecovery => l10n.recoveryOverallMixed,
    RecoveryDomainService.overallSeveralRecovering =>
      l10n.recoveryOverallSeveralRecovering,
    _ => l10n.recoveryOverallInsufficientData,
  };
}

/// Mirrors `StatisticsPresentationFormatter.recoveryOverallColor`, except that
/// the theme-dependent fallback becomes null: the widget resolves that against
/// its own colour scheme rather than being handed the app's.
Color? _recoveryOverallColor(String? state) {
  return switch (state) {
    RecoveryDomainService.overallSeveralRecovering => Colors.orange,
    RecoveryDomainService.overallMixedRecovery => Colors.blue,
    RecoveryDomainService.overallMostlyRecovered => Colors.green,
    _ => null,
  };
}

/// Mirrors `StatisticsPresentationFormatter.recoveryStateLabel`.
String _recoveryStateLabel(AppLocalizations l10n, String state) {
  return switch (state) {
    RecoveryDomainService.stateRecovering => l10n.recoveryStateRecovering,
    RecoveryDomainService.stateReady => l10n.recoveryStateReady,
    RecoveryDomainService.stateFresh => l10n.recoveryStateFresh,
    _ => l10n.recoveryStateUnknown,
  };
}

/// Mirrors `StatisticsPresentationFormatter.recoveryStateColor`. The three
/// states the widget draws are all covered, so there is no theme fallback here.
Color _recoveryStateColor(String state) {
  return switch (state) {
    RecoveryDomainService.stateRecovering => Colors.orange,
    RecoveryDomainService.stateReady => Colors.blue,
    RecoveryDomainService.stateFresh => Colors.green,
    _ => Colors.grey,
  };
}

// ---------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------

/// The seven-day steps section.
///
/// [dailyTotals] may be sparse — days the phone was off simply do not appear —
/// so the seven days ending on [now] are materialised here rather than in the
/// widget, which would otherwise have to invent a calendar of its own.
HomeWidgetSteps buildHomeWidgetSteps({
  required List<StepsBucket> dailyTotals,
  required int todaySteps,
  required int dailyGoal,
  required bool isTrackingEnabled,
  required DateTime now,
}) {
  final byDay = <String, int>{};
  for (final bucket in dailyTotals) {
    final key = homeWidgetCalendarDayKey(bucket.start);
    byDay[key] = (byDay[key] ?? 0) + bucket.steps;
  }

  final today = DateTime(now.year, now.month, now.day);
  final days = List.generate(7, (i) {
    final date = today.subtract(Duration(days: 6 - i));
    final key = homeWidgetCalendarDayKey(date);
    return HomeWidgetStepsDay(
      dayKey: key,
      // Today comes from the live counter rather than the stored aggregation,
      // exactly as `StatisticsStepsCard` injects it into its last bar.
      steps: i == 6 ? todaySteps : (byDay[key] ?? 0),
    );
  });

  return HomeWidgetSteps(
    isTrackingEnabled: isTrackingEnabled,
    todaySteps: todaySteps,
    dailyGoal: dailyGoal,
    days: days,
  );
}

// ---------------------------------------------------------------------------
// Measurements
// ---------------------------------------------------------------------------

/// How many metrics travel at most. Well past the fourteen the app offers, but
/// a bound the App Group payload can rely on.
const int homeWidgetMaxMeasurementMetrics = 16;

/// Recent points kept verbatim per metric.
const int homeWidgetRecentMeasurementPoints = 120;

/// Older points kept, evenly spaced, so "Max" still has a shape.
const int homeWidgetHistoricMeasurementPoints = 40;

/// Turns the measurement history into one series per metric.
///
/// Values are converted into the user's display units and the names localized
/// here, so the widget never has to know that `left_bicep` is a thing.
List<HomeWidgetMeasurementMetric> buildHomeWidgetMeasurements({
  required List<MeasurementSession> sessions,
  required AppLocalizations l10n,
  required UnitService unitService,
}) {
  final byType = <String, List<HomeWidgetMeasurementPoint>>{};

  final ordered = sessions.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  for (final session in ordered) {
    final epochMs = session.timestamp.millisecondsSinceEpoch.toDouble();
    for (final measurement in session.measurements) {
      byType.putIfAbsent(measurement.type, () => []).add(
            HomeWidgetMeasurementPoint(
              epochMs: epochMs,
              value: _displayMeasurementValue(
                measurement.type,
                measurement.value,
                unitService,
              ),
            ),
          );
    }
  }

  // Weight first — it is the app's own default metric — then alphabetically by
  // key, matching `_availableMeasurementTypes..sort()`.
  final types = byType.keys.toList()..sort();
  if (types.remove('weight')) types.insert(0, 'weight');

  return types.take(homeWidgetMaxMeasurementMetrics).map((type) {
    return HomeWidgetMeasurementMetric(
      id: type,
      name: l10n.getLocalizedMeasurementName(type),
      unit: _measurementUnit(type, unitService),
      points: _thinMeasurementPoints(byType[type]!),
    );
  }).toList();
}

/// Caps a series without flattening the recent past.
///
/// A uniform decimation would thin out the last seven days as aggressively as
/// the last seven years, which is backwards: the short timeframes are the ones
/// the widget renders most often. So the tail is kept whole and only the older
/// history is sampled.
List<HomeWidgetMeasurementPoint> _thinMeasurementPoints(
  List<HomeWidgetMeasurementPoint> points,
) {
  if (points.length <= homeWidgetRecentMeasurementPoints) return points;

  final splitAt = points.length - homeWidgetRecentMeasurementPoints;
  final recent = points.sublist(splitAt);
  final older = points.sublist(0, splitAt);

  if (older.length <= homeWidgetHistoricMeasurementPoints) {
    return [...older, ...recent];
  }

  final step = older.length / homeWidgetHistoricMeasurementPoints;
  final sampled = [
    for (var i = 0; i < homeWidgetHistoricMeasurementPoints; i++)
      older[(i * step).floor()],
  ];
  return [...sampled, ...recent];
}

/// Mirrors `MeasurementsScreen._displayMeasurementValue`.
double _displayMeasurementValue(
  String type,
  double value,
  UnitService unitService,
) {
  if (type == 'weight') {
    return unitService.convertDisplayValue(value, UnitDimension.weight);
  }
  if (_circumferenceMeasurementTypes.contains(type)) {
    return unitService.convertDisplayValue(value, UnitDimension.height);
  }
  return value;
}

/// Mirrors `MeasurementsScreen._getMeasurementUnit`.
String _measurementUnit(String type, UnitService unitService) {
  if (type == 'weight') return unitService.suffixFor(UnitDimension.weight);
  if (type == 'fat_percent') return '%';
  if (_circumferenceMeasurementTypes.contains(type)) {
    return unitService.suffixFor(UnitDimension.height);
  }
  return '';
}

const Set<String> _circumferenceMeasurementTypes = {
  'neck',
  'shoulder',
  'chest',
  'left_bicep',
  'right_bicep',
  'left_forearm',
  'right_forearm',
  'abdomen',
  'waist',
  'hips',
  'left_thigh',
  'right_thigh',
  'left_calf',
  'right_calf',
};

// ---------------------------------------------------------------------------
// Last workout
// ---------------------------------------------------------------------------

/// The finished workout the widget shows, with the same three metrics
/// `WorkoutSummaryBar` shows on the detail screen.
///
/// Returns null for a log without an id or an end time — neither can be linked
/// to or timed, and half a card is worse than the empty state.
HomeWidgetLastWorkout? buildHomeWidgetLastWorkout({
  required WorkoutLog? log,
  required AppLocalizations l10n,
  required UnitService unitService,
  String? heatmapImageName,
}) {
  if (log == null) return null;
  final id = log.id;
  final endTime = log.endTime;
  if (id == null || endTime == null) return null;

  var volumeKg = 0.0;
  var reps = 0;
  var hasWeightedSet = false;
  for (final set in log.sets) {
    final weight = set.weightKg ?? 0;
    final setReps = set.reps ?? 0;
    reps += setReps;
    volumeKg += weight * setReps;
    if (weight > 0) hasWeightedSet = true;
  }

  return HomeWidgetLastWorkout(
    id: id,
    title: log.routineName ?? l10n.freeWorkoutTitle,
    completedAtEpochMs: endTime.millisecondsSinceEpoch.toDouble(),
    durationSeconds: endTime.difference(log.startTime).inSeconds,
    // A pure calisthenics session has no volume to speak of, and a bold `0 kg`
    // reads as a failure rather than as "this was bodyweight work".
    totalVolume: hasWeightedSet
        ? unitService.convertDisplayValue(volumeKg, UnitDimension.weight)
        : null,
    volumeUnit: unitService.suffixFor(UnitDimension.weight),
    totalReps: reps,
    totalSets: log.sets.length,
    heatmapImageName: heatmapImageName,
  );
}
