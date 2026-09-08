part of '../workout_local_data_source.dart';

extension WorkoutLoggingQueries on WorkoutLocalDataSource {
  Future<List<SetLog>> getProgressionHistory({
    required String exerciseId,
    required String exerciseNameSnapshot,
  }) async {
    final d = await database;
    final rows = await (d.select(d.setLogs).join([
      drift.innerJoin(
          d.workoutLogs, d.workoutLogs.id.equalsExp(d.setLogs.workoutLogId)),
    ])
          ..where((d.setLogs.exerciseId.equals(exerciseId) |
                  (d.setLogs.exerciseId.isNull() &
                      d.setLogs.exerciseNameSnapshot
                          .equals(exerciseNameSnapshot))) &
              d.workoutLogs.status.equals('completed'))
          ..orderBy([
            drift.OrderingTerm.desc(d.workoutLogs.startTime),
            drift.OrderingTerm.asc(d.setLogs.logOrder),
            drift.OrderingTerm.asc(d.setLogs.localId)
          ]))
        .get();
    return rows.map((r) {
      final set = r.readTable(d.setLogs);
      final workout = r.readTable(d.workoutLogs);
      return _mapSetLogToModel(set, workout.localId)
          .copyWith(performedAt: workout.startTime);
    }).toList();
  }

  /// Creates a new [WorkoutLog] and marks it as "ongoing".
  Future<WorkoutLog> startWorkout({String? routineName}) async {
    final dbInstance = await database;
    final now = DateTime.now();

    // Try to find routine UUID for linking (optional).
    String? routineId;
    String? routineNameSnapshot = routineName;

    if (routineName != null) {
      final rRow = await (dbInstance.select(dbInstance.routines)
            ..where((tbl) => tbl.name.equals(routineName))
            ..limit(1))
          .getSingleOrNull();
      routineId = rRow?.id;
    }

    final row = await dbInstance.into(dbInstance.workoutLogs).insertReturning(
          db.WorkoutLogsCompanion(
            startTime: drift.Value(now),
            status: const drift.Value('ongoing'),
            routineId: drift.Value(routineId),
            routineNameSnapshot: drift.Value(routineNameSnapshot),
          ),
        );

    return WorkoutLog(
      id: row.localId,
      routineName: routineName,
      routineId: row.routineId,
      startTime: row.startTime,
      // status field removed from WorkoutLog model in UI, handling internally if needed
    );
  }

