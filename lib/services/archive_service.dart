import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/drift_database.dart';
import '../features/diary/domain/models/food_item.dart';

class ArchiveService {
  final AppDatabase _db;

  ArchiveService(this._db);

  /// Computes the content hash and returns the localId of the archived product snapshot.
  /// If it does not exist in the archive, it creates it.
  Future<int> getOrCreateArchiveEntry({
    required FoodItem foodItem,
    bool hadUserOverride = false,
  }) async {
    final barcode = foodItem.barcode;
    final name = foodItem.name;
    final brand = foodItem.brand;
    final calories = foodItem.calories;
    final protein = foodItem.protein;
    final carbs = foodItem.carbs;
    final fat = foodItem.fat;
    final sugar = foodItem.sugar;
    final fiber = foodItem.fiber;
    final salt = foodItem.salt;
    final caffeine = foodItem.caffeineMgPer100ml;
    final caffeineMgPer100g = foodItem.caffeineMgPer100g;
    final productQuantity = foodItem.productQuantity;
    final productQuantityUnit = foodItem.productQuantityUnit;
    final isFluid = foodItem.isFluid ?? false;
    final isLiquid = foodItem.isLiquid ?? false;
    final source = _sourceToString(foodItem.source);
    final category = foodItem.category;

    final contentHash = calculateProductContentHash(
      barcode: barcode,
      name: name,
      brand: brand,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugar: sugar,
      fiber: fiber,
      salt: salt,
      caffeine: caffeine,
      caffeineMgPer100g: caffeineMgPer100g,
      productQuantity: productQuantity,
      productQuantityUnit: productQuantityUnit,
      isFluid: isFluid,
      isLiquid: isLiquid,
      hadUserOverride: hadUserOverride,
    );

    // 1. Try to find the existing entry in the database
    final existing = await (_db.select(_db.offProductsArchive)
          ..where((tbl) => tbl.contentHash.equals(contentHash))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      return existing.localId;
    }

    // 2. If not found, create a new archive entry
    final companion = OffProductsArchiveCompanion.insert(
      id: Value(const Uuid().v4()),
      barcode: barcode,
      productName: name,
      brand: Value(brand),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugar: Value(sugar),
      fiber: Value(fiber),
      salt: Value(salt),
      caffeine: Value(caffeine),
      caffeineMgPer100g: Value(caffeineMgPer100g),
      productQuantity: Value(productQuantity),
      productQuantityUnit: Value(productQuantityUnit),
      isFluid: Value(isFluid),
      isLiquid: Value(isLiquid),
      category: Value(category),
      contentHash: contentHash,
      source: source,
      hadUserOverride: Value(hadUserOverride),
    );

    return await _db.into(_db.offProductsArchive).insert(companion);
  }

  String _sourceToString(FoodItemSource source) {
    switch (source) {
      case FoodItemSource.base:
        return 'base';
      case FoodItemSource.off:
        return 'off';
      case FoodItemSource.user:
        return 'user';
    }
  }
}
