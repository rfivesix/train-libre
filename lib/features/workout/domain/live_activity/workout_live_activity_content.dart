/// The five states of the workout Live Activity.
///
/// `restOverdue` is deliberately absent: it is derived on the iOS side from
/// `staleDate` once the rest timer runs out, because the app is typically
/// suspended at that moment and cannot push an update.
/// See `documentation/features/live_activity_workout.md`.
enum WorkoutLiveActivityPhase {
  setPending,
  resting,
  noSetsLeft,
  empty;

  String get wireName => switch (this) {
        WorkoutLiveActivityPhase.setPending => 'setPending',
        WorkoutLiveActivityPhase.resting => 'resting',
        WorkoutLiveActivityPhase.noSetsLeft => 'noSetsLeft',
        WorkoutLiveActivityPhase.empty => 'empty',
      };
}

/// Static data for the lifetime of one activity.
class WorkoutLiveActivityAttributes {
  final String workoutTitle;
  final DateTime workoutStartedAt;
  final String deepLink;
  final int workoutLogId;

  /// Localized labels — the iOS extension carries no string catalog.
  final String labelAddExercise;
  final String labelOpenApp;
  final String labelSkip;
  final String labelOverdue;

  const WorkoutLiveActivityAttributes({
    required this.workoutTitle,
    required this.workoutStartedAt,
    required this.deepLink,
    required this.workoutLogId,
    required this.labelAddExercise,
    required this.labelOpenApp,
    required this.labelSkip,
    required this.labelOverdue,
  });

  Map<String, Object?> toMap() => {
        'workoutTitle': workoutTitle,
        'workoutStartedAtEpochMs': workoutStartedAt.millisecondsSinceEpoch,
        'deepLink': deepLink,
        'workoutLogId': workoutLogId,
        'labelAddExercise': labelAddExercise,
        'labelOpenApp': labelOpenApp,
        'labelSkip': labelSkip,
        'labelOverdue': labelOverdue,
      };
}

/// Everything that changes during the workout.
///
/// Every string arrives pre-formatted. No field may change every second — if
/// one does, it is modelled wrong and belongs in a `Date` instead, so SwiftUI
/// can animate it without an update being pushed.
class WorkoutLiveActivityContent {
  final WorkoutLiveActivityPhase phase;

  final DateTime? restEndsAt;
  final DateTime? restStartedAt;

  final String exerciseName;
  final String setPosition;

  /// `W`, `F`, `D`, `S`, `O`, or the set number for normal sets.
  /// Empty for cardio, where the metrics line starts at the leading edge.
  final String badgeText;
  final String badgeColorHex;

  final String metricPrimary;
  final String metricSecondary;
  final String metricTertiary;
  final String metricSeparator;

  final String compactPrimary;
  final String compactSecondary;

  /// Whether the set carries enough data to be ticked off from the Live
  /// Activity. False when weight or reps (duration or distance for cardio) are
  /// missing — the checkmark must not invent values, so it goes grey and only
  /// opens the app.
  final bool canCompleteSet;

  const WorkoutLiveActivityContent({
    required this.phase,
    this.restEndsAt,
    this.restStartedAt,
    this.exerciseName = '',
    this.setPosition = '',
    this.badgeText = '',
    this.badgeColorHex = '#8E8E93',
    this.metricPrimary = '',
    this.metricSecondary = '',
    this.metricTertiary = '',
    this.metricSeparator = '×',
    this.compactPrimary = '',
    this.compactSecondary = '',
    this.canCompleteSet = false,
  });

  Map<String, Object?> toMap() => {
        'phase': phase.wireName,
        'restEndsAtEpochMs': restEndsAt?.millisecondsSinceEpoch,
        'restStartedAtEpochMs': restStartedAt?.millisecondsSinceEpoch,
        'exerciseName': exerciseName,
        'setPosition': setPosition,
        'badgeText': badgeText,
        'badgeColorHex': badgeColorHex,
        'metricPrimary': metricPrimary,
        'metricSecondary': metricSecondary,
        'metricTertiary': metricTertiary,
        'metricSeparator': metricSeparator,
        'compactPrimary': compactPrimary,
        'compactSecondary': compactSecondary,
        'canCompleteSet': canCompleteSet,
      };

  @override
  bool operator ==(Object other) =>
      other is WorkoutLiveActivityContent &&
      other.phase == phase &&
      other.restEndsAt == restEndsAt &&
      other.restStartedAt == restStartedAt &&
      other.exerciseName == exerciseName &&
      other.setPosition == setPosition &&
      other.badgeText == badgeText &&
      other.badgeColorHex == badgeColorHex &&
      other.metricPrimary == metricPrimary &&
      other.metricSecondary == metricSecondary &&
      other.metricTertiary == metricTertiary &&
      other.metricSeparator == metricSeparator &&
      other.compactPrimary == compactPrimary &&
      other.compactSecondary == compactSecondary &&
      other.canCompleteSet == canCompleteSet;

  @override
  int get hashCode => Object.hash(
        phase,
        restEndsAt,
        restStartedAt,
        exerciseName,
        setPosition,
        badgeText,
        badgeColorHex,
        metricPrimary,
        metricSecondary,
        metricTertiary,
        metricSeparator,
        compactPrimary,
        compactSecondary,
        canCompleteSet,
      );
}
