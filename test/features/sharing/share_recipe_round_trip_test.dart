import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/sharing/share_link_repository.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recipe share import preserves servings and cooked yield', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final helper = DatabaseHelper.forTesting(database);
    DatabaseHelper.setDriftDb(database);
    addTearDown(database.close);

    await database.into(database.products).insert(
          const ProductsCompanion(
            barcode: drift.Value('recipe-test-rice'),
            name: drift.Value('Rice'),
            calories: drift.Value(130),
            protein: drift.Value(2.7),
            carbs: drift.Value(28),
            fat: drift.Value(0.3),
            source: drift.Value('base'),
          ),
        );
    final recipeId = await helper.insertMeal(
      name: 'Rice bowl',
      notes: 'Meal prep',
      servingCount: 4,
      cookedWeightInGrams: 900,
    );
    await helper.addMealItem(
      mealId: recipeId,
      barcode: 'recipe-test-rice',
      amount: 1000,
    );

    final recipe = (await helper.getMeals()).single;
    final repository = const ShareLinkRepository();
    final payload = await repository.forRecipe(recipe);
    await repository.import(payload);

    final imported = (await helper.getMeals()).last;
    expect(imported['serving_count'], 4);
    expect(imported['cooked_weight_in_grams'], 900);
    final importedItems = await helper.getMealItems(imported['id'] as int);
    expect(importedItems, hasLength(1));
    expect(importedItems.single['quantity_in_grams'], 1000);
  });
}
