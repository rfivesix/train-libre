import 'package:intl/intl.dart';

import '../../../../services/unit_service.dart';
import '../classification/exercise_log_mask.dart';
import '../models/routine_exercise.dart';
import '../models/set_log.dart';
import '../models/set_template.dart';
import '../workout_next_set.dart';
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
  int? setTimerTemplateId,
  DateTime? setTimerStartedAt,
  int setTimerElapsedSeconds = 0,
  String labelStartTimer = '',
  String labelStopTimer = '',
  String labelTimerRunning = '',
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

  // Duration-based exercises need the same metric format as cardio even if
  // their catalog category is not Cardio (for example a plank). Category is a
  // browsing concern; tracking type describes what the current set contains.
  final mask = ExerciseLogMask.forExercise(next.exercise.exercise);
  final isDurationBased = mask.logsDuration;
  final metrics = isDurationBased
      ? _durationMetrics(next, mask, unitService, strings, localeName)
      : _strengthMetrics(next, unitService, strings, localeName);

  return WorkoutLiveActivityContent(
    phase: hasRest
        ? WorkoutLiveActivityPhase.resting
        : WorkoutLiveActivityPhase.setPending,
    restEndsAt: restEndsAt,
    restStartedAt: restStartedAt,
    setTimerStartedAt:
        setTimerTemplateId == next.templateId ? setTimerStartedAt : null,
    setTimerDeadline: null,
    setTimerTemplateId: isDurationBased &&
            (setTimerTemplateId == null ||
                setTimerTemplateId == next.templateId)
        ? next.templateId
        : null,
    setTimerElapsedSeconds: isDurationBased ? setTimerElapsedSeconds : 0,
    labelStartTimer: labelStartTimer,
    labelStopTimer: labelStopTimer,
    labelTimerRunning: labelTimerRunning,
    exerciseName: next.localizedName(_languageCode(localeName)),
    setPosition:
        strings.setPosition(next.indexInExercise, next.totalInExercise),
    // Cardio sends no badge — the metrics line starts at the leading edge and
    // the compact leading zone falls back to the app icon.
    badgeText: isDurationBased ? '' : _badgeText(next),
    badgeColorHex: isDurationBased ? _colorNeutral : _badgeColor(next.setType),
    metricPrimary: metrics.primary,
    metricSecondary: metrics.secondary,
    metricTertiary: metrics.tertiary,
    metricSeparator: metrics.separator,
    compactPrimary: metrics.compactPrimary,
    compactSecondary: metrics.compactSecondary,
    canCompleteSet:
        metrics.complete || (isDurationBased && setTimerStartedAt != null),
    upcomingSets: _upcomingSetSnapshots(
      current: next,
      exercises: exercises,
      setLogs: setLogs,
      unitService: unitService,
      strings: strings,
      localeName: localeName,
    ),
  );
}

List<WorkoutLiveActivitySetSnapshot> _upcomingSetSnapshots({
  required _NextSet current,
  required List<RoutineExercise> exercises,
  required Map<int, SetLog> setLogs,
  required UnitService unitService,
  required WorkoutLiveActivityStrings strings,
  required String localeName,
}) {
  final upcoming = <WorkoutLiveActivitySetSnapshot>[];
  final simulatedLogs = Map<int, SetLog>.of(setLogs)
    ..[current.templateId] = current.log.copyWith(isCompleted: true);
  while (upcoming.length < 30) {
    final next = _findNextSet(exercises, simulatedLogs);
    if (next == null) break;
    final mask = ExerciseLogMask.forExercise(next.exercise.exercise);
    final metrics = mask.logsDuration
        ? _durationMetrics(next, mask, unitService, strings, localeName)
        : _strengthMetrics(next, unitService, strings, localeName);
    upcoming.add(WorkoutLiveActivitySetSnapshot(
      exerciseName: next.localizedName(_languageCode(localeName)),
      setPosition:
          strings.setPosition(next.indexInExercise, next.totalInExercise),
      badgeText: mask.logsDuration ? '' : _badgeText(next),
      badgeColorHex:
          mask.logsDuration ? _colorNeutral : _badgeColor(next.setType),
      metricPrimary: metrics.primary,
      metricSecondary: metrics.secondary,
      metricTertiary: metrics.tertiary,
      metricSeparator: metrics.separator,
      compactPrimary: metrics.compactPrimary,
      compactSecondary: metrics.compactSecondary,
      setTimerTemplateId: mask.logsDuration ? next.templateId : null,
      canCompleteSet: metrics.complete,
    ));
    simulatedLogs[next.templateId] = next.log.copyWith(isCompleted: true);
  }
  return upcoming;
}

