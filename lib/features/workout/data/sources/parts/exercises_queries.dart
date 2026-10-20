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

  /// Equipment that at least one live exercise actually uses as its primary
  /// implement, with names in [languageCode].
  ///
  /// Restricted to equipment in use so the filter cannot offer a chip that
  /// selects nothing — the catalog carries 42 pieces, not all of which are the
  /// load-bearing one anywhere.
  Future<List<({String id, String name})>> getPrimaryEquipment(
    String languageCode,
  ) async {
    final dbInstance = await database;
    final chain = await ExerciseLocaleChain.resolve(dbInstance, languageCode);

    final rows = await dbInstance.customSelect(
      '''
      SELECT q.id AS id,
             COALESCE(t_pref.name, t_en.name, q.id) AS name
      FROM equipment q
      LEFT JOIN equipment_translations t_pref
        ON t_pref.equipment_id = q.id AND t_pref.language_code = ?
      LEFT JOIN equipment_translations t_en
        ON t_en.equipment_id = q.id AND t_en.language_code = 'en'
      WHERE EXISTS (
        SELECT 1 FROM exercise_equipment ee
        JOIN exercises e ON e.id = ee.exercise_id
        WHERE ee.equipment_id = q.id AND ee.kind = 'primary'
          AND (e.status IS NULL OR e.status = 'active')
      )
      ORDER BY name ASC
      ''',
      variables: [drift.Variable.withString(chain.first)],
      readsFrom: {
        dbInstance.equipment,
        dbInstance.equipmentTranslations,
        dbInstance.exerciseEquipment,
        dbInstance.exercises,
      },
    ).get();

    return rows
        .map((row) =>
            (id: row.read<String>('id'), name: row.read<String>('name')))
        .toList(growable: false);
  }

  /// The `usage_tags` in use on live exercises: warmup, activation, main_lift,
  /// accessory, conditioning, finisher, cooldown, prehab.
  Future<List<String>> getUsageTags() async {
    final dbInstance = await database;
    final rows = await dbInstance.customSelect(
      '''
      SELECT DISTINCT et.tag AS tag
      FROM exercise_tags et
      JOIN exercises e ON e.id = et.exercise_id
      WHERE (e.status IS NULL OR e.status = 'active')
      ORDER BY tag ASC
      ''',
      readsFrom: {dbInstance.exerciseTags, dbInstance.exercises},
    ).get();
    return rows.map((row) => row.read<String>('tag')).toList(growable: false);
  }

  /// The classification axes the catalog annotates, restricted to the values
  /// that actually occur on live exercises.
  ///
  /// One query rather than three because the three lists are always wanted
  /// together, by the one caller that builds the filter sheet. The `rank`
  /// column is what keeps `beginner` in front of `advanced`: these are ordered
  /// vocabularies, and sorting them alphabetically would put "advanced" first
  /// and read like a mistake.
  Future<
      ({
        List<String> difficulties,
        List<String> mechanics,
        List<String> lateralities,
      })> getClassificationAxes() async {
    final dbInstance = await database;
    final rows = await dbInstance.customSelect(
      '''
      SELECT 'difficulty' AS axis, e.difficulty AS value,
             CASE e.difficulty
               WHEN 'beginner' THEN 0
               WHEN 'intermediate' THEN 1
               WHEN 'advanced' THEN 2
               ELSE 3 END AS rank
      FROM exercises e
      WHERE $_kActiveExerciseSql AND e.difficulty IS NOT NULL
      UNION
      SELECT 'mechanic', e.mechanic,
             CASE e.mechanic
               WHEN 'compound' THEN 0
               WHEN 'isolation' THEN 1
               ELSE 2 END
      FROM exercises e
      WHERE $_kActiveExerciseSql AND e.mechanic IS NOT NULL
      UNION
      SELECT 'laterality', e.laterality,
             CASE e.laterality
               WHEN 'bilateral' THEN 0
               WHEN 'unilateral' THEN 1
               WHEN 'alternating' THEN 2
               ELSE 3 END
      FROM exercises e
      WHERE $_kActiveExerciseSql AND e.laterality IS NOT NULL
      ORDER BY axis ASC, rank ASC
      ''',
      readsFrom: {dbInstance.exercises},
    ).get();

    final grouped = <String, List<String>>{};
    for (final row in rows) {
      final value = row.read<String>('value');
      if (value.isEmpty) continue;
      grouped.putIfAbsent(row.read<String>('axis'), () => []).add(value);
    }

    return (
      difficulties: grouped['difficulty'] ?? const <String>[],
      mechanics: grouped['mechanic'] ?? const <String>[],
      lateralities: grouped['laterality'] ?? const <String>[],
    );
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

  static String _transliterateToUmlauts(String text) {
    return text
        .replaceAll('ae', 'ä')
        .replaceAll('oe', 'ö')
        .replaceAll('ue', 'ü')
        .replaceAll('ss', 'ß');
  }

  static String _transliterateFromUmlauts(String text) {
    return text
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  static bool _isShortAcronym(String term) {
    return const {'rdl', 'ohp', 'kh', 'lh'}.contains(term);
  }

  static String _stripParenthesesAndClean(String input) {
    if (input.isEmpty) return '';
    final stripped = input.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    return stripped.isEmpty ? input.trim() : stripped;
  }

  static const Map<String, List<String>> _kExerciseSynonyms = {
    // Squat variations
    'squat': ['squats', 'kniebeuge', 'kniebeugen'],
    'squats': ['squat', 'kniebeuge', 'kniebeugen'],
    'kniebeuge': ['kniebeugen', 'squat', 'squats'],
    'kniebeugen': ['kniebeuge', 'squat', 'squats'],

    // Deadlift variations
    'deadlift': ['deadlifts', 'kreuzheben'],
    'deadlifts': ['deadlift', 'kreuzheben'],
    'kreuzheben': ['deadlift', 'deadlifts'],
    'rdl': ['romanian deadlift', 'rumänisches kreuzheben'],
    'romanian': ['rumänisch', 'rumänisches', 'rdl'],
    'rumänisch': ['romanian', 'rdl'],
    'rumänisches': ['romanian', 'rdl'],

    // Bench press variations
    'bankdrücken': ['bankdruecken', 'bench press', 'benchpress'],
    'bankdruecken': ['bankdrücken', 'bench press', 'benchpress'],
    'benchpress': ['bench press', 'bankdrücken', 'bankdruecken'],

    // Overhead / Shoulder press
    'ohp': ['overhead press', 'military press', 'schulterdrücken'],
    'overheadpress': ['overhead press', 'ohp', 'schulterdrücken'],
    'schulterdrücken': [
      'schulterdruecken',
      'overhead press',
      'military press',
      'ohp'
    ],
    'schulterdruecken': [
      'schulterdrücken',
      'overhead press',
      'military press',
      'ohp'
    ],
    'ueberkopfdrücken': [
      'überkopfdrücken',
      'overhead press',
      'schulterdrücken',
      'ohp'
    ],
    'überkopfdrücken': [
      'ueberkopfdrücken',
      'overhead press',
      'schulterdrücken',
      'ohp'
    ],
    'ueberkopfdruecken': [
      'überkopfdrücken',
      'overhead press',
      'schulterdrücken',
      'ohp'
    ],
    'schulterpresse': ['schulterdrücken', 'overhead press'],
    'brustpresse': ['chest press', 'bankdrücken'],

    // Pull-up / Chin-up variations
    'klimmzug': [
      'klimmzüge',
      'klimmzuege',
      'pullup',
      'pullups',
      'pull-up',
      'pull-ups',
      'chinup',
      'chinups'
    ],
    'klimmzüge': [
      'klimmzug',
      'klimmzuege',
      'pullup',
      'pullups',
      'pull-up',
      'pull-ups',
      'chinup',
      'chinups'
    ],
    'klimmzuege': [
      'klimmzug',
      'klimmzüge',
      'pullup',
      'pullups',
      'pull-up',
      'pull-ups',
      'chinup',
      'chinups'
    ],
    'pullup': ['pullups', 'pull-up', 'pull-ups', 'klimmzug', 'klimmzüge'],
    'pullups': ['pullup', 'pull-up', 'pull-ups', 'klimmzug', 'klimmzüge'],
    'chinup': ['chinups', 'chin-up', 'chin-ups', 'klimmzug', 'klimmzüge'],
    'chinups': ['chinup', 'chin-up', 'chin-ups', 'klimmzug', 'klimmzüge'],

    // Push-up variations
    'pushup': ['pushups', 'push-up', 'push-ups', 'liegestütz', 'liegestütze'],
    'pushups': ['pushup', 'push-up', 'push-ups', 'liegestütz', 'liegestütze'],
    'liegestütz': [
      'liegestütze',
      'liegestuetze',
      'pushup',
      'pushups',
      'push-up',
      'push-ups'
    ],
    'liegestütze': [
      'liegestütz',
      'liegestuetze',
      'pushup',
      'pushups',
      'push-up',
      'push-ups'
    ],
    'liegestuetze': [
      'liegestütz',
      'liegestütze',
      'pushup',
      'pushups',
      'push-up',
      'push-ups'
    ],

    // Dips
    'dips': ['dip'],
    'dip': ['dips'],

    // Lunges
    'lunge': ['lunges', 'ausfallschritt', 'ausfallschritte'],
    'lunges': ['lunge', 'ausfallschritt', 'ausfallschritte'],
    'ausfallschritt': ['ausfallschritte', 'lunge', 'lunges'],
    'ausfallschritte': ['ausfallschritt', 'lunge', 'lunges'],

    // Rows
    'rudern': ['row', 'rows', 'rowing'],
    'row': ['rows', 'rudern'],
    'rows': ['row', 'rudern'],
    'rowing': ['rudern', 'row'],

    // Curls
    'curl': ['curls', 'beugen'],
    'curls': ['curl'],
    'bizepscurl': ['bizeps curl', 'bicep curl', 'biceps curl', 'curl'],
    'bizepscurls': ['bizeps curls', 'bicep curls', 'biceps curls', 'curls'],
    'bicep': ['bizeps', 'biceps'],
    'biceps': ['bizeps', 'bicep'],
    'bizeps': ['bicep', 'biceps'],

    // Triceps
    'tricep': ['trizeps', 'triceps'],
    'triceps': ['trizeps', 'tricep'],
    'trizeps': ['tricep', 'triceps'],
    'trizepsdrücken': [
      'trizepsdruecken',
      'seildrücken',
      'triceps extension',
      'tricep extension'
    ],
    'trizepsdruecken': [
      'trizepsdrücken',
      'seildrücken',
      'triceps extension',
      'tricep extension'
    ],

    // Legs
    'beinstrecken': ['beinstrecker', 'leg extension', 'leg extensions'],
    'beinstrecker': ['beinstrecken', 'leg extension', 'leg extensions'],
    'legextension': [
      'leg extension',
      'leg extensions',
      'beinstrecker',
      'beinstrecken'
    ],
    'legextensions': [
      'leg extension',
      'leg extensions',
      'beinstrecker',
      'beinstrecken'
    ],
    'beinbeugen': ['beinbeuger', 'leg curl', 'leg curls'],
    'beinbeuger': ['beinbeugen', 'leg curl', 'leg curls'],
    'legcurl': ['leg curl', 'leg curls', 'beinbeuger', 'beinbeugen'],
    'legcurls': ['leg curl', 'leg curls', 'beinbeuger', 'beinbeugen'],

    // Calves
    'wadenheben': ['wadendrücken', 'wadendruecken', 'calf raise', 'calf raises'],
    'wadendrücken': ['wadenheben', 'wadendruecken', 'calf raise', 'calf raises'],
    'wadendruecken': ['wadenheben', 'wadendrücken', 'calf raise', 'calf raises'],
    'calfraise': ['calf raise', 'calf raises', 'wadenheben', 'wadendrücken'],
    'calfraises': ['calf raise', 'calf raises', 'wadenheben', 'wadendrücken'],
    'calf': ['calves', 'waden'],
    'calves': ['calf', 'waden'],
    'waden': ['calf', 'calves'],

    // Lateral raise / Face pull
    'seitheben': ['seitenheben', 'lateral raise', 'lateral raises'],
    'seitenheben': ['seitheben', 'lateral raise', 'lateral raises'],
    'lateralraise': ['lateral raise', 'lateral raises', 'seitheben'],
    'lateralraises': ['lateral raise', 'lateral raises', 'seitheben'],
    'facepull': ['face pull', 'facepulls', 'face pulls'],
    'facepulls': ['face pull', 'facepull', 'face pulls'],

    // Lat pulldown
    'latzug': ['lat', 'pulldown', 'lat pulldown', 'latzugmaschine'],
    'latpulldown': ['lat pulldown', 'latzug'],

    // Equipment abbreviations
    'kurzhantel': ['kh', 'dumbbell'],
    'kh': ['kurzhantel', 'dumbbell'],
    'langhantel': ['lh', 'barbell'],
    'lh': ['langhantel', 'barbell'],
    'kabelzug': ['kabel', 'cable'],
    'kabel': ['kabelzug', 'cable'],

    // Hip abduction/adduction
    'abduktion': ['abduktoren', 'abductor', 'abductors'],
    'adduktion': ['adduktoren', 'adductor', 'adductors'],
    'hüftabduktion': ['abduktoren', 'abduktion', 'abductor'],
    'hüftadduktion': ['adduktoren', 'adduktion', 'adductor'],

    // Cardio
    'radfahren': ['fahrrad', 'cycling', 'bike'],
    'fahrrad': ['radfahren', 'cycling', 'bike'],
  };

  static List<String> _expandTokenVariants(String token) {
    final t = token.toLowerCase().trim();
    if (t.isEmpty) return const [];
    final variants = <String>{t};

    final withUmlauts = _transliterateToUmlauts(t);
    if (withUmlauts != t) variants.add(withUmlauts);
    final withoutUmlauts = _transliterateFromUmlauts(t);
    if (withoutUmlauts != t) variants.add(withoutUmlauts);

    if (t.endsWith('e') && t.length > 3) {
      variants.add(t.substring(0, t.length - 1));
    }
    if (t.endsWith('en') && t.length > 4) {
      variants.add(t.substring(0, t.length - 2));
      variants.add(t.substring(0, t.length - 1));
    }
    if (t.endsWith('s') && t.length > 3) {
      variants.add(t.substring(0, t.length - 1));
    }
    if (t.endsWith('es') && t.length > 4) {
      variants.add(t.substring(0, t.length - 2));
    }

    for (final v in [...variants]) {
      final syns = _kExerciseSynonyms[v];
      if (syns != null) {
        variants.addAll(syns);
      }
    }

    return variants.toList(growable: false);
  }

  static List<String> _expandTokensWithSynonyms(List<String> tokens) {
    final Set<String> expanded = {...tokens};
    for (final token in tokens) {
      expanded.addAll(_expandTokenVariants(token));
    }
    return expanded.toList();
  }

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
    List<String> equipmentIds = const [],
    List<String> usageTags = const [],
    List<String> difficulties = const [],
    List<String> mechanics = const [],
    List<String> lateralities = const [],
    String languageCode = 'en',
    bool onlyPerformed = false,
  }) async {
    final dbInstance = await database;
    final chain = await ExerciseLocaleChain.resolve(dbInstance, languageCode);
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) {
      return _executeSearchSql(
        rawSearchQuery: '',
        tokenGroups: const [],
        isOrSearch: false,
        selectedCategories: selectedCategories,
        equipmentIds: equipmentIds,
        usageTags: usageTags,
        difficulties: difficulties,
        mechanics: mechanics,
        lateralities: lateralities,
        chain: chain,
        onlyPerformed: onlyPerformed,
      );
    }

    // Pass 1: Strict all-token match with raw query and per-token variants
    final pass1Tokens = _tokenizeAndClean(rawQuery);
    final pass1Groups = pass1Tokens
        .map((t) => _expandTokenVariants(t))
        .where((g) => g.isNotEmpty)
        .toList(growable: false);

    var results = await _executeSearchSql(
      rawSearchQuery: rawQuery,
      tokenGroups: pass1Groups,
      isOrSearch: false,
      selectedCategories: selectedCategories,
      equipmentIds: equipmentIds,
      usageTags: usageTags,
      difficulties: difficulties,
      mechanics: mechanics,
      lateralities: lateralities,
      chain: chain,
      onlyPerformed: onlyPerformed,
    );

    if (results.isNotEmpty) return results;

    // Pass 2: Sanitized search (stripping parenthetical qualifiers e.g. (Maschine), (Langhantel))
    final cleanedQuery = _stripParenthesesAndClean(rawQuery);
    if (cleanedQuery != rawQuery) {
      final pass2Tokens = _tokenizeAndClean(cleanedQuery);
      final pass2Groups = pass2Tokens
          .map((t) => _expandTokenVariants(t))
          .where((g) => g.isNotEmpty)
          .toList(growable: false);

      results = await _executeSearchSql(
        rawSearchQuery: cleanedQuery,
        tokenGroups: pass2Groups,
        isOrSearch: false,
        selectedCategories: selectedCategories,
        equipmentIds: equipmentIds,
        usageTags: usageTags,
        difficulties: difficulties,
        mechanics: mechanics,
        lateralities: lateralities,
        chain: chain,
        onlyPerformed: onlyPerformed,
      );

      if (results.isNotEmpty) return results;
    }

    // Pass 3: Flexible OR search across tokens with synonym expansion
    final pass3Tokens = _expandTokensWithSynonyms(pass1Tokens);
    final pass3Groups = pass3Tokens
        .map((t) => _expandTokenVariants(t))
        .where((g) => g.isNotEmpty)
        .toList(growable: false);

    results = await _executeSearchSql(
      rawSearchQuery: cleanedQuery,
      tokenGroups: pass3Groups,
      isOrSearch: true,
      selectedCategories: selectedCategories,
      equipmentIds: equipmentIds,
      usageTags: usageTags,
      difficulties: difficulties,
      mechanics: mechanics,
      lateralities: lateralities,
      chain: chain,
      onlyPerformed: onlyPerformed,
    );

    return results;
  }

  Future<List<Exercise>> _executeSearchSql({
    required String rawSearchQuery,
    required List<List<String>> tokenGroups,
    required bool isOrSearch,
    required List<String> selectedCategories,
    required List<String> chain,
    List<String> equipmentIds = const [],
    List<String> usageTags = const [],
    List<String> difficulties = const [],
    List<String> mechanics = const [],
    List<String> lateralities = const [],
    bool onlyPerformed = false,
  }) async {
    final dbInstance = await database;
    final rawSearchLower = rawSearchQuery.toLowerCase();
    final umlautSearchLower = _transliterateToUmlauts(rawSearchLower);
    final hasUmlautVariant =
        umlautSearchLower.isNotEmpty && umlautSearchLower != rawSearchLower;
    final ninetyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 90));

    final String exactMatchExpr;
    final exactMatchVars = <drift.Variable>[];

    final String prefixMatchExpr;
    final prefixMatchVars = <drift.Variable>[];

    if (tokenGroups.isEmpty) {
      exactMatchExpr = '0 AS is_exact_match';
      prefixMatchExpr = '0 AS is_prefix_match';
    } else {
      final exactBuffer = StringBuffer();
      exactBuffer.write('(CASE ');
      exactBuffer.write('WHEN LOWER(t_best.name) = ? ');
      exactMatchVars.add(drift.Variable.withString(rawSearchLower));
      if (hasUmlautVariant) {
        exactBuffer.write('OR LOWER(t_best.name) = ? ');
        exactMatchVars.add(drift.Variable.withString(umlautSearchLower));
      }
      exactBuffer.write('THEN 3 ');

      exactBuffer.write(
          'WHEN EXISTS (SELECT 1 FROM exercise_translations tt_exact '
          'WHERE tt_exact.exercise_id = e.id AND (LOWER(tt_exact.name) = ? ');
      exactMatchVars.add(drift.Variable.withString(rawSearchLower));
      if (hasUmlautVariant) {
        exactBuffer.write('OR LOWER(tt_exact.name) = ? ');
        exactMatchVars.add(drift.Variable.withString(umlautSearchLower));
      }
      exactBuffer.write(')) THEN 2 ');

      exactBuffer.write(
          'WHEN EXISTS (SELECT 1 FROM exercise_translations tt_term '
          'WHERE tt_term.exercise_id = e.id AND (IFNULL(tt_term.search_terms, \'\') LIKE ? ');
      exactMatchVars.add(drift.Variable.withString('%"$rawSearchLower"%'));
      if (hasUmlautVariant) {
        exactBuffer.write('OR IFNULL(tt_term.search_terms, \'\') LIKE ? ');
        exactMatchVars.add(drift.Variable.withString('%"$umlautSearchLower"%'));
      }
      exactBuffer.write(')) THEN 1 ');
      exactBuffer.write('ELSE 0 END) AS is_exact_match');
      exactMatchExpr = exactBuffer.toString();

      final prefixBuffer = StringBuffer();
      prefixBuffer.write('(CASE ');
      prefixBuffer.write('WHEN LOWER(t_best.name) LIKE ? ');
      prefixMatchVars.add(drift.Variable.withString('$rawSearchLower%'));
      if (hasUmlautVariant) {
        prefixBuffer.write('OR LOWER(t_best.name) LIKE ? ');
        prefixMatchVars.add(drift.Variable.withString('$umlautSearchLower%'));
      }
      prefixBuffer.write('THEN 2 ');

      prefixBuffer.write(
          'WHEN EXISTS (SELECT 1 FROM exercise_translations tt_pref '
          'WHERE tt_pref.exercise_id = e.id AND (LOWER(tt_pref.name) LIKE ? ');
      prefixMatchVars.add(drift.Variable.withString('$rawSearchLower%'));
      if (hasUmlautVariant) {
        prefixBuffer.write('OR LOWER(tt_pref.name) LIKE ? ');
        prefixMatchVars.add(drift.Variable.withString('$umlautSearchLower%'));
      }
      prefixBuffer.write(')) THEN 1 ');
      prefixBuffer.write('ELSE 0 END) AS is_prefix_match');
      prefixMatchExpr = prefixBuffer.toString();
    }

    final whereClauses = <String>[
      "NOT (e.source = 'wger' AND "
          "EXISTS (SELECT 1 FROM exercises other_exercises "
          "WHERE other_exercises.replaces_exercise_id = e.id))",
      _kActiveExerciseSql,
    ];

    final tokenVars = <drift.Variable>[];
    if (tokenGroups.isNotEmpty) {
      final groupClauses = <String>[];
      for (final group in tokenGroups) {
        if (group.isEmpty) continue;
        final orParts = <String>[];
        for (final variant in group) {
          if (_isShortAcronym(variant)) {
            orParts.add(
              '(tt.name LIKE ? OR tt.name LIKE ? OR tt.name LIKE ? OR tt.name LIKE ? OR tt.name = ? OR IFNULL(tt.search_terms, \'\') LIKE ?)',
            );
            tokenVars.add(drift.Variable.withString('%($variant)%'));
            tokenVars.add(drift.Variable.withString('%-$variant%'));
            tokenVars.add(drift.Variable.withString('% $variant %'));
            tokenVars.add(drift.Variable.withString('$variant %'));
            tokenVars.add(drift.Variable.withString(variant));
            tokenVars.add(drift.Variable.withString('%"$variant"%'));
          } else {
            orParts.add(
              '(tt.name LIKE ? OR IFNULL(tt.search_terms, \'\') LIKE ?)',
            );
            tokenVars.add(drift.Variable.withString('%$variant%'));
            tokenVars.add(drift.Variable.withString('%$variant%'));
          }
        }
        groupClauses.add(
          '(EXISTS (SELECT 1 FROM exercise_translations tt '
          'WHERE tt.exercise_id = e.id AND (${orParts.join(' OR ')})))',
        );
      }
      if (groupClauses.isNotEmpty) {
        if (isOrSearch) {
          whereClauses.add('(${groupClauses.join(' OR ')})');
        } else {
          whereClauses.addAll(groupClauses);
        }
      }
    }

    if (selectedCategories.isNotEmpty) {
      final placeholders =
          List.filled(selectedCategories.length, '?').join(', ');
      whereClauses.add('e.category_name IN ($placeholders)');
    }

    if (equipmentIds.isNotEmpty) {
      final placeholders = List.filled(equipmentIds.length, '?').join(', ');
      whereClauses.add(
        'EXISTS (SELECT 1 FROM exercise_equipment ee '
        "WHERE ee.exercise_id = e.id AND ee.kind = 'primary' "
        'AND ee.equipment_id IN ($placeholders))',
      );
    }

    if (usageTags.isNotEmpty) {
      final placeholders = List.filled(usageTags.length, '?').join(', ');
      whereClauses.add(
        'EXISTS (SELECT 1 FROM exercise_tags et '
        'WHERE et.exercise_id = e.id AND et.tag IN ($placeholders))',
      );
    }

    for (final axis in [
      (column: 'difficulty', values: difficulties),
      (column: 'mechanic', values: mechanics),
      (column: 'laterality', values: lateralities),
    ]) {
      if (axis.values.isEmpty) continue;
      final placeholders = List.filled(axis.values.length, '?').join(', ');
      whereClauses.add('e.${axis.column} IN ($placeholders)');
    }

    if (onlyPerformed) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM set_logs s '
        'JOIN workout_logs w ON s.workout_log_id = w.id '
        'WHERE (s.exercise_id = e.id '
        'OR s.exercise_id = e.replaces_exercise_id '
        'OR (s.exercise_name_snapshot IS NOT NULL AND LOWER(s.exercise_name_snapshot) = LOWER(IFNULL(t_best.name, \'\')))))',
      );
    }

    final whereSection = whereClauses.join(' AND ');
    final vars = <drift.Variable>[];

    // 1. history subquery
    vars.add(drift.Variable.withDateTime(ninetyDaysAgo));

    // 2. exactMatchExpr
    vars.addAll(exactMatchVars);

    // 3. prefixMatchExpr
    vars.addAll(prefixMatchVars);

    // 4. the language-preference join
    vars.addAll(_bestTranslationVars(chain));

    // 5. WHERE token clauses
    vars.addAll(tokenVars);

    // 6. WHERE category IN placeholders
    for (final cat in selectedCategories) {
      vars.add(drift.Variable.withString(cat));
    }

    // 7. equipment, then 8. usage tags
    for (final id in equipmentIds) {
      vars.add(drift.Variable.withString(id));
    }
    for (final tag in usageTags) {
      vars.add(drift.Variable.withString(tag));
    }

    // 9. the annotation axes
    for (final value in [...difficulties, ...mechanics, ...lateralities]) {
      vars.add(drift.Variable.withString(value));
    }

    final sql = '''
      SELECT e.*,
             t_best.name AS display_name,
             t_best.description AS display_description,
             t_best.language_code AS display_language,
             (SELECT pn.notes FROM pinned_exercise_notes pn
               WHERE pn.exercise_id = e.id LIMIT 1) AS pinned_note,
             (
               SELECT (CASE WHEN COUNT(*) > 0 THEN 25 ELSE 0 END) +
                      IFNULL(SUM(CASE WHEN w.start_time >= ? THEN 15 ELSE 0 END), 0)
               FROM set_logs s
               JOIN workout_logs w ON s.workout_log_id = w.id
               WHERE (s.exercise_id = e.id
                  OR s.exercise_id = e.replaces_exercise_id
                  OR (s.exercise_name_snapshot IS NOT NULL AND LOWER(s.exercise_name_snapshot) = LOWER(IFNULL(t_best.name, ''))))
             ) AS history_priority_score,
             (
               SELECT COUNT(*)
               FROM set_logs s
               WHERE (s.exercise_id = e.id
                  OR s.exercise_id = e.replaces_exercise_id
                  OR (s.exercise_name_snapshot IS NOT NULL AND LOWER(s.exercise_name_snapshot) = LOWER(IFNULL(t_best.name, ''))))
             ) AS total_logged_sets,
             (
               SELECT MAX(w.start_time)
               FROM set_logs s
               JOIN workout_logs w ON s.workout_log_id = w.id
               WHERE (s.exercise_id = e.id
                  OR s.exercise_id = e.replaces_exercise_id
                  OR (s.exercise_name_snapshot IS NOT NULL AND LOWER(s.exercise_name_snapshot) = LOWER(IFNULL(t_best.name, ''))))
             ) AS last_logged_timestamp,
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
        dbInstance.exerciseEquipment,
        dbInstance.exerciseTags,
        dbInstance.setLogs,
        dbInstance.workoutLogs,
        dbInstance.pinnedExerciseNotes,
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
    final rawCandidates = names
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toSet();
    final candidates = <String>{...rawCandidates};
    for (final c in rawCandidates) {
      final withUmlauts = _transliterateToUmlauts(c);
      if (withUmlauts != c) candidates.add(withUmlauts);
      final withoutUmlauts = _transliterateFromUmlauts(c);
      if (withoutUmlauts != c) candidates.add(withoutUmlauts);
    }
    if (candidates.isEmpty) return null;

    final candidateList = candidates.toList(growable: false);
    final placeholders =
        List.filled(candidateList.length, 'LOWER(?)').join(', ');
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

  Future<void> savePinnedExerciseNote({
    required String exerciseUuid,
    required String? notes,
  }) async {
    final dbInstance = await database;
    final normalized = notes?.trim();
    await dbInstance.transaction(() async {
      final existing = await (dbInstance.select(dbInstance.pinnedExerciseNotes)
            ..where((row) => row.exerciseId.equals(exerciseUuid)))
          .getSingleOrNull();
      if (normalized == null || normalized.isEmpty) {
        if (existing != null) {
          await (dbInstance.delete(dbInstance.pinnedExerciseNotes)
                ..where((row) => row.localId.equals(existing.localId)))
              .go();
        }
        return;
      }
      if (normalized.length > 10000) {
        throw ArgumentError.value(notes, 'notes', 'Note exceeds 10000 chars');
      }
      if (existing != null) {
        await (dbInstance.update(dbInstance.pinnedExerciseNotes)
              ..where((row) => row.localId.equals(existing.localId)))
            .write(db.PinnedExerciseNotesCompanion(
          notes: drift.Value(normalized),
          updatedAt: drift.Value(DateTime.now()),
        ));
      } else {
        await dbInstance.into(dbInstance.pinnedExerciseNotes).insert(
              db.PinnedExerciseNotesCompanion(
                exerciseId: drift.Value(exerciseUuid),
                notes: drift.Value(normalized),
              ),
            );
      }
    });
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
        mechanic: drift.Value(exercise.mechanic),
        forceVector: drift.Value(exercise.forceVector),
        movementPattern: drift.Value(exercise.movementPattern),
        laterality: drift.Value(exercise.laterality),
        difficulty: drift.Value(exercise.difficulty),
        trackingType: drift.Value(exercise.trackingType),
        loadMode: drift.Value(exercise.loadMode),
        primaryEquipment: drift.Value(exercise.primaryEquipment),
        supportsAddedWeight: drift.Value(exercise.supportsAddedWeight),
        imagePath: drift.Value(exercise.imagePath),
        isCustom: const drift.Value(true),
      );

      final row = await dbInstance
          .into(dbInstance.exercises)
          .insertReturning(companion);

      // Insert translations
      await _upsertTranslations(dbInstance, row.id, exercise);
      await _writePinnedExerciseNote(
        dbInstance,
        row.id,
        exercise.pinnedNote,
      );

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
                mechanic: drift.Value(ex.mechanic),
                forceVector: drift.Value(ex.forceVector),
                movementPattern: drift.Value(ex.movementPattern),
                laterality: drift.Value(ex.laterality),
                difficulty: drift.Value(ex.difficulty),
                trackingType: drift.Value(ex.trackingType),
                loadMode: drift.Value(ex.loadMode),
                primaryEquipment: drift.Value(ex.primaryEquipment),
                supportsAddedWeight: drift.Value(ex.supportsAddedWeight),
                imagePath: drift.Value(ex.imagePath),
                isCustom: const drift.Value(true),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );

        await _upsertTranslations(dbInstance, row.id, ex);
        await _writePinnedExerciseNote(dbInstance, row.id, ex.pinnedNote);
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
          mechanic: drift.Value(exercise.mechanic),
          forceVector: drift.Value(exercise.forceVector),
          movementPattern: drift.Value(exercise.movementPattern),
          laterality: drift.Value(exercise.laterality),
          difficulty: drift.Value(exercise.difficulty),
          trackingType: drift.Value(exercise.trackingType),
          loadMode: drift.Value(exercise.loadMode),
          primaryEquipment: drift.Value(exercise.primaryEquipment),
          supportsAddedWeight: drift.Value(exercise.supportsAddedWeight),
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

      await (dbInstance.delete(dbInstance.pinnedExerciseNotes)
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

  Future<void> _writePinnedExerciseNote(
    db.AppDatabase dbInstance,
    String exerciseUuid,
    String? notes,
  ) async {
    final normalized = notes?.trim();
    if (normalized == null || normalized.isEmpty) return;
    if (normalized.length > 10000) {
      throw ArgumentError.value(notes, 'notes', 'Note exceeds 10000 chars');
    }
    await dbInstance.into(dbInstance.pinnedExerciseNotes).insert(
          db.PinnedExerciseNotesCompanion(
            exerciseId: drift.Value(exerciseUuid),
            notes: drift.Value(normalized),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
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

    final totalLoggedSets = row.readNullable<int>('total_logged_sets') ?? 0;
    final lastLoggedRaw = row.data['last_logged_timestamp'];
    final DateTime? lastPerformedAt = switch (lastLoggedRaw) {
      int s when s > 10000000000 => DateTime.fromMillisecondsSinceEpoch(s),
      int s => DateTime.fromMillisecondsSinceEpoch(s * 1000),
      DateTime d => d,
      String str => DateTime.tryParse(str),
      _ => null,
    };

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
      trackingType: rawExercise.trackingType,
      loadMode: rawExercise.loadMode,
      primaryEquipment: rawExercise.primaryEquipment,
      supportsAddedWeight: rawExercise.supportsAddedWeight,
      mechanic: rawExercise.mechanic,
      laterality: rawExercise.laterality,
      difficulty: rawExercise.difficulty,
      movementPattern: rawExercise.movementPattern,
      forceVector: rawExercise.forceVector,
      pinnedNote: row.readNullable<String>('pinned_note'),
      lastPerformedAt: lastPerformedAt,
      totalLoggedSets: totalLoggedSets,
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
    final pinnedNoteRow =
        await (dbInstance.select(dbInstance.pinnedExerciseNotes)
              ..where((note) => note.exerciseId.equals(row.id)))
            .getSingleOrNull();

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
      trackingType: row.trackingType,
      loadMode: row.loadMode,
      primaryEquipment: row.primaryEquipment,
      supportsAddedWeight: row.supportsAddedWeight,
      mechanic: row.mechanic,
      laterality: row.laterality,
      difficulty: row.difficulty,
      movementPattern: row.movementPattern,
      forceVector: row.forceVector,
      pinnedNote: pinnedNoteRow?.notes,
    );
  }
}
