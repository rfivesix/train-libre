import 'package:drift/drift.dart' as drift;

import '../../../core/infrastructure/user_preferences_repository.dart';
import '../../../data/drift_database.dart';
import '../../diary/domain/calculate_daily_nutrition_use_case.dart';
import '../../diary/domain/repositories/diary_repository.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

class AssistantDiaryActions implements AssistantDataAction {
  const AssistantDiaryActions(
    this.diary, {
    this.database,
    this.preferences,
  });

  final IDiaryRepository diary;
  final AppDatabase? database;
  final UserPreferencesRepository? preferences;

  @override
  Set<AssistantDataCategory> get categories => const {
    AssistantDataCategory.diary,
    AssistantDataCategory.nutrition,
  };

  @override
  Future<AssistantActionResult> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    final prefs = preferences ?? UserPreferencesRepository.instance;
    int targetSugar = 0;
    int targetFiber = 0;
    int targetSalt = 0;
    int targetCaffeine = 0;
    try {
      targetSugar = await prefs.getTargetSugar() ?? 0;
      targetFiber = await prefs.getTargetFiber() ?? 0;
      targetSalt = await prefs.getTargetSalt() ?? 0;
      targetCaffeine = await prefs.getTargetCaffeine() ?? 0;
    } catch (_) {
      // SharedPreferences may be unavailable in minimal unit tests.
    }

    final incompleteDays = await _loadIncompleteDays(scope!);
    final caffeineByDay = await _loadSupplementCaffeineByDay(scope);

    final records = <Map<String, dynamic>>[];
    for (
      var day = scope.start;
      !day.isAfter(scope.end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final foods = await diary.watchEntriesForDate(day).first;
      final macros = await diary.watchMacroEntriesForDate(day).first;
      final fluids = await diary.watchFluidEntriesForDate(day).first;
      final products = await diary.getProductsByBarcodes(
        foods.map((food) => food.barcode).toSet().toList(),
      );
      final byBarcode = {
        for (final product in products) product.barcode: product,
      };
      final archived = await diary.getProductsByArchiveIds(
        foods
            .map((food) => food.archiveLocalId)
            .whereType<int>()
            .toSet()
            .toList(),
      );
      final date = _day(day);
      if (category == AssistantDataCategory.diary) {
        final meals = await diary.watchMealEntriesForDate(day).first;
        records.addAll([
          for (final meal in meals)
            {
              'ref': 'meal:${meal.id}',
              'date': date,
              'time': meal.consumedAt.toIso8601String(),
              'title': meal.title,
              'mealType': meal.mealType,
            },
          for (final food in foods)
            {
              'ref': 'foodEntry:${food.id}',
              'date': date,
              'time': food.timestamp.toIso8601String(),
              'name':
                  (food.archiveLocalId == null
                          ? byBarcode[food.barcode]
                          : archived[food.archiveLocalId])
                      ?.name,
              'grams': food.quantityInGrams,
              'mealType': food.mealType,
              'mealRef': food.mealEntryId == null
                  ? null
                  : 'meal:${food.mealEntryId}',
            },
          for (final macro in macros)
            {
              'ref': 'macroEntry:${macro.id}',
              'date': date,
              'time': macro.timestamp.toIso8601String(),
              'name': macro.name,
              'amount': macro.amount,
              'amountUnit': macro.amountUnit,
              'mealType': macro.mealType,
              'caloriesKcal': macro.totalCalories,
              'proteinGrams': macro.totalProtein,
              'carbsGrams': macro.totalCarbs,
              'fatGrams': macro.totalFat,
            },
          for (final fluid in fluids)
            {
              'ref': 'fluidEntry:${fluid.id}',
              'date': date,
              'time': fluid.timestamp.toIso8601String(),
              'name': fluid.name,
              'milliliters': fluid.quantityInMl,
            },
        ]);
      } else {
        final goals = await diary.watchGoalsForDate(day).first;
        final suppCaffeine = caffeineByDay[date] ?? 0.0;
        if (foods.isEmpty &&
            macros.isEmpty &&
            fluids.isEmpty &&
            suppCaffeine == 0.0 &&
            goals == null) {
          continue;
        }
        final summary = CalculateDailyNutritionUseCase()
            .execute(
              goals: goals,
              targetSugar: targetSugar,
              targetFiber: targetFiber,
              targetSalt: targetSalt,
              targetCaffeine: targetCaffeine,
              foodEntries: foods,
              macroEntries: macros,
              fluidEntries: fluids,
              foodProductsByBarcode: byBarcode,
              foodProductsByArchiveLocalId: archived,
              workoutLogs: const [],
              supplementsForDate: const [],
              allSupplements: const [],
              todaysSupplementLogs: const [],
            )
            .summary;
        final totalCaffeineMg = summary.caffeine + suppCaffeine;
        records.add({
          'ref': 'nutrition:$date',
          'date': date,
          'sourceRefs': [
            for (final food in foods) 'foodEntry:${food.id}',
            for (final macro in macros) 'macroEntry:${macro.id}',
            for (final fluid in fluids) 'fluidEntry:${fluid.id}',
          ],
          'foodEntryCount': foods.length,
          'macroEntryCount': macros.length,
          'fluidEntryCount': fluids.length,
          'caloriesKcal': summary.calories,
          'proteinGrams': summary.protein,
          'carbsGrams': summary.carbs,
          'fatGrams': summary.fat,
          'sugarGrams': _round1(summary.sugar),
          'fiberGrams': _round1(summary.fiber),
          'saltGrams': _round2(summary.salt),
          'caffeineMg': _round1(totalCaffeineMg),
          'waterMilliliters': summary.water,
          'targetCaloriesKcal': summary.targetCalories,
          'targetProteinGrams': summary.targetProtein,
          'targetCarbsGrams': summary.targetCarbs,
          'targetFatGrams': summary.targetFat,
          'targetWaterMilliliters': summary.targetWater,
          'targetSugarGrams': targetSugar > 0 ? targetSugar : null,
          'targetFiberGrams': targetFiber > 0 ? targetFiber : null,
          'targetSaltGrams': targetSalt > 0 ? targetSalt : null,
          'targetCaffeineMg': targetCaffeine > 0 ? targetCaffeine : null,
          'isIncompleteDay': incompleteDays.contains(date),
        });
      }
    }
    return AssistantActionResult(
      category: category,
      status: AssistantActionStatus.success,
      records: records,
    );
  }

