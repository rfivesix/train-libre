import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/canonical_scenarios.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/nutrition_test_data_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionTestDataSeeder', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('seedScenario injects scenario and clears cleanly', () async {
      final scenario = CanonicalNutritionScenarios.all.first;
      await NutritionTestDataSeeder.seedScenario(scenario, dbHelper: dbHelper);

      final goals = await database.select(database.userGoals).get();
      expect(goals.length, 1);
      expect(goals.first.title.contains('[DevLab]'), isTrue);

      final reviews = await database.select(database.goalReviews).get();
      expect(reviews.length, 1);

      final products = await database.select(database.products).get();
      expect(products.length, 1);
      expect(products.first.barcode, NutritionTestDataSeeder.testFixtureBarcode);

      await NutritionTestDataSeeder.clearNutritionTestData(dbHelper: dbHelper);

      final remainingGoals = await database.select(database.userGoals).get();
      expect(remainingGoals, isEmpty);

      final remainingReviews = await database.select(database.goalReviews).get();
      expect(remainingReviews, isEmpty);

      final remainingProducts = await database.select(database.products).get();
      expect(remainingProducts, isEmpty);
    });

    test('seedScenario is idempotent and does not fail on repeated injection', () async {
      // 1. Seed first scenario (on track)
      await NutritionTestDataSeeder.seedScenario(
        CanonicalNutritionScenarios.all[0],
        dbHelper: dbHelper,
      );

      // 2. Seed a second scenario immediately without clear (plateau)
      await NutritionTestDataSeeder.seedScenario(
        CanonicalNutritionScenarios.all[1],
        dbHelper: dbHelper,
      );

      // 3. Seed the same scenario again
      await NutritionTestDataSeeder.seedScenario(
        CanonicalNutritionScenarios.all[1],
        dbHelper: dbHelper,
      );

      // Only one active goal should exist
      final activeGoals = await (database.select(database.userGoals)
            ..where((t) => t.status.equals('active')))
          .get();
      expect(activeGoals.length, 1);

      // Products table should have exactly 1 test product without unique constraint crashes
      final products = await (database.select(database.products)
            ..where((t) => t.barcode.equals(NutritionTestDataSeeder.testFixtureBarcode)))
          .get();
      expect(products.length, 1);
    });
  });
}
