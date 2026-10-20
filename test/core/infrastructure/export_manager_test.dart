import 'package:drift/native.dart';
import 'package:excel_community/excel_community.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/export_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/domain/models/food_entry.dart';
import 'package:train_libre/services/bls_food_catalog_refresh_service.dart';
import 'package:train_libre/services/health/health_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseHelper databaseHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'unit_system': 'metric',
      'ai_api_key_openai': 'do-not-export',
      'installed_training_version': 'device-local',
      'installed_bls_food_version': 'bls-device-local',
      'bls_food_catalog_last_error': 'local cache status',
      'posthog_user_id': 'telemetry-id',
      'device_id': 'device-id',
      'profileImagePath': '/private/profile.jpg',
      'auto_backup_tree_uri': 'content://device-local/tree',
      'ai_meal_scan_diagnostics_v1': '[{}]',
      'custom_api_token': 'secret-token',
      'off_catalog_active_country': 'fr',
    });
    database = AppDatabase(NativeDatabase.memory());
    databaseHelper = DatabaseHelper.forTesting(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('complete workbook includes every declared personal data table',
      () async {
    final sheets = await ExportManager.collectCompleteDataSheetsForTesting(
      databaseHelper: databaseHelper,
      foodEntries: const [],
      nutrientFacts: const [],
      catalogAvailable: false,
    );
    final actualTableNames = sheets
        .where((sheet) =>
            sheet.name != 'app_preferences' &&
            sheet.name != 'micronutrients' &&
            sheet.name != 'micronutrient_coverage')
        .map((sheet) => sheet.name)
        .toSet();

    expect(
      actualTableNames,
      containsAll([
        'profiles',
        'app_settings',
        'custom_exercises',
        'exercise_translations',
        'routines',
        'routine_exercises',
        'routine_set_templates',
        'workout_logs',
        'set_logs',
        'cardio_activities',
        'cardio_samples',
        'food_items',
        'food_snapshots',
        'nutrition_logs',
        'fluid_logs',
        'supplements',
        'supplement_logs',
        'measurements',
        'meal_entries',
        'saved_meals',
        'saved_meal_items',
        'food_favorites',
        'daily_goals_history',
        'supplement_settings_history',
        'health_step_segments',
        'workout_exercise_logs',
        'pinned_exercise_notes',
        'user_food_overrides',
        'food_override_translations',
        'user_goals',
        'goal_events',
        'goal_reviews',
        'training_plans',
        'training_plan_revisions',
        'training_plan_activations',
        'training_plan_occurrences',
        'sleep_sessions',
        'sleep_stages',
        'sleep_heart_rate',
        'sleep_analyses',
        'pulse_hourly_aggregates',
        'shared_posts',
        'social_interactions',
      ]),
    );
    expect(
      ExportManager.completeWorkbookTableNames,
      containsAll([
        'profiles',
        'nutrition_logs',
        'supplement_logs',
        'measurements',
        'meal_entries',
        'workout_logs',
        'training_plan_occurrences',
        'sleep_canonical_heart_rate_samples',
      ]),
    );
  });

  test('workbook preserves diary IDs, links, timestamps, and preferences',
      () async {
    final consumedAt = DateTime.utc(2026, 10, 12, 12).millisecondsSinceEpoch;
    await database.customStatement('''
      INSERT INTO meal_entries (id, consumed_at, meal_type, title, source, capture_meta)
      VALUES ('meal-1', $consumedAt, 'lunch', 'Lunch bowl', 'manual', '{"provider":"openai","extra_photos":["media/meals/private.jpg"]}')
    ''');
    await database.customStatement('''
      INSERT INTO products (id, barcode, name, calories, protein, carbs, fat, source)
      VALUES ('product-1', 'legacy-123', 'Legacy food', 125, 4.0, 12.0, 3.0, 'off')
    ''');
    await database.customStatement('''
      INSERT INTO nutrition_logs (id, consumed_at, amount, meal_type, legacy_barcode, meal_entry_id)
      VALUES ('food-1', $consumedAt, 125.0, 'lunch', 'legacy-123', 'meal-1')
    ''');
    final goalStartedAt = DateTime.utc(2026, 9, 1).millisecondsSinceEpoch;
    await database.customStatement('''
      INSERT INTO user_goals (id, preset, title, start_date)
      VALUES ('goal-1', 'custom', 'September goal', $goalStartedAt)
    ''');

    final preferences = await SharedPreferences.getInstance();
    final sheets = await ExportManager.collectCompleteDataSheetsForTesting(
      databaseHelper: databaseHelper,
      preferences: preferences,
      foodEntries: const [],
      nutrientFacts: const [],
      catalogAvailable: true,
    );
    final data = ExcelExportData(
      nutritionRows: const [],
      workoutRows: const [],
      sleepRows: const [],
      stepSegments: const [],
      pulseAggregates: const [],
      workoutHeartRatesByDay: const {},
      stepsSourcePolicy: StepsSourcePolicy.autoDominant,
      measurementRows: const [],
      pinnedNoteRows: const [],
      completeDataSheets: sheets,
    );

    final bytes = ExportManager.buildWorkbookForTesting(data);
    expect(bytes, isNotNull);
    final workbook = xl.Excel.decodeBytes(bytes!);
    final nutrition = workbook.tables['nutrition_logs']!;
    final headers = nutrition.rows.first
        .map((cell) => cell?.value?.toString() ?? '')
        .toList();
    final row =
        nutrition.rows[1].map((cell) => cell?.value?.toString() ?? '').toList();

    expect(headers, containsAll(['id', 'meal_type', 'meal_entry_id']));
    expect(row[headers.indexOf('id')], 'food-1');
    expect(row[headers.indexOf('meal_entry_id')], 'meal-1');
    expect(row[headers.indexOf('consumed_at')], '2026-10-12T12:00:00.000Z');
    final foodItems = workbook.tables['food_items']!;
    final foodHeaders = foodItems.rows.first
        .map((cell) => cell?.value?.toString() ?? '')
        .toList();
    expect(
      foodItems.rows.any((cells) =>
          cells[foodHeaders.indexOf('id')]?.value?.toString() == 'product-1'),
      isTrue,
      reason: 'barcode-linked legacy food rows must retain their food record',
    );
    final goals = workbook.tables['user_goals']!;
    final goalHeaders =
        goals.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
    expect(
      goals.rows[1][goalHeaders.indexOf('start_date')]?.value?.toString(),
      '2026-09-01T00:00:00.000Z',
    );

    final exportedPreferences = workbook.tables['app_preferences']!.rows
        .map((cells) =>
            cells.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();
    expect(
        exportedPreferences.any((row) => row.first == 'unit_system'), isTrue);
    expect(exportedPreferences.any((row) => row.first == 'ai_api_key_openai'),
        isFalse);
    expect(exportedPreferences.any((row) => row.first == 'device_id'), isFalse);
    expect(exportedPreferences.any((row) => row.first == 'profileImagePath'),
        isFalse);
    expect(
        exportedPreferences.any((row) => row.first == 'auto_backup_tree_uri'),
        isFalse);
    expect(
        exportedPreferences
            .any((row) => row.first == 'ai_meal_scan_diagnostics_v1'),
        isFalse);
    expect(exportedPreferences.any((row) => row.first == 'custom_api_token'),
        isFalse);
    expect(exportedPreferences.any((row) => row.first == 'posthog_user_id'),
        isFalse);
    expect(
      exportedPreferences
          .any((row) => row.first == 'installed_training_version'),
      isFalse,
    );
    expect(
        exportedPreferences
            .any((row) => row.first == 'installed_bls_food_version'),
        isFalse);
    expect(
        exportedPreferences
            .any((row) => row.first == 'bls_food_catalog_last_error'),
        isFalse);
    expect(
        exportedPreferences
            .any((row) => row.first == 'off_catalog_active_country'),
        isTrue);

    final meals = workbook.tables['meal_entries']!;
    final mealHeaders =
        meals.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
    expect(mealHeaders, isNot(contains('photo_path')));
    expect(mealHeaders, isNot(contains('photo_thumb_path')));
    final captureMeta =
        meals.rows[1][mealHeaders.indexOf('capture_meta')]!.value.toString();
    expect(captureMeta, contains('openai'));
    expect(captureMeta, isNot(contains('extra_photos')));
    expect(captureMeta, isNot(contains('private.jpg')));

    final workouts = workbook.tables['workout_logs']!;
    final workoutHeaders = workouts.rows.first
        .map((cell) => cell?.value?.toString() ?? '')
        .toList();
    expect(workoutHeaders, isNot(contains('photo_path')));
    expect(workoutHeaders, isNot(contains('photo_thumb_path')));
    expect(workoutHeaders, isNot(contains('photo_extra_paths')));
  });

  test('micronutrient sheets report BLS values and incomplete coverage',
      () async {
    final firstEntry = FoodEntry(
      id: 10,
      barcode: 'bls:food-1',
      timestamp: DateTime.utc(2026, 10, 10, 8),
      quantityInGrams: 150,
      mealType: 'Breakfast',
      mealEntryId: 'meal-1',
    );
    final secondEntry = FoodEntry(
      id: 11,
      barcode: 'bls:food-2',
      timestamp: DateTime.utc(2026, 10, 10, 9),
      quantityInGrams: 80,
      mealType: 'Breakfast',
    );
    final fact = BlsNutrientFact(
      barcode: 'bls:food-1',
      code: 'vitamin_c',
      name: 'Vitamin C',
      unit: 'mg',
      group: 'Vitamins',
      value: 10,
      valueText: null,
      origin: 'BLS',
      reference: 'source-1',
    );

    final sheets = await ExportManager.collectCompleteDataSheetsForTesting(
      databaseHelper: databaseHelper,
      foodEntries: [firstEntry, secondEntry],
      nutrientFacts: [fact],
      catalogAvailable: true,
    );
    final nutrients =
        sheets.singleWhere((sheet) => sheet.name == 'micronutrients');
    final coverage =
        sheets.singleWhere((sheet) => sheet.name == 'micronutrient_coverage');

    expect(nutrients.rows, hasLength(1));
    expect(nutrients.rows.single[0], 10);
    expect(nutrients.rows.single[10], 15.0);
    expect(coverage.rows, hasLength(2));
    expect(coverage.rows[0][6], 1);
    expect(coverage.rows[1][6], 0);

    final missingCatalog =
        await ExportManager.collectCompleteDataSheetsForTesting(
      databaseHelper: databaseHelper,
      foodEntries: [firstEntry],
      nutrientFacts: const [],
      catalogAvailable: false,
    );
    final missingCoverage = missingCatalog
        .singleWhere((sheet) => sheet.name == 'micronutrient_coverage');
    expect(missingCoverage.rows.single[5], 0);
    expect(missingCoverage.rows.single[6], 0);

    await database.customStatement('''
      INSERT INTO products (id, barcode, name, calories, protein, carbs, fat)
      VALUES ('bls-product', 'bls:BLS1', 'BLS food', 100, 2.0, 3.0, 4.0)
    ''');
    final consumedAt = DateTime.utc(2026, 10, 11, 10).millisecondsSinceEpoch;
    await database.customStatement('''
      INSERT INTO nutrition_logs (id, product_id, consumed_at, amount, meal_type)
      VALUES ('legacy-bls-log', 'bls-product', $consumedAt, 80, 'breakfast')
    ''');
    final legacyProductExport =
        await ExportManager.collectCompleteDataSheetsForTesting(
      databaseHelper: databaseHelper,
      nutrientFacts: [
        BlsNutrientFact(
          barcode: 'bls:BLS1',
          code: 'iron',
          name: 'Iron',
          unit: 'mg',
          group: 'Minerals',
          value: 2,
          valueText: null,
          origin: 'BLS',
          reference: 'source-2',
        ),
      ],
      catalogAvailable: true,
    );
    final legacyNutrients = legacyProductExport
        .singleWhere((sheet) => sheet.name == 'micronutrients');
    expect(legacyNutrients.rows, hasLength(1));
    expect(legacyNutrients.rows.single[3], 'bls:BLS1');
    expect(legacyNutrients.rows.single[10], 1.6);
  });
}
