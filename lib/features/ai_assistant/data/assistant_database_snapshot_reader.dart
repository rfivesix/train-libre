import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../data/drift_database.dart';
import '../../../services/bls_food_catalog_refresh_service.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

/// Reads complete rows from an explicit allowlist of user-data tables.
/// Date-scoped categories are filtered in SQLite before entering the temporary
/// assistant snapshot. App configuration, social data, assistant history, and
/// unrelated catalog tables are never included.
class AssistantDatabaseSnapshotReader {
  const AssistantDatabaseSnapshotReader(
    this.database, {
    this.blsDatabasePath,
    this.blsDatabasePathProvider,
    this.nowProvider,
  });

  final AppDatabase database;
  final String? blsDatabasePath;
  final Future<String?> Function()? blsDatabasePathProvider;
  final DateTime Function()? nowProvider;

  static const Map<String, Map<String, String>> _restrictedTableColumns = {
    'profiles': {
      'id': 'TEXT',
      'birthday': 'INTEGER',
      'height': 'REAL',
      'gender': 'TEXT',
    },
    'app_settings': {
      'user_id': 'TEXT',
      'unit_system': 'TEXT',
      'target_calories': 'INTEGER',
      'target_protein': 'INTEGER',
      'target_carbs': 'INTEGER',
      'target_fat': 'INTEGER',
      'target_water': 'INTEGER',
      'target_steps': 'INTEGER',
      'experience_level': 'TEXT',
    },
  };

  static const Map<String, Map<String, String>> _syntheticTableColumns = {
    'active_plan_week': {
      'plan_id': 'TEXT',
      'plan_name': 'TEXT',
      'plan_kind': 'TEXT',
      'date': 'TEXT',
      'weekday_index': 'INTEGER',
      'slot_index': 'INTEGER',
      'revision_id': 'TEXT',
      'revision_number': 'INTEGER',
      'routine_uuid': 'TEXT',
      'routine_name': 'TEXT',
      'is_rest': 'INTEGER',
      'status': 'TEXT',
      'workout_log_id': 'TEXT',
      'routine_snapshot': 'TEXT',
    },
    'bls_food_nutrients': {
      'barcode': 'TEXT',
      'component_code': 'TEXT',
      'nutrient_name': 'TEXT',
      'name_de': 'TEXT',
      'name_en': 'TEXT',
      'unit': 'TEXT',
      'nutrient_group': 'TEXT',
      'group_de': 'TEXT',
      'group_en': 'TEXT',
      'value_per_100g': 'REAL',
      'value_numeric': 'REAL',
      'value_text': 'TEXT',
      'is_missing': 'INTEGER',
      'origin': 'TEXT',
      'reference': 'TEXT',
    },
  };

  static const Map<String, Map<String, String>> _enrichedTableColumns = {
    'nutrition_logs': {
      'effective_barcode': 'TEXT',
      'effective_name': 'TEXT',
      'effective_brand': 'TEXT',
      'effective_source': 'TEXT',
      'effective_is_fluid': 'INTEGER',
      'calories_per_100g': 'REAL',
      'protein_per_100g': 'REAL',
      'carbs_per_100g': 'REAL',
      'fat_per_100g': 'REAL',
      'sugar_per_100g': 'REAL',
      'fiber_per_100g': 'REAL',
      'salt_per_100g': 'REAL',
      'caffeine_mg_per_100g': 'REAL',
      'calories_kcal': 'REAL',
      'protein_g': 'REAL',
      'carbs_g': 'REAL',
      'fat_g': 'REAL',
      'sugar_g': 'REAL',
      'fiber_g': 'REAL',
      'salt_g': 'REAL',
      'caffeine_mg': 'REAL',
    },
    'workout_logs': {
      'effective_routine_name': 'TEXT',
    },
    'set_logs': {
      'effective_exercise_name': 'TEXT',
      'canonical_exercise_name': 'TEXT',
    },
    'workout_exercise_logs': {
      'effective_exercise_name': 'TEXT',
      'canonical_exercise_name': 'TEXT',
    },
    'exercises': {
      'name': 'TEXT',
      'name_de': 'TEXT',
      'name_en': 'TEXT',
      'primary_muscles': 'TEXT',
      'secondary_muscles': 'TEXT',
      'equipment_names': 'TEXT',
    },
  };

  Future<Map<String, Map<String, String>>> columnsFor(
      Map<String, List<Map<String, dynamic>>> tables) async {
    final result = <String, Map<String, String>>{};
    for (final entry in tables.entries) {
      final table = entry.key;
      final restricted = _restrictedTableColumns[table];
      if (restricted != null) {
        result[table] = Map<String, String>.from(restricted);
        continue;
      }
      final synthetic = _syntheticTableColumns[table];
      if (synthetic != null) {
        result[table] = Map<String, String>.from(synthetic);
        continue;
      }
      final columns = <String, String>{};
      if (RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(table)) {
        final rows =
            await database.customSelect('PRAGMA table_info($table)').get();
        for (final row in rows) {
          columns[row.read<String>('name')] =
              _sqliteType(row.read<String>('type'));
        }
      }
      final enriched = _enrichedTableColumns[table];
      if (enriched != null) {
        columns.addAll(enriched);
      }
      for (final row in entry.value) {
        for (final field in row.entries) {
          columns.putIfAbsent(field.key, () => _inferValueType(field.value));
        }
      }
      result[table] = columns;
    }
    return result;
  }

