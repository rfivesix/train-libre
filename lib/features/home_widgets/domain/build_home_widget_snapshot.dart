import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../diary/domain/models/daily_nutrition.dart';
import 'models/home_widget_snapshot.dart';

/// `#RRGGBB` for the widget payload.
///
/// The widget receives the colour rather than owning a copy, so the six bars
/// cannot drift away from `NutritionSummaryWidget`.
String homeWidgetColorHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// The diary day [now] belongs to, as `yyyy-MM-dd`.
///
/// Same rule as `resolveDiaryInitialDate`: before 03:00 the diary still shows
/// the previous day.
String homeWidgetLogicalDayKey(DateTime now) {
  final base = now.hour < HomeWidgetSnapshot.diaryRolloverHour
      ? now.subtract(const Duration(days: 1))
      : now;
  final month = base.month.toString().padLeft(2, '0');
  final day = base.day.toString().padLeft(2, '0');
  return '${base.year.toString().padLeft(4, '0')}-$month-$day';
}

/// Builds the payload for the "Heute im Blick" widget.
///
/// Pure: no repositories, no channels, no platform calls — everything it needs
/// arrives as an argument, which is what makes the day, unit and label logic
/// testable without a running app.
///
/// Mirrors `NutritionSummaryWidget` with `isExpandedView: false`: six tiles,
/// left column calories/water/extra, right column protein/carbs/fat.
HomeWidgetSnapshot buildHomeWidgetSnapshot({
  required DailyNutrition nutrition,
  required String extraNutrient,
  required AppLocalizations l10n,
  required UnitService unitService,
  required bool isAiEnabled,
  required DateTime now,
}) {
  final liquidSuffix = unitService.suffixFor(UnitDimension.liquid);

  return HomeWidgetSnapshot(
    schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
    generatedAtEpochMs: now.millisecondsSinceEpoch.toDouble(),
    logicalDayKey: homeWidgetLogicalDayKey(now),
    rolloverHour: HomeWidgetSnapshot.diaryRolloverHour,
    isAiEnabled: isAiEnabled,
    tiles: [
      HomeWidgetTile(
        slot: HomeWidgetSlot.calories,
        label: l10n.calories,
        unit: 'kcal',
        value: nutrition.calories.toDouble(),
        target: nutrition.targetCalories.toDouble(),
        colorHex: homeWidgetColorHex(Colors.orange),
      ),
      HomeWidgetTile(
        slot: HomeWidgetSlot.water,
        label: l10n.water,
        unit: liquidSuffix,
        value: unitService.convertDisplayValue(
          nutrition.water.toDouble(),
          UnitDimension.liquid,
        ),
        target: unitService.convertDisplayValue(
          nutrition.targetWater.toDouble(),
          UnitDimension.liquid,
        ),
        colorHex: homeWidgetColorHex(Colors.blue),
      ),
      _buildExtraTile(l10n, nutrition, extraNutrient),
      HomeWidgetTile(
        slot: HomeWidgetSlot.protein,
        label: l10n.protein,
        unit: 'g',
        value: nutrition.protein.toDouble(),
        target: nutrition.targetProtein.toDouble(),
        colorHex: homeWidgetColorHex(DesignConstants.brandRedColor),
      ),
      HomeWidgetTile(
        slot: HomeWidgetSlot.carbs,
        label: l10n.carbs,
        unit: 'g',
        value: nutrition.carbs.toDouble(),
        target: nutrition.targetCarbs.toDouble(),
        colorHex: homeWidgetColorHex(Colors.green.shade400),
      ),
      HomeWidgetTile(
        slot: HomeWidgetSlot.fat,
        label: l10n.fat,
        unit: 'g',
        value: nutrition.fat.toDouble(),
        target: nutrition.targetFat.toDouble(),
        colorHex: homeWidgetColorHex(Colors.purple.shade300),
      ),
    ],
  );
}

/// The configurable third tile, matching `NutritionSummaryWidget`'s
/// `_buildExtraNutrientBar` — including its "anything else means fiber"
/// fallback.
HomeWidgetTile _buildExtraTile(
  AppLocalizations l10n,
  DailyNutrition nutrition,
  String extraNutrient,
) {
  switch (extraNutrient.toLowerCase()) {
    case 'sugar':
      return HomeWidgetTile(
        slot: HomeWidgetSlot.extra,
        label: l10n.sugar,
        unit: 'g',
        value: nutrition.sugar,
        target: nutrition.targetSugar.toDouble(),
        colorHex: homeWidgetColorHex(Colors.pink.shade200),
      );
    case 'salt':
      return HomeWidgetTile(
        slot: HomeWidgetSlot.extra,
        label: l10n.salt,
        unit: 'g',
        value: nutrition.salt,
        target: nutrition.targetSalt.toDouble(),
        colorHex: homeWidgetColorHex(Colors.grey.shade500),
      );
    default:
      return HomeWidgetTile(
        slot: HomeWidgetSlot.extra,
        label: l10n.fiber,
        unit: 'g',
        value: nutrition.fiber,
        target: nutrition.targetFiber.toDouble(),
        colorHex: homeWidgetColorHex(Colors.brown.shade400),
      );
  }
}
