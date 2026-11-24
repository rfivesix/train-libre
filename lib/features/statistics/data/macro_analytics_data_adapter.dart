// lib/features/statistics/data/macro_analytics_data_adapter.dart

import 'package:drift/drift.dart' as drift;
import 'package:material_ui/material_ui.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as drift_db;
import '../../diary/data/sources/product_local_data_source.dart';
import '../../diary/domain/models/fluid_entry.dart';
import '../../diary/domain/models/food_entry.dart';
import '../../diary/domain/models/food_item.dart';
import '../../diary/domain/models/macro_entry.dart';

/// Represents aggregated nutritional intake for a single calendar day.
class DailyMacroIntake {
  final DateTime date;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final int? targetCalories;
  final bool isIncomplete;

  const DailyMacroIntake({
    required this.date,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.targetCalories,
    this.isIncomplete = false,
  });

  bool get hasData =>
      calories > 0 || proteinGrams > 0 || carbsGrams > 0 || fatGrams > 0;
}

/// Aggregated macronutrient analytics and averages across a timeframe.
class MacroPeriodSummary {
  final DateTimeRange range;
  final List<DailyMacroIntake> dailyIntakes;
  final int avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final int totalDays;
  final int trackedDays;
  final int incompleteDays;

  const MacroPeriodSummary({
    required this.range,
    required this.dailyIntakes,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.totalDays,
    required this.trackedDays,
    this.incompleteDays = 0,
  });

  static MacroPeriodSummary empty(DateTimeRange range) {
    return MacroPeriodSummary(
      range: range,
      dailyIntakes: const [],
      avgCalories: 0,
      avgProtein: 0.0,
      avgCarbs: 0.0,
      avgFat: 0.0,
      totalDays: 0,
      trackedDays: 0,
    );
  }

  factory MacroPeriodSummary.mockPreview(DateTimeRange range) {
    final startDay = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);
    final rawDays =
        DateTime.utc(endDay.year, endDay.month, endDay.day)
            .difference(DateTime.utc(startDay.year, startDay.month, startDay.day))
            .inDays +
        1;
    final totalDays = rawDays < 7 ? 7 : rawDays;
    final effectiveRange = rawDays < 7
        ? DateTimeRange(
            start: startDay,
            end: DateTime(startDay.year, startDay.month, startDay.day + 6),
          )
        : range;

    const pattern = <({int kcal, double p, double c, double f})>[
      (kcal: 2180, p: 155, c: 235, f: 68),
      (kcal: 2420, p: 170, c: 268, f: 74),
      (kcal: 1980, p: 145, c: 205, f: 64),
      (kcal: 2540, p: 175, c: 280, f: 80),
      (kcal: 2290, p: 160, c: 248, f: 72),
      (kcal: 2060, p: 150, c: 215, f: 66),
      (kcal: 2380, p: 165, c: 260, f: 75),
    ];

    int sumCalories = 0;
    double sumProtein = 0;
    double sumCarbs = 0;
    double sumFat = 0;

    final intakes = List<DailyMacroIntake>.generate(totalDays, (i) {
      final sample = pattern[i % pattern.length];
      final date = DateTime(startDay.year, startDay.month, startDay.day + i);
      sumCalories += sample.kcal;
      sumProtein += sample.p;
      sumCarbs += sample.c;
      sumFat += sample.f;
      return DailyMacroIntake(
        date: date,
        calories: sample.kcal,
        proteinGrams: sample.p,
        carbsGrams: sample.c,
        fatGrams: sample.f,
        targetCalories: 2300,
      );
    }, growable: false);

