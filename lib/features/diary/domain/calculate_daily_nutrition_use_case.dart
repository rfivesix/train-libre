import 'models/daily_goal.dart';
import 'models/daily_nutrition.dart';
import 'models/fluid_entry.dart';
import 'models/food_entry.dart';
import 'models/food_item.dart';
import 'models/tracked_food_item.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../supplements/domain/models/tracked_supplement.dart';
import '../../workout/domain/models/workout_log.dart';

class DailyNutritionState {
  final DailyNutrition summary;
  final Map<String, List<TrackedFoodItem>> entriesByMeal;
  final List<TrackedSupplement> trackedSupplements;
  final Map<String, dynamic>? workoutSummary;

  DailyNutritionState({
    required this.summary,
    required this.entriesByMeal,
    required this.trackedSupplements,
    this.workoutSummary,
  });
}

class CalculateDailyNutritionUseCase {
  DailyNutritionState execute({
    required DailyGoal? goals,
    required int targetSugar,
    required int targetCaffeine,
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
    required Map<String, FoodItem> foodProductsByBarcode,
    required Map<int, FoodItem> foodProductsByArchiveLocalId,
    required List<WorkoutLog> workoutLogs,
    required List<Supplement> supplementsForDate,
    required List<Supplement> allSupplements,
    required List<SupplementLog> todaysSupplementLogs,
  }) {
    final targetCalories = goals?.targetCalories ?? 2500;
    final targetProtein = goals?.targetProtein ?? 180;
    final targetCarbs = goals?.targetCarbs ?? 250;
    final targetFat = goals?.targetFat ?? 80;
    final targetWater = goals?.targetWater ?? 3000;

    final summary = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
      targetSugar: targetSugar,
      targetCaffeine: targetCaffeine,
    );

    // Workout Summary
    final completedLogs = workoutLogs
        .where((log) => log.endTime != null)
        .toList();
    Map<String, dynamic>? workoutSummary;
    if (completedLogs.isNotEmpty) {
      Duration totalDuration = Duration.zero;
      double totalVolume = 0.0;
      int totalSets = 0;
      for (final log in completedLogs) {
        totalDuration += log.endTime!.difference(log.startTime);
        totalSets += log.sets.length;
        for (final set in log.sets) {
          totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
        }
      }
      workoutSummary = {
        'duration': totalDuration,
        'volume': totalVolume,
        'sets': totalSets,
        'count': completedLogs.length,
      };
    }

    // Pre-filter fluid foods to avoid redundant map lookups in the nested loop
    final fluidFoodEntries = foodEntries.where((food) {
      final foodItem = food.archiveLocalId != null
          ? foodProductsByArchiveLocalId[food.archiveLocalId!]
          : foodProductsByBarcode[food.barcode];
      return foodItem != null &&
          (foodItem.isFluid || (foodItem.isLiquid ?? false));
    }).toList();

    // Cache properties for O(1) quantity matching and faster time diff calculations
    final Map<int, List<int>> fluidFoodSignatures = {};
    for (final food in fluidFoodEntries) {
      final qty = food.quantityInGrams;
      final ms = food.timestamp.millisecondsSinceEpoch;
      if (fluidFoodSignatures.containsKey(qty)) {
        fluidFoodSignatures[qty]!.add(ms);
      } else {
        fluidFoodSignatures[qty] = [ms];
      }
    }

    // Fluids
    summary.water = fluidEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.quantityInMl,
    );
    for (final entry in fluidEntries) {
      // Short-circuit: skip evaluating duplicate logic if entry is already explicitly linked
      if (entry.linkedFoodEntryId != null) {
        continue;
      }

      bool isDuplicateOfFood = false;
      final matchingMsList = fluidFoodSignatures[entry.quantityInMl];
      if (matchingMsList != null) {
        final entryMs = entry.timestamp.millisecondsSinceEpoch;
        for (final ms in matchingMsList) {
          // Defensive match: same day/time and similar quantity (< 2 seconds)
          if ((entryMs - ms).abs() < 2000) {
            isDuplicateOfFood = true;
            break;
          }
        }
      }

      if (isDuplicateOfFood) {
        continue;
      }

      summary.calories += entry.kcal ?? 0;
      final factor = entry.quantityInMl / 100.0;
      summary.sugar += (entry.sugarPer100ml ?? 0) * factor;
      summary.carbs += ((entry.carbsPer100ml ?? 0) * factor).round();
    }

    // Food

    final Map<String, List<TrackedFoodItem>> groupedEntries = {
      'mealtypeBreakfast': [],
      'mealtypeLunch': [],
      'mealtypeDinner': [],
      'mealtypeSnack': [],
    };

    for (final entry in foodEntries) {
      final foodItem = entry.archiveLocalId != null
          ? foodProductsByArchiveLocalId[entry.archiveLocalId!]
          : foodProductsByBarcode[entry.barcode];
      if (foodItem != null) {
        final ratio = entry.quantityInGrams / 100.0;
        summary.calories += (foodItem.calories * ratio).round();
        summary.protein += (foodItem.protein * ratio).round();
        summary.carbs += (foodItem.carbs * ratio).round();
        summary.fat += (foodItem.fat * ratio).round();
        summary.sugar += (foodItem.sugar ?? 0) * ratio;

        final trackedItem = TrackedFoodItem(entry: entry, item: foodItem);
        groupedEntries[entry.mealType]?.add(trackedItem);
      }
    }

    for (var meal in groupedEntries.values) {
      meal.sort((a, b) => b.entry.timestamp.compareTo(a.entry.timestamp));
    }

    // Supplements
    final Map<int, double> todaysDoses = {};
    for (final log in todaysSupplementLogs) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = allSupplements.firstWhere(
        (s) => (s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine',
      );
    } catch (e) {
      caffeineSupplement = null;
    }

    if (caffeineSupplement != null && caffeineSupplement.id != null) {
      summary.caffeine = todaysDoses[caffeineSupplement.id] ?? 0.0;
    }

    final Map<int, Supplement> byId = {
      for (final s in allSupplements)
        if (s.id != null) s.id!: s,
    };

    final List<TrackedSupplement> trackedSupps = [];
    for (final s in supplementsForDate) {
      final hasLog = todaysDoses.containsKey(s.id);
      if (s.isTracked || hasLog) {
        trackedSupps.add(
          TrackedSupplement(
            supplement: s,
            totalDosedToday: todaysDoses[s.id] ?? 0.0,
          ),
        );
      }
    }

    // Optimize supplement lookup by extracting tracked IDs to a Set
    final Set<int> trackedSuppIds = {
      for (final ts in trackedSupps)
        if (ts.supplement.id != null) ts.supplement.id!
    };

    for (final id in todaysDoses.keys) {
      if (!trackedSuppIds.contains(id)) {
        if (byId.containsKey(id)) {
          trackedSupps.add(
            TrackedSupplement(
              supplement: byId[id]!,
              totalDosedToday: todaysDoses[id]!,
            ),
          );
        }
      }
    }

    return DailyNutritionState(
      summary: summary,
      entriesByMeal: groupedEntries,
      trackedSupplements: trackedSupps,
      workoutSummary: workoutSummary,
    );
  }
}