  Future<Map<String, List<Map<String, dynamic>>>> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    switch (category) {
      case AssistantDataCategory.workouts:
        return _readWorkoutsSnapshot(scope);
      case AssistantDataCategory.routines:
        const routineIds = 'SELECT id FROM routines WHERE deleted_at IS NULL';
        const routineExerciseIds =
            'SELECT id FROM routine_exercises WHERE deleted_at IS NULL AND routine_id IN ($routineIds)';
        const exerciseIds =
            'SELECT exercise_id FROM routine_exercises WHERE deleted_at IS NULL AND routine_id IN ($routineIds)';
        const muscleIds =
            'SELECT muscle_id FROM exercise_muscles WHERE exercise_id IN ($exerciseIds)';
        const equipmentIds =
            'SELECT equipment_id FROM exercise_equipment WHERE exercise_id IN ($exerciseIds)';
        final exercises = await _select(
          'exercises',
          ' WHERE deleted_at IS NULL AND id IN ($exerciseIds)',
        );
        final exerciseTranslations = await _select(
          'exercise_translations',
          ' WHERE deleted_at IS NULL AND exercise_id IN ($exerciseIds)',
        );
        final exerciseMuscles = await _select(
            'exercise_muscles', ' WHERE exercise_id IN ($exerciseIds)');
        final muscles = await _select('muscles', ' WHERE id IN ($muscleIds)');
        final muscleTranslations = await _select(
            'muscle_translations', ' WHERE muscle_id IN ($muscleIds)');
        final exerciseEquipment = await _select(
            'exercise_equipment', ' WHERE exercise_id IN ($exerciseIds)');
        final equipment =
            await _select('equipment', ' WHERE id IN ($equipmentIds)');
        final equipmentTranslations = await _select(
            'equipment_translations', ' WHERE equipment_id IN ($equipmentIds)');
        final exerciseTags = await _select(
            'exercise_tags', ' WHERE exercise_id IN ($exerciseIds)');
        _enrichExercises(
          exercises: exercises,
          translations: exerciseTranslations,
          exerciseMuscles: exerciseMuscles,
          exerciseEquipment: exerciseEquipment,
          equipment: equipment,
          equipmentTranslations: equipmentTranslations,
        );
        return {
          'routines': await _select('routines', ' WHERE deleted_at IS NULL'),
          'routine_exercises': await _select(
            'routine_exercises',
            ' WHERE deleted_at IS NULL AND routine_id IN ($routineIds)',
          ),
          'routine_set_templates': await _select(
            'routine_set_templates',
            ' WHERE deleted_at IS NULL AND routine_exercise_id IN ($routineExerciseIds)',
          ),
          'exercises': exercises,
          'pinned_exercise_notes': await _select(
              'pinned_exercise_notes', ' WHERE exercise_id IN ($exerciseIds)'),
          'exercise_translations': exerciseTranslations,
          'exercise_muscles': exerciseMuscles,
          'muscles': muscles,
          'muscle_translations': muscleTranslations,
          'exercise_equipment': exerciseEquipment,
          'equipment': equipment,
          'equipment_translations': equipmentTranslations,
          'exercise_tags': exerciseTags,
        };
      case AssistantDataCategory.trainingPlans:
        const planIds =
            'SELECT id FROM training_plans WHERE deleted_at IS NULL';
        final tables = <String, List<Map<String, dynamic>>>{
          'training_plans':
              await _select('training_plans', ' WHERE deleted_at IS NULL'),
          'training_plan_revisions': await _select(
            'training_plan_revisions',
            ' WHERE deleted_at IS NULL AND plan_id IN ($planIds)',
          ),
          'training_plan_activations': await _select(
            'training_plan_activations',
            ' WHERE deleted_at IS NULL AND plan_id IN ($planIds)',
          ),
          'training_plan_occurrences': await _select(
            'training_plan_occurrences',
            ' WHERE deleted_at IS NULL AND plan_id IN ($planIds)',
          ),
        };
        final activeWeek = _activeWeekSchedule(tables);
        if (activeWeek.isNotEmpty) tables['active_plan_week'] = activeWeek;
        return tables;
      case AssistantDataCategory.diary:
      case AssistantDataCategory.nutrition:
        return _readNutritionSnapshot(scope);
      case AssistantDataCategory.steps:
        final range = _range(scope);
        return {
          'health_step_segments': await _select(
              'health_step_segments', _dateWhere('start_at', range),
              values: range),
        };
      case AssistantDataCategory.sleep:
        final dateRange = _range(scope, dateOnly: true);
        final analysisWhere =
            _dateWhere('night_date', dateRange, hasDeletedAt: false);
        final analyses = await _select('sleep_nightly_analyses', analysisWhere,
            values: dateRange);
        final sessionsByAnalysis = analyses
            .map((row) => row['session_id'])
            .whereType<String>()
            .toSet();
        List<Map<String, dynamic>> scopedSessions;
        if (scope == null) {
          scopedSessions = await _select('sleep_canonical_sessions', '');
        } else {
          final msRange = _range(scope, milliseconds: true);
          final secRange = _range(scope);
          scopedSessions = await _select(
            'sleep_canonical_sessions',
            ' WHERE (started_at >= ? AND started_at < ?) OR (ended_at > ? AND ended_at <= ?) OR (started_at >= ? AND started_at < ?) OR (ended_at > ? AND ended_at <= ?)',
            values: [
              msRange[0],
              msRange[1],
              msRange[0],
              msRange[1],
              secRange[0],
              secRange[1],
              secRange[0],
              secRange[1],
            ],
          );
        }
        final sessionIds = {
          ...sessionsByAnalysis,
          ...scopedSessions.map((row) => row['id']).whereType<String>(),
        }.toList();
        final analysisSessions = sessionIds.isEmpty
            ? <Map<String, dynamic>>[]
            : await _select(
                'sleep_canonical_sessions',
                ' WHERE id IN (${List.filled(sessionIds.length, '?').join(',')})',
                values: sessionIds,
              );
        final ids = sessionIds.isEmpty
            ? 'IN (NULL)'
            : 'IN (${List.filled(sessionIds.length, '?').join(',')})';
        final rawImports = sessionIds.isEmpty
            ? <Map<String, dynamic>>[]
            : await _select(
                'sleep_raw_imports',
                ' WHERE id IN (SELECT raw_import_id FROM sleep_canonical_sessions WHERE id $ids)',
                values: sessionIds,
              );
        return {
          'sleep_canonical_sessions': analysisSessions,
          'sleep_canonical_stage_segments': await _select(
              'sleep_canonical_stage_segments', ' WHERE session_id $ids',
              values: sessionIds),
          'sleep_canonical_heart_rate_samples': await _select(
              'sleep_canonical_heart_rate_samples', ' WHERE session_id $ids',
              values: sessionIds),
          'sleep_nightly_analyses': analyses,
          'sleep_raw_imports': rawImports,
        };
      case AssistantDataCategory.measurements:
        final range = _range(scope);
        return {
          'measurements': await _select(
              'measurements', _dateWhere('date', range),
              values: range),
        };
      case AssistantDataCategory.goals:
        const goalIds = 'SELECT id FROM user_goals WHERE deleted_at IS NULL';
        return {
          'user_goals':
              await _select('user_goals', ' WHERE deleted_at IS NULL'),
          'goal_events': await _select(
            'goal_events',
            ' WHERE deleted_at IS NULL AND goal_id IN ($goalIds)',
          ),
          'goal_reviews': await _select(
            'goal_reviews',
            ' WHERE deleted_at IS NULL AND goal_id IN ($goalIds)',
          ),
        };
      case AssistantDataCategory.profile:
        return {
          'profiles': await _select(
            'profiles',
            ' WHERE deleted_at IS NULL',
            columns: const ['id', 'birthday', 'height', 'gender'],
          ),
          'app_settings': await _select(
            'app_settings',
            ''' WHERE deleted_at IS NULL AND user_id IN (
              SELECT id FROM profiles WHERE deleted_at IS NULL)''',
            columns: const [
              'user_id',
              'unit_system',
              'target_calories',
              'target_protein',
              'target_carbs',
              'target_fat',
              'target_water',
              'target_steps',
              'experience_level',
            ],
          ),
        };
      case AssistantDataCategory.supplements:
        return {
          'supplements':
              await _select('supplements', ' WHERE deleted_at IS NULL'),
          'supplement_settings_history': await _select(
            'supplement_settings_history',
            ''' WHERE deleted_at IS NULL AND created_at = (
              SELECT MAX(latest.created_at) FROM supplement_settings_history latest
              WHERE latest.supplement_id = supplement_settings_history.supplement_id
              AND latest.deleted_at IS NULL)''',
          ),
        };
      case AssistantDataCategory.recipes:
        const meals = 'SELECT id FROM meals WHERE deleted_at IS NULL';
        final mealRows = await _select('meals', ' WHERE deleted_at IS NULL');
        final mealItems = await _select(
          'meal_items',
          ' WHERE deleted_at IS NULL AND meal_id IN ($meals)',
        );
        final products = await _select(
          'products',
          ''' WHERE deleted_at IS NULL AND (
            id IN (SELECT product_id FROM meal_items WHERE deleted_at IS NULL AND meal_id IN ($meals))
            OR barcode IN (SELECT product_barcode FROM meal_items WHERE deleted_at IS NULL AND meal_id IN ($meals)))''',
        );
        final archives = await _select(
          'off_products_archive',
          ''' WHERE deleted_at IS NULL AND barcode IN (
            SELECT product_barcode FROM meal_items WHERE deleted_at IS NULL AND meal_id IN ($meals))''',
        );
        final recipeBarcodes = <String>{
          for (final item in mealItems)
            if (item['product_barcode'] is String &&
                (item['product_barcode'] as String).isNotEmpty)
              item['product_barcode'] as String,
          for (final product in products)
            if (product['barcode'] is String &&
                (product['barcode'] as String).isNotEmpty)
              product['barcode'] as String,
          for (final archive in archives)
            if (archive['barcode'] is String &&
                (archive['barcode'] as String).isNotEmpty)
              archive['barcode'] as String,
        }.toList();
        final overrides = recipeBarcodes.isEmpty
            ? <Map<String, dynamic>>[]
            : await _select(
                'user_food_overrides',
                ' WHERE deleted_at IS NULL AND barcode IN (${_placeholders(recipeBarcodes.length)})',
                values: recipeBarcodes,
              );
        final overrideIds = overrides
            .map((row) => row['id'])
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final overrideTranslations = overrideIds.isEmpty
            ? <Map<String, dynamic>>[]
            : await _select(
                'user_food_override_translations',
                ' WHERE deleted_at IS NULL AND user_food_override_id IN (${_placeholders(overrideIds.length)})',
                values: overrideIds,
              );
        final blsNutrients = await _readBlsFoodNutrients(recipeBarcodes);
        return {
          'meals': mealRows,
          'meal_items': mealItems,
          'products': products,
          'off_products_archive': archives,
          'user_food_overrides': overrides,
          'user_food_override_translations': overrideTranslations,
          'bls_food_nutrients': blsNutrients,
        };
      case AssistantDataCategory.exerciseCatalog:
        const exerciseIds =
            'SELECT id FROM exercises WHERE deleted_at IS NULL AND (status IS NULL OR status = \'active\')';
        final exercises = await _select(
          'exercises',
          ' WHERE deleted_at IS NULL AND (status IS NULL OR status = \'active\')',
        );
        final exerciseTranslations = await _select(
          'exercise_translations',
          ' WHERE deleted_at IS NULL AND exercise_id IN ($exerciseIds)',
        );
        final exerciseMuscles = await _select(
          'exercise_muscles',
          ' WHERE exercise_id IN ($exerciseIds)',
        );
        final muscles = await _select(
          'muscles',
          ' WHERE id IN (SELECT muscle_id FROM exercise_muscles WHERE exercise_id IN ($exerciseIds))',
        );
        final muscleTranslations = await _select(
          'muscle_translations',
          ' WHERE muscle_id IN (SELECT muscle_id FROM exercise_muscles WHERE exercise_id IN ($exerciseIds))',
        );
        final exerciseEquipment = await _select(
          'exercise_equipment',
          ' WHERE exercise_id IN ($exerciseIds)',
        );
        final equipment = await _select(
          'equipment',
          ' WHERE id IN (SELECT equipment_id FROM exercise_equipment WHERE exercise_id IN ($exerciseIds))',
        );
        final equipmentTranslations = await _select(
          'equipment_translations',
          ' WHERE equipment_id IN (SELECT equipment_id FROM exercise_equipment WHERE exercise_id IN ($exerciseIds))',
        );
        final exerciseTags = await _select(
          'exercise_tags',
          ' WHERE exercise_id IN ($exerciseIds)',
        );
        _enrichExercises(
          exercises: exercises,
          translations: exerciseTranslations,
          exerciseMuscles: exerciseMuscles,
          exerciseEquipment: exerciseEquipment,
          equipment: equipment,
          equipmentTranslations: equipmentTranslations,
        );
        return {
          'exercises': exercises,
          'exercise_translations': exerciseTranslations,
          'exercise_muscles': exerciseMuscles,
          'muscles': muscles,
          'muscle_translations': muscleTranslations,
          'exercise_equipment': exerciseEquipment,
          'equipment': equipment,
          'equipment_translations': equipmentTranslations,
          'exercise_tags': exerciseTags,
        };
      case AssistantDataCategory.recovery:
        return const {};
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _readWorkoutsSnapshot(
    AssistantDateScope? scope,
  ) async {
    final range = _range(scope);
    final workoutWhere = _dateWhere('start_time', range);
    final workoutIds = 'SELECT id FROM workout_logs$workoutWhere';
    final workoutLogs =
        await _select('workout_logs', workoutWhere, values: range);
    final setLogs = await _select(
      'set_logs',
      ' WHERE deleted_at IS NULL AND workout_log_id IN ($workoutIds)',
      values: range,
    );
    final workoutExerciseLogs = await _select(
      'workout_exercise_logs',
      ' WHERE deleted_at IS NULL AND workout_log_id IN ($workoutIds)',
      values: range,
    );
    final cardioActivities = await _select(
      'cardio_activities',
      ' WHERE deleted_at IS NULL AND workout_log_id IN ($workoutIds)',
      values: range,
    );
    final cardioSamples = await _select(
      'cardio_samples',
      ''' WHERE deleted_at IS NULL AND cardio_activity_id IN (
        SELECT id FROM cardio_activities WHERE deleted_at IS NULL
        AND workout_log_id IN ($workoutIds))''',
      values: range,
    );

    final routineIds = workoutLogs
        .map((row) => row['routine_id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final routines = routineIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'routines',
            ' WHERE deleted_at IS NULL AND id IN (${_placeholders(routineIds.length)})',
            values: routineIds,
          );

    final exerciseIds = <String>{
      for (final row in setLogs) ...[
        if (row['exercise_id'] is String &&
            (row['exercise_id'] as String).isNotEmpty)
          row['exercise_id'] as String,
        if (row['substituted_for_exercise_id'] is String &&
            (row['substituted_for_exercise_id'] as String).isNotEmpty)
          row['substituted_for_exercise_id'] as String,
      ],
      for (final row in workoutExerciseLogs)
        if (row['exercise_id'] is String &&
            (row['exercise_id'] as String).isNotEmpty)
          row['exercise_id'] as String,
    }.toList();

    final exercises = exerciseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'exercises',
            ' WHERE deleted_at IS NULL AND id IN (${_placeholders(exerciseIds.length)})',
            values: exerciseIds,
          );
    final exerciseTranslations = exerciseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'exercise_translations',
            ' WHERE deleted_at IS NULL AND exercise_id IN (${_placeholders(exerciseIds.length)})',
            values: exerciseIds,
          );
    final exerciseMuscles = exerciseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'exercise_muscles',
            ' WHERE exercise_id IN (${_placeholders(exerciseIds.length)})',
            values: exerciseIds,
          );
    final muscleIds = exerciseMuscles
        .map((row) => row['muscle_id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final muscles = muscleIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'muscles',
            ' WHERE id IN (${_placeholders(muscleIds.length)})',
            values: muscleIds,
          );
    final muscleTranslations = muscleIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'muscle_translations',
            ' WHERE muscle_id IN (${_placeholders(muscleIds.length)})',
            values: muscleIds,
          );
    final exerciseEquipment = exerciseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'exercise_equipment',
            ' WHERE exercise_id IN (${_placeholders(exerciseIds.length)})',
            values: exerciseIds,
          );
    final equipmentIds = exerciseEquipment
        .map((row) => row['equipment_id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final equipment = equipmentIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'equipment',
            ' WHERE id IN (${_placeholders(equipmentIds.length)})',
            values: equipmentIds,
          );
    final equipmentTranslations = equipmentIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'equipment_translations',
            ' WHERE equipment_id IN (${_placeholders(equipmentIds.length)})',
            values: equipmentIds,
          );
    final exerciseTags = exerciseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'exercise_tags',
            ' WHERE exercise_id IN (${_placeholders(exerciseIds.length)})',
            values: exerciseIds,
          );
    final pinnedNotes = exerciseIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'pinned_exercise_notes',
            ' WHERE deleted_at IS NULL AND exercise_id IN (${_placeholders(exerciseIds.length)})',
            values: exerciseIds,
          );

    _enrichExercises(
      exercises: exercises,
      translations: exerciseTranslations,
      exerciseMuscles: exerciseMuscles,
      exerciseEquipment: exerciseEquipment,
      equipment: equipment,
      equipmentTranslations: equipmentTranslations,
    );

    final exercisesById = <String, Map<String, dynamic>>{
      for (final exercise in exercises)
        if (exercise['id'] is String) exercise['id'] as String: exercise,
    };
    final routinesById = <String, Map<String, dynamic>>{
      for (final routine in routines)
        if (routine['id'] is String) routine['id'] as String: routine,
    };

    for (final workout in workoutLogs) {
      final routineId = workout['routine_id'] as String?;
      final routine = routineId == null ? null : routinesById[routineId];
      final currentName = routine?['name'] as String?;
      final snapshotName =
          (workout['routine_name_snapshot'] as String?)?.trim();
      workout['effective_routine_name'] =
          (currentName != null && currentName.isNotEmpty)
              ? currentName
              : snapshotName;
    }

    void enrichExerciseLogRow(Map<String, dynamic> row) {
      final exerciseId = row['exercise_id'] as String?;
      final exercise = exerciseId == null ? null : exercisesById[exerciseId];
      final canonicalName = exercise?['name'] as String?;
      final snapshotName = (row['exercise_name_snapshot'] as String?)?.trim();
      row['canonical_exercise_name'] = canonicalName;
      row['effective_exercise_name'] =
          (canonicalName != null && canonicalName.isNotEmpty)
              ? canonicalName
              : snapshotName;
    }

    for (final setLog in setLogs) {
      enrichExerciseLogRow(setLog);
    }
    for (final exerciseLog in workoutExerciseLogs) {
      enrichExerciseLogRow(exerciseLog);
    }

    return {
      'workout_logs': workoutLogs,
      'set_logs': setLogs,
      'workout_exercise_logs': workoutExerciseLogs,
      'cardio_activities': cardioActivities,
      'cardio_samples': cardioSamples,
      'routines': routines,
      'exercises': exercises,
      'exercise_translations': exerciseTranslations,
      'exercise_muscles': exerciseMuscles,
      'muscles': muscles,
      'muscle_translations': muscleTranslations,
      'exercise_equipment': exerciseEquipment,
      'equipment': equipment,
      'equipment_translations': equipmentTranslations,
      'exercise_tags': exerciseTags,
      'pinned_exercise_notes': pinnedNotes,
    };
  }

  void _enrichExercises({
    required List<Map<String, dynamic>> exercises,
    required List<Map<String, dynamic>> translations,
    required List<Map<String, dynamic>> exerciseMuscles,
    required List<Map<String, dynamic>> exerciseEquipment,
    required List<Map<String, dynamic>> equipment,
    required List<Map<String, dynamic>> equipmentTranslations,
  }) {
    final nameDeByExercise = <String, String>{};
    final nameEnByExercise = <String, String>{};
    final anyNameByExercise = <String, String>{};
    for (final row in translations) {
      final exerciseId = row['exercise_id'];
      final name = (row['name'] as String?)?.trim();
      if (exerciseId is! String || name == null || name.isEmpty) continue;
      final lang = (row['language_code'] as String?)?.toLowerCase();
      anyNameByExercise.putIfAbsent(exerciseId, () => name);
      if (lang == 'de') {
        nameDeByExercise[exerciseId] = name;
      } else if (lang == 'en') {
        nameEnByExercise[exerciseId] = name;
      }
    }

    final primaryMusclesByExercise = <String, List<String>>{};
    final secondaryMusclesByExercise = <String, List<String>>{};
    for (final row in exerciseMuscles) {
      final exerciseId = row['exercise_id'];
      final muscleId = row['muscle_id'];
      if (exerciseId is! String || muscleId is! String || muscleId.isEmpty) {
        continue;
      }
      final role = (row['role'] as String?)?.toLowerCase();
      if (role == 'secondary') {
        secondaryMusclesByExercise
            .putIfAbsent(exerciseId, () => <String>[])
            .add(muscleId);
      } else {
        primaryMusclesByExercise
            .putIfAbsent(exerciseId, () => <String>[])
            .add(muscleId);
      }
    }

    final equipmentNameById = <String, String>{};
    for (final row in equipment) {
      final id = row['id'];
      if (id is String && id.isNotEmpty) {
        equipmentNameById[id] = (row['key'] as String?) ?? id;
      }
    }
    for (final row in equipmentTranslations) {
      final id = row['equipment_id'];
      final name = (row['name'] as String?)?.trim();
      final lang = (row['language_code'] as String?)?.toLowerCase();
      if (id is String && name != null && name.isNotEmpty) {
        if (lang == 'en' || !equipmentNameById.containsKey(id)) {
          equipmentNameById[id] = name;
        }
      }
    }

    final equipmentByExercise = <String, List<String>>{};
    for (final row in exerciseEquipment) {
      final exerciseId = row['exercise_id'];
      final equipmentId = row['equipment_id'];
      if (exerciseId is! String ||
          equipmentId is! String ||
          equipmentId.isEmpty) {
        continue;
      }
      final label = equipmentNameById[equipmentId] ?? equipmentId;
      final list =
          equipmentByExercise.putIfAbsent(exerciseId, () => <String>[]);
      if (!list.contains(label)) list.add(label);
    }

    for (final exercise in exercises) {
      final id = exercise['id'] as String?;
      if (id == null) continue;
      final nameDe = nameDeByExercise[id];
      final nameEn = nameEnByExercise[id];
      final fallbackName =
          anyNameByExercise[id] ?? (exercise['external_id'] as String?) ?? id;
      exercise['name'] = nameEn ?? nameDe ?? fallbackName;
      exercise['name_de'] = nameDe;
      exercise['name_en'] = nameEn;
      final primary = primaryMusclesByExercise[id];
      final secondary = secondaryMusclesByExercise[id];
      final equip = equipmentByExercise[id];
      exercise['primary_muscles'] =
          primary == null || primary.isEmpty ? null : primary.join(', ');
      exercise['secondary_muscles'] =
          secondary == null || secondary.isEmpty ? null : secondary.join(', ');
      exercise['equipment_names'] =
          equip == null || equip.isEmpty ? null : equip.join(', ');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _readNutritionSnapshot(
    AssistantDateScope? scope,
  ) async {
    final range = _range(scope);
    final foodWhere = _dateWhere('consumed_at', range);
    final mealWhere = _dateWhere('consumed_at', range);
    final fluidWhere = _dateWhere('consumed_at', range);
    final supplementWhere = _dateWhere('taken_at', range);

    final mealEntries = await _select('meal_entries', mealWhere, values: range);
    final nutritionLogs =
        await _select('nutrition_logs', foodWhere, values: range);
    final fluidLogs = await _select('fluid_logs', fluidWhere, values: range);
    final supplementLogs =
        await _select('supplement_logs', supplementWhere, values: range);

    // Saved recipes have no foreign key from meal_entries. They belong only to
    // the separately approved recipes category.
    final productIds = <String>{
      for (final row in nutritionLogs)
        if (row['product_id'] is String &&
            (row['product_id'] as String).isNotEmpty)
          row['product_id'] as String,
    };
    final archiveLocalIds = <int>{
      for (final row in nutritionLogs)
        if (row['archive_local_id'] is int) row['archive_local_id'] as int,
    };
    final barcodes = <String>{
      for (final row in nutritionLogs)
        if (row['legacy_barcode'] is String &&
            (row['legacy_barcode'] as String).isNotEmpty)
          row['legacy_barcode'] as String,
    };

    // Archived snapshots are selected only by their explicit log reference.
    // Another archive row with the same barcode may describe a different
    // historical product state and must not replace the logged snapshot.
    final archives = await _selectArchives(
      archiveLocalIds: archiveLocalIds,
      barcodes: const {},
    );

    // Read current products by the log's product_id or legacy barcode.
    final products = await _selectProducts(
      productIds: productIds,
      barcodes: barcodes,
    );
    for (final product in products) {
      final barcode = product['barcode'];
      if (barcode is String && barcode.isNotEmpty) barcodes.add(barcode);
    }
    // A product_id-only log can still need its barcode to find an override.

    // 3. Read user food overrides and translations for all resolved barcodes.
    final barcodeList = barcodes.toList();
    final overrides = barcodeList.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'user_food_overrides',
            ' WHERE deleted_at IS NULL AND barcode IN (${_placeholders(barcodeList.length)})',
            values: barcodeList,
          );
    final overrideIds = overrides
        .map((row) => row['id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final overrideTranslations = overrideIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _select(
            'user_food_override_translations',
            ' WHERE deleted_at IS NULL AND user_food_override_id IN (${_placeholders(overrideIds.length)})',
            values: overrideIds,
          );

    // 4. Enrich nutrition_logs with resolved links and effective nutrient values.
    _enrichNutritionLogs(
      nutritionLogs: nutritionLogs,
      products: products,
      archives: archives,
      overrides: overrides,
    );

    // 5. Read BLS micronutrients for all BLS barcodes present in the approved scope.
    final blsNutrients = await _readBlsFoodNutrients({
      ...barcodeList,
      for (final archive in archives)
        if (archive['barcode'] is String) archive['barcode'] as String,
    });

    // 6. Supplements & settings history for supplements logged in the approved scope.
    const supplementLogsSubquery = 'SELECT supplement_id FROM supplement_logs';
    final supplementIdsSubquery = '$supplementLogsSubquery$supplementWhere';
    final supplements = await _select(
      'supplements',
      ' WHERE deleted_at IS NULL AND id IN ($supplementIdsSubquery)',
      values: range,
    );
    final settingHistoryWhere = range.isEmpty
        ? ' WHERE deleted_at IS NULL'
        : ' WHERE deleted_at IS NULL AND created_at < ? AND supplement_id IN ($supplementIdsSubquery)';
    final supplementSettingsHistory = await _select(
      'supplement_settings_history',
      settingHistoryWhere,
      values: range.isEmpty ? const [] : [range.last, ...range],
    );

    // 7. Daily goals history: include rows in range plus the active goal at range start.
    final dailyGoalsHistory = await _readScopedDailyGoalsHistory(range);

    return {
      'meal_entries': mealEntries,
      'nutrition_logs': nutritionLogs,
      'fluid_logs': fluidLogs,
      'supplement_logs': supplementLogs,
      'products': products,
      'off_products_archive': archives,
      'supplements': supplements,
      'supplement_settings_history': supplementSettingsHistory,
      'user_food_overrides': overrides,
      'user_food_override_translations': overrideTranslations,
      'bls_food_nutrients': blsNutrients,
      'daily_goals_history': dailyGoalsHistory,
    };
  }

  Future<List<Map<String, dynamic>>> _selectArchives({
    required Set<int> archiveLocalIds,
    required Set<String> barcodes,
  }) async {
    if (archiveLocalIds.isEmpty && barcodes.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final clauses = <String>[];
    final values = <Object?>[];
    if (archiveLocalIds.isNotEmpty) {
      clauses.add('local_id IN (${_placeholders(archiveLocalIds.length)})');
      values.addAll(archiveLocalIds);
    }
    if (barcodes.isNotEmpty) {
      clauses.add('barcode IN (${_placeholders(barcodes.length)})');
      values.addAll(barcodes);
    }
    return _select(
      'off_products_archive',
      ' WHERE deleted_at IS NULL AND (${clauses.join(' OR ')})',
      values: values,
    );
  }

  Future<List<Map<String, dynamic>>> _selectProducts({
    required Set<String> productIds,
    required Set<String> barcodes,
  }) async {
    if (productIds.isEmpty && barcodes.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final clauses = <String>[];
    final values = <Object?>[];
    if (productIds.isNotEmpty) {
      clauses.add('id IN (${_placeholders(productIds.length)})');
      values.addAll(productIds);
    }
    if (barcodes.isNotEmpty) {
      clauses.add('barcode IN (${_placeholders(barcodes.length)})');
      values.addAll(barcodes);
    }
    return _select(
      'products',
      ' WHERE deleted_at IS NULL AND (${clauses.join(' OR ')})',
      values: values,
    );
  }

  void _enrichNutritionLogs({
    required List<Map<String, dynamic>> nutritionLogs,
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> archives,
    required List<Map<String, dynamic>> overrides,
  }) {
    final productsById = <String, Map<String, dynamic>>{
      for (final product in products)
        if (product['id'] is String) product['id'] as String: product,
    };
    final productsByBarcode = <String, Map<String, dynamic>>{
      for (final product in products)
        if (product['barcode'] is String) product['barcode'] as String: product,
    };
    final archivesByLocalId = <int, Map<String, dynamic>>{
      for (final archive in archives)
        if (archive['local_id'] is int) archive['local_id'] as int: archive,
    };
    final overridesByBarcode = <String, Map<String, dynamic>>{
      for (final override in overrides)
        if (override['barcode'] is String)
          override['barcode'] as String: override,
    };

    double? asDouble(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    int? asBoolInt(Object? value) {
      if (value == null) return null;
      if (value is bool) return value ? 1 : 0;
      if (value is num) return value.toInt() != 0 ? 1 : 0;
      return null;
    }

    for (final log in nutritionLogs) {
      final rawProductId = log['product_id'] as String?;
      final rawBarcode = log['legacy_barcode'] as String?;
      final rawArchiveId = log['archive_local_id'] as int?;

      final archive =
          rawArchiveId != null ? archivesByLocalId[rawArchiveId] : null;
      var product = (rawProductId != null && rawProductId.isNotEmpty)
          ? productsById[rawProductId]
          : null;

      final candidateBarcode = (rawBarcode != null && rawBarcode.isNotEmpty)
          ? rawBarcode
          : (product?['barcode'] as String?) ??
              (archive?['barcode'] as String?);

      if (rawArchiveId == null &&
          product == null &&
          candidateBarcode != null &&
          candidateBarcode.isNotEmpty) {
        product = productsByBarcode[candidateBarcode];
      }

      final effectiveBarcode = candidateBarcode ??
          (product?['barcode'] as String?) ??
          (archive?['barcode'] as String?);
      final override = rawArchiveId == null &&
              effectiveBarcode != null &&
              effectiveBarcode.isNotEmpty
          ? overridesByBarcode[effectiveBarcode]
          : null;

      Object? pickField(
        String productField, {
        String? archiveField,
        String? overrideField,
      }) {
        final aField = archiveField ?? productField;
        final oField = overrideField ?? productField;
        if (rawArchiveId != null) return archive?[aField];
        return override?[oField] ?? product?[productField];
      }

      final String effectiveSource;
      if (rawArchiveId != null) {
        effectiveSource = archive == null ? 'unlinked' : 'archive';
      } else if (override != null) {
        effectiveSource = 'override';
      } else if (product != null) {
        effectiveSource = 'products';
      } else {
        effectiveSource = 'unlinked';
      }

      final effectiveName = pickField(
        'name',
        archiveField: 'product_name',
        overrideField: 'name',
      ) as String?;
      final effectiveBrand = pickField('brand') as String?;
      final isFluid = asBoolInt(pickField('is_fluid')) ?? 0;
      final isLiquid = asBoolInt(pickField('is_liquid')) ?? 0;
      final effectiveIsFluid = (isFluid == 1 || isLiquid == 1) ? 1 : 0;

      final caloriesPer100g = asDouble(pickField('calories'));
      final proteinPer100g = asDouble(pickField('protein'));
      final carbsPer100g = asDouble(pickField('carbs'));
      final fatPer100g = asDouble(pickField('fat'));
      final sugarPer100g = asDouble(pickField('sugar'));
      final fiberPer100g = asDouble(pickField('fiber'));
      final saltPer100g = asDouble(pickField('salt'));
      final caffeinePer100g = asDouble(pickField('caffeine_mg_per_100g')) ??
          asDouble(pickField('caffeine'));

      final amount = asDouble(log['amount']) ?? 0.0;
      final ratio = amount / 100.0;

      double? scale(double? per100g) =>
          per100g == null ? null : per100g * ratio;

      log['effective_barcode'] = effectiveBarcode;
      log['effective_name'] = effectiveName;
      log['effective_brand'] = effectiveBrand;
      log['effective_source'] = effectiveSource;
      log['effective_is_fluid'] = effectiveIsFluid;
      log['calories_per_100g'] = caloriesPer100g;
      log['protein_per_100g'] = proteinPer100g;
      log['carbs_per_100g'] = carbsPer100g;
      log['fat_per_100g'] = fatPer100g;
      log['sugar_per_100g'] = sugarPer100g;
      log['fiber_per_100g'] = fiberPer100g;
      log['salt_per_100g'] = saltPer100g;
      log['caffeine_mg_per_100g'] = caffeinePer100g;
      log['calories_kcal'] = scale(caloriesPer100g);
      log['protein_g'] = scale(proteinPer100g);
      log['carbs_g'] = scale(carbsPer100g);
      log['fat_g'] = scale(fatPer100g);
      log['sugar_g'] = scale(sugarPer100g);
      log['fiber_g'] = scale(fiberPer100g);
      log['salt_g'] = scale(saltPer100g);
      log['caffeine_mg'] = scale(caffeinePer100g);
    }
  }

  Future<List<Map<String, dynamic>>> _readScopedDailyGoalsHistory(
    List<Object?> range,
  ) async {
    if (range.isEmpty) {
      return _select('daily_goals_history', ' WHERE deleted_at IS NULL');
    }
    final inRange = await _select(
      'daily_goals_history',
      _dateWhere('created_at', range),
      values: range,
    );
    final activeAtStart = await _select(
      'daily_goals_history',
      ' WHERE deleted_at IS NULL AND created_at < ? ORDER BY created_at DESC, local_id DESC LIMIT 1',
      values: [range.first],
    );
    final combined = <Map<String, dynamic>>[
      ...activeAtStart,
      ...inRange,
    ];
    if (combined.isNotEmpty) {
      final seen = <Object?>{};
      return [
        for (final row in combined)
          if (seen.add(row['id'] ?? row['local_id'])) row,
      ];
    }
    // Fallback to earliest configured goal if all goal rows were created after the range.
    return _select(
      'daily_goals_history',
      ' WHERE deleted_at IS NULL ORDER BY created_at ASC, local_id ASC LIMIT 1',
    );
  }

  Future<List<Map<String, dynamic>>> _readBlsFoodNutrients(
    Iterable<String> barcodes,
  ) async {
    final blsBarcodes = barcodes
        .where((barcode) => barcode.startsWith('bls:'))
        .toSet()
        .toList(growable: false);
    if (blsBarcodes.isEmpty) return const [];
    try {
      final resolvedPath = blsDatabasePath ??
          await (blsDatabasePathProvider?.call() ??
              BlsFoodCatalogRefreshService.instance.installedDatabasePath());
      if (resolvedPath == null || resolvedPath.isEmpty) return const [];
      final file = File(resolvedPath);
      if (!file.existsSync()) return const [];
      final blsDb = sqlite.sqlite3.open(
        resolvedPath,
        mode: sqlite.OpenMode.readOnly,
      );
      try {
        final results = <Map<String, dynamic>>[];
        const chunkSize = 300;
        for (var offset = 0; offset < blsBarcodes.length; offset += chunkSize) {
          final chunk = blsBarcodes.skip(offset).take(chunkSize).toList();
          final placeholders = _placeholders(chunk.length);
          final rows = blsDb.select(
            '''
            SELECT
              fn.barcode,
              fn.component_code,
              COALESCE(NULLIF(nc.name_en, ''), nc.name_de, fn.component_code) AS nutrient_name,
              nc.name_de,
              nc.name_en,
              nc.unit,
              COALESCE(NULLIF(nc.group_en, ''), nc.group_de) AS nutrient_group,
              nc.group_de,
              nc.group_en,
              fn.value_numeric AS value_per_100g,
              fn.value_numeric,
              fn.value_text,
              CASE WHEN fn.value_numeric IS NULL THEN 1 ELSE 0 END AS is_missing,
              o.label AS origin,
              r.citation AS reference
            FROM food_nutrients fn
            JOIN nutrient_components nc ON nc.component_code = fn.component_code
            LEFT JOIN data_origins o ON o.origin_id = fn.origin_id
            LEFT JOIN source_references r ON r.reference_id = fn.reference_id
            WHERE fn.barcode IN ($placeholders)
            ORDER BY fn.barcode, nc.group_de, fn.component_code
            ''',
            chunk,
          );
          for (final row in rows) {
            results.add(Map<String, dynamic>.from(row));
          }
        }
        return results;
      } finally {
        blsDb.close();
      }
    } catch (_) {
      // Handle an unavailable, missing, or corrupt BLS sidecar database gracefully.
      return const [];
    }
  }

  String _placeholders(int count) => List.filled(count, '?').join(', ');

  List<Object?> _range(
    AssistantDateScope? scope, {
    bool dateOnly = false,
    bool milliseconds = false,
  }) {
    if (scope == null) return const [];
    final startInclusive =
        DateTime(scope.start.year, scope.start.month, scope.start.day);
    final endExclusive =
        DateTime(scope.end.year, scope.end.month, scope.end.day + 1);
    if (dateOnly) {
      return [
        _day(startInclusive),
        _day(endExclusive),
      ];
    }
    if (milliseconds) {
      return [
        startInclusive.millisecondsSinceEpoch,
        endExclusive.millisecondsSinceEpoch,
      ];
    }
    // Drift stores DateTimeColumn values as Unix epoch seconds by default.
    return [
      startInclusive.millisecondsSinceEpoch ~/ 1000,
      endExclusive.millisecondsSinceEpoch ~/ 1000,
    ];
  }

  String _dateWhere(String column, List<Object?> range,
      {bool hasDeletedAt = true}) {
    if (range.isEmpty) return hasDeletedAt ? ' WHERE deleted_at IS NULL' : '';
    return '${hasDeletedAt ? ' WHERE deleted_at IS NULL AND' : ' WHERE'} $column >= ? AND $column < ?';
  }

  Future<List<Map<String, dynamic>>> _select(
    String table,
    String suffix, {
    List<Object?> values = const [],
    List<String>? columns,
  }) async {
    final variables = [
      for (final value in values)
        if (value is int)
          drift.Variable.withInt(value)
        else if (value is String)
          drift.Variable.withString(value)
        else if (value is DateTime)
          drift.Variable.withDateTime(value)
        else
          throw ArgumentError('Unsupported snapshot query variable.'),
    ];
    return (await database
            .customSelect(
                'SELECT ${columns?.join(', ') ?? '*'} FROM $table$suffix',
                variables: variables)
            .get())
        .map((row) => Map<String, dynamic>.from(row.data))
        .toList();
  }

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _activeWeekSchedule(
      Map<String, List<Map<String, dynamic>>> tables) {
    final activePlans = (tables['training_plans'] ?? const [])
        .where((plan) => plan['is_active'] == true || plan['is_active'] == 1)
        .where((plan) => plan['kind'] == 'week')
        .toList();
    if (activePlans.isEmpty) return const [];
    final plan = activePlans.first;
    final planId = plan['id'];
    if (planId is! String) return const [];
    final activations = (tables['training_plan_activations'] ?? const [])
        .where((row) => row['plan_id'] == planId && row['ended_on'] == null)
        .toList()
      ..sort((a, b) =>
          _dateValue(a['started_on']).compareTo(_dateValue(b['started_on'])));
    if (activations.isEmpty) return const [];
    final activation = activations.last;
    final startedOn = _dateValue(activation['started_on']);
    final startedOnDay =
        DateTime(startedOn.year, startedOn.month, startedOn.day);
    final today = (nowProvider?.call() ?? DateTime.now()).toLocal();
    final monday =
        DateTime(today.year, today.month, today.day - today.weekday + 1);
    final revisions = (tables['training_plan_revisions'] ?? const [])
        .where((row) => row['plan_id'] == planId)
        .toList()
      ..sort((a, b) =>
          (a['number'] as num? ?? 0).compareTo(b['number'] as num? ?? 0));
    if (revisions.isEmpty) return const [];
    final occurrences = tables['training_plan_occurrences'] ?? const [];
    final result = <Map<String, dynamic>>[];
    for (var index = 0; index < 7; index++) {
      final date = DateTime(monday.year, monday.month, monday.day + index);
      final daysDiff = DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(
              startedOnDay.year, startedOnDay.month, startedOnDay.day))
          .inDays;
      final cycle = daysDiff < 0 ? 0 : daysDiff ~/ 7;
      var revision = revisions.first;
      for (final candidate in revisions) {
        final effectiveOn = _dateValue(candidate['effective_on']);
        final effectiveOnDay =
            DateTime(effectiveOn.year, effectiveOn.month, effectiveOn.day);
        final effectiveCycle = candidate['effective_cycle'] as num?;
        if (!date.isBefore(effectiveOnDay) &&
            (effectiveCycle == null || cycle >= effectiveCycle.toInt())) {
          revision = candidate;
        }
      }
      if (revision['days_json'] is! String) continue;
      final days = jsonDecode(revision['days_json'] as String);
      if (days is! List || index >= days.length || days[index] is! Map) {
        continue;
      }
      final day = Map<String, dynamic>.from(days[index] as Map);
      final routine = day['routineSnapshot'] is Map
          ? Map<String, dynamic>.from(day['routineSnapshot'] as Map)
          : null;
      final occurrence = occurrences.where((row) {
        return row['activation_id'] == activation['id'] &&
            _sameDate(_dateValue(row['scheduled_on']), date) &&
            row['slot_index'] == index;
      }).firstOrNull;
      result.add({
        'plan_id': planId,
        'plan_name': plan['name'],
        'plan_kind': plan['kind'],
        'date': _day(date),
        'weekday_index': index + 1,
        'slot_index': index,
        'revision_id': revision['id'],
        'revision_number': revision['number'],
        'routine_uuid': day['routineUuid'],
        'routine_name': routine?['name'],
        'is_rest': routine == null,
        'status': routine == null ? 'rest' : occurrence?['status'] ?? 'planned',
        'workout_log_id': occurrence?['workout_log_id'],
        'routine_snapshot': routine,
      });
    }
    return result;
  }

  DateTime _dateValue(Object? value) {
    if (value is DateTime) return value.toLocal();
    if (value is int) {
      // Drift DateTimeColumn values are Unix epoch seconds (< 10^11);
      // custom tables or epoch-ms inputs are milliseconds (>= 10^11).
      final millis = value.abs() < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
    if (value is num) {
      final intVal = value.toInt();
      final millis = intVal.abs() < 100000000000 ? intVal * 1000 : intVal;
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
    return DateTime.parse(value.toString()).toLocal();
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _sqliteType(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('INT')) return 'INTEGER';
    if (normalized.contains('REAL') ||
        normalized.contains('FLOA') ||
        normalized.contains('DOUB')) {
      return 'REAL';
    }
    if (normalized.contains('BLOB')) return 'BLOB';
    return 'TEXT';
  }

  String _inferValueType(Object? value) {
    if (value is int || value is bool) return 'INTEGER';
    if (value is num) return 'REAL';
    return 'TEXT';
  }
}

/// Adds complete allowlisted SQLite table snapshots to existing semantic
/// action results so analysis can use all stored fields and relationships.
class AssistantComprehensiveDataAction implements AssistantDataAction {
  AssistantComprehensiveDataAction({
    required this.reader,
    required this.actions,
  });

  final AssistantDatabaseSnapshotReader reader;
  final List<AssistantDataAction> actions;

  @override
  Set<AssistantDataCategory> get categories => {
        for (final action in actions) ...action.categories,
      };

  @override
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope) async {
    final matches =
        actions.where((action) => action.categories.contains(category));
    if (matches.length != 1) throw StateError('No unique action for $category');
    final semantic = await matches.single.read(category, scope);
    if (semantic.status != AssistantActionStatus.success) return semantic;
    final tables = await reader.read(category, scope);
    return AssistantActionResult(
      category: category,
      status: semantic.status,
      records: semantic.records,
      tables: tables,
      tableColumns: await reader.columnsFor(tables),
      error: semantic.error,
    );
  }
}
