part of '../workout_local_data_source.dart';

extension WorkoutStatsQueries on WorkoutLocalDataSource {
  /// Retrieves the UUID (string) for an exercise given its local integer ID.
  Future<String?> getExerciseUuidByLocalId(int localId) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.localId.equals(localId))
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  Future<_ExerciseMuscleLookup> _loadExerciseMuscleLookup(
    db.AppDatabase dbInstance,
  ) async {
    final exerciseRows = await dbInstance.select(dbInstance.exercises).get();
    final translationRows =
        await dbInstance.select(dbInstance.exerciseTranslations).get();

    final byId = <String, _ExerciseMuscleProfile>{
      for (final exerciseRow in exerciseRows)
        exerciseRow.id: _ExerciseMuscleProfile(
          primary: _parseMuscles(exerciseRow.musclesPrimary),
          secondary: _parseMuscles(exerciseRow.musclesSecondary),
        ),
    };

    final byName = <String, _ExerciseMuscleProfile>{};
    for (final translationRow in translationRows) {
      final profile = byId[translationRow.exerciseId];
      if (profile == null) continue;

      final normalizedName = _normalizeExerciseName(translationRow.name);
      if (normalizedName.isEmpty) continue;
      byName.putIfAbsent(normalizedName, () => profile);
    }

    return _ExerciseMuscleLookup(byId: byId, byName: byName);
  }

  _ExerciseMuscleProfile? _resolveExerciseMuscleProfile({
    required _ExerciseMuscleLookup lookup,
    db.Exercise? exerciseRow,
    String? exerciseNameSnapshot,
  }) {
    if (exerciseRow != null) {
      final profile = lookup.byId[exerciseRow.id];
      if (profile != null) {
        return profile;
      }

      return _ExerciseMuscleProfile(
        primary: _parseMuscles(exerciseRow.musclesPrimary),
        secondary: _parseMuscles(exerciseRow.musclesSecondary),
      );
    }

    final normalizedSnapshot = _normalizeExerciseName(exerciseNameSnapshot);
    if (normalizedSnapshot.isEmpty) return null;
    return lookup.byName[normalizedSnapshot];
  }

  static List<String> _parseMuscles(String? rawMuscles) {
    return WorkoutLocalDataSource._parseMuscleList(rawMuscles)
        .map((muscle) => muscle.trim())
        .where((muscle) => muscle.isNotEmpty)
        .toList(growable: false);
  }

  static String _normalizeExerciseName(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  /// Builds a Drift expression that matches set_logs by exercise name snapshot
  /// (nameDe, optional nameEn) or by exercise UUID.
  drift.Expression<bool> _buildExerciseMatchCondition(
    db.AppDatabase dbInstance,
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    drift.Expression<bool> nameExpr =
        dbInstance.setLogs.exerciseNameSnapshot.equals(exerciseName);

    if (altName != null && altName.isNotEmpty && altName != exerciseName) {
      nameExpr =
          nameExpr | dbInstance.setLogs.exerciseNameSnapshot.equals(altName);
    }

    if (exerciseUuid != null && exerciseUuid.isNotEmpty) {
      return nameExpr | dbInstance.setLogs.exerciseId.equals(exerciseUuid);
    }
    return nameExpr;
  }

  /// Represents a single PR for a specific rep bracket.
  /// (Using a map/record or a specific class here; we will use a raw map structure
  /// for simplicity or a custom class if preferred. We'll use a Record for modern Dart.)
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async {
    final dbInstance = await database;

    final exerciseMatch = _buildExerciseMatchCondition(
      dbInstance,
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    // Qualifying sets for PRs:
    // isCompleted == true, setType != 'warmup', (weight > 0 & reps > 0 OR distance > 0 OR duration > 0)
    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            (isCardio
                ? (dbInstance.setLogs.distance.isBiggerThanValue(0.0) |
                    dbInstance.setLogs.durationSeconds.isBiggerThanValue(0))
                : (dbInstance.setLogs.weight.isBiggerThanValue(0.0) &
                    dbInstance.setLogs.reps.isBiggerThanValue(0))),
      );

    final rows = await query.get();

    final prMap = <String, SetLog?>{};

    if (isCardio) {
      prMap['Best Distance'] = null;
      prMap['Longest Duration'] = null;
      prMap['Fastest Pace'] = null;

      double bestDistance = 0.0;
      int longestDuration = 0;
      double fastestPace = double.infinity;

      for (final r in rows) {
        final setRow = r.readTable(dbInstance.setLogs);
        final logRow = r.readTable(dbInstance.workoutLogs);

        final setLog = SetLog(
          id: setRow.localId,
          workoutLogId: logRow.localId,
          exerciseName: setRow.exerciseNameSnapshot ?? exerciseName,
          setType: setRow.setType,
          distanceKm: setRow.distance,
          durationSeconds: setRow.durationSeconds,
          isCompleted: setRow.isCompleted,
        );

        final dist = setLog.distanceKm ?? 0.0;
        final dur = setLog.durationSeconds ?? 0;

        if (dist <= 0 && dur <= 0) continue;

        if (dist > bestDistance) {
          bestDistance = dist;
          prMap['Best Distance'] = setLog;
        }
        if (dur > longestDuration) {
          longestDuration = dur;
          prMap['Longest Duration'] = setLog;
        }
        if (dist > 0 && dur > 0) {
          final pace = dur / dist; // seconds per km
          if (pace < fastestPace) {
            fastestPace = pace;
            prMap['Fastest Pace'] = setLog;
          }
        }
      }
    } else {
      prMap.addAll({
        'Est. 1RM': null,
        '1 RM': null,
        '2-3 RM': null,
        '4-6 RM': null,
        '7-10 RM': null,
        '11-15 RM': null,
      });

      double bestEst1rmValue = 0.0;
      SetLog? bestEst1rmSet;

      String? getBracket(int reps) {
        if (reps == 1) return '1 RM';
        if (reps >= 2 && reps <= 3) return '2-3 RM';
        if (reps >= 4 && reps <= 6) return '4-6 RM';
        if (reps >= 7 && reps <= 10) return '7-10 RM';
        if (reps >= 11 && reps <= 15) return '11-15 RM';
        return null;
      }

      for (final r in rows) {
        final setRow = r.readTable(dbInstance.setLogs);
        final logRow = r.readTable(dbInstance.workoutLogs);

        final setLog = SetLog(
          id: setRow.localId,
          workoutLogId: logRow.localId,
          exerciseName: setRow.exerciseNameSnapshot ?? exerciseName,
          setType: setRow.setType,
          weightKg: setRow.weight,
          reps: setRow.reps,
          isCompleted: setRow.isCompleted,
        );

        final reps = setLog.reps ?? 0;
        final weight = setLog.weightKg ?? 0.0;

        if (reps <= 0 || weight <= 0) continue;

        if (reps <= 10) {
          final est1rm = weight * (36 / (37 - reps));
          if (est1rm > bestEst1rmValue) {
            bestEst1rmValue = est1rm;
            bestEst1rmSet = setLog;
          }
        }

        final bracket = getBracket(reps);
        if (bracket != null) {
          final currentPr = prMap[bracket];
          if (currentPr == null || weight > (currentPr.weightKg ?? 0.0)) {
            prMap[bracket] = setLog;
          } else if (weight == currentPr.weightKg &&
              reps > (currentPr.reps ?? 0)) {
            prMap[bracket] = setLog;
          }
        }
      }

      if (bestEst1rmSet != null) {
        prMap['Est. 1RM'] = bestEst1rmSet;
      }
    }

    return prMap;
  }

  /// Retrieves the historical bests (Max Weight, Max Volume, Max Est. 1RM)
  /// for a specific exercise to use as a baseline for real-time PR detection.
  Future<Map<String, double>> getExerciseBests(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    int? excludeWorkoutLogId,
    DateTime? beforeTimestamp,
    bool isCardio = false,
  }) async {
    final dbInstance = await database;

    final exerciseMatch = _buildExerciseMatchCondition(
      dbInstance,
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    // Get the UUID of the workout to exclude if provided
    String? excludeUuid;
    if (excludeWorkoutLogId != null) {
      excludeUuid = await _getUuidFromLocalId(
        dbInstance.workoutLogs,
        excludeWorkoutLogId,
      );
    }

    // Qualifying sets for PRs:
    // isCompleted == true, setType != 'warmup', weight > 0, reps > 0
    var query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            (isCardio
                ? (dbInstance.setLogs.distance.isBiggerThanValue(0.0) |
                    dbInstance.setLogs.durationSeconds.isBiggerThanValue(0))
                : (dbInstance.setLogs.weight.isBiggerThanValue(0.0) &
                    dbInstance.setLogs.reps.isBiggerThanValue(0))) &
            dbInstance.workoutLogs.status.equals('completed'),
      );

    if (excludeUuid != null) {
      query = query..where(dbInstance.workoutLogs.id.isNotValue(excludeUuid));
    }

    if (beforeTimestamp != null) {
      query = query
        ..where(dbInstance.workoutLogs.startTime.isSmallerThanValue(
          beforeTimestamp,
        ));
    }

    final rows = await query.get();

    double maxWeight = 0.0;
    double maxVolume = 0.0;
    double maxEst1rm = 0.0;

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;

      if (weight > maxWeight) maxWeight = weight;

      final volume = weight * reps;
      if (volume > maxVolume) maxVolume = volume;

      if (reps > 0 && reps <= 10) {
        final est1rm = weight * (36 / (37 - reps));
        if (est1rm > maxEst1rm) maxEst1rm = est1rm;
      }
    }

    return {
      'maxWeight': maxWeight,
      'maxVolume': maxVolume,
      'maxEst1rm': maxEst1rm,
    };
  }

  /// Calculates Time-Series data points for Weight, Volume, and Sets per session.
  /// Result is a List of Maps containing Date and the metrics.
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async {
    final dbInstance = await database;

    final exerciseMatch = _buildExerciseMatchCondition(
      dbInstance,
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.workoutLogs.status.equals('completed'),
      )
      ..orderBy([
        drift.OrderingTerm(
          expression: dbInstance.workoutLogs.startTime,
          mode: drift.OrderingMode.asc,
        ),
      ]);

    final rows = await query.get();

    // Group by session (WorkoutLog UUID or LocalID)
    final Map<int, Map<String, dynamic>> sessionAggregates = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final wLogId = logRow.localId;

      if (!sessionAggregates.containsKey(wLogId)) {
        sessionAggregates[wLogId] = {
          'date': logRow.startTime,
          'maxWeight': 0.0,
          'totalVolume': 0.0,
          'maxEst1rm': 0.0,
          'maxDistance': 0.0,
          'totalDuration': 0.0,
          'maxPace': double.infinity,
          'setCount': 0,
        };
      }

      final agg = sessionAggregates[wLogId]!;
      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      final dist = setRow.distance ?? 0.0;
      final dur = setRow.durationSeconds ?? 0;

      // Update Max Weight
      if (weight > agg['maxWeight']) {
        agg['maxWeight'] = weight;
      }

      // Update Volume
      agg['totalVolume'] += (weight * reps);

      // Update Max Est. 1RM (Brzycki formula)
      if (reps > 0 && reps <= 10) {
        final est1rm = weight * (36 / (37 - reps));
        if (est1rm > (agg['maxEst1rm'] as double)) {
          agg['maxEst1rm'] = est1rm;
        }
      }

      // Cardio
      if (dist > (agg['maxDistance'] as double)) {
        agg['maxDistance'] = dist;
      }
      agg['totalDuration'] = (agg['totalDuration'] as double) + dur;
      if (dist > 0 && dur > 0) {
        final pace = dur / dist;
        if (pace < (agg['maxPace'] as double)) {
          agg['maxPace'] = pace;
        }
      }

      // Update Set Count
      agg['setCount'] += 1;
    }

    // Return as chronologically sorted list
    final resultList = sessionAggregates.values.toList();
    for (var r in resultList) {
      if (r['maxPace'] == double.infinity) {
        r['maxPace'] = 0.0;
      }
    }
    resultList.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return resultList;
  }

  /// Returns the most recently updated all-time weight PRs across all exercises.
  ///
  /// For each exercise, the set with the highest recorded weight is returned.
  /// Results are sorted by the workout date of the latest session in which
  /// that PR weight was achieved, so recently active exercises appear first.
  ///
  /// Each entry contains: 'exerciseName' (String), 'weight' (double), 'reps' (int).
  Future<List<Map<String, dynamic>>> getRecentGlobalPRs({int limit = 3}) async {
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;

    final rows = await dbInstance.customSelect(
      '''
      SELECT
        s1.exercise_name_snapshot AS exerciseName,
        s1.weight                 AS weight,
        s1.reps                   AS reps
      FROM set_logs s1
      JOIN workout_logs wl ON wl.id = s1.workout_log_id
      LEFT JOIN exercises e ON e.id = s1.exercise_id
      WHERE s1.is_completed = 1
        AND s1.set_type != 'warmup'
        AND s1.weight > 0
        AND s1.reps  > 0
        AND wl.status = 'completed'
        AND (e.category_name IS NULL OR e.category_name COLLATE NOCASE != 'cardio')
        AND s1.weight = (
          SELECT MAX(s2.weight)
          FROM set_logs s2
          WHERE s2.exercise_name_snapshot = s1.exercise_name_snapshot
            AND s2.is_completed = 1
            AND s2.set_type != 'warmup'
            AND s2.weight > 0
        )
      GROUP BY s1.exercise_name_snapshot
      ORDER BY MAX(wl.start_time) DESC
      LIMIT ?
      ''',
      variables: [drift.Variable.withInt(limit)],
    ).get();

    final result = rows
        .map(
          (row) => {
            'exerciseName': row.read<String>('exerciseName'),
            'weight': row.read<double>('weight'),
            'reps': row.read<int>('reps'),
          },
        )
        .toList();
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getRecentGlobalPRs',
      elapsed: stopwatch.elapsed,
      fields: {'rows': rows.length, 'resultRows': result.length},
    );
    return result;
  }

  /// Weekly tonnage (kg) for the last [weeksBack] weeks.
  /// Each entry: {weekStart: DateTime, weekLabel: String, tonnage: double, setCount: int}
  Future<List<Map<String, dynamic>>> getWeeklyVolumeData({
    int weeksBack = 8,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();
    final since = now.subtract(Duration(days: weeksBack * 7));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        (dbInstance.exercises.categoryName.isNull() |
                dbInstance.exercises.categoryName
                    .lower()
                    .isNotValue('cardio')) &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      )
      ..orderBy([
        drift.OrderingTerm(expression: dbInstance.workoutLogs.startTime),
      ]);

    final rows = await query.get();

    final Map<String, Map<String, dynamic>> weekMap = {};

    void ensureWeek(DateTime date) {
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      weekMap.putIfAbsent(
        key,
        () => {
          'weekStart': mondayNorm,
          'weekLabel': '${mondayNorm.day}.${mondayNorm.month}.',
          'tonnage': 0.0,
          'setCount': 0,
        },
      );
    }

    // Pre-fill all weeks so missing weeks show as 0
    for (int w = 0; w < weeksBack; w++) {
      ensureWeek(now.subtract(Duration(days: w * 7)));
    }

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final date = logRow.startTime;
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';

      ensureWeek(date);

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      weekMap[key]!['tonnage'] =
          (weekMap[key]!['tonnage'] as double) + weight * reps;
      weekMap[key]!['setCount'] = (weekMap[key]!['setCount'] as int) + 1;
    }

    final result = weekMap.values.toList()
      ..sort(
        (a, b) =>
            (a['weekStart'] as DateTime).compareTo(b['weekStart'] as DateTime),
      );
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getWeeklyVolumeData',
      elapsed: stopwatch.elapsed,
      fields: {'rows': rows.length, 'weeks': weeksBack},
    );
    return result;
  }

  /// Volume (tonnage) grouped by primary muscle group for the last [daysBack] days.
  /// Returns list sorted descending by tonnage: {muscleGroup: String, tonnage: double}
  Future<List<Map<String, dynamic>>> getVolumeByMuscleGroup({
    int daysBack = 30,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;
    final muscleLookup = await _loadExerciseMuscleLookup(dbInstance);

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();
    final tonnageByMuscle = <String, double>{};

    for (final row in rows) {
      final setRow = row.readTable(dbInstance.setLogs);
      final exRow = row.readTableOrNull(dbInstance.exercises);
      final profile = _resolveExerciseMuscleProfile(
        lookup: muscleLookup,
        exerciseRow: exRow,
        exerciseNameSnapshot: setRow.exerciseNameSnapshot,
      );

      final tonnage = (setRow.weight ?? 0.0) * (setRow.reps ?? 0);
      final muscles = profile?.primary ?? const <String>[];

      if (muscles.isEmpty) {
        tonnageByMuscle['Other'] = (tonnageByMuscle['Other'] ?? 0.0) + tonnage;
        continue;
      }

      for (final muscle in muscles) {
        tonnageByMuscle[muscle] = (tonnageByMuscle[muscle] ?? 0.0) + tonnage;
      }
    }

    return tonnageByMuscle.entries
        .map((entry) => {
              'muscleGroup': entry.key,
              'tonnage': entry.value,
            })
        .toList()
      ..sort(
          (a, b) => (b['tonnage'] as double).compareTo(a['tonnage'] as double));
  }

  /// Equivalent hard-set analytics for muscle groups.
  Future<Map<String, dynamic>> getMuscleGroupAnalytics({
    int daysBack = 30,
    int weeksBack = 8,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;
    final muscleLookup = await _loadExerciseMuscleLookup(dbInstance);

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();

    // Map QueryRows to simple data objects for Isolate transfer
    final rawData = rows.map((row) {
      final logRow = row.readTable(dbInstance.workoutLogs);
      final setRow = row.readTable(dbInstance.setLogs);
      final exRow = row.readTableOrNull(dbInstance.exercises);
      final profile = _resolveExerciseMuscleProfile(
        lookup: muscleLookup,
        exerciseRow: exRow,
        exerciseNameSnapshot: setRow.exerciseNameSnapshot,
      );
      return MuscleContributionRawData(
        startTime: logRow.startTime,
        musclesPrimary: profile == null
            ? exRow?.musclesPrimary
            : jsonEncode(profile.primary),
        musclesSecondary: profile == null
            ? exRow?.musclesSecondary
            : jsonEncode(profile.secondary),
        modality: exRow?.modality,
        categoryName: exRow?.categoryName,
        setType: setRow.setType,
        exerciseNameSnapshot: setRow.exerciseNameSnapshot,
        reps: setRow.reps ?? 0,
      );
    }).toList(growable: false);

    final result = await compute(
      _processMuscleGroupAnalyticsInBackground,
      MuscleAnalyticsBackgroundTaskParams(
        rows: rawData,
        daysBack: daysBack,
        weeksBack: weeksBack,
        now: now,
      ),
    );

    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getMuscleGroupAnalytics',
      elapsed: stopwatch.elapsed,
      fields: {
        'rows': rows.length,
        'range': '${daysBack}d',
      },
    );
    return result;
  }

  static Map<String, dynamic> _processMuscleGroupAnalyticsInBackground(
    MuscleAnalyticsBackgroundTaskParams params,
  ) {
    final contributions = <Map<String, dynamic>>[];

    for (final row in params.rows) {
      // Volume had no such filter at all until now. With v2 that stops being
      // survivable: every one of the 122 stretch and mobility exercises now
      // carries a muscle annotation, and 120 of them wear a body region as
      // their category_name, so the old cardio heuristic never saw one.
      if (!WorkoutClassification.countsTowardsMuscleLoad(
        modality: row.modality,
        setType: row.setType,
        categoryName: row.categoryName,
        exerciseNameSnapshot: row.exerciseNameSnapshot,
        reps: row.reps,
      )) {
        continue;
      }

      final primary = <String>{
        ...WorkoutLocalDataSource._parseMuscleList(
          row.musclesPrimary,
        ).map((m) => m.trim()).where((m) => m.isNotEmpty),
      };
      final secondary = <String>{
        ...WorkoutLocalDataSource._parseMuscleList(
          row.musclesSecondary,
        ).map((m) => m.trim()).where((m) => m.isNotEmpty),
      }..removeAll(primary);

      // Map each raw muscle name to a canonical major group.
      bool anyMapped = false;
      for (final muscle in primary) {
        final majorGroup = RecoveryDomainService.majorMuscleGroupFor(muscle);
        if (majorGroup == null) continue;
        contributions.add({
          'day': row.startTime,
          'muscleGroup': majorGroup,
          'equivalentSets': 1.0,
        });
        anyMapped = true;
      }

      for (final muscle in secondary) {
        final majorGroup = RecoveryDomainService.majorMuscleGroupFor(muscle);
        if (majorGroup == null) continue;
        contributions.add({
          'day': row.startTime,
          'muscleGroup': majorGroup,
          'equivalentSets': 0.3,
        });
        anyMapped = true;
      }

      // If no muscles mapped (e.g. exercise has no tagged muscles), skip.
      if (!anyMapped) continue;
    } // end for (final row in params.rows)

    return MuscleAnalyticsUtils.buildSummary(
      contributions: contributions,
      daysBack: params.daysBack,
      weeksBack: params.weeksBack,
      now: params.now,
    );
  }

  /// Recovery analytics based on shared v1 heuristics.
  Future<Map<String, dynamic>> getRecoveryAnalytics({
    int lookbackDays = RecoveryDomainService.recoveryLookbackDays,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();
    final since = now.subtract(Duration(days: lookbackDays));
    final dbInstance = await database;
    final muscleLookup = await _loadExerciseMuscleLookup(dbInstance);

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();

    final Map<String, Map<String, dynamic>> muscleSessionMap = {};

    void addMuscleContribution({
      required String workoutLogId,
      required DateTime startTime,
      required String muscle,
      required double equivalentSets,
      required int? rir,
      required int? rpe,
    }) {
      final normalizedMuscle = muscle.trim();
      if (normalizedMuscle.isEmpty) return;

      final key = '$workoutLogId::$normalizedMuscle';
      final session = muscleSessionMap.putIfAbsent(
        key,
        () => {
          'muscleGroup': normalizedMuscle,
          'workoutLogId': workoutLogId,
          'startTime': startTime,
          'equivalentSets': 0.0,
          'rirSum': 0.0,
          'rirCount': 0,
          'rpeSum': 0.0,
          'rpeCount': 0,
        },
      );

      session['equivalentSets'] =
          (session['equivalentSets'] as double) + equivalentSets;

      if (rir != null) {
        session['rirSum'] = (session['rirSum'] as double) + rir;
        session['rirCount'] = (session['rirCount'] as int) + 1;
      }

      if (rpe != null) {
        session['rpeSum'] = (session['rpeSum'] as double) + rpe;
        session['rpeCount'] = (session['rpeCount'] as int) + 1;
      }
    }

    for (final row in rows) {
      final logRow = row.readTable(dbInstance.workoutLogs);
      final setRow = row.readTable(dbInstance.setLogs);
      final exRow = row.readTableOrNull(dbInstance.exercises);
      final profile = _resolveExerciseMuscleProfile(
        lookup: muscleLookup,
        exerciseRow: exRow,
        exerciseNameSnapshot: setRow.exerciseNameSnapshot,
      );

      if (!WorkoutLocalDataSource._isRecoveryStrengthWorkSet(
          setRow: setRow, exerciseRow: exRow)) {
        continue;
      }

      final primary = profile == null ? <String>{} : profile.primary.toSet();
      final secondary = profile == null ? <String>{} : profile.secondary.toSet()
        ..removeAll(primary);

      for (final muscle in primary) {
        final majorGroup = RecoveryDomainService.majorMuscleGroupFor(muscle);
        if (majorGroup == null) continue;
        addMuscleContribution(
          workoutLogId: logRow.id,
          startTime: logRow.startTime,
          muscle: majorGroup,
          equivalentSets: 1.0,
          rir: setRow.rir,
          rpe: setRow.rpe,
        );
      }

      for (final muscle in secondary) {
        final majorGroup = RecoveryDomainService.majorMuscleGroupFor(muscle);
        if (majorGroup == null) continue;
        addMuscleContribution(
          workoutLogId: logRow.id,
          startTime: logRow.startTime,
          muscle: majorGroup,
          equivalentSets: 0.3,
          rir: setRow.rir,
          rpe: setRow.rpe,
        );
      }
    }

    final Map<String, List<Map<String, dynamic>>> significantByMuscle = {};

    // Master tracking array containing all 13 muscle groups.
    final List<String> masterTrackingArray = [
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
      'adductors',
      'lower back',
      'forearms',
    ];

    for (final muscle in masterTrackingArray) {
      significantByMuscle.putIfAbsent(muscle, () => []);
    }

    for (final session in muscleSessionMap.values) {
      final eqSets = (session['equivalentSets'] as double);
      if (eqSets < RecoveryDomainService.minimumSignificantEquivalentSets) {
        continue;
      }

      final rawMuscle = session['muscleGroup'] as String;
      final majorGroup = RecoveryDomainService.majorMuscleGroupFor(rawMuscle);
      if (majorGroup == null) continue; // discard unmapped muscle

      significantByMuscle.putIfAbsent(majorGroup, () => []).add(session);
    }

    final List<Map<String, dynamic>> muscles = [];

    for (final entry in significantByMuscle.entries) {
      final muscle = entry.key;
      final sessions = entry.value;

      if (sessions.isEmpty) {
        final recoveringUpper = RecoveryDomainService.recoveringUpperHours(
          highSessionFatigue: false,
          muscleGroup: muscle,
          lastEquivalentSets: 0.0,
        );
        final readyUpper = RecoveryDomainService.readyUpperHours(
          highSessionFatigue: false,
          muscleGroup: muscle,
          lastEquivalentSets: 0.0,
        );
        muscles.add({
          'muscleGroup': muscle,
          'state': RecoveryDomainService.stateFresh,
          'hoursSinceLastSignificantLoad': 999.0,
          'lastSignificantLoadAt': null,
          'lastEquivalentSets': 0.0,
          'avgRir': null,
          'avgRpe': null,
          'highSessionFatigue': false,
          'recoveringUpperHours': recoveringUpper,
          'readyUpperHours': readyUpper,
        });
        continue;
      }

      sessions.sort(
        (a, b) =>
            (b['startTime'] as DateTime).compareTo(a['startTime'] as DateTime),
      );

      final mostRecentSession = sessions.first;
      final lastTime = mostRecentSession['startTime'] as DateTime;
      final hoursSince = now.difference(lastTime).inMinutes / 60.0;

      final totalEquivalentSets = sessions.fold<double>(
        0.0,
        (sum, s) => sum + (s['equivalentSets'] as double),
      );

      final rirCount = mostRecentSession['rirCount'] as int;
      final rpeCount = mostRecentSession['rpeCount'] as int;
      final avgRir = rirCount > 0
          ? (mostRecentSession['rirSum'] as double) / rirCount
          : null;
      final avgRpe = rpeCount > 0
          ? (mostRecentSession['rpeSum'] as double) / rpeCount
          : null;

      bool highSessionFatigue = RecoveryDomainService.hasHighSessionFatigue(
        avgRir: avgRir,
        avgRpe: avgRpe,
      );
      for (final s in sessions.skip(1)) {
        final rc = s['rirCount'] as int;
        final pc = s['rpeCount'] as int;
        final r = rc > 0 ? (s['rirSum'] as double) / rc : null;
        final p = pc > 0 ? (s['rpeSum'] as double) / pc : null;
        if (RecoveryDomainService.hasHighSessionFatigue(avgRir: r, avgRpe: p)) {
          highSessionFatigue = true;
          break;
        }
      }

      final recoveringUpper = RecoveryDomainService.recoveringUpperHours(
        highSessionFatigue: highSessionFatigue,
        muscleGroup: muscle,
        lastEquivalentSets: totalEquivalentSets,
      );
      final readyUpper = RecoveryDomainService.readyUpperHours(
        highSessionFatigue: highSessionFatigue,
        muscleGroup: muscle,
        lastEquivalentSets: totalEquivalentSets,
      );

      final state = RecoveryDomainService.muscleState(
        hoursSinceLastSignificantLoad: hoursSince,
        highSessionFatigue: highSessionFatigue,
        muscleGroup: muscle,
        lastEquivalentSets: totalEquivalentSets,
      );

      muscles.add({
        'muscleGroup': muscle,
        'state': state,
        'hoursSinceLastSignificantLoad': hoursSince,
        'lastSignificantLoadAt': lastTime,
        'lastEquivalentSets': totalEquivalentSets,
        'avgRir': avgRir,
        'avgRpe': avgRpe,
        'highSessionFatigue': highSessionFatigue,
        'recoveringUpperHours': recoveringUpper,
        'readyUpperHours': readyUpper,
      });
    }

    muscles.sort((a, b) {
      const stateOrder = {
        RecoveryDomainService.stateRecovering: 0,
        RecoveryDomainService.stateReady: 1,
        RecoveryDomainService.stateFresh: 2,
      };
      final stateCmp = (stateOrder[a['state'] as String] ?? 9).compareTo(
        stateOrder[b['state'] as String] ?? 9,
      );
      if (stateCmp != 0) return stateCmp;
      return ((a['hoursSinceLastSignificantLoad'] as num).toDouble()).compareTo(
        (b['hoursSinceLastSignificantLoad'] as num).toDouble(),
      );
    });

    final hasData = muscles.any((m) => m['lastSignificantLoadAt'] != null);

    final recoveringCount = muscles
        .where((m) => m['state'] == RecoveryDomainService.stateRecovering)
        .length;
    final readyCount = muscles
        .where((m) => m['state'] == RecoveryDomainService.stateReady)
        .length;
    final freshCount = muscles
        .where((m) => m['state'] == RecoveryDomainService.stateFresh)
        .length;
    final total = muscles.length;

    final overallState = RecoveryDomainService.overallState(
      totalTrackedMuscles: total,
      recoveringCount: recoveringCount,
    );

    final result = {
      'hasData': hasData,
      'overallState': hasData
          ? overallState
          : RecoveryDomainService.overallInsufficientData,
      'totals': {
        RecoveryDomainService.stateRecovering: hasData ? recoveringCount : 0,
        RecoveryDomainService.stateReady: hasData ? readyCount : 0,
        RecoveryDomainService.stateFresh: hasData ? freshCount : 0,
        'tracked': hasData ? total : 0,
      },
      'muscles': hasData ? muscles : <Map<String, dynamic>>[],
    };
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getRecoveryAnalytics',
      elapsed: stopwatch.elapsed,
      fields: {
        'rows': rows.length,
        'muscles': muscles.length,
        'range': '${lookbackDays}d',
      },
    );
    return result;
  }

  /// Top [limit] exercises by tonnage for the last [daysBack] days.
  Future<List<Map<String, dynamic>>> getTopExercisesByVolume({
    int daysBack = 30,
    int limit = 5,
  }) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();
    final Map<String, double> exVolume = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final name = setRow.exerciseNameSnapshot ?? 'Unknown';
      exVolume[name] =
          (exVolume[name] ?? 0.0) + (setRow.weight ?? 0.0) * (setRow.reps ?? 0);
    }

    return (exVolume.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(limit)
        .map((e) => {'exerciseName': e.key, 'tonnage': e.value})
        .toList();
  }

  /// Workouts logged per week for the last [weeksBack] weeks.
  Future<List<Map<String, dynamic>>> getWorkoutsPerWeek({
    int weeksBack = 12,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();
    final since = now.subtract(Duration(days: weeksBack * 7));
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          )
          ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime)]))
        .get();

    final Map<String, Map<String, dynamic>> weekMap = {};

    // Pre-fill all weeks
    for (int w = weeksBack - 1; w >= 0; w--) {
      final day = now.subtract(Duration(days: w * 7));
      final monday = day.subtract(Duration(days: day.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      weekMap[key] = {
        'weekStart': mondayNorm,
        'weekLabel': '${mondayNorm.day}.${mondayNorm.month}.',
        'count': 0,
      };
    }

    for (final row in rows) {
      final date = row.startTime;
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      if (weekMap.containsKey(key)) {
        weekMap[key]!['count'] = (weekMap[key]!['count'] as int) + 1;
      }
    }

    final result = weekMap.values.toList()
      ..sort(
        (a, b) =>
            (a['weekStart'] as DateTime).compareTo(b['weekStart'] as DateTime),
      );
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getWorkoutsPerWeek',
      elapsed: stopwatch.elapsed,
      fields: {'rows': rows.length, 'weeks': weeksBack},
    );
    return result;
  }

  /// Returns per-week consistency metrics for the last [weeksBack] weeks.
  Future<List<Map<String, dynamic>>> getWeeklyConsistencyMetrics({
    int weeksBack = 12,
    DateTime? untilDate,
  }) async {
    final stopwatch = Stopwatch()..start();
    final effectiveUntil = untilDate ?? DateTime.now();
    final since = effectiveUntil.subtract(Duration(days: weeksBack * 7));
    final dbInstance = await database;

    final weekMap = <String, Map<String, dynamic>>{};

    void ensureWeek(DateTime date) {
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';
      weekMap.putIfAbsent(
        key,
        () => {
          'weekStart': mondayNorm,
          'weekLabel': '${mondayNorm.day}.${mondayNorm.month}.',
          'count': 0,
          'durationMinutes': 0.0,
          'tonnage': 0.0,
        },
      );
    }

    for (int w = weeksBack - 1; w >= 0; w--) {
      ensureWeek(effectiveUntil.subtract(Duration(days: w * 7)));
    }

    final workoutRows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  effectiveUntil.add(const Duration(days: 1)),
                ),
          )
          ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime)]))
        .get();

    for (final row in workoutRows) {
      final start = row.startTime;
      ensureWeek(start);

      final monday = start.subtract(Duration(days: start.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';

      final durationMinutes = row.endTime == null
          ? 0.0
          : row.endTime!
                  .difference(start)
                  .inSeconds
                  .clamp(0, 24 * 60 * 60)
                  .toDouble() /
              60.0;

      weekMap[key]!['count'] = (weekMap[key]!['count'] as int) + 1;
      weekMap[key]!['durationMinutes'] =
          (weekMap[key]!['durationMinutes'] as double) + durationMinutes;
    }

    final tonnageRows = await (dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
          ..where(
            dbInstance.setLogs.isCompleted.equals(true) &
                dbInstance.setLogs.setType.isNotIn(['warmup']) &
                dbInstance.setLogs.weight.isBiggerThanValue(0) &
                dbInstance.setLogs.reps.isBiggerThanValue(0) &
                dbInstance.workoutLogs.status.equals('completed') &
                dbInstance.workoutLogs.startTime.isBetweenValues(
                  since,
                  effectiveUntil.add(const Duration(days: 1)),
                ),
          ))
        .get();

    for (final row in tonnageRows) {
      final setRow = row.readTable(dbInstance.setLogs);
      final logRow = row.readTable(dbInstance.workoutLogs);
      final start = logRow.startTime;
      ensureWeek(start);

      final monday = start.subtract(Duration(days: start.weekday - 1));
      final mondayNorm = DateTime(monday.year, monday.month, monday.day);
      final key =
          '${mondayNorm.year}-${mondayNorm.month.toString().padLeft(2, '0')}-${mondayNorm.day.toString().padLeft(2, '0')}';

      final tonnage = (setRow.weight ?? 0.0) * (setRow.reps ?? 0);
      weekMap[key]!['tonnage'] = (weekMap[key]!['tonnage'] as double) + tonnage;
    }

    final result = weekMap.values.toList()
      ..sort(
        (a, b) =>
            (a['weekStart'] as DateTime).compareTo(b['weekStart'] as DateTime),
      );
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getWeeklyConsistencyMetrics',
      elapsed: stopwatch.elapsed,
      fields: {
        'workoutRows': workoutRows.length,
        'setRows': tonnageRows.length,
        'weeks': weeksBack,
      },
    );
    return result;
  }

  /// Returns key training stats.
  Future<Map<String, dynamic>> getTrainingStats() async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();
    final dbInstance = await database;

    final allLogs = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.startTime,
                  mode: drift.OrderingMode.desc,
                ),
          ]))
        .get();

    final totalWorkouts = allLogs.length;

    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final thisWeekCount = allLogs
        .where(
          (r) =>
              !r.startTime.isBefore(thisMonday) &&
              r.startTime.isBefore(thisMonday.add(const Duration(days: 7))),
        )
        .length;

    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final last4Count =
        allLogs.where((r) => r.startTime.isAfter(fourWeeksAgo)).length;
    final avgPerWeek = last4Count / 4.0;

    // Current weekly streak
    int streakWeeks = 0;
    for (int w = 0; w < 52; w++) {
      final weekStart = thisMonday.subtract(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final hasWorkout = allLogs.any(
        (r) =>
            !r.startTime.isBefore(weekStart) && r.startTime.isBefore(weekEnd),
      );
      if (hasWorkout) {
        streakWeeks++;
      } else {
        break;
      }
    }

    final result = {
      'totalWorkouts': totalWorkouts,
      'thisWeekCount': thisWeekCount,
      'avgPerWeek': avgPerWeek,
      'streakWeeks': streakWeeks,
    };
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getTrainingStats',
      elapsed: stopwatch.elapsed,
      fields: {'rows': allLogs.length},
    );
    return result;
  }

  /// Returns the set of dates that had completed workouts.
  Future<Set<DateTime>> getWorkoutDatesSet({int daysBack = 91}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          ))
        .get();

    return rows.map((r) {
      final d = r.startTime;
      return DateTime(d.year, d.month, d.day);
    }).toSet();
  }

  /// Returns workout counts per day.
  Future<Map<DateTime, int>> getWorkoutDayCounts({int daysBack = 120}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: daysBack));
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('completed') &
                tbl.startTime.isBetweenValues(
                  since,
                  now.add(const Duration(days: 1)),
                ),
          ))
        .get();

    final Map<DateTime, int> counts = {};
    for (final row in rows) {
      final d = row.startTime;
      final day = DateTime(d.year, d.month, d.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the all-time best set for each rep bracket across all exercises.
  Future<Map<String, Map<String, dynamic>?>> getAllTimePRsByRepBracket() async {
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed'),
      );

    final rows = await query.get();

    String bracket(int reps) {
      if (reps == 1) return '1 RM';
      if (reps <= 3) return '2–3 RM';
      if (reps <= 6) return '4–6 RM';
      if (reps <= 10) return '7–10 RM';
      if (reps <= 15) return '11–15 RM';
      return '15+ RM';
    }

    final result = <String, Map<String, dynamic>?>{
      '1 RM': null,
      '2–3 RM': null,
      '4–6 RM': null,
      '7–10 RM': null,
      '11–15 RM': null,
      '15+ RM': null,
    };

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final reps = setRow.reps ?? 0;
      final weight = setRow.weight ?? 0.0;
      if (reps <= 0 || weight <= 0) continue;

      final b = bracket(reps);
      final current = result[b];
      if (current == null || weight > (current['weight'] as double)) {
        result[b] = {
          'exerciseName': setRow.exerciseNameSnapshot ?? '',
          'weight': weight,
          'reps': reps,
        };
      }
    }

    return result;
  }

  /// Returns top all-time PR entries across exercises, sorted by weight desc.
  Future<List<Map<String, dynamic>>> getAllTimeGlobalPRs({
    int limit = 10,
  }) async {
    final dbInstance = await database;

    final rows = await dbInstance.customSelect(
      '''
      SELECT
        s1.exercise_name_snapshot AS exerciseName,
        s1.weight                 AS weight,
        s1.reps                   AS reps
      FROM set_logs s1
      JOIN workout_logs wl ON wl.id = s1.workout_log_id
      LEFT JOIN exercises e ON e.id = s1.exercise_id
      WHERE s1.is_completed = 1
        AND s1.set_type != 'warmup'
        AND s1.weight > 0
        AND s1.reps  > 0
        AND wl.status = 'completed'
        AND (e.category_name IS NULL OR e.category_name COLLATE NOCASE != 'cardio')
        AND s1.weight = (
          SELECT MAX(s2.weight)
          FROM set_logs s2
          WHERE s2.exercise_name_snapshot = s1.exercise_name_snapshot
            AND s2.is_completed = 1
            AND s2.set_type != 'warmup'
            AND s2.weight > 0
        )
      GROUP BY s1.exercise_name_snapshot
      ORDER BY s1.weight DESC
      LIMIT ?
      ''',
      variables: [drift.Variable.withInt(limit)],
    ).get();

    return rows
        .map(
          (row) => {
            'exerciseName': row.read<String>('exerciseName'),
            'weight': row.read<double>('weight'),
            'reps': row.read<int>('reps'),
          },
        )
        .toList();
  }

  /// Monthly volume buckets for the last [monthsBack] months.
  Future<List<Map<String, dynamic>>> getMonthlyVolumeData({
    int monthsBack = 6,
  }) async {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final since = DateTime(
      firstOfThisMonth.year,
      firstOfThisMonth.month - (monthsBack - 1),
      1,
    );
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        (dbInstance.exercises.categoryName.isNull() |
                dbInstance.exercises.categoryName
                    .lower()
                    .isNotValue('cardio')) &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ),
      )
      ..orderBy([
        drift.OrderingTerm(expression: dbInstance.workoutLogs.startTime),
      ]);

    final rows = await query.get();

    final Map<String, Map<String, dynamic>> monthMap = {};

    void ensureMonth(DateTime date) {
      final start = DateTime(date.year, date.month, 1);
      final key = '${start.year}-${start.month.toString().padLeft(2, '0')}';
      monthMap.putIfAbsent(
        key,
        () => {
          'monthStart': start,
          'monthLabel': '${start.month}/${start.year.toString().substring(2)}',
          'tonnage': 0.0,
          'setCount': 0,
        },
      );
    }

    for (int i = monthsBack - 1; i >= 0; i--) {
      ensureMonth(
        DateTime(firstOfThisMonth.year, firstOfThisMonth.month - i, 1),
      );
    }

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final monthStart = DateTime(
        logRow.startTime.year,
        logRow.startTime.month,
        1,
      );
      final key =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

      ensureMonth(logRow.startTime);

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      monthMap[key]!['tonnage'] =
          (monthMap[key]!['tonnage'] as double) + weight * reps;
      monthMap[key]!['setCount'] = (monthMap[key]!['setCount'] as int) + 1;
    }

    final result = monthMap.values.toList()
      ..sort(
        (a, b) => (a['monthStart'] as DateTime).compareTo(
          b['monthStart'] as DateTime,
        ),
      );
    return result;
  }

  /// Finds exercises with the strongest PR momentum.
  Future<List<Map<String, dynamic>>> getNotablePrImprovements({
    int daysWindow = 30,
    int limit = 5,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();
    final dbInstance = await database;

    DateTime previousStart;
    DateTime recentStart;

    if (daysWindow >= 3650) {
      final earliest = await (dbInstance.select(dbInstance.workoutLogs)
            ..where((tbl) => tbl.status.equals('completed'))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime)])
            ..limit(1))
          .getSingleOrNull();

      final t0 = earliest?.startTime ?? now.subtract(const Duration(days: 365));
      final lifetimeDays = now.difference(t0).inDays;
      final halfDays = (lifetimeDays / 2).floor();
      final midpoint = t0.add(Duration(days: halfDays));

      previousStart = t0;
      recentStart = midpoint;
    } else {
      recentStart = now.subtract(Duration(days: daysWindow));
      previousStart = recentStart.subtract(Duration(days: daysWindow));
    }

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),
    ])
      ..where(
        (dbInstance.exercises.categoryName.isNull() |
                dbInstance.exercises.categoryName
                    .lower()
                    .isNotValue('cardio')) &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0) &
            dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime.isBetweenValues(
              previousStart,
              now.add(const Duration(days: 1)),
            ),
      );

    final rows = await query.get();

    final Map<String, double> previousBest = {};
    final Map<String, double> recentBest = {};

    double e1rm(double weight, int reps) => weight * (1 + (reps / 30.0));

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final name = (setRow.exerciseNameSnapshot ?? '').trim();
      if (name.isEmpty) continue;

      final value = e1rm(setRow.weight ?? 0.0, setRow.reps ?? 0);
      if (value <= 0) continue;

      final isRecent = !logRow.startTime.isBefore(recentStart);
      if (isRecent) {
        if (value > (recentBest[name] ?? 0.0)) recentBest[name] = value;
      } else {
        if (value > (previousBest[name] ?? 0.0)) previousBest[name] = value;
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final entry in recentBest.entries) {
      final name = entry.key;
      final recent = entry.value;
      final previous = previousBest[name] ?? 0.0;
      if (previous <= 0 || recent <= previous) continue;

      final improvementPct = ((recent - previous) / previous) * 100;
      result.add({
        'exerciseName': name,
        'previousBestE1rm': previous,
        'recentBestE1rm': recent,
        'improvementPct': improvementPct,
      });
    }

    result.sort(
      (a, b) => (b['improvementPct'] as double).compareTo(
        a['improvementPct'] as double,
      ),
    );
    final limited = result.take(limit).toList();
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getNotablePrImprovements',
      elapsed: stopwatch.elapsed,
      fields: {
        'rows': rows.length,
        'resultRows': limited.length,
        'range': daysWindow >= 3650 ? 'all-time' : '${daysWindow}d',
      },
    );
    return limited;
  }

  Future<double> getAverageCompletedWorkoutsPerWeek({
    int weeksBack = 4,
    DateTime? now,
  }) async {
    final dbInstance = await database;
    final referenceTime = now ?? DateTime.now();
    final lookbackDays = weeksBack * 7;
    final start = referenceTime.subtract(Duration(days: lookbackDays));

    final countExpr = dbInstance.workoutLogs.id.count();
    final query = dbInstance.selectOnly(dbInstance.workoutLogs)
      ..addColumns([countExpr])
      ..where(dbInstance.workoutLogs.status.equals('completed'))
      ..where(dbInstance.workoutLogs.startTime.isBiggerOrEqualValue(start))
      ..where(dbInstance.workoutLogs.startTime
          .isSmallerOrEqualValue(referenceTime));

    final row = await query.getSingleOrNull();
    final completedCount = row?.read(countExpr) ?? 0;
    if (weeksBack <= 0) return 0;
    return completedCount / weeksBack;
  }
}

class _ExerciseMuscleLookup {
  final Map<String, _ExerciseMuscleProfile> byId;
  final Map<String, _ExerciseMuscleProfile> byName;

  const _ExerciseMuscleLookup({
    required this.byId,
    required this.byName,
  });
}

class _ExerciseMuscleProfile {
  final List<String> primary;
  final List<String> secondary;

  const _ExerciseMuscleProfile({
    required this.primary,
    required this.secondary,
  });
}
