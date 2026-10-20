import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/core/infrastructure/caffeine_catalog_resolver.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #421: Beverage/Fluid Ingestion Mapping', () {
    late db.AppDatabase database;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    // Helper to invoke private _mapProductRow via the visibleForTesting helper
    dynamic mapProductRowHelper(Map<String, dynamic> row, String sourceLabel) {
      return BasisDataManager.instance
          .mapProductRowForTesting(row, sourceLabel: sourceLabel);
    }

    test('default fallback isFluid is false', () {
      final row = {
        'barcode': '123',
        'name': 'Solid Apple',
        'calories': 52,
        'protein': 0.3,
        'carbs': 14.0,
        'fat': 0.2,
      };
      final db.ProductsCompanion companion = mapProductRowHelper(row, 'off');
      expect(companion.isFluid.value, isFalse);
    });

    test('isFluid is false when nutrition baseline token contains 100g', () {
      final row = {
        'barcode': '123',
        'name': 'Apple Puree',
        'calories': 52,
        'protein': 0.3,
        'carbs': 14.0,
        'fat': 0.2,
        'nutrition_data_per': '100g',
        'is_fluid': 1, // Stale column value that should be overridden
      };
      final db.ProductsCompanion companion = mapProductRowHelper(row, 'off');
      expect(companion.isFluid.value, isFalse);
    });

    test('isFluid is true when nutrition baseline token contains 100ml', () {
      final row = {
        'barcode': '456',
        'name': 'Orange Juice',
        'calories': 45,
        'protein': 0.7,
        'carbs': 10.4,
        'fat': 0.2,
        'nutrition_data_prepared_per': '100ml',
      };
      final db.ProductsCompanion companion = mapProductRowHelper(row, 'off');
      expect(companion.isFluid.value, isTrue);
    });

    test(
        'isFluid is true when category contains beverages, drinks, or waters tags',
        () {
      final row1 = {
        'barcode': '789',
        'name': 'Cola',
        'calories': 40,
        'protein': 0.0,
        'carbs': 10.0,
        'fat': 0.0,
        'category': 'en:beverages',
      };
      final db.ProductsCompanion companion1 = mapProductRowHelper(row1, 'off');
      expect(companion1.isFluid.value, isTrue);

      final row2 = {
        'barcode': '7892',
        'name': 'Energy Drink',
        'calories': 45,
        'protein': 0.0,
        'carbs': 11.0,
        'fat': 0.0,
        'categories_tags': 'en:drinks',
      };
      final db.ProductsCompanion companion2 = mapProductRowHelper(row2, 'off');
      expect(companion2.isFluid.value, isTrue);

      final row3 = {
        'barcode': '7893',
        'name': 'Mineral Water',
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'categories': 'en:waters',
      };
      final db.ProductsCompanion companion3 = mapProductRowHelper(row3, 'off');
      expect(companion3.isFluid.value, isTrue);
    });

    test(
        'caffeine falls back to caffeine_mg_per_100g when caffeine/caffeine_mg_per_100ml is absent in catalog row',
        () {
      final coffeeRow = {
        'barcode': 'base_food_coffee_black',
        'name': 'Kaffee (schwarz, ungesüßt)',
        'calories': 2,
        'protein': 0.1,
        'carbs': 0.3,
        'fat': 0.0,
        'caffeine_mg_per_100g': 40.0,
        'category': 'en:coffees',
        'is_fluid': 1,
      };
      final db.ProductsCompanion companion =
          mapProductRowHelper(coffeeRow, 'base');
      expect(companion.caffeine.value, 40.0);
      expect(companion.caffeineMgPer100g.value, 40.0);
      expect(companion.isFluid.value, isTrue);

      final foodItem = FoodItem.fromMap(coffeeRow, source: FoodItemSource.base);
      expect(foodItem.caffeineMgPer100g, 40.0);
      expect(foodItem.caffeineMgPer100ml, 40.0);
      expect(foodItem.effectiveCaffeinePer100ml, 40.0);
      expect(foodItem.isFluidOrLiquid, isTrue);
    });
  });

  group('Issue #423: EAN Master Record Overrides', () {
    late db.AppDatabase database;
    late ProductLocalDataSource productDb;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
      productDb = ProductLocalDataSource.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('prioritizes user overrides over static OFF catalog records',
        () async {
      // 1. Insert static uncorrected OFF item
      final barcode = '4012345678901';
      await database.into(database.products).insert(
            db.ProductsCompanion.insert(
              barcode: barcode,
              name: 'Monster Ultra (Uncorrected)',
              calories: 2,
              protein: 0.0,
              carbs: 0.9,
              fat: 0.0,
              source: const drift.Value('off'),
              isFluid: const drift.Value(false),
            ),
          );

      // Verify base fetch retrieves uncorrected values
      final initialItem = await productDb.getProductByBarcode(barcode);
      expect(initialItem, isNotNull);
      expect(initialItem!.name, 'Monster Ultra (Uncorrected)');
      expect(initialItem.isFluid, isFalse);

      // 2. Perform custom user modifications (updates caffeine, fluid status, Net Qty)
      final modifiedItem = FoodItem(
        barcode: barcode,
        name: 'Monster Ultra',
        brand: 'Monster Energy',
        calories: 3,
        protein: 0.1,
        carbs: 1.1,
        fat: 0.0,
        source: FoodItemSource.off,
        isFluid: true,
        caffeineMgPer100ml: 32.0,
        productQuantity: 500.0,
        productQuantityUnit: 'ml',
      );

      // Save using updateProduct (which executes an automatic upsert into user_food_overrides)
      await productDb.updateProduct(modifiedItem);

      // Verify that user_food_overrides table has the record saved
      final overrideRow = await (database.select(database.userFoodOverrides)
            ..where((tbl) => tbl.barcode.equals(barcode)))
          .getSingle();
      expect(overrideRow.name, 'Monster Ultra');
      expect(overrideRow.caffeine, 32.0);
      expect(overrideRow.isFluid, isTrue);

      // 3. Verify repository lookups prioritize the overrides!
      final fetchedItem = await productDb.getProductByBarcode(barcode);
      expect(fetchedItem, isNotNull);
      expect(fetchedItem!.name, 'Monster Ultra');
      expect(fetchedItem.brand, 'Monster Energy');
      expect(fetchedItem.calories, 3);
      expect(fetchedItem.protein, 0.1);
      expect(fetchedItem.carbs, 1.1);
      expect(fetchedItem.isFluid, isTrue);
      expect(fetchedItem.caffeineMgPer100ml, 32.0);
      expect(fetchedItem.productQuantity, 500.0);
      expect(fetchedItem.productQuantityUnit, 'ml');

      // Verify batch lookup also prioritizes the override
      final batchFetched = await productDb.getProductsByBarcodes([barcode]);
      expect(batchFetched.first.name, 'Monster Ultra');
      expect(batchFetched.first.caffeineMgPer100ml, 32.0);

      // Verify global search prioritized overrides
      final searchResult = await productDb.searchProducts('Monster');
      expect(searchResult.first.name, 'Monster Ultra');
      expect(searchResult.first.caffeineMgPer100ml, 32.0);
    });

    test(
        'can call updateProduct consecutively for the same barcode without unique constraint exceptions',
        () async {
      final barcode = '9999999999999';
      final item1 = FoodItem(
        barcode: barcode,
        name: 'First Version',
        brand: 'Brand',
        calories: 100,
        protein: 1.0,
        carbs: 10.0,
        fat: 1.0,
        source: FoodItemSource.user,
      );

      await productDb.insertProduct(item1);

      final item2 = FoodItem(
        barcode: barcode,
        name: 'Second Version',
        brand: 'Brand',
        calories: 120,
        protein: 2.0,
        carbs: 12.0,
        fat: 2.0,
        source: FoodItemSource.user,
      );

      // Verify that this call succeeds without throwing any UNIQUE constraint SQLite exception!
      await productDb.updateProduct(item2);

      final fetched = await productDb.getProductByBarcode(barcode);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Second Version');
      expect(fetched.calories, 120);
    });

    test('CaffeineCatalogResolver resolves caffeine for BLS beverages and by name heuristic', () {
      expect(CaffeineCatalogResolver.lookupCaffeine('bls:N330000', 'Colagetränk koffeinhaltig'), 10.0);
      expect(CaffeineCatalogResolver.lookupCaffeine('bls:N331000', 'Colagetränk koffeinhaltig, mit Süßungsmitteln'), 10.0);
      expect(CaffeineCatalogResolver.lookupCaffeine('bls:N340000', 'Colagetränk koffeinfrei'), 0.0);
      expect(CaffeineCatalogResolver.lookupCaffeine('bls:N410100', 'Kaffee (Getränk)'), 40.0);
      expect(CaffeineCatalogResolver.lookupCaffeine('bls:N411100', 'Espresso'), 212.0);
      expect(CaffeineCatalogResolver.lookupCaffeine(null, 'Monster Energy Drink'), 32.0);
      expect(CaffeineCatalogResolver.lookupCaffeine(null, 'Kaffee entkoffeiniert'), 0.0);
      expect(CaffeineCatalogResolver.lookupCaffeine(null, 'Kaffeeersatz (Getränk)'), 0.0);
      expect(CaffeineCatalogResolver.lookupCaffeine(null, 'Club Mate'), 35.0);
      expect(CaffeineCatalogResolver.lookupCaffeine(null, 'Schwarztee (ungesüßt)'), 20.0);
      expect(CaffeineCatalogResolver.lookupCaffeine(null, 'Grüner Tee'), 15.0);
    });

    test('FoodItem effectiveCaffeinePer100ml falls back to CaffeineCatalogResolver when raw fields are null', () {
      final cola = FoodItem(
        barcode: 'bls:N330000',
        name: 'Colagetränk koffeinhaltig',
        nameDe: 'Colagetränk koffeinhaltig',
        calories: 41,
        protein: 0.0,
        carbs: 10.3,
        fat: 0.0,
        isFluid: true,
      );
      expect(cola.caffeineMgPer100g, isNull);
      expect(cola.caffeineMgPer100ml, isNull);
      expect(cola.effectiveCaffeinePer100ml, 10.0);
      expect(cola.effectiveCaffeinePer100g, 10.0);

      final coffee = FoodItem(
        barcode: 'bls:N410100',
        name: 'Kaffee (Getränk)',
        nameDe: 'Kaffee (Getränk)',
        calories: 2,
        protein: 0.2,
        carbs: 0.3,
        fat: 0.0,
        isFluid: true,
      );
      expect(coffee.effectiveCaffeinePer100ml, 40.0);
    });
  });
}
