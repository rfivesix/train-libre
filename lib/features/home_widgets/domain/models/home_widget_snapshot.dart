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

/// The payload published to the iOS App Group.
///
/// Aggregate totals and targets only — no food names, no timestamps, no entry
/// level data leaves the app's own container.
class HomeWidgetSnapshot {
  static const int currentSchemaVersion = 1;

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

  const HomeWidgetSnapshot({
    required this.schemaVersion,
    required this.generatedAtEpochMs,
    required this.logicalDayKey,
    required this.rolloverHour,
    required this.isAiEnabled,
    required this.tiles,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'generatedAtEpochMs': generatedAtEpochMs,
        'logicalDayKey': logicalDayKey,
        'rolloverHour': rolloverHour,
        'isAiEnabled': isAiEnabled,
        'tiles': tiles.map((t) => t.toJson()).toList(),
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
      );

  String encode() => jsonEncode(toJson());

  static HomeWidgetSnapshot decode(String source) =>
      HomeWidgetSnapshot.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