  Future<void> finishWorkout(
    int workoutLogId, {
    String? title,
    String? notes,
  }) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(workoutLogId)))
        .write(
      db.WorkoutLogsCompanion(
        endTime: drift.Value(DateTime.now()),
        status: const drift.Value('completed'),
        routineNameSnapshot:
            title != null ? drift.Value(title) : const drift.Value.absent(),
        notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
      ),
    );

    // Increment usageCount for exercises used in this workout
    try {
      final logRow = await (dbInstance.select(dbInstance.workoutLogs)
            ..where((t) => t.localId.equals(workoutLogId)))
          .getSingle();

      final setLogsQuery =
          dbInstance.selectOnly(dbInstance.setLogs, distinct: true)
            ..addColumns([dbInstance.setLogs.exerciseId])
            ..where(dbInstance.setLogs.workoutLogId.equals(logRow.id))
            ..where(dbInstance.setLogs.exerciseId.isNotNull());

      final exerciseIds = (await setLogsQuery.get())
          .map((r) => r.read(dbInstance.setLogs.exerciseId))
          .whereType<String>()
          .toList();

      if (exerciseIds.isNotEmpty) {
        await dbInstance.customUpdate(
          'UPDATE exercises SET usage_count = usage_count + 1 WHERE id IN (${exerciseIds.map((_) => '?').join(',')})',
          variables:
              exerciseIds.map((id) => drift.Variable.withString(id)).toList(),
          updates: {dbInstance.exercises},
        );
      }
    } catch (e) {
      // Non-critical: don't fail finishWorkout if usageCount update fails
    }
  }

  Future<int> insertSetLog(SetLog setLog) async {
    final dbInstance = await database;
    final workoutLogUuid = await _getUuidFromLocalId(
      dbInstance.workoutLogs,
      setLog.workoutLogId,
    );

    if (workoutLogUuid == null) {
      throw Exception(
        "WorkoutLog UUID not found for localId ${setLog.workoutLogId}",
      );
    }

    // Search for exercise UUID
    String? exerciseUuid = setLog.exerciseId;
    if (exerciseUuid == null || exerciseUuid.isEmpty) {
      final exercise = await getExerciseByName(setLog.exerciseName);
      exerciseUuid = exercise?.uuid;
    }

    // Keep existing exercise linkage on updates when name-based lookup fails.
    if (setLog.id != null && (exerciseUuid == null || exerciseUuid.isEmpty)) {
      final existingSetRow = await (dbInstance.select(dbInstance.setLogs)
            ..where((tbl) => tbl.localId.equals(setLog.id!))
            ..limit(1))
          .getSingleOrNull();
      exerciseUuid = existingSetRow?.exerciseId;
    }

    final companion = db.SetLogsCompanion(
      workoutLogId: drift.Value(workoutLogUuid),
      exerciseId: drift.Value(exerciseUuid),
      exerciseNameSnapshot: drift.Value(setLog.exerciseName),
      weight: drift.Value(setLog.weightKg),
      reps: drift.Value(setLog.reps),
      setType: drift.Value(setLog.setType),
      restTimeSeconds: drift.Value(setLog.restTimeSeconds),
      isCompleted: drift.Value(setLog.isCompleted ?? false),
      logOrder: drift.Value(setLog.logOrder ?? 0),
      exerciseBlock: drift.Value(setLog.exerciseBlock),
      supersetGroup: drift.Value(setLog.supersetGroup),
      notes: drift.Value(setLog.notes),
      distance: drift.Value(setLog.distanceKm),
      durationSeconds: drift.Value(setLog.durationSeconds),
      rpe: drift.Value(setLog.rpe),
      rir: drift.Value(setLog.rir), // Direct int now, perfect.
      prescriptionOrigin: drift.Value(setLog.prescriptionOrigin),
      prescribedRepMin: drift.Value(setLog.prescribedRepMin),
      prescribedRepMax: drift.Value(setLog.prescribedRepMax),
      prescribedWeight: drift.Value(setLog.prescribedWeight),
      prescribedRir: drift.Value(setLog.prescribedRir),
      prescriptionOverridden: drift.Value(setLog.prescriptionOverridden),
      valuesAutoFilled: drift.Value(setLog.valuesAutoFilled),
      substitutedForExerciseId: drift.Value(setLog.substitutedForExerciseId),
      progressionData: drift.Value(setLog.progressionData),
      progressionReason: drift.Value(setLog.progressionReason),
      progressionAlgorithmVersion:
          drift.Value(setLog.progressionAlgorithmVersion),
    );

    if (setLog.id != null && setLog.id! > 0) {
      // Update
      await (dbInstance.update(
        dbInstance.setLogs,
      )..where((tbl) => tbl.localId.equals(setLog.id!)))
          .write(companion);
      return setLog.id!;
    } else {
      // Insert
      final row =
          await dbInstance.into(dbInstance.setLogs).insertReturning(companion);

      // Increment usageCount for the exercise if linked
      if (exerciseUuid != null) {
        try {
          await dbInstance.customUpdate(
            'UPDATE exercises SET usage_count = usage_count + 1 WHERE id = ?',
            variables: [drift.Variable.withString(exerciseUuid)],
            updates: {dbInstance.exercises},
          );
        } catch (_) {}
      }

      return row.localId;
    }
  }

  Future<WorkoutLog?> getWorkoutLogById(int id) async {
    final dbInstance = await database;
    final logRow = await (dbInstance.select(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(id)))
        .getSingleOrNull();

    if (logRow == null) return null;

    // Ordered by localId as well: rows written before log_order was assigned
    // per set all carry the column default of 0, and ordering on that alone
    // leaves SQLite free to return them in any order it likes — which is how
    // a restored session ended up with its exercises shuffled.
    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where((tbl) => tbl.workoutLogId.equals(logRow.id))
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.logOrder),
            (t) => drift.OrderingTerm(expression: t.localId),
          ]))
        .get();

    return _mapWorkoutLogWithSets(logRow, setRows);
  }

  Future<void> updateSetLogs(List<SetLog> updatedSets) async {
    if (updatedSets.isEmpty) return;
    final dbInstance = await database;
    for (final s in updatedSets) {
      if (s.id != null) {
        await (dbInstance.update(dbInstance.setLogs)
              ..where((tbl) => tbl.localId.equals(s.id!)))
            .write(db.SetLogsCompanion(
          progressionData: drift.Value(s.progressionData),
          prescriptionOrigin: drift.Value(s.prescriptionOrigin),
          prescribedWeight: drift.Value(s.prescribedWeight),
          prescribedRepMin: drift.Value(s.prescribedRepMin),
          prescribedRepMax: drift.Value(s.prescribedRepMax),
          prescribedRir: drift.Value(s.prescribedRir),
          progressionReason: drift.Value(s.progressionReason),
          progressionAlgorithmVersion:
              drift.Value(s.progressionAlgorithmVersion),
          substitutedForExerciseId: drift.Value(s.substitutedForExerciseId),
          weight: drift.Value(s.weightKg),
          reps: drift.Value(s.reps),
          isCompleted: drift.Value(s.isCompleted ?? false),
          notes: drift.Value(s.notes),
          rir: drift.Value(s.rir),
          setType: drift.Value(s.setType),
          logOrder: drift.Value(s.logOrder ?? 0),
          exerciseBlock: drift.Value(s.exerciseBlock),
          supersetGroup: drift.Value(s.supersetGroup),
          distance: drift.Value(s.distanceKm),
          durationSeconds: drift.Value(s.durationSeconds),
          restTimeSeconds: drift.Value(s.restTimeSeconds),
          valuesAutoFilled: drift.Value(s.valuesAutoFilled),
          prescriptionOverridden: drift.Value(s.prescriptionOverridden),
        ));
      }
    }
  }

  Future<void> deleteWorkoutLog(int logId) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.localId.equals(logId)))
        .getSingleOrNull();
    if (row != null) {
      final extraPaths = <String>[];
      if (row.photoExtraPaths != null && row.photoExtraPaths!.isNotEmpty) {
        try {
          final decoded = jsonDecode(row.photoExtraPaths!);
          if (decoded is List) {
            extraPaths.addAll(decoded.whereType<String>());
          }
        } catch (_) {}
      }
      await WorkoutPhotoStore.instance.delete(
        photoPath: row.photoPath,
        thumbPath: row.photoThumbPath,
        extraPaths: extraPaths,
      );
    }
    await (dbInstance.delete(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(logId)))
        .go();
  }

  Future<void> updateWorkoutLogPhotos(int logId, List<String> paths) async {
    final dbInstance = await database;
    if (paths.isEmpty) {
      await (dbInstance.update(dbInstance.workoutLogs)
            ..where((tbl) => tbl.localId.equals(logId)))
          .write(
        const db.WorkoutLogsCompanion(
          photoPath: drift.Value(null),
          photoThumbPath: drift.Value(null),
          photoExtraPaths: drift.Value(null),
        ),
      );
    } else {
      final first = paths.first;
      final thumb = AppMediaStore.thumbPathFor(first);
      final extras = paths.length > 1 ? jsonEncode(paths.sublist(1)) : null;
      await (dbInstance.update(dbInstance.workoutLogs)
            ..where((tbl) => tbl.localId.equals(logId)))
          .write(
        db.WorkoutLogsCompanion(
          photoPath: drift.Value(first),
          photoThumbPath: drift.Value(thumb),
          photoExtraPaths: drift.Value(extras),
        ),
      );
    }
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    // Returns only completed logs (base info).
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    return rows
        .map(
          (r) => WorkoutLog(
            id: r.localId,
            routineName: r.routineNameSnapshot,
            routineId: r.routineId,
            startTime: r.startTime,
            endTime: r.endTime,
            notes: r.notes,
            photoPaths: WorkoutLocalDataSource._extractPhotoPaths(
              r.photoPath,
              r.photoExtraPaths,
            ),
          ),
        )
        .toList();
  }

  Future<List<WorkoutLog>> getFullWorkoutLogs() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    return _loadWorkoutLogsWithSets(rows);
  }

  Stream<List<WorkoutLog>> watchFullWorkoutLogs() {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final query = dbInstance.select(dbInstance.workoutLogs)
      ..where((tbl) => tbl.status.equals('completed'))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.startTime,
              mode: drift.OrderingMode.desc,
            ),
      ]);
    return query.watch().asyncMap((rows) => _loadWorkoutLogsWithSets(rows));
  }

  Stream<List<WorkoutLog>> watchWorkoutLogsForDateRange(
      DateTime start, DateTime end) {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.workoutLogs)
      ..where((tbl) =>
          tbl.startTime.isBetweenValues(effectiveStart, effectiveEnd) &
          tbl.status.equals('completed'))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.startTime,
              mode: drift.OrderingMode.desc,
            ),
      ]);
    return query.watch().asyncMap((rows) => _loadWorkoutLogsWithSets(rows));
  }

  Future<WorkoutLog?> getLatestWorkoutLog() async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getWorkoutLogById(row.localId);
    }
    return null;
  }

  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final dbInstance = await database;

    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.startTime.isBetweenValues(
                  effectiveStart,
                  effectiveEnd,
                ) &
                tbl.status.equals('completed'),
          )
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    return _loadWorkoutLogsWithSets(rows);
  }

  Future<void> updateWorkoutLogDetails(
    int logId,
    DateTime startTime,
    String? notes,
  ) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(logId)))
        .write(
      db.WorkoutLogsCompanion(
        startTime: drift.Value(startTime),
        notes: drift.Value(notes),
      ),
    );
  }

  Future<void> deleteSetLogs(List<int> idsToDelete) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.setLogs,
    )..where((tbl) => tbl.localId.isIn(idsToDelete)))
        .go();
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final full = await getWorkoutLogById(workoutLogId);
    return full?.sets ?? [];
  }

  Stream<List<SetLog>> watchSetLogsForWorkout(int workoutLogId) async* {
    final dbInstance = DatabaseHelper.instance.dbInstance;
    final logRow = await (dbInstance.select(
      dbInstance.workoutLogs,
    )..where((tbl) => tbl.localId.equals(workoutLogId)))
        .getSingleOrNull();

    if (logRow == null) {
      yield [];
      return;
    }

    final query = dbInstance.select(dbInstance.setLogs)
      ..where((tbl) => tbl.workoutLogId.equals(logRow.id))
      ..orderBy([
        (t) => drift.OrderingTerm(expression: t.logOrder),
        (t) => drift.OrderingTerm(expression: t.localId),
      ]);

    yield* query.watch().map(
          (rows) =>
              rows.map((r) => _mapSetLogToModel(r, workoutLogId)).toList(),
        );
  }

  Future<void> importWorkoutData({
    required List<Routine> routines,
    required List<WorkoutLog> workoutLogs,
  }) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      // Routines
      for (final r in routines) {
        final rRow = await dbInstance
            .into(dbInstance.routines)
            .insertReturning(db.RoutinesCompanion(name: drift.Value(r.name)));
        final newRoutineId = rRow.id; // UUID

        for (int orderIndex = 0;
            orderIndex < r.exercises.length;
            orderIndex++) {
          final re = r.exercises[orderIndex];
          // Check exercise mapping (name -> UUID).
          // Search for the exercise in the DB. If custom and present in the backup, it should already be imported.
          final exModel = re.exercise;
          // Any name the shared routine carries, in any language it was
          // written in.
          Exercise? exercise;
          for (final name in exModel.allNames) {
            exercise = await getExerciseByName(name);
            if (exercise != null) break;
          }

          if (exercise == null) continue;

          final reRow = await dbInstance
              .into(dbInstance.routineExercises)
              .insertReturning(
                db.RoutineExercisesCompanion(
                  routineId: drift.Value(newRoutineId),
                  exerciseId: drift.Value(exercise.uuid!),
                  orderIndex: drift.Value(orderIndex),
                  pauseSeconds: drift.Value(re.pauseSeconds),
                  supersetGroup: drift.Value(re.supersetGroup),
                  progressionData: drift.Value(re.progressionData),
                  notes: drift.Value(re.notes),
                ),
              );

          // Templates
          for (final t in re.setTemplates) {
            await dbInstance.into(dbInstance.routineSetTemplates).insert(
                  db.RoutineSetTemplatesCompanion(
                    routineExerciseId: drift.Value(reRow.id),
                    setType: drift.Value(t.setType),
                    targetReps: drift.Value(t.targetReps),
                    targetWeight: drift.Value(t.targetWeight),
                    targetRir: drift.Value(t.targetRir),
                    targetRepMin: drift.Value(t.targetRepMin),
                    targetRepMax: drift.Value(t.targetRepMax),
                  ),
                );
          }
        }
      }

      // WorkoutLogs
      for (final w in workoutLogs) {
        final firstPhoto = w.photoPaths.isNotEmpty ? w.photoPaths.first : null;
        final thumbPhoto =
            firstPhoto != null ? AppMediaStore.thumbPathFor(firstPhoto) : null;
        final extraPhotos = w.photoPaths.length > 1
            ? jsonEncode(w.photoPaths.sublist(1))
            : null;

        final wRow =
            await dbInstance.into(dbInstance.workoutLogs).insertReturning(
                  db.WorkoutLogsCompanion(
                    startTime: drift.Value(w.startTime),
                    endTime: drift.Value(w.endTime),
                    status: const drift.Value('completed'),
                    routineNameSnapshot: drift.Value(w.routineName),
                    notes: drift.Value(w.notes),
                    photoPath: drift.Value(firstPhoto),
                    photoThumbPath: drift.Value(thumbPhoto),
                    photoExtraPaths: drift.Value(extraPhotos),
                  ),
                );

        for (final s in w.sets) {
          final exercise = await getExerciseByName(s.exerciseName);

          await dbInstance.into(dbInstance.setLogs).insert(
                db.SetLogsCompanion(
                  workoutLogId: drift.Value(wRow.id),
                  exerciseNameSnapshot: drift.Value(s.exerciseName),
                  exerciseId: drift.Value(exercise?.uuid),
                  weight: drift.Value(s.weightKg),
                  reps: drift.Value(s.reps),
                  setType: drift.Value(s.setType),
                  restTimeSeconds: drift.Value(s.restTimeSeconds),
                  isCompleted: drift.Value(s.isCompleted ?? true),
                  logOrder: drift.Value(s.logOrder ?? 0),
                  exerciseBlock: drift.Value(s.exerciseBlock),
                  supersetGroup: drift.Value(s.supersetGroup),
                  notes: drift.Value(s.notes),
                  distance: drift.Value(s.distanceKm),
                  durationSeconds: drift.Value(s.durationSeconds),
                  rpe: drift.Value(s.rpe),
                  rir: drift.Value(s.rir),
                  prescriptionOrigin: drift.Value(s.prescriptionOrigin),
                  prescribedRepMin: drift.Value(s.prescribedRepMin),
                  prescribedRepMax: drift.Value(s.prescribedRepMax),
                  prescribedWeight: drift.Value(s.prescribedWeight),
                  prescribedRir: drift.Value(s.prescribedRir),
                  prescriptionOverridden: drift.Value(s.prescriptionOverridden),
                  valuesAutoFilled: drift.Value(s.valuesAutoFilled),
                  substitutedForExerciseId:
                      drift.Value(s.substitutedForExerciseId),
                  progressionData: drift.Value(s.progressionData),
                  progressionReason: drift.Value(s.progressionReason),
                  progressionAlgorithmVersion:
                      drift.Value(s.progressionAlgorithmVersion),
                ),
              );
        }
      }
    });
  }

  Future<List<String>> findUnknownExerciseNames() async {
    final dbInstance = await database;
    // Drift has no direct Dart-syntax path for this complex join + IS NULL check.
    // Daher Custom Query.
    final result = await dbInstance.customSelect('''
      SELECT DISTINCT sl.exercise_name_snapshot
      FROM set_logs sl
      LEFT JOIN exercises e ON sl.exercise_id = e.id
      WHERE e.id IS NULL AND sl.exercise_name_snapshot IS NOT NULL
      ORDER BY sl.exercise_name_snapshot ASC
    ''').get();

    return result.map((r) => r.read<String>('exercise_name_snapshot')).toList();
  }

  Future<void> applyExerciseNameMapping(Map<String, String> map) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      for (final entry in map.entries) {
        final oldName = entry.key;
        final newName = entry.value;

        // Find the new exercise UUID
        final exercise = await getExerciseByName(newName);

        if (exercise != null) {
          // Update SetLogs
          await (dbInstance.update(
            dbInstance.setLogs,
          )..where((tbl) => tbl.exerciseNameSnapshot.equals(oldName)))
              .write(
            db.SetLogsCompanion(
              exerciseId: drift.Value(exercise.uuid!),
              exerciseNameSnapshot: drift.Value(newName),
            ),
          );
        }
      }
    });
  }

  Future<Set<int>> getWorkoutDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.workoutLogs)
          ..addColumns([dbInstance.workoutLogs.startTime])
          ..where(
            dbInstance.workoutLogs.startTime.isBetweenValues(start, end),
          ))
        .get();

    return rows
        .map((r) => r.read(dbInstance.workoutLogs.startTime)!.day)
        .toSet();
  }

  /// Returns the most recently completed sets for an exercise, ordered by [SetLog.logOrder].
  ///
  /// Exercise history is read by stable exercise UUID ([exerciseId]) rather than
  /// by display name snapshot, so that renames or catalogue merges do not silently
  /// attach one exercise's history to another.
  ///
  /// The condition `(exercise_id = :exerciseId) OR (exercise_id IS NULL AND exercise_name_snapshot = :name)`
  /// handles mixed data in a single query without two-stage reloading:
  /// - New rows match on stable [exerciseId].
  /// - Legacy rows written before `set_logs.exercise_id` existed carry a null
  ///   `exercise_id` and fall back to matching on [exerciseNameSnapshot].
  /// - If [exerciseId] is null, only the name snapshot applies.
  /// - A row with an explicit, differing `exercise_id` is never matched, even if
  ///   its snapshot name is identical.
  Future<List<SetLog>> getLastSetsForExercise({
    required String? exerciseId,
    required String exerciseNameSnapshot,
  }) async {
    final dbInstance = await database;

    // Select by exercise UUID, falling back to name snapshot only for legacy
    // rows written before exercise_id existed. A row with an explicit, differing
    // exercise_id is never matched even if the snapshot name is identical.
    drift.Expression<bool> exercisePredicate(db.$SetLogsTable tbl) {
      if (exerciseId != null && exerciseId.isNotEmpty) {
        return tbl.exerciseId.equals(exerciseId) |
            (tbl.exerciseId.isNull() &
                tbl.exerciseNameSnapshot.equals(exerciseNameSnapshot));
      }
      return tbl.exerciseNameSnapshot.equals(exerciseNameSnapshot);
    }

    final query = dbInstance.select(dbInstance.workoutLogs).join([
      drift.innerJoin(
        dbInstance.setLogs,
        dbInstance.setLogs.workoutLogId.equalsExp(
          dbInstance.workoutLogs.id,
        ),
      ),
    ])
      ..where(
        exercisePredicate(dbInstance.setLogs) &
            dbInstance.workoutLogs.status.equals('completed'),
      )
      ..orderBy([
        drift.OrderingTerm(
          expression: dbInstance.workoutLogs.startTime,
          mode: drift.OrderingMode.desc,
        ),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    if (result == null) return [];

    final workoutRow = result.readTable(dbInstance.workoutLogs);
    final logUuid = workoutRow.id;
    final wLogId = workoutRow.localId;
    final workoutStartTime = workoutRow.startTime;

    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where(
            (tbl) => tbl.workoutLogId.equals(logUuid) & exercisePredicate(tbl),
          )
          ..orderBy([(t) => drift.OrderingTerm(expression: t.logOrder)]))
        .get();

    return setRows
        .map(
          (r) => SetLog(
            id: r.localId,
            workoutLogId: wLogId,
            exerciseId: r.exerciseId,
            exerciseName: r.exerciseNameSnapshot ?? '',
            setType: r.setType,
            weightKg: r.weight,
            reps: r.reps,
            // Duration and distance were missing here, so "last time" was
            // blank for every exercise that logs neither a weight nor reps: a
            // plank held for a minute last week, and every run ever recorded.
            // The column itself renders them correctly — it was never given
            // them.
            durationSeconds: r.durationSeconds,
            distanceKm: r.distance,
            isCompleted: r.isCompleted,
            rir: r.rir, // Use directly
            exerciseBlock: r.exerciseBlock,
            supersetGroup: r.supersetGroup,
            notes: r.notes,
            rpe: r.rpe,
            logOrder: r.logOrder,
            prescriptionOrigin: r.prescriptionOrigin,
            prescribedRepMin: r.prescribedRepMin,
            prescribedRepMax: r.prescribedRepMax,
            prescribedWeight: r.prescribedWeight,
            prescribedRir: r.prescribedRir,
            prescriptionOverridden: r.prescriptionOverridden,
            valuesAutoFilled: r.valuesAutoFilled,
            substitutedForExerciseId: r.substitutedForExerciseId,
            progressionData: r.progressionData,
            progressionReason: r.progressionReason,
            progressionAlgorithmVersion: r.progressionAlgorithmVersion,
            performedAt: workoutStartTime,
          ),
        )
        .toList();
  }

  Future<void> clearAllWorkoutData() async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      await dbInstance.delete(dbInstance.cardioSamples).go();
      await dbInstance.delete(dbInstance.cardioActivities).go();
      await dbInstance.delete(dbInstance.setLogs).go();
      await dbInstance.delete(dbInstance.workoutLogs).go();
      await dbInstance.delete(dbInstance.routineSetTemplates).go();
      await dbInstance.delete(dbInstance.routineExercises).go();
      await dbInstance.delete(dbInstance.routines).go();
      // Delete only custom exercises
      await (dbInstance.delete(
        dbInstance.exercises,
      )..where((tbl) => tbl.isCustom.equals(true)))
          .go();
    });
  }

  Future<WorkoutLog?> getOngoingWorkout() async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('ongoing'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getWorkoutLogById(row.localId);
    }
    return null;
  }
}
