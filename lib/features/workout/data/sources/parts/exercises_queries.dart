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

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final dbInstance = await database;

    var stmt = dbInstance.select(dbInstance.exercises);

    // Exclude overridden system exercises
    stmt = stmt..where((tbl) {
      final other = dbInstance.exercises.createAlias('other_exercises');
      final subqueryExists = drift.existsQuery(
        dbInstance.select(other)
          ..where((otherTable) => otherTable.replacesExerciseId.equalsExp(tbl.id)),
      );
      return (tbl.source.equals('wger') & subqueryExists).not();
    });

    if (query.isNotEmpty) {
      final term = query.trim();
      stmt = stmt
        ..where(
          (tbl) => tbl.nameDe.like('%$term%') | tbl.nameEn.like('%$term%'),
        );

      stmt = stmt
        ..orderBy([
          (t) => drift.OrderingTerm(
                expression: drift.CaseWhenExpression(
                  cases: [
                    drift.CaseWhen(
                      t.nameDe.equals(term) | t.nameEn.equals(term),
                      then: const drift.Constant(0),
                    ),
                    drift.CaseWhen(
                      t.nameDe.like('$term%') | t.nameEn.like('$term%'),
                      then: const drift.Constant(1),
                    ),
                  ],
                  orElse: const drift.Constant(2),
                ),
                mode: drift.OrderingMode.asc,
              ),
          (t) => drift.OrderingTerm(
                expression: t.usageCount,
                mode: drift.OrderingMode.desc,
              ),
          (t) => drift.OrderingTerm(
              expression: t.nameDe, mode: drift.OrderingMode.asc),
        ]);
    } else {
      stmt = stmt
        ..orderBy([
          (t) => drift.OrderingTerm(
                expression: t.usageCount,
                mode: drift.OrderingMode.desc,
              ),
          (t) => drift.OrderingTerm(
              expression: t.nameDe, mode: drift.OrderingMode.asc),
        ]);
    }

    if (selectedCategories.isNotEmpty) {
      stmt = stmt..where((tbl) => tbl.categoryName.isIn(selectedCategories));
    }

    stmt = stmt..limit(50);

    final rows = await stmt.get();
    return rows.map(_mapExerciseToModel).toList();
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
