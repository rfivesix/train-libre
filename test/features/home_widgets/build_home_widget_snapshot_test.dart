import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/diary/domain/models/daily_nutrition.dart';
import 'package:train_libre/features/home_widgets/domain/build_home_widget_snapshot.dart';
import 'package:train_libre/features/home_widgets/domain/models/home_widget_snapshot.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/generated/app_localizations_de.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/util/design_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final AppLocalizations l10n = AppLocalizationsDe();

  late UnitService metricUnits;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    metricUnits = UnitService();
  });

  DailyNutrition sampleNutrition() => DailyNutrition(
        calories: 1234,
        water: 1500,
        protein: 98,
        carbs: 180,
        fat: 55,
        fiber: 12.5,
        sugar: 40.25,
        salt: 3.5,
        caffeine: 90,
        targetCalories: 2000,
        targetWater: 2500,
        targetProtein: 150,
        targetCarbs: 200,
        targetFat: 60,
        targetSugar: 50,
        targetFiber: 30,
        targetSalt: 6,
        targetCaffeine: 400,
      );

  HomeWidgetSnapshot build({
    DailyNutrition? nutrition,
    String extraNutrient = 'fiber',
    UnitService? units,
    bool isAiEnabled = true,
    DateTime? now,
  }) =>
      buildHomeWidgetSnapshot(
        nutrition: nutrition ?? sampleNutrition(),
        extraNutrient: extraNutrient,
        l10n: l10n,
        unitService: units ?? metricUnits,
        isAiEnabled: isAiEnabled,
        now: now ?? DateTime(2026, 8, 10, 12, 0),
      );

  HomeWidgetTile tileOf(HomeWidgetSnapshot s, String slot) =>
      s.tiles.firstWhere((t) => t.slot == slot);

  group('logical day key', () {
    test('before 03:00 reports the previous day, matching the diary', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 8, 10, 2, 59)),
        '2026-08-09',
      );
    });

    test('at 03:00 the day has rolled over', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 8, 10, 3, 0)),
        '2026-08-10',
      );
    });

    test('midday reports the calendar day', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 8, 10, 12, 0)),
        '2026-08-10',
      );
    });

    test('rolls back across a month boundary', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 9, 1, 1, 30)),
        '2026-08-31',
      );
    });

    test('rolls back across a year boundary', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 1, 1, 0, 5)),
        '2025-12-31',
      );
    });

    test('pads single-digit months and days', () {
      expect(
        homeWidgetLogicalDayKey(DateTime(2026, 3, 7, 12, 0)),
        '2026-03-07',
      );
    });
  });

  group('grid composition', () {
    test('produces the diary\'s six tiles in column order', () {
      expect(
        build().tiles.map((t) => t.slot).toList(),
        [
          HomeWidgetSlot.calories,
          HomeWidgetSlot.water,
          HomeWidgetSlot.extra,
          HomeWidgetSlot.protein,
          HomeWidgetSlot.carbs,
          HomeWidgetSlot.fat,
        ],
      );
    });

    test('carries localized labels rather than keys', () {
      final snapshot = build();
      expect(tileOf(snapshot, HomeWidgetSlot.calories).label, 'Kalorien');
      expect(tileOf(snapshot, HomeWidgetSlot.carbs).label, 'Kohlenhydrate');
    });

    test('reports the values and targets the diary shows', () {
      final calories = tileOf(build(), HomeWidgetSlot.calories);
      expect(calories.value, 1234);
      expect(calories.target, 2000);
      expect(calories.unit, 'kcal');
    });
  });

  group('extra nutrient slot', () {
    test('sugar', () {
      final tile = tileOf(build(extraNutrient: 'sugar'), HomeWidgetSlot.extra);
      expect(tile.label, 'Zucker');
      expect(tile.value, 40.25);
      expect(tile.target, 50);
      expect(tile.colorHex, homeWidgetColorHex(Colors.pink.shade200));
    });

    test('salt', () {
      final tile = tileOf(build(extraNutrient: 'salt'), HomeWidgetSlot.extra);
      expect(tile.label, 'Salz');
      expect(tile.value, 3.5);
      expect(tile.target, 6);
      expect(tile.colorHex, homeWidgetColorHex(Colors.grey.shade500));
    });

    test('fiber', () {
      final tile = tileOf(build(extraNutrient: 'fiber'), HomeWidgetSlot.extra);
      expect(tile.label, 'Ballaststoffe');
      expect(tile.value, 12.5);
      expect(tile.target, 30);
    });

    test('is case insensitive, like the diary widget', () {
      expect(
        tileOf(build(extraNutrient: 'SUGAR'), HomeWidgetSlot.extra).label,
        'Zucker',
      );
    });

    test('falls back to fiber for an unknown value', () {
      expect(
        tileOf(build(extraNutrient: 'nonsense'), HomeWidgetSlot.extra).label,
        'Ballaststoffe',
      );
    });
  });

  group('units', () {
    test('metric keeps millilitres', () {
      final water = tileOf(build(), HomeWidgetSlot.water);
      expect(water.unit, 'ml');
      expect(water.value, 1500);
      expect(water.target, 2500);
    });

    test('imperial converts both value and target to fluid ounces', () async {
      SharedPreferences.setMockInitialValues({'unit_system': 'imperial'});
      final imperial = UnitService();
      await imperial.setUnitSystem(UnitSystem.imperial);

      final water = tileOf(build(units: imperial), HomeWidgetSlot.water);
      expect(water.unit, 'fl oz');
      // Converted, not raw millilitres — the widget must not do this itself.
      expect(water.value, lessThan(1500));
      expect(water.value, closeTo(50.7, 0.5));
      expect(water.target, closeTo(84.5, 0.5));
    });
  });

  group('colours', () {
    test('are emitted as #RRGGBB', () {
      for (final tile in build().tiles) {
        expect(tile.colorHex, matches(RegExp(r'^#[0-9A-F]{6}$')));
      }
    });

    test('match the diary bars exactly', () {
      final snapshot = build();
      expect(
        tileOf(snapshot, HomeWidgetSlot.calories).colorHex,
        homeWidgetColorHex(Colors.orange),
      );
      expect(
        tileOf(snapshot, HomeWidgetSlot.protein).colorHex,
        homeWidgetColorHex(DesignConstants.brandRedColor),
      );
      expect(
        tileOf(snapshot, HomeWidgetSlot.fat).colorHex,
        homeWidgetColorHex(Colors.purple.shade300),
      );
    });

    test('drops the alpha channel', () {
      expect(homeWidgetColorHex(const Color(0xFF66BB6A)), '#66BB6A');
      expect(homeWidgetColorHex(const Color(0x0066BB6A)), '#66BB6A');
    });

    test('pads a colour with leading zero components', () {
      expect(homeWidgetColorHex(const Color(0xFF000102)), '#000102');
    });
  });

  group('edge cases', () {
    test('a zero target survives without dividing by zero downstream', () {
      final snapshot = build(
        nutrition: DailyNutrition(calories: 500),
      );
      final calories = tileOf(snapshot, HomeWidgetSlot.calories);
      expect(calories.target, 0);
      expect(calories.value, 500);
    });

    test('an empty day reports zeros against real targets', () {
      final snapshot = build(
        nutrition: DailyNutrition(targetCalories: 2000, targetProtein: 150),
      );
      expect(tileOf(snapshot, HomeWidgetSlot.calories).value, 0);
      expect(tileOf(snapshot, HomeWidgetSlot.calories).target, 2000);
    });

    test('carries the AI flag through for quick-action gating', () {
      expect(build(isAiEnabled: false).isAiEnabled, isFalse);
      expect(build(isAiEnabled: true).isAiEnabled, isTrue);
    });

    test('pins the rollover hour the widget must use', () {
      expect(build().rolloverHour, 3);
    });
  });

  group('json round trip', () {
    test('survives encode and decode unchanged', () {
      final original = build(extraNutrient: 'salt');
      final restored = HomeWidgetSnapshot.decode(original.encode());

      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.logicalDayKey, original.logicalDayKey);
      expect(restored.rolloverHour, original.rolloverHour);
      expect(restored.isAiEnabled, original.isAiEnabled);
      expect(restored.tiles, original.tiles);
    });

    test('declares the schema version the Swift decoder expects', () {
      expect(build().schemaVersion, 1);
    });
  });
}
