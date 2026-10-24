import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_database_snapshot_reader.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_sql_sandbox.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_action.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late File blsDbFile;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('assistant_bls_test_');
    blsDbFile = File('${tempDir.path}/train_libre_bls_foods.db');

    // Create a real BLS sidecar database with schema and sample food nutrients
    final blsDb = sqlite.sqlite3.open(blsDbFile.path);
    blsDb.execute('''
      CREATE TABLE nutrient_components (
        component_code TEXT PRIMARY KEY,
        name_de TEXT,
        name_en TEXT,
        unit TEXT,
        group_de TEXT,
        group_en TEXT
      );
      CREATE TABLE data_origins (
        origin_id TEXT PRIMARY KEY,
        label TEXT
      );
      CREATE TABLE source_references (
        reference_id TEXT PRIMARY KEY,
        citation TEXT
      );
      CREATE TABLE food_nutrients (
        barcode TEXT,
        component_code TEXT,
        value_numeric REAL,
        value_text TEXT,
        origin_id TEXT,
        reference_id TEXT,
        PRIMARY KEY (barcode, component_code)
      );
    ''');

    blsDb.execute('''
      INSERT INTO nutrient_components VALUES
        ('VITC', 'Vitamin C', 'Vitamin C', 'mg', 'Vitamine', 'Vitamins'),
        ('FE', 'Eisen', 'Iron', 'mg', 'Mineralstoffe', 'Minerals'),
        ('ALC', 'Alkohol', 'Alcohol', 'g', 'Sonstiges', 'Other');
      INSERT INTO data_origins VALUES ('O1', 'Analytisch gemessen');
      INSERT INTO source_references VALUES ('R1', 'BLS 3.02 Fachdokumentation');

      INSERT INTO food_nutrients (barcode, component_code, value_numeric, value_text, origin_id, reference_id) VALUES
        ('bls:B101000', 'VITC', 12.5, '12.5', 'O1', 'R1'),
        ('bls:B101000', 'ALC', 0.0, '0', 'O1', 'R1'),
        ('bls:B101000', 'FE', NULL, NULL, NULL, NULL);
    ''');
    blsDb.close();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<AssistantActionResult> readSnapshot(
    AssistantDatabaseSnapshotReader reader,
    AssistantDataCategory category,
    AssistantDateScope scope,
  ) async {
    final tables = await reader.read(category, scope);
    final columns = await reader.columnsFor(tables);
    return AssistantActionResult(
      category: category,
      status: AssistantActionStatus.success,
      records: const [],
      tables: tables,
      tableColumns: columns,
    );
  }

  group('AssistantDatabaseSnapshotReader Regression Tests', () {
    test(
        'nutrition diary correctly joins products, archives, overrides, and BLS nutrients',
        () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 1. Standard Product in database
      await db.customInsert(
        '''
        INSERT INTO products (id, local_id, barcode, name, calories, protein, carbs, fat, is_fluid, created_at, updated_at)
        VALUES ('prod-oatmeal', 1, '4001', 'Oatmeal', 370, 13.0, 60.0, 7.0, 0, $nowSec, $nowSec)
        ''',
      );

      // 2. Archived Product
      await db.customInsert(
        '''
        INSERT INTO off_products_archive (id, local_id, barcode, product_name, calories, protein, carbs, fat, is_fluid, content_hash, source, had_user_override, created_at, updated_at)
        VALUES ('arch-shake', 10, '4002', 'Archived Protein Shake', 200, 20.0, 10.0, 4.0, 0, 'hash1', 'off', 0, $nowSec, $nowSec)
        ''',
      );
      await db.customInsert('''
        INSERT INTO off_products_archive (id, local_id, barcode, product_name, calories, protein, carbs, fat, is_fluid, content_hash, source, had_user_override, created_at, updated_at)
        VALUES ('other-shake-snapshot', 11, '4002', 'Later Shake', 500, 50.0, 10.0, 4.0, 0, 'hash2', 'off', 0, $nowSec, $nowSec)
      ''');
      await db.customInsert('''
        INSERT INTO products (id, local_id, barcode, name, calories, protein, carbs, fat, is_fluid, created_at, updated_at)
        VALUES ('current-shake', 4, '4002', 'Current Shake', 400, 40.0, 10.0, 4.0, 0, $nowSec, $nowSec)
      ''');
      await db.customInsert('''
        INSERT INTO user_food_overrides (id, local_id, barcode, name, calories, protein, carbs, fat, is_fluid, created_at, updated_at)
        VALUES ('shake-override', 21, '4002', 'Overridden Shake', 300, 30.0, 10.0, 4.0, 0, $nowSec, $nowSec)
      ''');

      // 3. User Food Override (base product has 10g protein, override sets 15g protein)
      await db.customInsert(
        '''
        INSERT INTO products (id, local_id, barcode, name, calories, protein, carbs, fat, is_fluid, created_at, updated_at)
        VALUES ('prod-yogurt', 2, '4003', 'Greek Yogurt', 100, 10.0, 5.0, 2.0, 0, $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO user_food_overrides (id, local_id, barcode, name, calories, protein, carbs, fat, is_fluid, created_at, updated_at)
        VALUES ('ovr-yogurt', 20, '4003', 'Custom Greek Yogurt', 110, 15.0, 4.0, 2.0, 0, $nowSec, $nowSec)
        ''',
      );

      // 4. BLS food product
      await db.customInsert(
        '''
        INSERT INTO products (id, local_id, barcode, name, calories, protein, carbs, fat, is_fluid, source, created_at, updated_at)
        VALUES ('prod-apple', 3, 'bls:B101000', 'Apfel frisch', 52, 0.3, 11.4, 0.2, 0, 'bls', $nowSec, $nowSec)
        ''',
      );

      // Date Range: 2026-10-18 00:00:00 to 2026-10-19 23:59:59 local civil time
      final d18Start = DateTime(2026, 10, 18, 8, 30);
      final d18Noon = DateTime(2026, 10, 18, 12, 30);
      final d19Evening = DateTime(2026, 10, 19, 19, 0);
      final d19Night = DateTime(2026, 10, 19, 21, 0);
      final d19Boundary = DateTime(2026, 10, 19, 23, 59, 59);
      final outOfRangeBefore = DateTime(2026, 10, 17, 23, 59, 59);
      final outOfRangeAfter = DateTime(2026, 10, 20, 0, 0, 0);

      int toEpochSec(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

      // Insert diary entries:
      // Entry 0 (Out of range before)
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, product_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-out-before', 100, 'prod-oatmeal', '4001', ${toEpochSec(outOfRangeBefore)}, 100.0, $nowSec, $nowSec)
        ''',
      );

      // Entry 1 (In range - standard product link) -> 50g oatmeal
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, product_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-1', 101, 'prod-oatmeal', '4001', ${toEpochSec(d18Start)}, 50.0, $nowSec, $nowSec)
        ''',
      );

      // Entry 2 (In range - archived product) -> 300g shake
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, archive_local_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-2', 102, 10, '4002', ${toEpochSec(d18Noon)}, 300.0, $nowSec, $nowSec)
        ''',
      );

      // Entry 3 (In range - user override on yogurt) -> 200g yogurt
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-3', 103, '4003', ${toEpochSec(d19Evening)}, 200.0, $nowSec, $nowSec)
        ''',
      );

      // Entry 4 (In range - BLS apple) -> 150g apple
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-4', 104, 'bls:B101000', ${toEpochSec(d19Night)}, 150.0, $nowSec, $nowSec)
        ''',
      );

      // Entry 5 (In range - boundary 23:59:59 unlinked product)
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-5', 105, 'unlinked-barcode-999', ${toEpochSec(d19Boundary)}, 75.0, $nowSec, $nowSec)
        ''',
      );

      // Entry 6 (Out of range after)
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, product_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-out-after', 106, 'prod-oatmeal', '4001', ${toEpochSec(outOfRangeAfter)}, 100.0, $nowSec, $nowSec)
        ''',
      );

      final reader = AssistantDatabaseSnapshotReader(
        db,
        blsDatabasePath: blsDbFile.path,
      );

      final scope = AssistantDateScope(
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 19),
        'Oct 18-19',
      );

      final result =
          await readSnapshot(reader, AssistantDataCategory.nutrition, scope);
      expect(result.status, AssistantActionStatus.success);

      final logs = result.tables['nutrition_logs']!;
      expect(logs.length, 5,
          reason:
              'Must contain exactly the 5 in-range logs (out-of-range excluded)');

      // Verify log-1 (Oatmeal):
      final log1 = logs.firstWhere((l) => l['id'] == 'log-1');
      expect(log1['effective_source'], 'products');
      expect(log1['effective_name'], 'Oatmeal');
      expect(log1['effective_barcode'], '4001');
      expect(log1['calories_per_100g'], 370);
      expect(log1['protein_per_100g'], 13.0);
      expect(log1['calories_kcal'], 185.0); // 50g / 100g * 370
      expect(log1['protein_g'], 6.5); // 50g / 100g * 13

      // Verify log-2 (Archived Shake):
      final log2 = logs.firstWhere((l) => l['id'] == 'log-2');
      expect(log2['effective_source'], 'archive');
      expect(log2['effective_name'], 'Archived Protein Shake');
      expect(log2['effective_barcode'], '4002');
      expect(log2['protein_per_100g'], 20.0);
      expect(log2['calories_kcal'], 600.0); // 300g / 100g * 200
      expect(log2['protein_g'], 60.0); // 300g / 100g * 20
      expect(log2['archive_local_id'], 10);
      expect(result.tables['off_products_archive']!.map((row) => row['id']),
          ['arch-shake']);

      // Verify log-3 (User Override Yogurt):
      final log3 = logs.firstWhere((l) => l['id'] == 'log-3');
      expect(log3['effective_source'], 'override');
      expect(log3['effective_name'], 'Custom Greek Yogurt');
      expect(log3['effective_barcode'], '4003');
      expect(
          log3['protein_per_100g'], 15.0); // Override took precedence over 10.0
      expect(log3['protein_g'], 30.0); // 200g / 100g * 15

      // Verify log-4 (BLS Apple):
      final log4 = logs.firstWhere((l) => l['id'] == 'log-4');
      expect(log4['effective_source'], 'products');
      expect(log4['effective_name'], 'Apfel frisch');
      expect(log4['effective_barcode'], 'bls:B101000');

      // Verify BLS Micronutrients Table:
      final blsNutrients = result.tables['bls_food_nutrients']!;
      expect(blsNutrients.length, 3);

      final vitC =
          blsNutrients.firstWhere((n) => n['component_code'] == 'VITC');
      expect(vitC['nutrient_name'], 'Vitamin C');
      expect(vitC['value_per_100g'], 12.5);
      expect(vitC['unit'], 'mg');
      expect(vitC['is_missing'], 0);
      expect(vitC['origin'], 'Analytisch gemessen');
      expect(vitC['reference'], 'BLS 3.02 Fachdokumentation');

      // Measured Zero vs Missing:
      final alc = blsNutrients.firstWhere((n) => n['component_code'] == 'ALC');
      expect(alc['nutrient_name'], 'Alcohol');
      expect(alc['value_per_100g'], 0.0);
      expect(alc['is_missing'], 0,
          reason: 'Measured 0.0 must have is_missing = 0');

      final fe = blsNutrients.firstWhere((n) => n['component_code'] == 'FE');
      expect(fe['nutrient_name'], 'Iron');
      expect(fe['value_per_100g'], isNull);
      expect(fe['is_missing'], 1,
          reason:
              'Unmeasured/missing nutrient must have is_missing = 1 and value NULL');

      // Verify log-5 (Unlinked food):
      final log5 = logs.firstWhere((l) => l['id'] == 'log-5');
      expect(log5['effective_source'], 'unlinked');
      expect(log5['effective_name'], isNull);
      expect(log5['calories_kcal'], isNull,
          reason: 'Unlinked product nutrients must be NULL, never 0');
      expect(log5['protein_g'], isNull);

      // Verify that query sandbox can query these enriched tables with SQLite functions
      final sandbox = await AssistantSqlSandbox.create([result]);
      addTearDown(sandbox.close);

      final queryResult = await sandbox.query('''
        SELECT
          date(consumed_at, 'unixepoch', 'localtime') AS day_date,
          COUNT(*) AS log_count,
          SUM(calories_kcal) AS total_calories,
          SUM(protein_g) AS total_protein
        FROM nutrition_logs
        WHERE calories_kcal IS NOT NULL
        GROUP BY day_date
        ORDER BY day_date
      ''');

      expect(queryResult.rows.length, 2);
      expect(queryResult.rows[0]['log_count'],
          2); // Oatmeal (185) + Shake (600) = 785 kcal
      expect((queryResult.rows[0]['total_calories'] as num).toDouble(), 785.0);
      expect((queryResult.rows[0]['total_protein'] as num).toDouble(),
          66.5); // 6.5 + 60.0

      // Query BLS nutrients in sandbox
      final blsQuery = await sandbox.query('''
        SELECT nutrient_name, value_per_100g, unit, is_missing
        FROM bls_food_nutrients
        WHERE is_missing = 0
        ORDER BY component_code
      ''');
      expect(blsQuery.rows.length, 2); // ALC (0.0) and VITC (12.5)
      expect(blsQuery.rows[0]['value_per_100g'], 0.0);
      expect(blsQuery.rows[1]['value_per_100g'], 12.5);
    });

    test(
        'workout logs include exercise metadata, scoped relationships, and historical name snapshots',
        () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Exercises in database
      await db.customInsert(
        '''
        INSERT INTO exercises (id, local_id, category_name, is_custom, created_at, updated_at)
        VALUES ('ex-bench', 1, 'Chest', 0, $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO exercise_translations (id, local_id, exercise_id, language_code, name, created_at, updated_at)
        VALUES ('tr-bench-en', 10, 'ex-bench', 'en', 'Barbell Bench Press', $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO muscles (id, level, group_id) VALUES ('pectoralis_major', 'muscle', 'chest')
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO muscle_translations (muscle_id, language_code, name)
        VALUES ('pectoralis_major', 'en', 'Pectoralis Major')
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO exercise_muscles (exercise_id, muscle_id, role)
        VALUES ('ex-bench', 'pectoralis_major', 'primary')
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO equipment (id, kind) VALUES ('barbell', 'free_weight')
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO equipment_translations (equipment_id, language_code, name)
        VALUES ('barbell', 'en', 'Barbell')
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO exercise_equipment (exercise_id, equipment_id, kind)
        VALUES ('ex-bench', 'barbell', 'primary')
        ''',
      );

      // Unrelated exercise (should NEVER leak into workout snapshot)
      await db.customInsert(
        '''
        INSERT INTO exercises (id, local_id, category_name, is_custom, created_at, updated_at)
        VALUES ('ex-squat', 2, 'Legs', 0, $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO exercise_translations (id, local_id, exercise_id, language_code, name, created_at, updated_at)
        VALUES ('tr-squat-en', 11, 'ex-squat', 'en', 'Barbell Back Squat', $nowSec, $nowSec)
        ''',
      );

      // Routines
      await db.customInsert(
        '''
        INSERT INTO routines (id, local_id, name, created_at, updated_at)
        VALUES ('rt-chest', 1, 'Push Day', $nowSec, $nowSec)
        ''',
      );

      final wDate1 = DateTime(2026, 10, 18, 10, 0);
      final wDate2 = DateTime(2026, 10, 19, 16, 0);
      final wDateOut = DateTime(2026, 10, 17, 10, 0);

      int toEpochSec(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

      // Workout 1: in range, with Push Day routine and ex-bench
      await db.customInsert(
        '''
        INSERT INTO workout_logs (id, local_id, routine_id, routine_name_snapshot, start_time, end_time, status, created_at, updated_at)
        VALUES ('w-1', 101, 'rt-chest', 'Push Day Vintage', ${toEpochSec(wDate1)}, ${toEpochSec(wDate1.add(const Duration(hours: 1)))}, 'completed', $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO set_logs (id, local_id, workout_log_id, exercise_id, exercise_name_snapshot, weight, reps, rpe, created_at, updated_at)
        VALUES ('set-1-1', 201, 'w-1', 'ex-bench', 'Bench Press Old', 80.0, 8, 8, $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO set_logs (id, local_id, workout_log_id, exercise_id, exercise_name_snapshot, weight, reps, rpe, created_at, updated_at)
        VALUES ('set-1-2', 202, 'w-1', 'ex-bench', 'Bench Press Old', 85.0, 6, 9, $nowSec, $nowSec)
        ''',
      );

      // Workout 2: in range, with a deleted/historical exercise that only has a snapshot name
      await db.customInsert(
        '''
        INSERT INTO workout_logs (id, local_id, routine_name_snapshot, start_time, end_time, status, created_at, updated_at)
        VALUES ('w-2', 102, 'Old Freestyle', ${toEpochSec(wDate2)}, ${toEpochSec(wDate2.add(const Duration(minutes: 45)))}, 'completed', $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO set_logs (id, local_id, workout_log_id, exercise_name_snapshot, weight, reps, rpe, created_at, updated_at)
        VALUES ('set-2-1', 203, 'w-2', 'Deleted Vintage Incline Dumbbell Press', 24.0, 10, 7, $nowSec, $nowSec)
        ''',
      );

      // Workout 3: OUT OF RANGE
      await db.customInsert(
        '''
        INSERT INTO workout_logs (id, local_id, start_time, end_time, status, created_at, updated_at)
        VALUES ('w-out', 103, ${toEpochSec(wDateOut)}, ${toEpochSec(wDateOut.add(const Duration(hours: 1)))}, 'completed', $nowSec, $nowSec)
        ''',
      );

      final reader = AssistantDatabaseSnapshotReader(db);
      final scope = AssistantDateScope(
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 19),
        'Oct 18-19',
      );

      final result =
          await readSnapshot(reader, AssistantDataCategory.workouts, scope);
      expect(result.status, AssistantActionStatus.success);

      final workoutRows = result.tables['workout_logs']!;
      expect(workoutRows.length, 2);
      expect(workoutRows.map((w) => w['id']).toSet(), {'w-1', 'w-2'});

      final setRows = result.tables['set_logs']!;
      expect(setRows.length, 3);

      // Check effective_exercise_name and snapshot preservation
      final set1 = setRows.firstWhere((s) => s['id'] == 'set-1-1');
      expect(set1['effective_exercise_name'], 'Barbell Bench Press');
      expect(set1['exercise_name_snapshot'], 'Bench Press Old');
      expect(set1['weight'], 80.0);
      expect(set1['reps'], 8);

      final set2 = setRows.firstWhere((s) => s['id'] == 'set-2-1');
      expect(set2['effective_exercise_name'],
          'Deleted Vintage Incline Dumbbell Press');
      expect(set2['exercise_name_snapshot'],
          'Deleted Vintage Incline Dumbbell Press');

      // Verify privacy scoping: only exercises logged in approved workouts are included
      final exerciseRows = result.tables['exercises']!;
      expect(exerciseRows.length, 1);
      expect(exerciseRows.single['id'], 'ex-bench');

      final muscles = result.tables['muscles']!;
      expect(muscles.length, 1);
      expect(muscles.single['id'], 'pectoralis_major');

      final equipment = result.tables['equipment']!;
      expect(equipment.length, 1);
      expect(equipment.single['id'], 'barbell');

      // Verify in AssistantSqlSandbox
      final sandbox = await AssistantSqlSandbox.create([result]);
      addTearDown(sandbox.close);

      final queryResult = await sandbox.query('''
        SELECT
          w.id AS workout_id,
          s.effective_exercise_name,
          s.weight,
          s.reps,
          m.muscle_id
        FROM workout_logs w
        JOIN set_logs s ON s.workout_log_id = w.id
        LEFT JOIN exercise_muscles m ON m.exercise_id = s.exercise_id
        ORDER BY w.start_time, s.id
      ''');

      expect(queryResult.rows.length, 3);
      expect(queryResult.rows[0]['effective_exercise_name'],
          'Barbell Bench Press');
      expect(queryResult.rows[0]['muscle_id'], 'pectoralis_major');
      expect(queryResult.rows[2]['effective_exercise_name'],
          'Deleted Vintage Incline Dumbbell Press');
      expect(queryResult.rows[2]['muscle_id'], isNull);
    });

    test('dated diary approval does not expose separately saved recipes',
        () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final consumedAt =
          DateTime(2026, 10, 18, 12).millisecondsSinceEpoch ~/ 1000;
      await db.customInsert('''
        INSERT INTO meals (id, local_id, name, created_at, updated_at)
        VALUES ('private-recipe', 1, 'Saved recipe', $nowSec, $nowSec)
      ''');
      await db.customInsert('''
        INSERT INTO meal_entries (id, local_id, consumed_at, meal_type, source, created_at, updated_at)
        VALUES ('logged-meal', 1, $consumedAt, 'Lunch', 'manual', $nowSec, $nowSec)
      ''');
      final reader = AssistantDatabaseSnapshotReader(db);
      final scope = AssistantDateScope(
          DateTime(2026, 10, 18), DateTime(2026, 10, 18), 'Oct 18');
      final diary =
          await readSnapshot(reader, AssistantDataCategory.diary, scope);
      expect(diary.tables['meal_entries'], hasLength(1));
      expect(diary.tables.containsKey('meals'), isFalse);
      expect(diary.tables.containsKey('meal_items'), isFalse);
      final recipes =
          await readSnapshot(reader, AssistantDataCategory.recipes, scope);
      expect(recipes.tables['meals']!.single['id'], 'private-recipe');
    });

    test('approval boundary strictly separates nutrition and workouts',
        () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final d18 = DateTime.utc(2026, 10, 18, 10, 0);

      await db.customInsert(
        '''
        INSERT INTO workout_logs (id, local_id, start_time, end_time, status, created_at, updated_at)
        VALUES ('w-secret', 1, ${d18.millisecondsSinceEpoch ~/ 1000}, ${d18.millisecondsSinceEpoch ~/ 1000 + 3600}, 'completed', $nowSec, $nowSec)
        ''',
      );
      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, consumed_at, amount, created_at, updated_at)
        VALUES ('nut-secret', 1, ${d18.millisecondsSinceEpoch ~/ 1000}, 100.0, $nowSec, $nowSec)
        ''',
      );

      final reader = AssistantDatabaseSnapshotReader(db);
      final scope = AssistantDateScope(
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 18),
        'Oct 18',
      );

      // Only nutrition approved
      final nutResult =
          await readSnapshot(reader, AssistantDataCategory.nutrition, scope);
      expect(nutResult.tables.containsKey('workout_logs'), isFalse);
      expect(nutResult.tables.containsKey('set_logs'), isFalse);
      expect(nutResult.tables.containsKey('exercises'), isFalse);

      final nutSandbox = await AssistantSqlSandbox.create([nutResult]);
      addTearDown(nutSandbox.close);

      // Attempting to query workouts from a nutrition-only approval must throw
      await expectLater(
        nutSandbox.query('SELECT * FROM workout_logs'),
        throwsA(isA<AssistantSqlQueryException>()),
      );

      // Only workouts approved
      final workoutResult =
          await readSnapshot(reader, AssistantDataCategory.workouts, scope);
      expect(workoutResult.tables.containsKey('nutrition_logs'), isFalse);
      expect(workoutResult.tables.containsKey('products'), isFalse);
      expect(workoutResult.tables.containsKey('bls_food_nutrients'), isFalse);

      final workoutSandbox = await AssistantSqlSandbox.create([workoutResult]);
      addTearDown(workoutSandbox.close);

      // Attempting to query nutrition from a workouts-only approval must throw
      await expectLater(
        workoutSandbox.query('SELECT * FROM nutrition_logs'),
        throwsA(isA<AssistantSqlQueryException>()),
      );
    });

    test('gracefully handles missing BLS sidecar database', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final d18 = DateTime.utc(2026, 10, 18, 12, 0);

      await db.customInsert(
        '''
        INSERT INTO nutrition_logs (id, local_id, legacy_barcode, consumed_at, amount, created_at, updated_at)
        VALUES ('log-bls', 1, 'bls:B999999', ${d18.millisecondsSinceEpoch ~/ 1000}, 100.0, $nowSec, $nowSec)
        ''',
      );

      // Pass a non-existent path
      final reader = AssistantDatabaseSnapshotReader(
        db,
        blsDatabasePath: '${tempDir.path}/non_existent_bls.db',
      );

      final scope = AssistantDateScope(
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 18),
        'Oct 18',
      );

      final result =
          await readSnapshot(reader, AssistantDataCategory.nutrition, scope);
      expect(result.status, AssistantActionStatus.success);
      expect(result.tables['bls_food_nutrients'], isEmpty);
      expect(result.tableColumns['bls_food_nutrients'], isNotEmpty);

      final sandbox = await AssistantSqlSandbox.create([result]);
      addTearDown(sandbox.close);

      final countQuery = await sandbox
          .query('SELECT COUNT(*) AS total FROM bls_food_nutrients');
      expect(countQuery.rows.single['total'], 0);
    });

    test(
        'schema guidance accurately documents timestamps, joins, units, and missing value semantics',
        () async {
      final reader = AssistantDatabaseSnapshotReader(db);
      final scope = AssistantDateScope(
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 18),
        'Oct 18',
      );

      final result =
          await readSnapshot(reader, AssistantDataCategory.nutrition, scope);
      final sandbox = await AssistantSqlSandbox.create([result]);
      addTearDown(sandbox.close);

      final schema = sandbox.schema;

      // 1. Timestamps accuracy: must specify Unix epoch timestamps in seconds, NOT ISO-8601 strings
      expect(schema, contains('Unix epoch timestamps in seconds'));
      expect(schema, contains("datetime(col, 'unixepoch', 'localtime')"));
      expect(
          schema,
          isNot(contains(
              'Timestamps are ISO-8601 strings in the device time zone')));

      // 2. Nutrition joins, per-100g formula, and units
      expect(schema, contains('nutrition_logs.amount'));
      expect(schema, contains('calories_per_100g'));
      expect(schema, contains('(amount / 100.0) * nutrient_per_100g'));
      expect(schema, contains('calories_kcal'));
      expect(schema, contains('caffeine_mg'));

      // 3. BLS micronutrients and missing vs zero
      expect(schema, contains('bls_food_nutrients'));
      expect(schema, contains('is_missing'));
      expect(schema, contains('value_per_100g'));
      expect(schema, contains('Do not treat NULL as zero'));

      // 4. Workout exercise relationships and historical snapshots
      expect(schema, contains('set_logs'));
      expect(schema, contains('effective_exercise_name'));
      expect(schema, contains('exercise_name_snapshot'));
      expect(schema, contains('workout_logs` (start_time, end_time'));
      expect(schema, contains('bls_food_nutrients.barcode'));
      expect(schema,
          contains('sleep_canonical_sessions) are Unix epoch milliseconds'));
      expect(schema, isNot(contains('body_weight_kg')));
      expect(schema, isNot(contains('food_name_de')));
      expect(schema, isNot(contains('meal_entries.meal_id')));
    });
  });
}
