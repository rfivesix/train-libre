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
  final DateTime? setTimerStartedAt;
  final DateTime? setTimerDeadline;
  final int? setTimerTemplateId;
  final int setTimerElapsedSeconds;
  final String labelStartTimer;
  final String labelStopTimer;
  final String labelTimerRunning;

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
  final List<WorkoutLiveActivitySetSnapshot> upcomingSets;

  const WorkoutLiveActivityContent({
    required this.phase,
    this.restEndsAt,
    this.restStartedAt,
    this.setTimerStartedAt,
    this.setTimerDeadline,
    this.setTimerTemplateId,
    this.setTimerElapsedSeconds = 0,
    this.labelStartTimer = '',
    this.labelStopTimer = '',
    this.labelTimerRunning = '',
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
    this.upcomingSets = const [],
  });

  Map<String, Object?> toMap() => {
        'phase': phase.wireName,
        'restEndsAtEpochMs': restEndsAt?.millisecondsSinceEpoch,
        'restStartedAtEpochMs': restStartedAt?.millisecondsSinceEpoch,
        'setTimerStartedAtEpochMs': setTimerStartedAt?.millisecondsSinceEpoch,
        'setTimerDeadlineEpochMs': setTimerDeadline?.millisecondsSinceEpoch,
        'setTimerTemplateId': setTimerTemplateId,
        'setTimerElapsedSeconds': setTimerElapsedSeconds,
        'labelStartTimer': labelStartTimer,
        'labelStopTimer': labelStopTimer,
        'labelTimerRunning': labelTimerRunning,
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
        'upcomingSets': upcomingSets.map((set) => set.toMap()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      other is WorkoutLiveActivityContent &&
      other.phase == phase &&
      other.restEndsAt == restEndsAt &&
      other.restStartedAt == restStartedAt &&
      other.setTimerStartedAt == setTimerStartedAt &&
      other.setTimerDeadline == setTimerDeadline &&
      other.setTimerTemplateId == setTimerTemplateId &&
      other.setTimerElapsedSeconds == setTimerElapsedSeconds &&
      other.labelStartTimer == labelStartTimer &&
      other.labelStopTimer == labelStopTimer &&
      other.labelTimerRunning == labelTimerRunning &&
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
      other.canCompleteSet == canCompleteSet &&
      other.upcomingSets.length == upcomingSets.length &&
      List.generate(upcomingSets.length, (index) => index)
          .every((index) => other.upcomingSets[index] == upcomingSets[index]);

  @override
  int get hashCode => Object.hashAll([
        phase,
        restEndsAt,
        restStartedAt,
        setTimerStartedAt,
        setTimerDeadline,
        setTimerTemplateId,
        setTimerElapsedSeconds,
        labelStartTimer,
        labelStopTimer,
        labelTimerRunning,
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
        Object.hashAll(upcomingSets),
      ]);
}

/// The native Live Activity keeps a small workout-order snapshot so its
/// complete action can advance the card without opening the Flutter app.
class WorkoutLiveActivitySetSnapshot {
  final String exerciseName;
  final String setPosition;
  final String badgeText;
  final String badgeColorHex;
  final String metricPrimary;
  final String metricSecondary;
  final String metricTertiary;
  final String metricSeparator;
  final String compactPrimary;
  final String compactSecondary;
  final int? setTimerTemplateId;
  final bool canCompleteSet;

  const WorkoutLiveActivitySetSnapshot({
    required this.exerciseName,
    required this.setPosition,
    required this.badgeText,
    required this.badgeColorHex,
    required this.metricPrimary,
    required this.metricSecondary,
    required this.metricTertiary,
    required this.metricSeparator,
    required this.compactPrimary,
    required this.compactSecondary,
    required this.setTimerTemplateId,
    required this.canCompleteSet,
  });

  Map<String, Object?> toMap() => {
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
        'setTimerTemplateId': setTimerTemplateId,
        'canCompleteSet': canCompleteSet,
      };

  @override
  bool operator ==(Object other) =>
      other is WorkoutLiveActivitySetSnapshot &&
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
      other.setTimerTemplateId == setTimerTemplateId &&
      other.canCompleteSet == canCompleteSet;

  @override
  int get hashCode => Object.hash(
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
        setTimerTemplateId,
        canCompleteSet,
      );
}
