// lib/features/statistics/data/macro_analytics_data_adapter.dart

import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../diary/data/sources/product_local_data_source.dart';
import '../../diary/domain/models/fluid_entry.dart';
import '../../diary/domain/models/food_entry.dart';
import '../../diary/domain/models/food_item.dart';

/// Represents aggregated nutritional intake for a single calendar day.
class DailyMacroIntake {
  final DateTime date;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const DailyMacroIntake({
    required this.date,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
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

  const MacroPeriodSummary({
    required this.range,
    required this.dailyIntakes,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.totalDays,
    required this.trackedDays,
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
}

class MacroAnalyticsDataAdapter {
  final DatabaseHelper? _customDatabaseHelper;
  final ProductLocalDataSource? _customProductDataSource;

  const MacroAnalyticsDataAdapter({
    DatabaseHelper? databaseHelper,
    ProductLocalDataSource? productDataSource,
  })  : _customDatabaseHelper = databaseHelper,
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
    final endOfDay = DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59);

    final results = await Future.wait([
      _databaseHelper.getEntriesForDateRange(startDay, endOfDay),
      _databaseHelper.getFluidEntriesForDateRange(startDay, endOfDay),
    ]);

    final foodEntries = results[0] as List<FoodEntry>;
    final fluidEntries = results[1] as List<FluidEntry>;

    final dailyMap = await _aggregateDays(
      startDay: startDay,
      endDay: endDay,
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
    );

    final totalDays = endDay.difference(startDay).inDays + 1;
    final List<DailyMacroIntake> intakes = [];
    int sumCalories = 0;
    double sumProtein = 0.0;
    double sumCarbs = 0.0;
    double sumFat = 0.0;
    int trackedDays = 0;

    for (int i = 0; i < totalDays; i++) {
      final currentDay = startDay.add(Duration(days: i));
      final dayKey = DateTime.utc(currentDay.year, currentDay.month, currentDay.day);
      final intake = dailyMap[dayKey] ??
          DailyMacroIntake(
            date: currentDay,
            calories: 0,
            proteinGrams: 0.0,
            carbsGrams: 0.0,
            fatGrams: 0.0,
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
    final divisor = trackedDays > 0 ? trackedDays : (totalDays > 0 ? totalDays : 1);

    return MacroPeriodSummary(
      range: range,
      dailyIntakes: intakes,
      avgCalories: (sumCalories / divisor).round(),
      avgProtein: sumProtein / divisor,
      avgCarbs: sumCarbs / divisor,
      avgFat: sumFat / divisor,
      totalDays: totalDays,
      trackedDays: trackedDays,
    );
  }

  /// Fetches the last [days] (e.g. 7) ending on [anchorDate] or today.
  Future<List<DailyMacroIntake>> fetchRecentDays({
    int days = 7,
    DateTime? anchorDate,
  }) async {
    final end = normalizeDay(anchorDate ?? DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    final summary = await fetchSummary(range: DateTimeRange(start: start, end: end));
    return summary.dailyIntakes;
  }

  /// Fetches the 7 days of the calendar week (Monday to Sunday) containing [date] or today.
  Future<List<DailyMacroIntake>> fetchCurrentWeekDays({
    DateTime? date,
  }) async {
    final target = normalizeDay(date ?? DateTime.now());
    final offset = target.weekday - DateTime.monday;
    final monday = target.subtract(Duration(days: offset));
    final sunday = monday.add(const Duration(days: 6));
    final summary = await fetchSummary(range: DateTimeRange(start: monday, end: sunday));
    return summary.dailyIntakes;
  }

  Future<Map<DateTime, DailyMacroIntake>> _aggregateDays({
    required DateTime startDay,
    required DateTime endDay,
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
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
      final archivedProducts =
          await _productDataSource.getProductsByArchiveIds(archiveIdsSet.toList());
      archiveProductsMap.addAll(archivedProducts);
    }

    if (barcodesSet.isNotEmpty) {
      final legacyProducts =
          await _productDataSource.getProductsByBarcodes(barcodesSet.toList());
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

    for (final entry in fluidEntries) {
      final isLinked = entry.linkedFoodEntryId != null;
      final isDuplicateOfFood = foodEntries.any((food) {
        final foodItem = food.archiveLocalId != null
            ? archiveProductsMap[food.archiveLocalId!]
            : legacyProductsMap[food.barcode];
        final isFluidFood = foodItem != null && foodItem.isFluid;
        if (!isFluidFood) return false;
        if (entry.linkedFoodEntryId == food.id) return true;
        final timeDiff =
            entry.timestamp.difference(food.timestamp).inSeconds.abs();
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
    final allDays = {...caloriesByDay.keys, ...proteinByDay.keys, ...carbsByDay.keys, ...fatByDay.keys};

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
}
