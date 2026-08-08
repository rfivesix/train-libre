import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/backup_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/diary/domain/models/food_entry.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/domain/calculate_daily_nutrition_use_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Offline Food Archive Integration & Unit Tests', () {
    late db.AppDatabase database;
    late DiaryLocalDataSource diaryDb;
    late ProductLocalDataSource productDb;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
      diaryDb = DiaryLocalDataSource(database);
      productDb = ProductLocalDataSource.forTesting(database);
      DatabaseHelper.setDriftDb(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
        'Auto-creates archive snapshots upon diary log insertions and reuse existing snaps',
        () async {
      final barcode = '4008400401821';
      // 1. Insert product into catalog
      await database.into(database.products).insert(
            db.ProductsCompanion.insert(
              barcode: barcode,
              name: 'Nutella',
              brand: const drift.Value('Ferrero'),
              calories: 539,
              protein: 6.3,
              carbs: 57.5,
              fat: 30.9,
              source: const drift.Value('off'),
            ),
          );

      // 2. Insert diary log
      final entry1 = FoodEntry(
        barcode: barcode,
        timestamp: DateTime.now(),
        quantityInGrams: 50,
        mealType: 'mealtypeBreakfast',
      );

      final logId1 = await diaryDb.insertFoodEntry(entry1);
      final insertedLog1 = await (database.select(database.nutritionLogs)
            ..where((tbl) => tbl.localId.equals(logId1)))
          .getSingle();

      expect(insertedLog1.archiveLocalId, isNotNull);

      // Verify archived snapshot content
      final archiveRow1 = await (database.select(database.offProductsArchive)
            ..where((tbl) => tbl.localId.equals(insertedLog1.archiveLocalId!)))
          .getSingle();

      expect(archiveRow1.barcode, barcode);
      expect(archiveRow1.productName, 'Nutella');
      expect(archiveRow1.calories, 539);
      expect(archiveRow1.protein, 6.3);

      // 3. Log same product again, should reuse the same snapshot (deduplication)
      final entry2 = FoodEntry(
        barcode: barcode,
        timestamp: DateTime.now().add(const Duration(hours: 1)),
        quantityInGrams: 30,
        mealType: 'mealtypeLunch',
      );

      final logId2 = await diaryDb.insertFoodEntry(entry2);
      final insertedLog2 = await (database.select(database.nutritionLogs)
            ..where((tbl) => tbl.localId.equals(logId2)))
          .getSingle();

      expect(insertedLog2.archiveLocalId, equals(insertedLog1.archiveLocalId));

      // Assert archive row count is 1
      final allArchiveRows =
          await database.select(database.offProductsArchive).get();
      expect(allArchiveRows.length, 1);
    });

    test(
        'Bakes custom overrides into the snapshot and keeps historical records immune from edits',
        () async {
      final barcode = '4001234567890';
      // 1. Insert product
      await database.into(database.products).insert(
            db.ProductsCompanion.insert(
              barcode: barcode,
              name: 'Peanut Butter',
              calories: 600,
              protein: 25.0,
              carbs: 20.0,
              fat: 50.0,
              source: const drift.Value('off'),
            ),
          );

      // 2. Perform overrides
      final overrideItem = FoodItem(
        barcode: barcode,
        name: 'Organic Peanut Butter',
        brand: 'Ur-Brand',
        calories: 620,
        protein: 26.0,
        carbs: 18.0,
        fat: 52.0,
        source: FoodItemSource.off,
      );
      await productDb.updateProduct(overrideItem);

      // 3. Log to diary
      final entry1 = FoodEntry(
        barcode: barcode,
        timestamp: DateTime.now(),
        quantityInGrams: 100,
        mealType: 'mealtypeBreakfast',
      );
      final logId1 = await diaryDb.insertFoodEntry(entry1);
      final insertedLog1 = await (database.select(database.nutritionLogs)
            ..where((tbl) => tbl.localId.equals(logId1)))
          .getSingle();

      final archiveRow1 = await (database.select(database.offProductsArchive)
            ..where((tbl) => tbl.localId.equals(insertedLog1.archiveLocalId!)))
          .getSingle();

      expect(archiveRow1.productName, 'Organic Peanut Butter');
      expect(archiveRow1.calories, 620);
      expect(archiveRow1.hadUserOverride, isTrue);

      // 4. Update the override again (simulate future edits)

      final secondaryOverride = FoodItem(
        barcode: barcode,
        name: 'Extra Crunchy Peanut Butter',
        brand: 'Ur-Brand',
        calories: 650,
        protein: 26.0,
        carbs: 18.0,
        fat: 52.0,
        source: FoodItemSource.off,
      );
      await productDb.updateProduct(secondaryOverride);

      // Log again (should create a NEW snapshot version)
      final entry2 = FoodEntry(
        barcode: barcode,
        timestamp: DateTime.now(),
        quantityInGrams: 50,
        mealType: 'mealtypeSnack',
      );
      final logId2 = await diaryDb.insertFoodEntry(entry2);
      final insertedLog2 = await (database.select(database.nutritionLogs)
            ..where((tbl) => tbl.localId.equals(logId2)))
          .getSingle();

      expect(insertedLog2.archiveLocalId, isNot(insertedLog1.archiveLocalId));

      final archiveRow2 = await (database.select(database.offProductsArchive)
            ..where((tbl) => tbl.localId.equals(insertedLog2.archiveLocalId!)))
          .getSingle();

      expect(archiveRow2.productName, 'Extra Crunchy Peanut Butter');
      expect(archiveRow2.calories, 650);

      // Verify historical first log is immune (keeps pointing to version 1)
      final archiveRow1Verify = await (database
              .select(database.offProductsArchive)
            ..where((tbl) => tbl.localId.equals(insertedLog1.archiveLocalId!)))
          .getSingle();
      expect(archiveRow1Verify.productName, 'Organic Peanut Butter');
      expect(archiveRow1Verify.calories, 620);
    });

    test('3-Tier lookup resolution chain calculates correct nutrition values',
        () async {
      final barcode1 = 'EAN1';
      final barcode2 = 'EAN2';

      // 1. Create a product in offProductsArchive (mocking archived product)
      final archiveLocalId =
          await database.into(database.offProductsArchive).insert(
                db.OffProductsArchiveCompanion.insert(
                  id: const drift.Value('uuid-archive-1'),
                  barcode: barcode1,
                  productName: 'Archived Granola',
                  calories: 400,
                  protein: 10.0,
                  carbs: 60.0,
                  fat: 15.0,
                  contentHash: 'hash1',
                  source: 'off',
                ),
              );

      // 2. Create a product in Products (catalog product)
      await database.into(database.products).insert(
            db.ProductsCompanion.insert(
              barcode: barcode2,
              name: 'Catalog Granola Bar',
              calories: 380,
              protein: 8.0,
              carbs: 50.0,
              fat: 12.0,
              source: const drift.Value('off'),
            ),
          );

      // Create FoodEntry objects representing logged items
      final foodEntries = [
        FoodEntry(
          id: 101,
          barcode: barcode1,
          timestamp: DateTime.now(),
          quantityInGrams: 100, // 400 kcal
          mealType: 'mealtypeBreakfast',
          archiveLocalId: archiveLocalId,
        ),
        FoodEntry(
          id: 102,
          barcode: barcode2,
          timestamp: DateTime.now(),
          quantityInGrams: 50, // 380 * 0.5 = 190 kcal
          mealType: 'mealtypeLunch',
        ),
      ];

      // Perform resolution using IDiaryRepository lookups in ViewModel
      final archiveProductsMap = <int, FoodItem>{};
      final legacyProductsMap = <String, FoodItem>{};

      // Query archived products
      final archivedProducts =
          await productDb.getProductsByArchiveIds([archiveLocalId]);
      archiveProductsMap.addAll(archivedProducts);

      // Query legacy products
      final legacyProducts = await productDb.getProductsByBarcodes([barcode2]);
      for (final p in legacyProducts) {
        legacyProductsMap[p.barcode] = p;
      }

      // Execute Daily Nutrition calculations UseCase
      final useCase = CalculateDailyNutritionUseCase();
      final state = useCase.execute(
        goals: null,
        targetSugar: 50,
        targetFiber: 30,
        targetSalt: 6,
        targetCaffeine: 400,
        foodEntries: foodEntries,
        fluidEntries: [],
        foodProductsByBarcode: legacyProductsMap,
        foodProductsByArchiveLocalId: archiveProductsMap,
        workoutLogs: [],
        supplementsForDate: [],
        allSupplements: [],
        todaysSupplementLogs: [],
      );

      expect(state.summary.calories, 590); // 400 + 190
      expect(state.summary.protein, 14); // 10 + 4
      expect(state.summary.carbs, 85); // 60 + 25
      expect(state.summary.fat, 21); // 15 + 6
    });

    test(
        'Backup and restore preserves archive references and snapshots round-trip (Backup format v5)',
        () async {
      final barcode = '4008400401821';
      // 1. Setup DB state with an archived log
      await database.into(database.products).insert(
            db.ProductsCompanion.insert(
              barcode: barcode,
              name: 'Nutella',
              brand: const drift.Value('Ferrero'),
              calories: 539,
              protein: 6.3,
              carbs: 57.5,
              fat: 30.9,
              source: const drift.Value('off'),
            ),
          );

      await diaryDb.insertFoodEntry(
        FoodEntry(
          barcode: barcode,
          timestamp: DateTime.now(),
          quantityInGrams: 40,
          mealType: 'mealtypeBreakfast',
        ),
      );

      final manager = BackupManager(dbHelper: DatabaseHelper.instance);
      final payload = await manager.generateBackupPayload();

      // Ensure offProductsArchive is in the JSON payload and database backup format version is 5
      expect(payload['schemaVersion'], 5);
      expect(payload['offProductsArchive'], isNotEmpty);
      expect(payload['offProductsArchive'].first['product_name'], 'Nutella');

      // Clear all data
      await DatabaseHelper.instance.clearAllUserData();
      final afterClearArchive =
          await database.select(database.offProductsArchive).get();
      expect(afterClearArchive, isEmpty);

      // Restore backup payload
      final success = await manager.importBackupPayloadForTesting(payload);
      expect(success, isTrue);

      // Verify restoration of archive snapshots and FK linkages
      final restoredArchive =
          await database.select(database.offProductsArchive).get();
      expect(restoredArchive, isNotEmpty);
      expect(restoredArchive.first.productName, 'Nutella');

      final restoredLogs = await database.select(database.nutritionLogs).get();
      expect(restoredLogs.first.archiveLocalId,
          equals(restoredArchive.first.localId));
    });
  });
}
