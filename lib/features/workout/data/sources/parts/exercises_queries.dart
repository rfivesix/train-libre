part of '../workout_local_data_source.dart';

extension ExercisesQueries on WorkoutLocalDataSource {
  /// Retrieves all unique exercise categories present in the database.
  Future<List<String>> getAllCategories() async {
    final dbInstance = await database;
    final query = dbInstance.selectOnly(dbInstance.exercises, distinct: true)
      ..addColumns([dbInstance.exercises.categoryName]);

    final rows = await query.get();
    final categories = rows
        .map((r) => r.read(dbInstance.exercises.categoryName))
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();

    return categories..sort();
  }

  Future<List<String>> getAllMuscleGroups() async {
    final dbInstance = await database;
    final exercises = await dbInstance.select(dbInstance.exercises).get();
    final Set<String> muscles = {};

    for (var ex in exercises) {
      muscles.addAll(WorkoutLocalDataSource._parseMuscleList(ex.musclesPrimary));
      muscles.addAll(WorkoutLocalDataSource._parseMuscleList(ex.musclesSecondary));
    }
    return muscles.toList()..sort();
  }

  List<String> _tokenizeAndClean(String input) {
    final sanitized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß ]', unicode: true), ' ');
    return sanitized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final dbInstance = await database;

    final tokens = _tokenizeAndClean(query);
    final rawSearchLower = query.trim().toLowerCase();
    final ninetyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;

    final variables = <drift.Variable>[];

    // 1. History subquery variable
    variables.add(drift.Variable.withInt(ninetyDaysAgo));

    // 2. Exact match variables (if query is not empty)
    final String exactMatchExpr = tokens.isEmpty
        ? '0 AS is_exact_match'
        : '(CASE WHEN LOWER(e.name_de) = ? OR LOWER(e.name_en) = ? THEN 1 ELSE 0 END) AS is_exact_match';
    if (tokens.isNotEmpty) {
      variables.add(drift.Variable.withString(rawSearchLower));
      variables.add(drift.Variable.withString(rawSearchLower));
    }

    // 3. Prefix match variables (if query is not empty)
    final String prefixMatchExpr = tokens.isEmpty
        ? '0 AS is_prefix_match'
        : '(CASE WHEN LOWER(e.name_de) LIKE ? OR LOWER(e.name_en) LIKE ? THEN 1 ELSE 0 END) AS is_prefix_match';
    if (tokens.isNotEmpty) {
      variables.add(drift.Variable.withString('$rawSearchLower%'));
      variables.add(drift.Variable.withString('$rawSearchLower%'));
    }

    // 4. Token matches in WHERE clause
    final whereClauses = <String>[
      'NOT (e.source = \'wger\' AND EXISTS (SELECT 1 FROM exercises other_exercises WHERE other_exercises.replaces_exercise_id = e.id))'
    ];

    if (tokens.isNotEmpty) {
      for (final token in tokens) {
        whereClauses.add('(e.name_de LIKE ? OR e.name_en LIKE ?)');
        variables.add(drift.Variable.withString('%$token%'));
        variables.add(drift.Variable.withString('%$token%'));
      }
    }

    if (selectedCategories.isNotEmpty) {
      final placeholders = List.filled(selectedCategories.length, '?').join(', ');
      whereClauses.add('e.category_name IN ($placeholders)');
      for (final cat in selectedCategories) {
        variables.add(drift.Variable.withString(cat));
      }
    }

    final whereSection = whereClauses.join(' AND ');