    return MacroPeriodSummary(
      range: effectiveRange,
      dailyIntakes: intakes,
      avgCalories: (sumCalories / totalDays).round(),
      avgProtein: sumProtein / totalDays,
      avgCarbs: sumCarbs / totalDays,
      avgFat: sumFat / totalDays,
      totalDays: totalDays,
      trackedDays: totalDays,
    );
  }

  /// Starts the range at the first tracked or explicitly incomplete day.
  MacroPeriodSummary trimmedToFirstTracked() {
    final firstTrackedIndex = dailyIntakes.indexWhere(
      (day) => day.hasData || day.isIncomplete,
    );
    if (firstTrackedIndex < 0) {
      return MacroPeriodSummary.empty(range);
    }
    if (firstTrackedIndex == 0) {
      return this;
    }
    final trimmed = dailyIntakes.sublist(firstTrackedIndex);
    return MacroPeriodSummary(
      range: DateTimeRange(start: trimmed.first.date, end: range.end),
      dailyIntakes: trimmed,
      avgCalories: avgCalories,
      avgProtein: avgProtein,
      avgCarbs: avgCarbs,
      avgFat: avgFat,
      totalDays: trimmed.length,
      trackedDays: trackedDays,
      incompleteDays: incompleteDays,
    );
  }
}

class MacroAnalyticsDataAdapter {
  final DatabaseHelper? _customDatabaseHelper;
  final ProductLocalDataSource? _customProductDataSource;

  const MacroAnalyticsDataAdapter({
    DatabaseHelper? databaseHelper,
    ProductLocalDataSource? productDataSource,
  }) : _customDatabaseHelper = databaseHelper,
       _customProductDataSource = productDataSource;

  DatabaseHelper get _databaseHelper =>
      _customDatabaseHelper ?? DatabaseHelper.instance;
  ProductLocalDataSource get _productDataSource =>
      _customProductDataSource ?? ProductLocalDataSource.instance;

  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Fetches aggregated daily macros and timeframe averages for a specified range.
  Future<MacroPeriodSummary> fetchSummary({
    required DateTimeRange range,
  }) async {
    final startDay = normalizeDay(range.start);
    final endDay = normalizeDay(range.end);
    final endOfDay = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      23,
      59,
      59,
    );

    final results = await Future.wait([
      _databaseHelper.getEntriesForDateRange(startDay, endOfDay),
      _databaseHelper.getFluidEntriesForDateRange(startDay, endOfDay),
      _databaseHelper.getMacroEntriesForDateRange(startDay, endOfDay),
      _loadCalorieGoalTimeline(),
      _databaseHelper.getIncompleteNutritionDays(startDay, endDay),
    ]);

    final foodEntries = results[0] as List<FoodEntry>;
    final fluidEntries = results[1] as List<FluidEntry>;
    final macroEntries = results[2] as List<MacroEntry>;
    final goalTimeline =
        results[3] as ({List<drift_db.DailyGoalsHistoryData> history, int? fallbackTarget});
    final incompleteDays = results[4] as Set<DateTime>;

    final dailyMap = await _aggregateDays(
      startDay: startDay,
      endDay: endDay,
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
      macroEntries: macroEntries,
    );

    final totalDays =
        DateTime.utc(endDay.year, endDay.month, endDay.day)
            .difference(DateTime.utc(startDay.year, startDay.month, startDay.day))
            .inDays +
        1;
    final List<DailyMacroIntake> intakes = [];
    int sumCalories = 0;
    double sumProtein = 0.0;
    double sumCarbs = 0.0;
    double sumFat = 0.0;
    int trackedDays = 0;

    for (int i = 0; i < totalDays; i++) {
      final currentDay = DateTime(startDay.year, startDay.month, startDay.day + i);
      final dayKey = DateTime.utc(
        currentDay.year,
        currentDay.month,
        currentDay.day,
      );
      final targetForDay = _resolveTargetCaloriesForDay(
        currentDay,
        goalTimeline.history,
        goalTimeline.fallbackTarget,
      );
      final isIncomplete = incompleteDays.contains(currentDay);
      final existing = isIncomplete ? null : dailyMap[dayKey];
      final intake = existing != null
          ? DailyMacroIntake(
              date: existing.date,
              calories: existing.calories,
              proteinGrams: existing.proteinGrams,
              carbsGrams: existing.carbsGrams,
              fatGrams: existing.fatGrams,
              targetCalories: targetForDay,
            )
          : DailyMacroIntake(
              date: currentDay,
              calories: 0,
              proteinGrams: 0.0,
              carbsGrams: 0.0,
              fatGrams: 0.0,
              targetCalories: targetForDay,
              isIncomplete: isIncomplete,
            );
      intakes.add(intake);
      if (intake.hasData) {
        sumCalories += intake.calories;
        sumProtein += intake.proteinGrams;
        sumCarbs += intake.carbsGrams;
        sumFat += intake.fatGrams;
        trackedDays++;
      }
    }

