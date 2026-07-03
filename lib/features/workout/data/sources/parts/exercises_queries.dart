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
      muscles
          .addAll(WorkoutLocalDataSource._parseMuscleList(ex.musclesPrimary));
      muscles
          .addAll(WorkoutLocalDataSource._parseMuscleList(ex.musclesSecondary));
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

    // Build SELECT expressions for scoring
    final String exactMatchExpr = tokens.isEmpty
        ? '0 AS is_exact_match'
        : '(CASE WHEN LOWER(COALESCE(t_de.name, t_en.name, t_any.name)) = ? '
            'THEN 1 ELSE 0 END) AS is_exact_match';

    final String prefixMatchExpr = tokens.isEmpty
        ? '0 AS is_prefix_match'
        : '(CASE WHEN LOWER(COALESCE(t_de.name, t_en.name, t_any.name)) LIKE ? '
            'THEN 1 ELSE 0 END) AS is_prefix_match';

    // Build WHERE clauses
    final whereClauses = <String>[
      "NOT (e.source = 'wger' AND "
          "EXISTS (SELECT 1 FROM exercises other_exercises "
          "WHERE other_exercises.replaces_exercise_id = e.id))",
    ];

    if (tokens.isNotEmpty) {
      for (final _ in tokens) {
        whereClauses.add(
          '(t_de.name LIKE ? OR t_en.name LIKE ? OR t_any.name LIKE ?)',
        );
      }
    }

    if (selectedCategories.isNotEmpty) {
      final placeholders =
          List.filled(selectedCategories.length, '?').join(', ');
      whereClauses.add('e.category_name IN ($placeholders)');
    }

    final whereSection = whereClauses.join(' AND ');

    // Variable list MUST match ? positions in the SQL below
    final vars = <drift.Variable>[];

    // 1. history subquery
    vars.add(drift.Variable.withInt(ninetyDaysAgo));

    // 2. exactMatchExpr (1 placeholder)
    if (tokens.isNotEmpty) {
      vars.add(drift.Variable.withString(rawSearchLower));
    }

    // 3. prefixMatchExpr (1 placeholder)
    if (tokens.isNotEmpty) {
      vars.add(drift.Variable.withString('$rawSearchLower%'));
    }

    // 4. WHERE token clauses (3 per token: t_de, t_en, t_any)
    for (final token in tokens) {
      vars.add(drift.Variable.withString('%$token%'));
      vars.add(drift.Variable.withString('%$token%'));
      vars.add(drift.Variable.withString('%$token%'));
    }

    // 5. WHERE category IN placeholders
    for (final cat in selectedCategories) {
      vars.add(drift.Variable.withString(cat));
    }

    final sql = '''
      SELECT e.*,
             t_de.name AS name_de,
             t_en.name AS name_en,
             t_de.description AS desc_de,
             t_en.description AS desc_en,
             COALESCE(t_de.name, t_en.name, t_any.name) AS display_name,
             COALESCE(t_de.description, t_en.description) AS display_description,
             (
               SELECT COUNT(*) * 15
               FROM set_logs s
               JOIN workout_logs w ON s.workout_log_id = w.id
               WHERE s.exercise_id = e.id
                 AND w.start_time >= ?
             ) AS history_priority_score,
             $exactMatchExpr,
             (CASE WHEN e.is_custom = 1 OR e.source = 'user'
              THEN 1 ELSE 0 END) AS is_custom_exercise,
             $prefixMatchExpr
      FROM exercises e
      LEFT JOIN exercise_translations t_de
        ON e.id = t_de.exercise_id AND t_de.language_code = 'de'
      LEFT JOIN exercise_translations t_en
        ON e.id = t_en.exercise_id AND t_en.language_code = 'en'
      LEFT JOIN (
        SELECT exercise_id, name, description
        FROM exercise_translations
        GROUP BY exercise_id
      ) t_any ON e.id = t_any.exercise_id
      WHERE $whereSection
      ORDER BY
        is_exact_match DESC,
        history_priority_score DESC,
        is_custom_exercise DESC,
        is_prefix_match DESC,
        COALESCE(t_de.name, t_en.name, t_any.name) ASC
      LIMIT 50
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: vars,
      readsFrom: {
        dbInstance.exercises,
        dbInstance.exerciseTranslations,
        dbInstance.setLogs,
        dbInstance.workoutLogs,
      },
    ).get();

    return rows.map((row) {
      final rawExercise = dbInstance.exercises.map(row.data);
      final displayName = row.readNullable<String>('display_name') ?? '';
      final displayDescription =
          row.readNullable<String>('display_description') ?? '';

      final nameDe = row.readNullable<String>('name_de') ?? displayName;
      final nameEn = row.readNullable<String>('name_en') ?? displayName;
      final descDe = row.readNullable<String>('desc_de') ?? displayDescription;
      final descEn = row.readNullable<String>('desc_en') ?? displayDescription;

      return Exercise(
        id: rawExercise.localId,
        uuid: rawExercise.id,
        source: rawExercise.source,
        replacesExerciseId: rawExercise.replacesExerciseId,
        nameDe: nameDe,
        nameEn: nameEn,
        descriptionDe: descDe,
        descriptionEn: descEn,
        categoryName: rawExercise.categoryName ?? 'Other',
        imagePath: rawExercise.imagePath,
        primaryMuscles:
            WorkoutLocalDataSource._parseMuscleList(rawExercise.musclesPrimary),
        secondaryMuscles: WorkoutLocalDataSource._parseMuscleList(
            rawExercise.musclesSecondary),
      );
    }).toList();
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final dbInstance = await database;

    final sql = '''
      SELECT e.*,
             t_de.name AS name_de,
             t_en.name AS name_en,
             t_de.description AS desc_de,
             t_en.description AS desc_en,
             COALESCE(t_en.name, t_de.name, t_any.name) AS display_name,
             COALESCE(t_en.description, t_de.description) AS display_description
      FROM exercises e
      LEFT JOIN exercise_translations t_en
        ON e.id = t_en.exercise_id AND t_en.language_code = 'en'
      LEFT JOIN exercise_translations t_de
        ON e.id = t_de.exercise_id AND t_de.language_code = 'de'
      LEFT JOIN (
        SELECT exercise_id, name, description, MIN(language_code)
        FROM exercise_translations
        GROUP BY exercise_id
      ) t_any ON e.id = t_any.exercise_id
      WHERE t_de.name = ? OR t_en.name = ? OR t_any.name = ?
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        drift.Variable.withString(name),
        drift.Variable.withString(name),
        drift.Variable.withString(name),
      ],
      readsFrom: {dbInstance.exercises, dbInstance.exerciseTranslations},
    ).get();

    if (rows.isEmpty) return null;

    // Prefer custom/user exercises
    final userRow = rows.where((r) => r.data['source'] == 'user').firstOrNull;
    if (userRow != null) {
      return _mapRowToExercise(dbInstance, userRow);
    }

    // Check if the system exercise has an active override
    final firstRawExercise = dbInstance.exercises.map(rows.first.data);
    final overrideRow = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) =>
              tbl.replacesExerciseId.equals(firstRawExercise.id) &
              tbl.source.equals('user'))
          ..limit(1))
        .getSingleOrNull();

    if (overrideRow != null) {
      return _mapExerciseRowToModel(dbInstance, overrideRow);
    }

    return _mapRowToExercise(dbInstance, rows.first);
  }

  Future<Exercise?> getExerciseByUuid(String exerciseUuid) async {
    final dbInstance = await database;

    // Resolve overriding custom exercises first
    final overrideRow = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) =>
              tbl.replacesExerciseId.equals(exerciseUuid) &
              tbl.source.equals('user'))
          ..limit(1))
        .getSingleOrNull();

    if (overrideRow != null) {
      return _mapExerciseRowToModel(dbInstance, overrideRow);
    }

    final row = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.id.equals(exerciseUuid))
          ..limit(1))
        .getSingleOrNull();

    return row != null ? _mapExerciseRowToModel(dbInstance, row) : null;
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

    return await dbInstance.transaction(() async {
      final companion = db.ExercisesCompanion(
        id: exercise.uuid != null
            ? drift.Value(exercise.uuid!)
            : const drift.Value.absent(),
        source: drift.Value(exercise.source),
        replacesExerciseId: drift.Value(exercise.replacesExerciseId),
        categoryName: drift.Value(exercise.categoryName),
        musclesPrimary: drift.Value(jsonEncode(exercise.primaryMuscles)),
        musclesSecondary: drift.Value(jsonEncode(exercise.secondaryMuscles)),
        imagePath: drift.Value(exercise.imagePath),
        isCustom: const drift.Value(true),
      );

      final row = await dbInstance
          .into(dbInstance.exercises)
          .insertReturning(companion);

      // Insert translations
      await _upsertTranslations(dbInstance, row.id, exercise);

      return _mapExerciseRowToModel(dbInstance, row);
    });
  }

  Future<void> importCustomExercises(List<Exercise> exercises) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      for (final ex in exercises) {
        final row = await dbInstance.into(dbInstance.exercises).insertReturning(
              db.ExercisesCompanion(
                categoryName: drift.Value(ex.categoryName),
                musclesPrimary: drift.Value(jsonEncode(ex.primaryMuscles)),
                musclesSecondary: drift.Value(jsonEncode(ex.secondaryMuscles)),
                imagePath: drift.Value(ex.imagePath),
                isCustom: const drift.Value(true),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );

        await _upsertTranslations(dbInstance, row.id, ex);
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
        throw Exception(
            "Cannot update non-user exercise directly. Create a custom copy instead.");
      }

      await (dbInstance.update(dbInstance.exercises)
            ..where((tbl) => tbl.localId.equals(exercise.id!)))
          .write(
        db.ExercisesCompanion(
          categoryName: drift.Value(exercise.categoryName),
          musclesPrimary: drift.Value(jsonEncode(exercise.primaryMuscles)),
          musclesSecondary: drift.Value(jsonEncode(exercise.secondaryMuscles)),
          imagePath: drift.Value(exercise.imagePath),
        ),
      );

      await _upsertTranslations(dbInstance, existing.id, exercise);
    });
  }

  Future<List<Exercise>> getCustomExercises() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.exercises,
    )..where((tbl) => tbl.isCustom.equals(true)))
        .get();

    final result = <Exercise>[];
    for (final row in rows) {
      result.add(await _mapExerciseRowToModel(dbInstance, row));
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Upserts 'de' and 'en' translations for [exerciseId] from an [Exercise] domain model.
  Future<void> _upsertTranslations(
    db.AppDatabase dbInstance,
    String exerciseId,
    Exercise exercise,
  ) async {
    final langs = <String, (String name, String? desc)>{
      if (exercise.nameDe.isNotEmpty)
        'de': (
          exercise.nameDe,
          exercise.descriptionDe.isNotEmpty ? exercise.descriptionDe : null
        ),
      if (exercise.nameEn.isNotEmpty)
        'en': (
          exercise.nameEn,
          exercise.descriptionEn.isNotEmpty ? exercise.descriptionEn : null
        ),
    };

    for (final entry in langs.entries) {
      final langCode = entry.key;
      final (name, desc) = entry.value;

      final companion = db.ExerciseTranslationsCompanion(
        exerciseId: drift.Value(exerciseId),
        languageCode: drift.Value(langCode),
        name: drift.Value(name),
        description: drift.Value(desc),
      );

      await dbInstance.into(dbInstance.exerciseTranslations).insert(
            companion,
            onConflict: drift.DoUpdate(
              (old) => companion,
              target: [
                dbInstance.exerciseTranslations.exerciseId,
                dbInstance.exerciseTranslations.languageCode
              ],
            ),
          );
    }
  }

  /// Maps a custom-select row (from a JOIN query) to [Exercise].
  Exercise _mapRowToExercise(db.AppDatabase dbInstance, drift.QueryRow row) {
    final rawExercise = dbInstance.exercises.map(row.data);
    final displayName = row.readNullable<String>('display_name') ?? '';
    final displayDescription =
        row.readNullable<String>('display_description') ?? '';

    final nameDe = row.readNullable<String>('name_de') ?? displayName;
    final nameEn = row.readNullable<String>('name_en') ?? displayName;
    final descDe = row.readNullable<String>('desc_de') ?? displayDescription;
    final descEn = row.readNullable<String>('desc_en') ?? displayDescription;

    return Exercise(
      id: rawExercise.localId,
      uuid: rawExercise.id,
      source: rawExercise.source,
      replacesExerciseId: rawExercise.replacesExerciseId,
      nameDe: nameDe,
      nameEn: nameEn,
      descriptionDe: descDe,
      descriptionEn: descEn,
      categoryName: rawExercise.categoryName ?? 'Other',
      imagePath: rawExercise.imagePath,
      primaryMuscles:
          WorkoutLocalDataSource._parseMuscleList(rawExercise.musclesPrimary),
      secondaryMuscles:
          WorkoutLocalDataSource._parseMuscleList(rawExercise.musclesSecondary),
    );
  }

  /// Maps a Drift [db.Exercise] row to [Exercise], loading translations from the DB.
  Future<Exercise> _mapExerciseRowToModel(
    db.AppDatabase dbInstance,
    db.Exercise row,
  ) async {
    final translations =
        await (dbInstance.select(dbInstance.exerciseTranslations)
              ..where((t) => t.exerciseId.equals(row.id)))
            .get();

    String nameDe = '';
    String nameEn = '';
    String descriptionDe = '';
    String descriptionEn = '';

    for (final t in translations) {
      switch (t.languageCode) {
        case 'de':
          nameDe = t.name;
          descriptionDe = t.description ?? '';
        case 'en':
          nameEn = t.name;
          descriptionEn = t.description ?? '';
      }
    }

    // Fallback: if only one language is present, use it for both
    if (nameDe.isEmpty && nameEn.isNotEmpty) nameDe = nameEn;
    if (nameEn.isEmpty && nameDe.isNotEmpty) nameEn = nameDe;

    return Exercise(
      id: row.localId,
      uuid: row.id,
      source: row.source,
      replacesExerciseId: row.replacesExerciseId,
      nameDe: nameDe,
      nameEn: nameEn,
      descriptionDe: descriptionDe,
      descriptionEn: descriptionEn,
      categoryName: row.categoryName ?? 'Other',
      imagePath: row.imagePath,
      primaryMuscles:
          WorkoutLocalDataSource._parseMuscleList(row.musclesPrimary),
      secondaryMuscles:
          WorkoutLocalDataSource._parseMuscleList(row.musclesSecondary),
    );
  }
}
