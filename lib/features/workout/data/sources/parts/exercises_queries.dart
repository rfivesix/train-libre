part of '../workout_local_data_source.dart';

/// Rows the catalog still stands behind.
///
/// `status` is NULL for exercises written before schema v2 and for everything
/// the user created, and both of those are active as far as the app is
/// concerned — so the NULL branch is the common case, not a fallback.
///
/// Applied to discovery (search, filter chips), never to resolution: a merged
/// or deprecated exercise must stay reachable by id so that a workout logged
/// two years ago still opens. It just must not be offered again.
const String _kActiveExerciseSql = "(e.status IS NULL OR e.status = 'active')";

extension ExercisesQueries on WorkoutLocalDataSource {
  /// Retrieves all unique exercise categories present in the database.
  Future<List<String>> getAllCategories() async {
    final dbInstance = await database;
    final query = dbInstance.selectOnly(dbInstance.exercises, distinct: true)
      ..addColumns([dbInstance.exercises.categoryName])
      // A category that only exists on retired rows is a filter chip that
      // selects nothing.
      ..where(dbInstance.exercises.status.isNull() |
          dbInstance.exercises.status.equals('active'));

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
    final exercises = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.status.isNull() | tbl.status.equals('active')))
        .get();
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

  static String _stripParenthesesAndClean(String input) {
    if (input.isEmpty) return '';
    final stripped = input.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    return stripped.isEmpty ? input.trim() : stripped;
  }

  static List<String> _expandTokensWithSynonyms(List<String> tokens) {
    final Map<String, List<String>> synonyms = {
      'beinstrecken': ['beinstrecker', 'leg', 'extension'],
      'beinstrecker': ['beinstrecken', 'leg', 'extension'],
      'wadendrücken': ['wadenheben', 'calf', 'raise'],
      'wadenheben': ['wadendrücken', 'calf', 'raise'],
      'bizepscurl': ['bizeps', 'curl', 'curls'],
      'bizepscurls': ['bizeps', 'curl', 'curls'],
      'trizepsdrücken': ['trizeps', 'seildrücken', 'extension'],
      'schulterpresse': ['schulterdrücken', 'press'],
      'brustpresse': ['brustpresse', 'press'],
      'dips': ['dip'],
      'dip': ['dips'],
      'squat': ['squats', 'kniebeuge', 'kniebeugen'],
      'squats': ['squat', 'kniebeuge', 'kniebeugen'],
      'kniebeuge': ['squat', 'kniebeugen'],
      'kniebeugen': ['squat', 'kniebeuge'],
      'radfahren': ['fahrrad', 'cycling'],
      'latzug': ['lat', 'pulldown'],
      'abduktion': ['abduktoren', 'abductor'],
      'adduktion': ['adduktoren', 'adductor'],
      'hüftabduktion': ['abduktoren', 'abduktion'],
      'hüftadduktion': ['adduktoren', 'adduktion'],
      'kurzhantel': ['kh', 'dumbbell'],
      'langhantel': ['lh', 'barbell'],
      'kabelzug': ['kabel', 'cable'],
    };

    final Set<String> expanded = {...tokens};
    for (final token in tokens) {
      final t = token.toLowerCase();
      if (synonyms.containsKey(t)) {
        expanded.addAll(synonyms[t]!);
      }
    }
    return expanded.toList();
  }

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) {
      return _executeSearchSql(
        rawSearchQuery: '',
        tokens: const [],
        isOrSearch: false,
        selectedCategories: selectedCategories,
      );
    }

    // Pass 1: Strict all-token match with raw query
    final pass1Tokens = _tokenizeAndClean(rawQuery);
    var results = await _executeSearchSql(
      rawSearchQuery: rawQuery,
      tokens: pass1Tokens,
      isOrSearch: false,
      selectedCategories: selectedCategories,
    );

    if (results.isNotEmpty) return results;

    // Pass 2: Sanitized search (stripping parenthetical qualifiers e.g. (Maschine), (Langhantel))
    final cleanedQuery = _stripParenthesesAndClean(rawQuery);
    if (cleanedQuery != rawQuery) {
      final pass2Tokens = _tokenizeAndClean(cleanedQuery);
      results = await _executeSearchSql(
        rawSearchQuery: cleanedQuery,
        tokens: pass2Tokens,
        isOrSearch: false,
        selectedCategories: selectedCategories,
      );

      if (results.isNotEmpty) return results;
    }

    // Pass 3: Flexible OR search across tokens with synonym expansion
    final pass3Tokens = _expandTokensWithSynonyms(pass1Tokens);
    results = await _executeSearchSql(
      rawSearchQuery: cleanedQuery,
      tokens: pass3Tokens,
      isOrSearch: true,
      selectedCategories: selectedCategories,
    );

    return results;
  }

  Future<List<Exercise>> _executeSearchSql({
    required String rawSearchQuery,
    required List<String> tokens,
    required bool isOrSearch,
    required List<String> selectedCategories,
  }) async {
    final dbInstance = await database;
    final rawSearchLower = rawSearchQuery.toLowerCase();
    final ninetyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;

    final String exactMatchExpr = tokens.isEmpty
        ? '0 AS is_exact_match'
        : '(CASE WHEN LOWER(COALESCE(t_de.name, t_en.name, t_any.name)) = ? '
            'THEN 1 ELSE 0 END) AS is_exact_match';

    final String prefixMatchExpr = tokens.isEmpty
        ? '0 AS is_prefix_match'
        : '(CASE WHEN LOWER(COALESCE(t_de.name, t_en.name, t_any.name)) LIKE ? '
            'THEN 1 ELSE 0 END) AS is_prefix_match';

    final whereClauses = <String>[
      "NOT (e.source = 'wger' AND "
          "EXISTS (SELECT 1 FROM exercises other_exercises "
          "WHERE other_exercises.replaces_exercise_id = e.id))",
      // Without this the v2 catalog puts 41 rows back into search: 15 merged
      // ones sitting next to the twin they were merged into, and 26 the data
      // repo has retired.
      _kActiveExerciseSql,
    ];

    if (tokens.isNotEmpty) {
      final tokenClauses = <String>[];
      for (final _ in tokens) {
        tokenClauses.add(
          '(t_de.name LIKE ? OR t_en.name LIKE ? OR t_any.name LIKE ?)',
        );
      }
      if (isOrSearch) {
        whereClauses.add('(${tokenClauses.join(' OR ')})');
      } else {
        whereClauses.addAll(tokenClauses);
      }
    }

    if (selectedCategories.isNotEmpty) {
      final placeholders =
          List.filled(selectedCategories.length, '?').join(', ');
      whereClauses.add('e.category_name IN ($placeholders)');
    }

    final whereSection = whereClauses.join(' AND ');
    final vars = <drift.Variable>[];

    // 1. history subquery
    vars.add(drift.Variable.withInt(ninetyDaysAgo));

    // 2. exactMatchExpr
    if (tokens.isNotEmpty) {
      vars.add(drift.Variable.withString(rawSearchLower));
    }

    // 3. prefixMatchExpr
    if (tokens.isNotEmpty) {
      vars.add(drift.Variable.withString('$rawSearchLower%'));
    }

    // 4. WHERE token clauses
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
      LIMIT 100
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

  /// Returns an [Exercise] only if an exact case-insensitive name match exists
  /// in the database. Does NOT perform parenthetical stripping or fuzzy search fallbacks.
  Future<Exercise?> getExactExerciseByName(String name) async {
    final dbInstance = await database;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final sql = '''
      SELECT e.*,
             t_de.name AS name_de,
             t_en.name AS name_en,
             t_de.description AS desc_de,
             t_en.description AS desc_en,
             COALESCE(t_de.name, t_en.name, t_any.name) AS display_name,
             COALESCE(t_de.description, t_en.description) AS display_description
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
      WHERE LOWER(t_de.name) = LOWER(?) OR LOWER(t_en.name) = LOWER(?) OR LOWER(t_any.name) = LOWER(?)
      -- Resolution, not discovery: a retired exercise must stay findable so a
      -- workout logged years ago still opens. But after a merge the same name
      -- exists twice ("Leg Extension" is both 851, merged, and 369, active),
      -- and rows.first would pick whichever the planner happened to emit —
      -- so the survivor is ordered first rather than the retired row filtered
      -- out.
      ORDER BY (CASE WHEN e.status IS NULL OR e.status = 'active'
                     THEN 0 ELSE 1 END) ASC
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        drift.Variable.withString(trimmedName),
        drift.Variable.withString(trimmedName),
        drift.Variable.withString(trimmedName),
      ],
      readsFrom: {dbInstance.exercises, dbInstance.exerciseTranslations},
    ).get();

    if (rows.isNotEmpty) {
      final userRow = rows.where((r) => r.data['source'] == 'user').firstOrNull;
      if (userRow != null) {
        return _mapRowToExercise(dbInstance, userRow);
      }

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

    return null;
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final dbInstance = await database;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final cleanedName = _stripParenthesesAndClean(trimmedName);

    final sql = '''
      SELECT e.*,
             t_de.name AS name_de,
             t_en.name AS name_en,
             t_de.description AS desc_de,
             t_en.description AS desc_en,
             COALESCE(t_de.name, t_en.name, t_any.name) AS display_name,
             COALESCE(t_de.description, t_en.description) AS display_description
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
      WHERE LOWER(t_de.name) = LOWER(?) OR LOWER(t_en.name) = LOWER(?) OR LOWER(t_any.name) = LOWER(?)
         OR LOWER(t_de.name) = LOWER(?) OR LOWER(t_en.name) = LOWER(?) OR LOWER(t_any.name) = LOWER(?)
      -- Resolution, not discovery: a retired exercise must stay findable so a
      -- workout logged years ago still opens. But after a merge the same name
      -- exists twice ("Leg Extension" is both 851, merged, and 369, active),
      -- and rows.first would pick whichever the planner happened to emit —
      -- so the survivor is ordered first rather than the retired row filtered
      -- out.
      ORDER BY (CASE WHEN e.status IS NULL OR e.status = 'active'
                     THEN 0 ELSE 1 END) ASC
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        drift.Variable.withString(trimmedName),
        drift.Variable.withString(trimmedName),
        drift.Variable.withString(trimmedName),
        drift.Variable.withString(cleanedName),
        drift.Variable.withString(cleanedName),
        drift.Variable.withString(cleanedName),
      ],
      readsFrom: {dbInstance.exercises, dbInstance.exerciseTranslations},
    ).get();

    if (rows.isNotEmpty) {
      final userRow = rows.where((r) => r.data['source'] == 'user').firstOrNull;
      if (userRow != null) {
        return _mapRowToExercise(dbInstance, userRow);
      }

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

    // High-confidence fallback match via searchExercises
    final searchMatches = await searchExercises(query: trimmedName);
    if (searchMatches.isNotEmpty) {
      return searchMatches.first;
    }

    return null;
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

  /// Deletes a custom (source == 'user') exercise by its [localId].
  ///
  /// Within a single transaction:
  /// 1. Resolves the UUID from [localId].
  /// 2. Nulls out `exercise_id` in all `set_logs` that reference this exercise,
  ///    preserving `exercise_name_snapshot` so workout history remains intact.
  /// 3. Deletes all `routine_exercises` rows that reference this exercise.
  /// 4. Deletes the exercise row itself (translations cascade via FK).
  ///
  /// Returns `true` if any set-log rows were affected (i.e. the exercise
  /// appeared in workout history), so the UI can display a relevant warning.
  ///
  /// Throws if the exercise is not found or is not a user-owned exercise.
  Future<bool> deleteCustomExercise(int localId) async {
    final dbInstance = await database;

    return await dbInstance.transaction(() async {
      // 1. Resolve UUID
      final exerciseRow = await (dbInstance.select(dbInstance.exercises)
            ..where((tbl) => tbl.localId.equals(localId))
            ..limit(1))
          .getSingleOrNull();

      if (exerciseRow == null) {
        throw Exception('Exercise not found (localId=$localId)');
      }
      if (exerciseRow.source != 'user') {
        throw Exception(
            'Cannot delete non-user exercise (source=${exerciseRow.source})');
      }

      final exerciseUuid = exerciseRow.id;

      // 2. Null out exercise_id in set_logs (keep name snapshot intact)
      final affectedRows = await dbInstance.customUpdate(
        'UPDATE set_logs SET exercise_id = NULL WHERE exercise_id = ?',
        variables: [drift.Variable.withString(exerciseUuid)],
        updates: {dbInstance.setLogs},
      );
      final hadLogs = affectedRows > 0;

      // 3. Remove routine_exercises referencing this exercise
      await (dbInstance.delete(dbInstance.routineExercises)
            ..where((tbl) => tbl.exerciseId.equals(exerciseUuid)))
          .go();

      // 4. Delete the exercise itself (translations cascade via FK)
      await (dbInstance.delete(dbInstance.exercises)
            ..where((tbl) => tbl.localId.equals(localId)))
          .go();

      return hadLogs;
    });
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