    // Averages are calculated across days with actual tracking when available,
    // or across total days if trackedDays == 0.
    final divisor = trackedDays > 0
        ? trackedDays
        : (totalDays > 0 ? totalDays : 1);

    return MacroPeriodSummary(
      range: range,
      dailyIntakes: intakes,
      avgCalories: (sumCalories / divisor).round(),
      avgProtein: sumProtein / divisor,
      avgCarbs: sumCarbs / divisor,
      avgFat: sumFat / divisor,
      totalDays: totalDays,
      trackedDays: trackedDays,
      incompleteDays: incompleteDays.length,
    );
  }

  /// Fetches the last [days] (e.g. 7) ending on [anchorDate] or today.
  Future<List<DailyMacroIntake>> fetchRecentDays({
    int days = 7,
    DateTime? anchorDate,
  }) async {
    final end = normalizeDay(anchorDate ?? DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    final summary = await fetchSummary(
      range: DateTimeRange(start: start, end: end),
    );
    return summary.dailyIntakes;
  }

  /// Fetches the 7 days of the calendar week (Monday to Sunday) containing [date] or today.
  Future<List<DailyMacroIntake>> fetchCurrentWeekDays({DateTime? date}) async {
    final target = normalizeDay(date ?? DateTime.now());
    final offset = target.weekday - DateTime.monday;
    final monday = target.subtract(Duration(days: offset));
    final sunday = monday.add(const Duration(days: 6));
    final summary = await fetchSummary(
      range: DateTimeRange(start: monday, end: sunday),
    );
    return summary.dailyIntakes;
  }

  Future<Map<DateTime, DailyMacroIntake>> _aggregateDays({
    required DateTime startDay,
    required DateTime endDay,
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
    required List<MacroEntry> macroEntries,
  }) async {
    final Set<int> archiveIdsSet = {};
    final Set<String> barcodesSet = {};

    for (final entry in foodEntries) {
      if (entry.archiveLocalId != null) {
        archiveIdsSet.add(entry.archiveLocalId!);
      } else {
        barcodesSet.add(entry.barcode);
      }
    }

    final Map<int, FoodItem> archiveProductsMap = {};
    final Map<String, FoodItem> legacyProductsMap = {};

    if (archiveIdsSet.isNotEmpty) {
      final archivedProducts = await _productDataSource.getProductsByArchiveIds(
        archiveIdsSet.toList(),
      );
      archiveProductsMap.addAll(archivedProducts);
    }

    if (barcodesSet.isNotEmpty) {
      final legacyProducts = await _productDataSource.getProductsByBarcodes(
        barcodesSet.toList(),
      );
      for (final p in legacyProducts) {
        legacyProductsMap[p.barcode] = p;
      }
    }

    final Map<DateTime, double> caloriesByDay = {};
    final Map<DateTime, double> proteinByDay = {};
    final Map<DateTime, double> carbsByDay = {};
    final Map<DateTime, double> fatByDay = {};

    for (final entry in foodEntries) {
      final day = DateTime.utc(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final product = entry.archiveLocalId != null
          ? archiveProductsMap[entry.archiveLocalId!]
          : legacyProductsMap[entry.barcode];

      if (product != null) {
        final amountFactor = entry.quantityInGrams / 100.0;
        final cals = product.calories * amountFactor;
        final prot = product.protein * amountFactor;
        final carbs = product.carbs * amountFactor;
        final fat = product.fat * amountFactor;

        caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + cals;
        proteinByDay[day] = (proteinByDay[day] ?? 0.0) + prot;
        carbsByDay[day] = (carbsByDay[day] ?? 0.0) + carbs;
        fatByDay[day] = (fatByDay[day] ?? 0.0) + fat;
      }
    }

    for (final entry in macroEntries) {
      final day = DateTime.utc(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + entry.totalCalories;
      proteinByDay[day] = (proteinByDay[day] ?? 0.0) + entry.totalProtein;
      carbsByDay[day] = (carbsByDay[day] ?? 0.0) + entry.totalCarbs;
      fatByDay[day] = (fatByDay[day] ?? 0.0) + entry.totalFat;
    }

    for (final entry in fluidEntries) {
      final isLinked =
          entry.linkedFoodEntryId != null || entry.linkedMacroEntryId != null;
      final isDuplicateOfFood = foodEntries.any((food) {
        final foodItem = food.archiveLocalId != null
            ? archiveProductsMap[food.archiveLocalId!]
            : legacyProductsMap[food.barcode];
        final isFluidFood = foodItem != null && foodItem.isFluid;
        if (!isFluidFood) return false;
        if (entry.linkedFoodEntryId == food.id) return true;
        final timeDiff = entry.timestamp
            .difference(food.timestamp)
            .inSeconds
            .abs();
        return timeDiff < 2 && entry.quantityInMl == food.quantityInGrams;
      });

      if (isLinked || isDuplicateOfFood) continue;

      final day = DateTime.utc(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final amountFactor = entry.quantityInMl / 100.0;
      final cals = (entry.kcal ?? 0).toDouble();
      final carbs = (entry.carbsPer100ml ?? 0.0) * amountFactor;

      caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + cals;
      carbsByDay[day] = (carbsByDay[day] ?? 0.0) + carbs;
    }

    final Map<DateTime, DailyMacroIntake> result = {};
    final allDays = {
      ...caloriesByDay.keys,
      ...proteinByDay.keys,
      ...carbsByDay.keys,
      ...fatByDay.keys,
    };

    for (final day in allDays) {
      result[day] = DailyMacroIntake(
        date: DateTime(day.year, day.month, day.day),
        calories: (caloriesByDay[day] ?? 0.0).round(),
        proteinGrams: proteinByDay[day] ?? 0.0,
        carbsGrams: carbsByDay[day] ?? 0.0,
        fatGrams: fatByDay[day] ?? 0.0,
      );
    }

    return result;
  }

  Future<({List<drift_db.DailyGoalsHistoryData> history, int? fallbackTarget})>
  _loadCalorieGoalTimeline() async {
    try {
      final db = await _databaseHelper.database;
      final history =
          await (db.select(db.dailyGoalsHistory)..orderBy([
                (t) => drift.OrderingTerm(expression: t.createdAt),
                (t) => drift.OrderingTerm(expression: t.localId),
              ]))
              .get();
      if (history.isNotEmpty) {
        return (history: history, fallbackTarget: null);
      }
      final settings = await db.select(db.appSettings).getSingleOrNull();
      return (history: history, fallbackTarget: settings?.targetCalories);
    } catch (_) {
      return (history: const <drift_db.DailyGoalsHistoryData>[], fallbackTarget: null);
    }
  }

  int? _resolveTargetCaloriesForDay(
    DateTime day,
    List<drift_db.DailyGoalsHistoryData> history,
    int? fallbackTarget,
  ) {
    if (history.isEmpty) {
      return fallbackTarget != null && fallbackTarget > 0 ? fallbackTarget : null;
    }
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    drift_db.DailyGoalsHistoryData? match;
    for (final entry in history) {
      if (!entry.createdAt.isAfter(endOfDay)) {
        match = entry;
      } else {
        break;
      }
    }
    final resolved = (match ?? history.first).targetCalories;
    return resolved > 0 ? resolved : null;
  }
}