    final sql = '''
      SELECT e.*,
             (
               SELECT COUNT(*) * 15
               FROM set_logs s
               JOIN workout_logs w ON s.workout_log_id = w.id
               WHERE s.exercise_id = e.id
                 AND w.start_time >= ?
             ) AS history_priority_score,
             $exactMatchExpr,
             (CASE WHEN e.is_custom = 1 OR e.source = 'user' THEN 1 ELSE 0 END) AS is_custom_exercise,
             $prefixMatchExpr
      FROM exercises e
      WHERE $whereSection
      ORDER BY 
        is_exact_match DESC, 
        history_priority_score DESC, 
        is_custom_exercise DESC, 
        is_prefix_match DESC, 
        e.name_de ASC
      LIMIT 50
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: variables,
      readsFrom: {
        dbInstance.exercises,
        dbInstance.setLogs,
        dbInstance.workoutLogs,
      },
    ).get();

    final dbExercises =
        rows.map((row) => dbInstance.exercises.map(row.data)).toList();
    return dbExercises.map(_mapExerciseToModel).toList();
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.exercises)
          ..where(
            (tbl) => tbl.nameDe.equals(name) | tbl.nameEn.equals(name),
          ))
        .get();

    if (rows.isEmpty) return null;

    // Prefer custom/user exercises
    final userRow = rows.where((r) => r.source == 'user').firstOrNull;
    if (userRow != null) {
      return _mapExerciseToModel(userRow);
    }

    // Check if the system exercise has an active override
    final firstRow = rows.first;
    final overrideRow = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.replacesExerciseId.equals(firstRow.id) & tbl.source.equals('user'))
          ..limit(1))
        .getSingleOrNull();
    if (overrideRow != null) {
      return _mapExerciseToModel(overrideRow);
    }

    return _mapExerciseToModel(firstRow);
  }

  Future<Exercise?> getExerciseByUuid(String exerciseUuid) async {
    final dbInstance = await database;

    // Resolve overriding custom exercises first
    final overrideRow = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.replacesExerciseId.equals(exerciseUuid) & tbl.source.equals('user'))
          ..limit(1))
        .getSingleOrNull();
    if (overrideRow != null) {
      return _mapExerciseToModel(overrideRow);
    }

    final row = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.id.equals(exerciseUuid))
          ..limit(1))
        .getSingleOrNull();

    return row != null ? _mapExerciseToModel(row) : null;
  }

  Future<Exercise?> resolveExerciseForSetLog(SetLog setLog) async {
    final dbInstance = await database;
    String? exerciseUuid;

    if (setLog.id != null) {
      final setRow = await (dbInstance.select(dbInstance.setLogs)
            ..where((tbl) => tbl.localId.equals(setLog.id!))
            ..limit(1))
          .getSingleOrNull();
      exerciseUuid = setRow?.exerciseId;
    }

    if (exerciseUuid != null && exerciseUuid.isNotEmpty) {
      final exercise = await getExerciseByUuid(exerciseUuid);
      if (exercise != null) return exercise;
    }

    return getExerciseByName(setLog.exerciseName);
  }

  Future<Exercise> insertExercise(Exercise exercise) async {
    final dbInstance = await database;

    final companion = db.ExercisesCompanion(
      id: exercise.uuid != null ? drift.Value(exercise.uuid!) : const drift.Value.absent(),
      source: drift.Value(exercise.source),
      replacesExerciseId: drift.Value(exercise.replacesExerciseId),
      nameDe: drift.Value(exercise.nameDe),
      nameEn: drift.Value(exercise.nameEn),
      descriptionDe: drift.Value(exercise.descriptionDe),
      descriptionEn: drift.Value(exercise.descriptionEn),
      categoryName: drift.Value(exercise.categoryName),
      musclesPrimary: drift.Value(jsonEncode(exercise.primaryMuscles)),
      musclesSecondary: drift.Value(jsonEncode(exercise.secondaryMuscles)),
      imagePath: drift.Value(exercise.imagePath),
      isCustom: const drift.Value(true),
    );

    final row =
        await dbInstance.into(dbInstance.exercises).insertReturning(companion);
    return _mapExerciseToModel(row);
  }

  Future<List<Exercise>> getCustomExercises() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.exercises,
    )..where((tbl) => tbl.isCustom.equals(true)))
        .get();
    return rows.map(_mapExerciseToModel).toList();
  }

  Future<void> importCustomExercises(List<Exercise> exercises) async {
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final ex in exercises) {
        batch.insert(
          dbInstance.exercises,
          db.ExercisesCompanion(
            nameDe: drift.Value(ex.nameDe),
            nameEn: drift.Value(ex.nameEn),
            descriptionDe: drift.Value(ex.descriptionDe),
            descriptionEn: drift.Value(ex.descriptionEn),
            categoryName: drift.Value(ex.categoryName),
            musclesPrimary: drift.Value(jsonEncode(ex.primaryMuscles)),
            musclesSecondary: drift.Value(jsonEncode(ex.secondaryMuscles)),
            imagePath: drift.Value(ex.imagePath),
            isCustom: const drift.Value(true),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updateCustomExercise(Exercise exercise) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      final existing = await (dbInstance.select(dbInstance.exercises)
            ..where((tbl) => tbl.localId.equals(exercise.id!))
            ..limit(1))
          .getSingleOrNull();

      if (existing == null) {
        throw Exception("Exercise not found");
      }

      if (existing.source != 'user') {
        throw Exception("Cannot update non-user exercise directly. Create a custom copy instead.");
      }

      await (dbInstance.update(dbInstance.exercises)
            ..where((tbl) => tbl.localId.equals(exercise.id!)))
          .write(
        db.ExercisesCompanion(
          nameDe: drift.Value(exercise.nameDe),
          nameEn: drift.Value(exercise.nameEn),
          descriptionDe: drift.Value(exercise.descriptionDe),
          descriptionEn: drift.Value(exercise.descriptionEn),
          categoryName: drift.Value(exercise.categoryName),
          musclesPrimary: drift.Value(jsonEncode(exercise.primaryMuscles)),
          musclesSecondary: drift.Value(jsonEncode(exercise.secondaryMuscles)),
          imagePath: drift.Value(exercise.imagePath),
        ),
      );
    });
  }
}
