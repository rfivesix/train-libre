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

  static const Set<String> all = {
    aiMealCapture,
    scanBarcode,
    startWorkout,
    addMeasurement,
    logSupplement,
    addLiquid,
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

  return null;
}
