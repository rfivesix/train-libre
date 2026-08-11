import 'dart:convert';

/// Slot identifiers, mirroring the six tiles of the diary's "Heute im Blick"
/// grid. Order is the grid's reading order per column:
/// left column = calories, water, extra — right column = protein, carbs, fat.
class HomeWidgetSlot {
  static const String calories = 'calories';
  static const String water = 'water';
  static const String extra = 'extra';
  static const String protein = 'protein';
  static const String carbs = 'carbs';
  static const String fat = 'fat';

  const HomeWidgetSlot._();
}

/// One progress bar in the widget grid.
///
/// [value] and [target] are already unit-converted for display, and [label] and
/// [unit] are already localized — the Swift side never formats a word.
class HomeWidgetTile {
  final String slot;
  final String label;
  final String unit;
  final double value;
  final double target;

  /// `#RRGGBB`, taken from the very same `Color` the diary bar uses, so the two
  /// can never drift apart.
  final String colorHex;

  const HomeWidgetTile({
    required this.slot,
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'label': label,
        'unit': unit,
        'value': value,
        'target': target,
        'colorHex': colorHex,
      };

  factory HomeWidgetTile.fromJson(Map<String, dynamic> json) => HomeWidgetTile(
        slot: json['slot'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String,
        value: (json['value'] as num).toDouble(),
        target: (json['target'] as num).toDouble(),
        colorHex: json['colorHex'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetTile &&
      other.slot == slot &&
      other.label == label &&
      other.unit == unit &&
      other.value == value &&
      other.target == target &&
      other.colorHex == colorHex;

  @override
  int get hashCode => Object.hash(slot, label, unit, value, target, colorHex);
}

/// One of the three readiness pills in the Muscle Readiness widget.
///
/// Mirrors `RecoverySectionCard._buildReadinessPill`: a count, its share of the
/// tracked muscles, and the colour that share is drawn in.
class HomeWidgetRecoveryState {
  /// `recovering` / `ready` / `fresh` — `RecoveryDomainService`'s state keys.
  final String state;

  /// Already localized (`l10n.recoveryStateRecovering` etc.).
  final String label;
  final int count;

  /// Rounded percentage of the tracked muscles, exactly as the card computes it.
  final int percent;
  final String colorHex;

  const HomeWidgetRecoveryState({
    required this.state,
    required this.label,
    required this.count,
    required this.percent,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'state': state,
        'label': label,
        'count': count,
        'percent': percent,
        'colorHex': colorHex,
      };

  factory HomeWidgetRecoveryState.fromJson(Map<String, dynamic> json) =>
      HomeWidgetRecoveryState(
        state: json['state'] as String,
        label: json['label'] as String,
        count: (json['count'] as num).toInt(),
        percent: (json['percent'] as num).toInt(),
        colorHex: json['colorHex'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetRecoveryState &&
      other.state == state &&
      other.label == label &&
      other.count == count &&
      other.percent == percent &&
      other.colorHex == colorHex;

  @override
  int get hashCode => Object.hash(state, label, count, percent, colorHex);
}

/// The Muscle Readiness widget's payload — a flattened `RecoveryAnalyticsPayload`.
class HomeWidgetRecovery {
  final bool hasData;

  /// Already localized headline (`recoveryOverallLabel`).
  final String headline;

  /// `recoveryOverallColor` as `#RRGGBB`, or null when the app would fall back
  /// to `colorScheme.outline` — the widget resolves that against its own scheme.
  final String? headlineColorHex;
  final List<HomeWidgetRecoveryState> states;

  const HomeWidgetRecovery({
    required this.hasData,
    required this.headline,
    required this.headlineColorHex,
    required this.states,
  });

  Map<String, dynamic> toJson() => {
        'hasData': hasData,
        'headline': headline,
        if (headlineColorHex != null) 'headlineColorHex': headlineColorHex,
        'states': states.map((s) => s.toJson()).toList(),
      };

  factory HomeWidgetRecovery.fromJson(Map<String, dynamic> json) =>
      HomeWidgetRecovery(
        hasData: json['hasData'] as bool,
        headline: json['headline'] as String,
        headlineColorHex: json['headlineColorHex'] as String?,
        states: (json['states'] as List<dynamic>)
            .map((e) =>
                HomeWidgetRecoveryState.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetRecovery &&
      other.hasData == hasData &&
      other.headline == headline &&
      other.headlineColorHex == headlineColorHex &&
      _listEquals(other.states, states);

  @override
  int get hashCode =>
      Object.hash(hasData, headline, headlineColorHex, Object.hashAll(states));
}

/// One bar of the seven-day steps chart.
class HomeWidgetStepsDay {
  /// `yyyy-MM-dd`, so the widget can tell which bar is today without a timezone
  /// of its own.
  final String dayKey;
  final int steps;

  const HomeWidgetStepsDay({required this.dayKey, required this.steps});

  Map<String, dynamic> toJson() => {'dayKey': dayKey, 'steps': steps};

  factory HomeWidgetStepsDay.fromJson(Map<String, dynamic> json) =>
      HomeWidgetStepsDay(
        dayKey: json['dayKey'] as String,
        steps: (json['steps'] as num).toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetStepsDay &&
      other.dayKey == dayKey &&
      other.steps == steps;

  @override
  int get hashCode => Object.hash(dayKey, steps);
}

/// The Steps widget's payload, mirroring `StatisticsStepsCard` in its
/// seven-day configuration.
class HomeWidgetSteps {
  /// False when step tracking is off or HealthKit access was never granted —
  /// the widget then shows the permission state rather than a chart of zeros.
  final bool isTrackingEnabled;
  final int todaySteps;
  final int dailyGoal;

  /// Oldest first, always seven entries with the last one being today.
  final List<HomeWidgetStepsDay> days;

  const HomeWidgetSteps({
    required this.isTrackingEnabled,
    required this.todaySteps,
    required this.dailyGoal,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'isTrackingEnabled': isTrackingEnabled,
        'todaySteps': todaySteps,
        'dailyGoal': dailyGoal,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory HomeWidgetSteps.fromJson(Map<String, dynamic> json) =>
      HomeWidgetSteps(
        isTrackingEnabled: json['isTrackingEnabled'] as bool,
        todaySteps: (json['todaySteps'] as num).toInt(),
        dailyGoal: (json['dailyGoal'] as num).toInt(),
        days: (json['days'] as List<dynamic>)
            .map((e) => HomeWidgetStepsDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetSteps &&
      other.isTrackingEnabled == isTrackingEnabled &&
      other.todaySteps == todaySteps &&
      other.dailyGoal == dailyGoal &&
      _listEquals(other.days, days);

  @override
  int get hashCode => Object.hash(
        isTrackingEnabled,
        todaySteps,
        dailyGoal,
        Object.hashAll(days),
      );
}

/// One point of a measurement series.
class HomeWidgetMeasurementPoint {
  final double epochMs;

  /// Already converted into the user's display unit.
  final double value;

  const HomeWidgetMeasurementPoint(
      {required this.epochMs, required this.value});

  Map<String, dynamic> toJson() => {'epochMs': epochMs, 'value': value};

  factory HomeWidgetMeasurementPoint.fromJson(Map<String, dynamic> json) =>
      HomeWidgetMeasurementPoint(
        epochMs: (json['epochMs'] as num).toDouble(),
        value: (json['value'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetMeasurementPoint &&
      other.epochMs == epochMs &&
      other.value == value;

  @override
  int get hashCode => Object.hash(epochMs, value);
}

/// One selectable metric of the configurable Measurements widget.
///
/// The full series travels rather than one pre-sliced timeframe: the timeframe
/// is a widget configuration the app never learns about, so the widget has to
/// be able to answer for any of the five periods on its own.
class HomeWidgetMeasurementMetric {
  /// The `Measurement.type` key — `weight`, `fat_percent`, `waist`, …
  final String id;

  /// Already localized (`l10n.getLocalizedMeasurementName`).
  final String name;

  /// Display unit suffix (`kg`, `%`, `cm`), matching `_getMeasurementUnit`.
  final String unit;

  /// Oldest first.
  final List<HomeWidgetMeasurementPoint> points;

  const HomeWidgetMeasurementMetric({
    required this.id,
    required this.name,
    required this.unit,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory HomeWidgetMeasurementMetric.fromJson(Map<String, dynamic> json) =>
      HomeWidgetMeasurementMetric(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        points: (json['points'] as List<dynamic>)
            .map((e) =>
                HomeWidgetMeasurementPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetMeasurementMetric &&
      other.id == id &&
      other.name == name &&
      other.unit == unit &&
      _listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(id, name, unit, Object.hashAll(points));
}

/// The Last Workout widget's payload.
class HomeWidgetLastWorkout {
  final int id;
  final String title;
  final double completedAtEpochMs;
  final int durationSeconds;

  /// Already converted into the user's weight unit. Null for a session without
  /// a single weighted set — the widget shows reps instead.
  final double? totalVolume;
  final String volumeUnit;
  final int totalReps;
  final int totalSets;

  /// File name inside the App Group container of the front+back heatmap the app
  /// renders when a workout is finished, or null if it could not be produced.
  final String? heatmapImageName;

  const HomeWidgetLastWorkout({
    required this.id,
    required this.title,
    required this.completedAtEpochMs,
    required this.durationSeconds,
    required this.totalVolume,
    required this.volumeUnit,
    required this.totalReps,
    required this.totalSets,
    required this.heatmapImageName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completedAtEpochMs': completedAtEpochMs,
        'durationSeconds': durationSeconds,
        if (totalVolume != null) 'totalVolume': totalVolume,
        'volumeUnit': volumeUnit,
        'totalReps': totalReps,
        'totalSets': totalSets,
        if (heatmapImageName != null) 'heatmapImageName': heatmapImageName,
      };

  factory HomeWidgetLastWorkout.fromJson(Map<String, dynamic> json) =>
      HomeWidgetLastWorkout(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        completedAtEpochMs: (json['completedAtEpochMs'] as num).toDouble(),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        totalVolume: (json['totalVolume'] as num?)?.toDouble(),
        volumeUnit: json['volumeUnit'] as String,
        totalReps: (json['totalReps'] as num).toInt(),
        totalSets: (json['totalSets'] as num).toInt(),
        heatmapImageName: json['heatmapImageName'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetLastWorkout &&
      other.id == id &&
      other.title == title &&
      other.completedAtEpochMs == completedAtEpochMs &&
      other.durationSeconds == durationSeconds &&
      other.totalVolume == totalVolume &&
      other.volumeUnit == volumeUnit &&
      other.totalReps == totalReps &&
      other.totalSets == totalSets &&
      other.heatmapImageName == heatmapImageName;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        completedAtEpochMs,
        durationSeconds,
        totalVolume,
        volumeUnit,
        totalReps,
        totalSets,
        heatmapImageName,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The payload published to the iOS App Group.
///
/// Aggregate totals and targets only — no food names, no timestamps, no entry
/// level data leaves the app's own container.
class HomeWidgetSnapshot {
  /// v2 added the four statistics sections below. Every one of them is nullable
  /// and every reader treats a missing section as "this widget has nothing to
  /// show yet", so a v1 payload left over from an older build still decodes.
  static const int currentSchemaVersion = 2;

  /// The hour at which the diary rolls over to the next day. Mirrors
  /// `resolveDiaryInitialDate`, and travels in the payload so the widget never
  /// hardcodes its own copy of the rule.
  static const int diaryRolloverHour = 3;

  final int schemaVersion;
  final double generatedAtEpochMs;

  /// `yyyy-MM-dd` in the user's local calendar.
  final String logicalDayKey;
  final int rolloverHour;
  final bool isAiEnabled;
  final List<HomeWidgetTile> tiles;

  /// Null until the app has computed recovery analytics at least once.
  final HomeWidgetRecovery? recovery;
  final HomeWidgetSteps? steps;

  /// Every metric the user has ever recorded, so the configurable widget can
  /// offer them all without a round trip into the app.
  final List<HomeWidgetMeasurementMetric> measurements;
  final HomeWidgetLastWorkout? lastWorkout;

  const HomeWidgetSnapshot({
    required this.schemaVersion,
    required this.generatedAtEpochMs,
    required this.logicalDayKey,
    required this.rolloverHour,
    required this.isAiEnabled,
    required this.tiles,
    this.recovery,
    this.steps,
    this.measurements = const [],
    this.lastWorkout,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'generatedAtEpochMs': generatedAtEpochMs,
        'logicalDayKey': logicalDayKey,
        'rolloverHour': rolloverHour,
        'isAiEnabled': isAiEnabled,
        'tiles': tiles.map((t) => t.toJson()).toList(),
        if (recovery != null) 'recovery': recovery!.toJson(),
        if (steps != null) 'steps': steps!.toJson(),
        if (measurements.isNotEmpty)
          'measurements': measurements.map((m) => m.toJson()).toList(),
        if (lastWorkout != null) 'lastWorkout': lastWorkout!.toJson(),
      };

  factory HomeWidgetSnapshot.fromJson(Map<String, dynamic> json) =>
      HomeWidgetSnapshot(
        schemaVersion: json['schemaVersion'] as int,
        generatedAtEpochMs: (json['generatedAtEpochMs'] as num).toDouble(),
        logicalDayKey: json['logicalDayKey'] as String,
        rolloverHour: json['rolloverHour'] as int,
        isAiEnabled: json['isAiEnabled'] as bool,
        tiles: (json['tiles'] as List<dynamic>)
            .map((e) => HomeWidgetTile.fromJson(e as Map<String, dynamic>))
            .toList(),
        recovery: json['recovery'] == null
            ? null
            : HomeWidgetRecovery.fromJson(
                json['recovery'] as Map<String, dynamic>),
        steps: json['steps'] == null
            ? null
            : HomeWidgetSteps.fromJson(json['steps'] as Map<String, dynamic>),
        measurements: (json['measurements'] as List<dynamic>? ?? const [])
            .map((e) =>
                HomeWidgetMeasurementMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastWorkout: json['lastWorkout'] == null
            ? null
            : HomeWidgetLastWorkout.fromJson(
                json['lastWorkout'] as Map<String, dynamic>),
      );

  String encode() => jsonEncode(toJson());

  static HomeWidgetSnapshot decode(String source) =>
      HomeWidgetSnapshot.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