/// `localeName` arrives as a full language tag such as `de-DE`.
String _languageCode(String localeName) =>
    localeName.split(RegExp('[-_]')).first;

/// Shown in place of a value that simply is not known yet. Never a guess.
const String _unknownValue = '–';

class _MetricLine {
  final String primary;
  final String secondary;
  final String tertiary;
  final String separator;
  final String compactPrimary;
  final String compactSecondary;

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
    required this.complete,
  });
}

_MetricLine _strengthMetrics(
  _NextSet next,
  UnitService unitService,
  WorkoutLiveActivityStrings strings,
  String localeName,
) {
  // What the user has typed always wins over what the routine planned. The
  // other way round meant a set logged as 24 kg kept showing the template's
  // 10 kg, and the checkmark then wrote the template value back over it.
  final weight = next.log.weightKg ?? next.template?.targetWeight;
  final weightText = weight == null
      ? ''
      : '${_formatDecimal(unitService.convertDisplayValue(weight, UnitDimension.weight), localeName)} ${strings.weightUnit}';

  final repsRaw = next.log.reps?.toString() ?? next.template?.targetReps;
  final repsText = (repsRaw == null || repsRaw.isEmpty)
      ? ''
      : '$repsRaw ${strings.repsShort}';

  final rir = next.log.rir ?? next.template?.targetRir;
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
    complete: hasBoth,
  );
}

/// Cardio has no planned targets in the data model — `SetTemplate` carries
/// only reps, weight and RIR. The line therefore falls back to values already
/// entered on the set, and stays empty for a fresh cardio set. Once templates
/// gain duration and distance targets, only this function changes.
_MetricLine _durationMetrics(
  _NextSet next,
  ExerciseLogMask mask,
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

  final weight = next.log.weightKg ?? next.template?.targetWeight;
  final weightText = weight == null
      ? ''
      : '${_formatDecimal(unitService.convertDisplayValue(weight, UnitDimension.weight), localeName)} ${strings.weightUnit}';

  final rpe = next.log.rpe;
  final rpeText = rpe == null ? '' : '(${strings.rpeLabel} $rpe)';

  final primaryText = mask.logsWeight
      ? weightText
      : durationText.isEmpty
          ? distanceText
          : durationText;
  final secondaryText = mask.logsWeight
      ? durationText
      : durationText.isEmpty
          ? ''
          : distanceText;

  final complete = mask.logsWeight
      ? weightText.isNotEmpty && durationText.isNotEmpty
      : mask.logsDistance
          ? durationText.isNotEmpty || distanceText.isNotEmpty
          : durationText.isNotEmpty;

  return _MetricLine(
    primary: primaryText.isEmpty ? _unknownValue : primaryText,
    secondary: secondaryText,
    tertiary: rpeText,
    separator: '·',
    compactPrimary: primaryText.isEmpty ? _unknownValue : primaryText,
    compactSecondary: secondaryText,
    complete: complete,
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
  final int templateId;
  final RoutineExercise exercise;
  final SetTemplate? template;
  final SetLog log;
  final int indexInExercise;
  final int totalInExercise;

  const _NextSet({
    required this.templateId,
    required this.exercise,
    required this.template,
    required this.log,
    required this.indexInExercise,
    required this.totalInExercise,
  });

  /// `SetLog.exerciseName` always stores the English name, so it can never be
  /// used for display — the catalog entry is localized instead.
  String localizedName(String languageCode) {
    final name = exercise.exercise.localizedNameFor(languageCode);
    return name.isNotEmpty ? name : log.exerciseName;
  }

  String get setType => log.setType;
}

_NextSet? _findNextSet(
  List<RoutineExercise> exercises,
  Map<int, SetLog> setLogs,
) {
  final next = findNextWorkoutSet(exercises, setLogs);
  if (next == null) return null;

  final exercise = exercises[next.exerciseIndex];
  final template = exercise.setTemplates[next.templateIndex];
  final log = setLogs[next.templateId];
  if (log == null) return null;

  return _NextSet(
    templateId: next.templateId,
    exercise: exercise,
    template: template,
    log: log,
    indexInExercise: next.templateIndex + 1,
    totalInExercise: exercise.setTemplates.length,
  );
}