  Future<Set<String>> _loadIncompleteDays(AssistantDateScope scope) async {
    final db = database;
    if (db == null) return const {};
    try {
      final rows = await db
          .customSelect(
            'SELECT day FROM incomplete_nutrition_days WHERE day >= ? AND day <= ?',
            variables: [
              drift.Variable.withString(_day(scope.start)),
              drift.Variable.withString(_day(scope.end)),
            ],
          )
          .get();
      return {for (final row in rows) row.read<String>('day')};
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, double>> _loadSupplementCaffeineByDay(
    AssistantDateScope scope,
  ) async {
    final db = database;
    if (db == null) return const {};
    try {
      final startSec =
          DateTime(
            scope.start.year,
            scope.start.month,
            scope.start.day,
          ).millisecondsSinceEpoch ~/
          1000;
      final endSec =
          DateTime(
            scope.end.year,
            scope.end.month,
            scope.end.day + 1,
          ).millisecondsSinceEpoch ~/
          1000;
      final rows = await db
          .customSelect(
            '''
            SELECT sl.taken_at, sl.amount
            FROM supplement_logs sl
            JOIN supplements s ON s.id = sl.supplement_id
            WHERE sl.deleted_at IS NULL
              AND s.deleted_at IS NULL
              AND (LOWER(COALESCE(s.code, '')) = 'caffeine'
                   OR LOWER(s.name) IN ('caffeine', 'koffein'))
              AND sl.taken_at >= ? AND sl.taken_at < ?
            ''',
            variables: [
              drift.Variable.withInt(startSec),
              drift.Variable.withInt(endSec),
            ],
          )
          .get();
      final byDay = <String, double>{};
      for (final row in rows) {
        final rawTs = row.read<int>('taken_at');
        final ms = rawTs.abs() < 100000000000 ? rawTs * 1000 : rawTs;
        final dayKey = _day(DateTime.fromMillisecondsSinceEpoch(ms).toLocal());
        final amount = row.read<double>('amount');
        byDay.update(dayKey, (v) => v + amount, ifAbsent: () => amount);
      }
      return byDay;
    } catch (_) {
      return const {};
    }
  }

  double _round1(double v) => (v * 10).roundToDouble() / 10;
  double _round2(double v) => (v * 100).roundToDouble() / 100;
  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
