import '../models/daily_goal.dart';
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/meal_entry.dart';
import '../models/food_item.dart';
import '../models/macro_entry.dart';
import '../../../supplements/domain/models/supplement_log.dart';

/// Abstract contract for Diary data persistence and operations.
abstract class IDiaryRepository {
  Stream<DailyGoal?> watchGoalsForDate(DateTime date);
  Stream<List<FoodEntry>> watchEntriesForDate(DateTime date);
  Stream<List<MacroEntry>> watchMacroEntriesForDate(DateTime date);
  Stream<List<FluidEntry>> watchFluidEntriesForDate(DateTime date);
  Stream<List<MealEntry>> watchMealEntriesForDate(DateTime date);
  Future<MealEntry?> getMealEntryById(String id);
  Future<bool> hasAnyDiaryEntries();
  Future<bool> hasWeightMeasurementForDate(DateTime date);

  @Deprecated('Use watchGoalsForDate instead')
  Future<DailyGoal?> getGoalsForDate(DateTime date);

  @Deprecated('Use watchEntriesForDate instead')
  Future<List<FoodEntry>> getEntriesForDate(DateTime date);

  @Deprecated('Use watchFluidEntriesForDate instead')
  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date);

  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes);
  Future<Map<int, FoodItem>> getProductsByArchiveIds(List<int> ids);

  Future<void> deleteFoodEntry(int id);
  Future<void> deleteMacroEntry(String id);
  Future<void> deleteFluidEntry(int id);
  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId);

  Future<void> updateFluidEntry(FluidEntry entry);
  Future<void> updateFoodEntry(FoodEntry entry);
  Future<void> updateMacroEntry(MacroEntry entry);
  Future<int> insertFluidEntry(FluidEntry entry);
  Future<int> insertFoodEntry(FoodEntry entry, {String telemetrySource});
  Future<void> insertMacroEntry(MacroEntry entry);

  Future<String> insertMealEntry(MealEntry entry);
  Future<void> insertMealEntryWithMacroEntries(
    MealEntry entry,
    List<MacroEntry> macroEntries,
  );
  Future<void> updateMealEntry(MealEntry entry);

  /// Moves a logged meal and every row linked to it to [newConsumedAt].
  ///
  /// Use this rather than [updateMealEntry] whenever the timestamp changes:
  /// the diary buckets rows by their own timestamp column, so the linked
  /// nutrition, fluid and supplement logs have to move along or the two days
  /// end up disagreeing about where the meal's calories live.
  Future<void> moveMealEntryTo(String mealEntryId, DateTime newConsumedAt);

  Future<void> deleteMealEntry(String id, {required bool deleteFoodLogs});

  Future<void> updateSupplementLog(SupplementLog log);
  Future<void> deleteSupplementLog(int id);
}
