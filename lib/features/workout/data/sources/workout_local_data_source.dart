import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;
import '../../../exercise_catalog/domain/exercise_locale_chain.dart';
import '../../../exercise_catalog/domain/muscle_vocabulary.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_log.dart';
import '../../domain/models/set_template.dart';
import '../../domain/models/workout_log.dart';
import '../../domain/classification/set_load.dart';
import '../../domain/classification/workout_classification.dart';
import '../../../statistics/domain/recovery_domain_service.dart';
import '../../../../core/media/app_media_store.dart';
import '../../../../util/muscle_analytics_utils.dart';
import '../../../../util/perf_debug_timer.dart';
import '../workout_photo_store.dart';

part 'parts/exercises_queries.dart';
part 'parts/routines_queries.dart';
part 'parts/workout_logging_queries.dart';
part 'parts/workout_stats_queries.dart';

class MuscleAnalyticsBackgroundTaskParams {
  final List<MuscleContributionRawData> rows;
  final int daysBack;
  final int weeksBack;
  final DateTime now;

  MuscleAnalyticsBackgroundTaskParams({
    required this.rows,
    required this.daysBack,
    required this.weeksBack,
    required this.now,
  });
}

class MuscleContributionRawData {
  final DateTime startTime;
  final String? musclesPrimary;
  final String? musclesSecondary;

  /// Carried into the isolate so volume can drop the sets that are not work on
  /// the annotated muscle. Null for pre-v2 rows and user exercises, where the
  /// old category/name heuristic still decides.
  final String? modality;
  final String? categoryName;
  final String? setType;
  final String? exerciseNameSnapshot;
  final int reps;
  final int durationSeconds;

  MuscleContributionRawData({
    required this.startTime,
    this.musclesPrimary,
    this.musclesSecondary,
    this.modality,
    this.categoryName,
    this.setType,
    this.exerciseNameSnapshot,
    this.reps = 0,
    this.durationSeconds = 0,
  });
}

/// Helper class for managing workout-specific data in the Drift database.
class WorkoutLocalDataSource {
  final db.AppDatabase _dbInstance;

  WorkoutLocalDataSource(this._dbInstance);
  WorkoutLocalDataSource.forTesting(this._dbInstance);
  static WorkoutLocalDataSource get instance =>
      DatabaseHelper.instance.workoutLocalDataSource;

  // Access the central Drift instance.
  Future<db.AppDatabase> get database async {
    return _dbInstance;
  }

  // ===========================================================================
  // HELPER METHODS (Mapping & IDs)
  // ===========================================================================

  /// Converts a local integer ID into the UUID used in relational references.
  Future<String?> _getUuidFromLocalId<T extends drift.Table, D>(
    drift.TableInfo<T, D> table,
    int localId,
  ) async {
    final dbInstance = await database;
    // Assumption: all relevant tables expose `localId` and `id` via HybridId.
    final query = dbInstance.select(table)
      ..where((tbl) => (tbl as dynamic).localId.equals(localId));
    final row = await query.getSingleOrNull();
    return (row as dynamic)?.id;
  }

  /// Converts a UUID back to its local integer ID when needed.
  Future<int?> _getLocalIdFromUuid<T extends drift.Table, D>(
    drift.TableInfo<T, D> table,
    String uuid,
  ) async {
    final dbInstance = await database;
    final query = dbInstance.select(table)
      ..where((tbl) => (tbl as dynamic).id.equals(uuid));
    final row = await query.getSingleOrNull();
    return (row as dynamic)?.localId;
  }

  static List<String> _parseMuscleList(String? jsonStr) {
    return WorkoutClassification.parseMuscleList(jsonStr);
  }

  static bool _isRecoveryStrengthWorkSet({
    required db.SetLog setRow,
    required db.Exercise? exerciseRow,
  }) {
    // nameDe/nameEn are no longer flat columns on exercises — use the snapshot
    // for cardio classification. categoryName is still available.
    return WorkoutClassification.isRecoveryStrengthWorkSet(
      modality: exerciseRow?.modality,
      setType: setRow.setType,
      categoryName: exerciseRow?.categoryName,
      nameDe: null,
      nameEn: null,
      exerciseNameSnapshot: setRow.exerciseNameSnapshot,
      reps: setRow.reps ?? 0,
      durationSeconds: setRow.durationSeconds ?? 0,
    );
  }

  SetLog _mapSetLogToModel(db.SetLog row, int workoutLogLocalId) {
    return SetLog(
      id: row.localId,
      workoutLogId: workoutLogLocalId,
      exerciseName: row.exerciseNameSnapshot ?? 'Unknown',
      setType: row.setType,
      weightKg: row.weight,
      reps: row.reps,
      restTimeSeconds: row.restTimeSeconds,
      isCompleted: row.isCompleted,
      logOrder: row.logOrder,
      exerciseBlock: row.exerciseBlock,
      supersetGroup: row.supersetGroup,
      notes: row.notes,
      distanceKm: row.distance,
      durationSeconds: row.durationSeconds,
      rpe: row.rpe,
      rir: row.rir,
    );
  }

  static List<String> _extractPhotoPaths(
    String? photoPath,
    String? photoExtraPaths,
  ) {
    if (photoPath == null || photoPath.isEmpty) return const [];
    final paths = <String>[photoPath];
    if (photoExtraPaths != null && photoExtraPaths.isNotEmpty) {
      try {
        final decoded = jsonDecode(photoExtraPaths);
        if (decoded is List) {
          paths.addAll(decoded.whereType<String>());
        }
      } catch (_) {}
    }
    return paths;
  }

  WorkoutLog _mapWorkoutLogWithSets(
    db.WorkoutLog logRow,
    List<db.SetLog> setRows,
  ) {
    return WorkoutLog(
      id: logRow.localId,
      routineName: logRow.routineNameSnapshot,
      routineId: logRow.routineId,
      startTime: logRow.startTime,
      endTime: logRow.endTime,
      notes: logRow.notes,
      photoPaths: _extractPhotoPaths(
        logRow.photoPath,
        logRow.photoExtraPaths,
      ),
      sets:
          setRows.map((row) => _mapSetLogToModel(row, logRow.localId)).toList(),
    );
  }

  Future<List<WorkoutLog>> _loadWorkoutLogsWithSets(
    List<db.WorkoutLog> logRows,
  ) async {
    if (logRows.isEmpty) return [];

    final dbInstance = await database;
    final localIdsByUuid = {
      for (final row in logRows) row.id: row.localId,
    };

    final allUuids = localIdsByUuid.keys.toList();
    final setRows = <db.SetLog>[];

    const chunkSize = 500;
    for (var i = 0; i < allUuids.length; i += chunkSize) {
      final chunk = allUuids.sublist(
        i,
        i + chunkSize > allUuids.length ? allUuids.length : i + chunkSize,
      );
      final batchSets = await (dbInstance.select(dbInstance.setLogs)
            ..where((tbl) => tbl.workoutLogId.isIn(chunk))
            ..orderBy([
              (t) => drift.OrderingTerm(expression: t.workoutLogId),
              (t) => drift.OrderingTerm(expression: t.logOrder),
            ]))
          .get();
      setRows.addAll(batchSets);
    }

    final setsByWorkoutUuid = <String, List<db.SetLog>>{};
    for (final setRow in setRows) {
      setsByWorkoutUuid.putIfAbsent(setRow.workoutLogId, () => []).add(setRow);
    }

    return logRows
        .map((row) => _mapWorkoutLogWithSets(
              row,
              setsByWorkoutUuid[row.id] ?? const <db.SetLog>[],
            ))
        .toList();
  }
}
