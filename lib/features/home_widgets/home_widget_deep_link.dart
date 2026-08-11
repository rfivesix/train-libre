/// Deep links the iOS Home Screen widgets emit.
///
/// The widget extension builds these URLs from the same action keys the app's
/// speed dial already uses, so a widget tap ends up in exactly the same handler
/// as the in-app button.
library;

/// What a widget URL asked the app to do.
sealed class HomeWidgetDeepLink {
  const HomeWidgetDeepLink();
}

/// `trainlibre://diary` — the "Heute im Blick" widget was tapped.
class OpenDiaryLink extends HomeWidgetDeepLink {
  const OpenDiaryLink();

  @override
  bool operator ==(Object other) => other is OpenDiaryLink;

  @override
  int get hashCode => (OpenDiaryLink).hashCode;
}

/// `trainlibre://analytics/recovery` — the Muscle Readiness widget was tapped.
class OpenRecoveryLink extends HomeWidgetDeepLink {
  const OpenRecoveryLink();

  @override
  bool operator ==(Object other) => other is OpenRecoveryLink;

  @override
  int get hashCode => (OpenRecoveryLink).hashCode;
}

/// `trainlibre://steps` — the Steps widget was tapped.
class OpenStepsLink extends HomeWidgetDeepLink {
  const OpenStepsLink();

  @override
  bool operator ==(Object other) => other is OpenStepsLink;

  @override
  int get hashCode => (OpenStepsLink).hashCode;
}

/// `trainlibre://measurements?metric=<id>&period=<key>` — the Measurements
/// widget was tapped, carrying whatever the user configured it to show.
///
/// Both parameters are optional: a widget added before the app ever wrote a
/// snapshot has nothing to name, and the screen has its own defaults.
class OpenMeasurementsLink extends HomeWidgetDeepLink {
  final String? metricId;

  /// One of [HomeWidgetMeasurementPeriod]'s keys.
  final String? periodKey;

  const OpenMeasurementsLink({this.metricId, this.periodKey});

  @override
  bool operator ==(Object other) =>
      other is OpenMeasurementsLink &&
      other.metricId == metricId &&
      other.periodKey == periodKey;

  @override
  int get hashCode => Object.hash(OpenMeasurementsLink, metricId, periodKey);
}

/// `trainlibre://workout/log/<id>` — the Last Workout widget was tapped.
class OpenWorkoutLogLink extends HomeWidgetDeepLink {
  final int logId;

  const OpenWorkoutLogLink(this.logId);

  @override
  bool operator ==(Object other) =>
      other is OpenWorkoutLogLink && other.logId == logId;

  @override
  int get hashCode => Object.hash(OpenWorkoutLogLink, logId);
}

/// The timeframe keys the Measurements widget may send.
///
/// Kept in lockstep with `MeasurementPeriod` in
/// `ios/TrainLibreLiveActivity/MeasurementsWidget.swift`, and mapped onto the
/// `TimeframeBlock` values `MeasurementsScreen` already offers.
class HomeWidgetMeasurementPeriod {
  static const String sevenDays = '7d';
  static const String oneMonth = '1m';
  static const String threeMonths = '3m';
  static const String sixMonths = '6m';
  static const String max = 'max';

  static const Set<String> all = {
    sevenDays,
    oneMonth,
    threeMonths,
    sixMonths,
    max,
  };

  const HomeWidgetMeasurementPeriod._();
}

/// `trainlibre://action/<key>` — a quick action tile was tapped.
class QuickActionLink extends HomeWidgetDeepLink {
  final String actionKey;

  const QuickActionLink(this.actionKey);

  @override
  bool operator ==(Object other) =>
      other is QuickActionLink && other.actionKey == actionKey;

  @override
  int get hashCode => Object.hash(QuickActionLink, actionKey);
}

/// The action keys the quick-access widget may send.
///
/// Kept in lockstep with `QuickActionKind` in
/// `ios/TrainLibreLiveActivity/QuickActionEntity.swift` and with the `action`
/// strings in `MainScreen._executeAddMenuAction`.
class HomeWidgetAction {
  static const String aiMealCapture = 'ai_meal_capture';
  static const String scanBarcode = 'scan_barcode';
  static const String startWorkout = 'start_workout';
  static const String addMeasurement = 'add_measurement';
  static const String logSupplement = 'log_supplement';
  static const String addLiquid = 'add_liquid';
  static const String addFood = 'add_food';

  static const Set<String> all = {
    aiMealCapture,
    scanBarcode,
    startWorkout,
    addMeasurement,
    logSupplement,
    addLiquid,
    addFood,
  };

  const HomeWidgetAction._();
}

/// Parses a platform route into a widget intent, or returns `null` if the URL
/// did not come from a widget.
///
/// Accepts both `trainlibre://diary` (host form, how iOS delivers a custom
/// scheme) and `/diary` (path form, how Flutter's route information sometimes
/// presents it), because both reach `didPushRouteInformation` depending on
/// launch path.
HomeWidgetDeepLink? parseHomeWidgetDeepLink(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return null;

  final segments = <String>[
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  if (segments.isEmpty) return null;

  if (segments.first == 'diary' && segments.length == 1) {
    return const OpenDiaryLink();
  }

  if (segments.first == 'action' && segments.length == 2) {
    final key = segments[1];
    if (!HomeWidgetAction.all.contains(key)) return null;
    return QuickActionLink(key);
  }

  if (segments.length == 2 &&
      segments.first == 'analytics' &&
      segments[1] == 'recovery') {
    return const OpenRecoveryLink();
  }

  if (segments.first == 'steps' && segments.length == 1) {
    return const OpenStepsLink();
  }

  if (segments.first == 'measurements' && segments.length == 1) {
    final metric = uri.queryParameters['metric'];
    final period = uri.queryParameters['period'];
    return OpenMeasurementsLink(
      metricId: (metric != null && metric.isNotEmpty) ? metric : null,
      // An unknown period is dropped rather than rejected: the metric is still
      // worth honouring, and the screen falls back to its own default.
      periodKey:
          HomeWidgetMeasurementPeriod.all.contains(period) ? period : null,
    );
  }

  if (segments.length == 3 &&
      segments.first == 'workout' &&
      segments[1] == 'log') {
    final id = int.tryParse(segments[2]);
    if (id == null) return null;
    return OpenWorkoutLogLink(id);
  }

  return null;
}
