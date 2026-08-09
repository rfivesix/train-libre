/// Localized text and unit labels handed to the Live Activity.
///
/// The iOS extension has no string catalog of its own, so every word it shows
/// is formatted here and shipped across the channel (spec §7). This also keeps
/// the view model free of a `BuildContext`.
class WorkoutLiveActivityStrings {
  /// „Satz 3 von 5" — receives the current index and the total.
  final String Function(int index, int total) setPosition;

  /// Unit label for weights, already matching the user's unit system.
  final String weightUnit;

  /// Unit label for distances.
  final String distanceUnit;

  /// „Wdh" / „reps".
  final String repsShort;

  /// „RIR" and „RPE" prefixes.
  final String rirLabel;
  final String rpeLabel;

  final String addExercise;
  final String openApp;
  final String skip;

  /// Leading half of „seit 0:47 überfällig" — the counter itself is rendered
  /// by SwiftUI and appended after this text.
  final String overduePrefix;

  /// Title and body of the "rest is over" sound notification. Scheduled
  /// natively while a Live Activity is running (§7a), so the text has to
  /// travel across the channel like everything else.
  final String restDoneTitle;
  final String restDoneBody;

  const WorkoutLiveActivityStrings({
    required this.setPosition,
    required this.weightUnit,
    required this.distanceUnit,
    required this.repsShort,
    required this.rirLabel,
    required this.rpeLabel,
    required this.addExercise,
    required this.openApp,
    required this.skip,
    required this.overduePrefix,
    required this.restDoneTitle,
    required this.restDoneBody,
  });
}
