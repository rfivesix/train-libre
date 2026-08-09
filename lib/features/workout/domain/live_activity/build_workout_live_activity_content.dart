import 'package:intl/intl.dart';

import '../../../../services/unit_service.dart';
import '../models/routine_exercise.dart';
import '../models/set_log.dart';
import '../models/set_template.dart';
import 'workout_live_activity_content.dart';
import 'workout_live_activity_strings.dart';

/// Set-type badge characters and colors. The colors mirror `SetTypeChip` so
/// the Live Activity and the live workout screen never disagree.
///
/// The letters differ from `SetTypeChip` in one place: normal sets show `N`
/// here rather than the set number, because the Live Activity already spells
/// the position out as "Set x of y" right next to it. `superset` and `other`
/// have no entry in `SetTypeChip` yet and stay neutral until the app defines
/// them.
const String _colorWarmup = '#FF9800';
const String _colorFailure = '#E5253A';
const String _colorDropset = '#2196F3';
const String _colorNeutral = '#8E8E93';

/// Builds the Live Activity content for the current workout state.
///
/// Pure and context-free so it can be unit tested without a widget tree.
/// Everything it returns is display-ready: no unit conversion, no number
/// formatting and no localization happens on the Swift side.
WorkoutLiveActivityContent buildWorkoutLiveActivityContent({
  required List<RoutineExercise> exercises,
  required Map<int, SetLog> setLogs,
  required UnitService unitService,
  required WorkoutLiveActivityStrings strings,
  required String localeName,
  DateTime? restEndsAt,
  DateTime? restStartedAt,
}) {
  final next = _findNextSet(exercises, setLogs);

  if (exercises.isEmpty) {
    return const WorkoutLiveActivityContent(
      phase: WorkoutLiveActivityPhase.empty,
    );
  }

  if (next == null) {
    return const WorkoutLiveActivityContent(
      phase: WorkoutLiveActivityPhase.noSetsLeft,
    );
  }

  // A rest that has already run out stays `resting` on purpose: iOS decides
  // between "counting down" and "overdue" by comparing `restEndsAt` to the
  // current time, so it needs the date even after it has passed. Dropping back
  // to `setPending` here would erase the overdue state.
  final hasRest = restEndsAt != null;

  final isCardio = next.exercise.exercise.isCardio;
  final metrics = isCardio
      ? _cardioMetrics(next, unitService, strings, localeName)
      : _strengthMetrics(next, unitService, strings, localeName);

  return WorkoutLiveActivityContent(
    phase: hasRest
        ? WorkoutLiveActivityPhase.resting
        : WorkoutLiveActivityPhase.setPending,
    restEndsAt: restEndsAt,
    restStartedAt: restStartedAt,
    exerciseName: next.exerciseName,
    setPosition:
        strings.setPosition(next.indexInExercise, next.totalInExercise),
    // Cardio sends no badge — the metrics line starts at the leading edge and
    // the compact leading zone falls back to the app icon.
    badgeText: isCardio ? '' : _badgeText(next),
    badgeColorHex: isCardio ? _colorNeutral : _badgeColor(next.setType),
    metricPrimary: metrics.primary,
    metricSecondary: metrics.secondary,
    metricTertiary: metrics.tertiary,
    metricSeparator: metrics.separator,
    compactPrimary: metrics.compactPrimary,
    compactSecondary: metrics.compactSecondary,
    minimalText: metrics.minimal,
    canCompleteSet: metrics.complete,
  );
}

/// Shown in place of a value that simply is not known yet. Never a guess.
const String _unknownValue = '–';

class _MetricLine {
  final String primary;
  final String secondary;
  final String tertiary;
  final String separator;
  final String compactPrimary;
  final String compactSecondary;
  final String minimal;

  /// Whether the set can be completed from the Live Activity with the values
  /// shown. False as soon as one of the required numbers is missing.
  final bool complete;

  const _MetricLine({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.separator,
    required this.compactPrimary,
    required this.compactSecondary,
    required this.minimal,
    required this.complete,
  });
}

