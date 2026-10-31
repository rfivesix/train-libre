import '../../diary/domain/calculate_daily_nutrition_use_case.dart';
import '../../diary/domain/repositories/diary_repository.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

class AssistantDiaryActions implements AssistantDataAction {
  const AssistantDiaryActions(this.diary);
  final IDiaryRepository diary;

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
    final records = <Map<String, dynamic>>[];
    for (
      var day = scope!.start;
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
      final date =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
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
        if (foods.isEmpty &&
            macros.isEmpty &&
            fluids.isEmpty &&
            goals == null) {
          continue;
        }
        final summary = CalculateDailyNutritionUseCase()
            .execute(
              goals: goals,
              targetSugar: 0,
              targetFiber: 0,
              targetSalt: 0,
              targetCaffeine: 0,
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
          'waterMilliliters': summary.water,
          'targetCaloriesKcal': summary.targetCalories,
          'targetProteinGrams': summary.targetProtein,
          'targetCarbsGrams': summary.targetCarbs,
          'targetFatGrams': summary.targetFat,
          'targetWaterMilliliters': summary.targetWater,
        });
      }
    }
    return AssistantActionResult(
      category: category,
      status: AssistantActionStatus.success,
      records: records,
    );
  }
}
