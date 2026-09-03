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

/// Picks one translation per exercise, by language preference.
///
/// SQLite's documented bare-column rule does the work: in a `GROUP BY` query
/// whose only aggregate is `MIN()`, the non-aggregated columns come from the
/// row that produced the minimum. So this yields the name and description of
/// the most-preferred language each exercise actually has.
///
/// The `ELSE 99` arm is not a leftover — it is what keeps an exercise visible
/// when it exists only in a language nothing in this app speaks. Better a name
/// in Polish than a blank row.
///
/// Takes exactly three placeholders whatever the chain's real length; a
/// repeated code is harmless because `CASE` stops at the first match.
const String _kBestTranslationJoinSql = '''
      LEFT JOIN (
        SELECT exercise_id, name, description, language_code,
               MIN(CASE language_code
                     WHEN ? THEN 0
                     WHEN ? THEN 1
                     WHEN ? THEN 2
                     ELSE 99
                   END) AS lang_rank
        FROM exercise_translations
        GROUP BY exercise_id
      ) t_best ON e.id = t_best.exercise_id''';

/// The three placeholder values for [_kBestTranslationJoinSql].
List<drift.Variable> _bestTranslationVars(List<String> chain) {
  final padded = [...chain];
  while (padded.length < 3) {
    padded.add(padded.isEmpty ? 'en' : padded.last);
  }
  return padded
      .take(3)
      .map((code) => drift.Variable.withString(code))
      .toList(growable: false);
}

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
    String languageCode = 'en',
  }) async {
    final dbInstance = await database;
    final chain = await ExerciseLocaleChain.resolve(dbInstance, languageCode);
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) {
      return _executeSearchSql(
        rawSearchQuery: '',
        tokens: const [],
        isOrSearch: false,
        selectedCategories: selectedCategories,
        chain: chain,
      );
    }

    // Pass 1: Strict all-token match with raw query
    final pass1Tokens = _tokenizeAndClean(rawQuery);
    var results = await _executeSearchSql(
      rawSearchQuery: rawQuery,
      tokens: pass1Tokens,
      isOrSearch: false,
      selectedCategories: selectedCategories,
      chain: chain,
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
        chain: chain,
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
      chain: chain,
    );

    return results;
  }

  Future<List<Exercise>> _executeSearchSql({
    required String rawSearchQuery,
    required List<String> tokens,
    required bool isOrSearch,
    required List<String> selectedCategories,
    required List<String> chain,
  }) async {
    final dbInstance = await database;
    final rawSearchLower = rawSearchQuery.toLowerCase();
    final ninetyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;

    final String exactMatchExpr = tokens.isEmpty
        ? '0 AS is_exact_match'
        : '(CASE WHEN LOWER(t_best.name) = ? THEN 1 ELSE 0 END) '
            'AS is_exact_match';

    final String prefixMatchExpr = tokens.isEmpty
        ? '0 AS is_prefix_match'
        : '(CASE WHEN LOWER(t_best.name) LIKE ? THEN 1 ELSE 0 END) '
            'AS is_prefix_match';

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
        // Matches every language the catalog carries, plus the search_terms
        // the data repo ships for exactly this: synonyms and common
        // misspellings, indexed but never displayed. A German user looking for
        // "bench press" finds it; so does someone typing "kniebeuge".
        tokenClauses.add(
          '(EXISTS (SELECT 1 FROM exercise_translations tt '
          'WHERE tt.exercise_id = e.id '
          'AND (tt.name LIKE ? OR IFNULL(tt.search_terms, \'\') LIKE ?)))',
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

    // 4. the language-preference join, which sits after the SELECT list and
    //    before the WHERE clause in the SQL text — placeholders bind by
    //    position, so this order is not cosmetic.
    vars.addAll(_bestTranslationVars(chain));

    // 5. WHERE token clauses: name and search_terms, per token
    for (final token in tokens) {
      vars.add(drift.Variable.withString('%$token%'));
      vars.add(drift.Variable.withString('%$token%'));
    }

    // 6. WHERE category IN placeholders
    for (final cat in selectedCategories) {
      vars.add(drift.Variable.withString(cat));
    }

    final sql = '''
      SELECT e.*,
             t_best.name AS display_name,
             t_best.description AS display_description,
             t_best.language_code AS display_language,
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
$_kBestTranslationJoinSql
      WHERE $whereSection
      ORDER BY
        is_exact_match DESC,
        history_priority_score DESC,
        is_custom_exercise DESC,
        is_prefix_match DESC,
        t_best.name ASC
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

    return rows.map((row) => _mapSearchRowToExercise(dbInstance, row)).toList();
  }

  /// Returns an [Exercise] only if an exact case-insensitive name match exists
  /// in the database. Does NOT perform parenthetical stripping or fuzzy search
  /// fallbacks.
  Future<Exercise?> getExactExerciseByName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;
    return _resolveByNames([trimmedName]);
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final cleanedName = _stripParenthesesAndClean(trimmedName);
    return _resolveByNames([trimmedName, cleanedName]);
  }

  /// Finds the exercise that goes by any of [names], in any language.
  ///
  /// Resolution, not discovery. The name it is given comes from
  /// `set_logs.exercise_name_snapshot` or a shared routine, written in
  /// whatever language was current at the time — so matching only German and
  /// English would lose exactly the users the locale rebuild was for.
  ///
  /// Retired exercises stay findable, because a workout logged years ago has
  /// to keep opening. They are only ordered last: after a merge the same name
  /// exists twice ("Leg Extension" is both 851, merged, and 369, active), and
  /// taking the first row would otherwise pick whichever the planner emitted.
  Future<Exercise?> _resolveByNames(List<String> names) async {
    final dbInstance = await database;
    final candidates = names
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    final placeholders = List.filled(candidates.length, 'LOWER(?)').join(', ');
    final sql = '''
      SELECT e.*
      FROM exercises e
      WHERE EXISTS (
        SELECT 1 FROM exercise_translations t
        WHERE t.exercise_id = e.id AND LOWER(t.name) IN ($placeholders)
      )
      ORDER BY (CASE WHEN e.status IS NULL OR e.status = 'active'
                     THEN 0 ELSE 1 END) ASC,
               (CASE WHEN e.source = 'user' THEN 0 ELSE 1 END) ASC
      LIMIT 8
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: candidates.map((n) => drift.Variable.withString(n)).toList(),
      readsFrom: {dbInstance.exercises, dbInstance.exerciseTranslations},
    ).get();
    if (rows.isEmpty) return null;

    final first = dbInstance.exercises.map(rows.first.data);

    // A user's own exercise wins outright; the ORDER BY has already put one
    // first if it exists.
    if (first.source != 'user') {
      final overrideRow = await (dbInstance.select(dbInstance.exercises)
            ..where((tbl) =>
                tbl.replacesExerciseId.equals(first.id) &
                tbl.source.equals('user'))
            ..limit(1))
          .getSingleOrNull();
      if (overrideRow != null) {
        return _mapExerciseRowToModel(dbInstance, overrideRow);
      }
    }

    return _mapExerciseRowToModel(dbInstance, first);
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

  /// Upserts one translation row per language the model carries.
  ///
  /// Used to write exactly 'de' and 'en'. Now it writes whatever is there,
  /// which is what makes a user's own exercise expressible in their own
  /// language instead of being filed under German.
  Future<void> _upsertTranslations(
    db.AppDatabase dbInstance,
    String exerciseId,
    Exercise exercise,
  ) async {
    final langs = <String, (String name, String? desc)>{
      for (final entry in exercise.texts.entries)
        if (entry.value.name.trim().isNotEmpty)
          entry.key: (
            entry.value.name,
            entry.value.description.isNotEmpty ? entry.value.description : null
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

  /// Maps one search row to [Exercise].
  ///
  /// Carries exactly the one language the query resolved, under its real code.
  /// A list shows one name per row; loading all 22 translations for 100 rows
  /// to render one of them would be 2200 rows of waste.
  Exercise _mapSearchRowToExercise(
      db.AppDatabase dbInstance, drift.QueryRow row) {
    final rawExercise = dbInstance.exercises.map(row.data);
    final displayName = row.readNullable<String>('display_name') ?? '';
    final displayDescription =
        row.readNullable<String>('display_description') ?? '';
    final displayLanguage =
        row.readNullable<String>('display_language') ?? 'en';

    return Exercise(
      id: rawExercise.localId,
      uuid: rawExercise.id,
      source: rawExercise.source,
      replacesExerciseId: rawExercise.replacesExerciseId,
      texts: displayName.isEmpty
          ? const {}
          : {
              displayLanguage: ExerciseText(
                name: displayName,
                description: displayDescription,
              ),
            },
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

    // Precise muscle ids, when the catalog has them. Loaded only on this
    // path — a single exercise — because it is the only place the extra
    // precision is rendered.
    final muscleRows = await (dbInstance.select(dbInstance.exerciseMuscles)
          ..where((m) => m.exerciseId.equals(row.id)))
        .get();

    // Every language this exercise has. This path returns a single exercise —
    // a detail screen, a resolved set log — where the cost is one query and
    // the payoff is that the fallback chain has something to fall back to.
    final texts = <String, ExerciseText>{
      for (final t in translations)
        if (t.name.trim().isNotEmpty)
          t.languageCode: ExerciseText(
            name: t.name,
            description: t.description ?? '',
          ),
    };

    return Exercise(
      id: row.localId,
      uuid: row.id,
      source: row.source,
      replacesExerciseId: row.replacesExerciseId,
      texts: texts,
      categoryName: row.categoryName ?? 'Other',
      imagePath: row.imagePath,
      primaryMuscles:
          WorkoutLocalDataSource._parseMuscleList(row.musclesPrimary),
      secondaryMuscles:
          WorkoutLocalDataSource._parseMuscleList(row.musclesSecondary),
      primaryMuscleIds: [
        for (final m in muscleRows)
          if (m.role == 'primary') m.muscleId,
      ],
      secondaryMuscleIds: [
        for (final m in muscleRows)
          if (m.role != 'primary') m.muscleId,
      ],
    );
  }
}