_MetricLine _strengthMetrics(
  _NextSet next,
  UnitService unitService,
  WorkoutLiveActivityStrings strings,
  String localeName,
) {
  final plannedWeight = next.template?.targetWeight ?? next.log.weightKg;
  final weightText = plannedWeight == null
      ? ''
      : '${_formatDecimal(unitService.convertDisplayValue(plannedWeight, UnitDimension.weight), localeName)} ${strings.weightUnit}';

  final repsRaw = next.template?.targetReps ?? next.log.reps?.toString();
  final repsText = (repsRaw == null || repsRaw.isEmpty)
      ? ''
      : '$repsRaw ${strings.repsShort}';

  final rir = next.template?.targetRir ?? next.log.rir;
  final rirText = rir == null ? '' : '(${strings.rirLabel} $rir)';

  // Both numbers are required to tick the set off. A missing one shows as a
  // dash rather than being skipped, so the line keeps its shape and it is
  // obvious what is missing instead of a value being invented.
  final hasBoth = weightText.isNotEmpty && repsText.isNotEmpty;

  return _MetricLine(
    primary: weightText.isEmpty ? _unknownValue : weightText,
    secondary: repsText.isEmpty ? _unknownValue : repsText,
    tertiary: rirText,
    separator: '×',
    compactPrimary: weightText.isEmpty ? _unknownValue : weightText,
    compactSecondary: '× ${repsRaw ?? _unknownValue}',
    minimal: hasBoth
        ? '${_formatDecimal(unitService.convertDisplayValue(plannedWeight!, UnitDimension.weight), localeName)}×$repsRaw'
        : '',
    complete: hasBoth,
  );
}

/// Cardio has no planned targets in the data model — `SetTemplate` carries
/// only reps, weight and RIR. The line therefore falls back to values already
/// entered on the set, and stays empty for a fresh cardio set. Once templates
/// gain duration and distance targets, only this function changes.
_MetricLine _cardioMetrics(
  _NextSet next,
  UnitService unitService,
  WorkoutLiveActivityStrings strings,
  String localeName,
) {
  final seconds = next.log.durationSeconds;
  final durationText = seconds == null ? '' : _formatClock(seconds);

  final distanceKm = next.log.distanceKm;
  final distanceText = distanceKm == null
      ? ''
      : '${_formatDecimal(unitService.convertDisplayValue(distanceKm, UnitDimension.distance), localeName, decimals: 2)} ${strings.distanceUnit}';

  final rpe = next.log.rpe;
  final rpeText = rpe == null ? '' : '(${strings.rpeLabel} $rpe)';

  // Cardio needs at least one of the two to be meaningful; there is no
  // planned value to fall back on (see the note above).
  final hasAny = durationText.isNotEmpty || distanceText.isNotEmpty;

  return _MetricLine(
    primary: durationText.isEmpty
        ? (distanceText.isEmpty ? _unknownValue : distanceText)
        : durationText,
    secondary: durationText.isEmpty ? '' : distanceText,
    tertiary: rpeText,
    separator: '·',
    compactPrimary: durationText.isEmpty
        ? (distanceText.isEmpty ? _unknownValue : distanceText)
        : durationText,
    compactSecondary: durationText.isEmpty ? '' : distanceText,
    minimal: durationText.isNotEmpty ? durationText : distanceText,
    complete: hasAny,
  );
}

String _formatDecimal(double value, String localeName, {int decimals = 1}) {
  final rounded = double.parse(value.toStringAsFixed(decimals));
  final pattern =
      rounded == rounded.roundToDouble() ? '#,##0' : '#,##0.${'#' * decimals}';
  return NumberFormat(pattern, localeName).format(rounded);
}

String _formatClock(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

String _badgeText(_NextSet next) => switch (next.setType) {
      'warmup' => 'W',
      'failure' => 'F',
      'dropset' => 'D',
      'superset' => 'S',
      'other' => 'O',
      // Normal sets show `N`, not the set number — the position is already
      // spelled out as "Set x of y" on the same card, so repeating it as a
      // digit added nothing.
      _ => 'N',
    };

String _badgeColor(String setType) => switch (setType) {
      'warmup' => _colorWarmup,
      'failure' => _colorFailure,
      'dropset' => _colorDropset,
      _ => _colorNeutral,
    };

class _NextSet {
  final RoutineExercise exercise;
  final SetTemplate? template;
  final SetLog log;
  final int indexInExercise;
  final int totalInExercise;

  const _NextSet({
    required this.exercise,
    required this.template,
    required this.log,
    required this.indexInExercise,
    required this.totalInExercise,
  });

  String get exerciseName =>
      log.exerciseName.isNotEmpty ? log.exerciseName : exercise.exercise.nameEn;

  String get setType => log.setType;
}

/// The first set that is not yet completed, in routine order.
_NextSet? _findNextSet(
  List<RoutineExercise> exercises,
  Map<int, SetLog> setLogs,
) {
  for (final exercise in exercises) {
    final templates = exercise.setTemplates;
    for (var i = 0; i < templates.length; i++) {
      final template = templates[i];
      final templateId = template.id;
      if (templateId == null) continue;
      final log = setLogs[templateId];
      if (log == null || log.isCompleted == true) continue;
      return _NextSet(
        exercise: exercise,
        template: template,
        log: log,
        indexInExercise: i + 1,
        totalInExercise: templates.length,
      );
    }
  }
  return null;
}
