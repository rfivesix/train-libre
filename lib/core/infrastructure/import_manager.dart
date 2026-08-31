// lib/data/import_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:excel_community/excel_community.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../data/drift_database.dart' as db;
import '../../features/workout/domain/models/set_log.dart';
import '../../features/exercise_catalog/domain/models/exercise.dart';
import '../../services/unit_service.dart';

class WorkoutImportData {
  final String title;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final List<SetLog> sets;

  WorkoutImportData({
    required this.title,
    this.notes,
    required this.startTime,
    this.endTime,
    required this.sets,
  });
}

class ImportBackgroundTaskParams {
  final Uint8List fileBytes;
  final String extension;
  final bool isImperial;
  final String defaultWorkoutTitle;
  final String defaultExerciseName;

  ImportBackgroundTaskParams({
    required this.fileBytes,
    required this.extension,
    required this.isImperial,
    this.defaultWorkoutTitle = 'Imported Workout',
    this.defaultExerciseName = 'Unknown Exercise',
  });
}

/// Manager responsible for importing workout data from external sources (CSV/Excel).
class ImportManager {
  /// Imports workout data from a CSV or Excel file.
  ///
  /// [isImperial] if true, incoming weight values are treated as lbs and converted to kg.
  Future<int> importWorkoutFile({
    required bool isImperial,
    String? defaultWorkoutTitle,
    String? defaultExerciseName,
  }) async {
    try {
      // 1. Select file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result.isEmpty || result.single.path == null) return 0;

      final filePath = result.single.path!;
      final extension = result.single.extension?.toLowerCase() ?? '';
      final fileBytes = await File(filePath).readAsBytes();

      // 2. Offload decoding and grouping to background isolate
      final workoutGroups = await compute(
        decodeAndGroupWorkouts,
        ImportBackgroundTaskParams(
          fileBytes: fileBytes,
          extension: extension,
          isImperial: isImperial,
          defaultWorkoutTitle: defaultWorkoutTitle ?? 'Imported Workout',
          defaultExerciseName: defaultExerciseName ?? 'Unknown Exercise',
        ),
      );

      if (workoutGroups.isEmpty) return 0;

      // 3. Query existing completed workouts for deduplication
      final workoutHelper = WorkoutLocalDataSource.instance;
      final database = await workoutHelper.database;

      final existingLogs = await (database.select(database.workoutLogs)
            ..where((tbl) => tbl.status.equals('completed')))
          .get();

      final existingSignatures = <String>{
        for (final log in existingLogs)
          "${log.startTime.millisecondsSinceEpoch}",
      };

      // Filter out duplicate workouts that already exist
      final newWorkoutGroups = workoutGroups.where((group) {
        final sig = "${group.startTime.millisecondsSinceEpoch}";
        return !existingSignatures.contains(sig);
      }).toList();

      if (newWorkoutGroups.isEmpty) return 0;

      int importedWorkouts = 0;
      final exerciseCache = <String, Exercise?>{};

      // Pre-seed exercise cache for all unique exercise names in this import
      final uniqueExerciseNames = newWorkoutGroups
          .expand((g) => g.sets)
          .map((s) => s.exerciseName)
          .toSet();

      for (final exName in uniqueExerciseNames) {
        exerciseCache[exName] =
            await workoutHelper.getExactExerciseByName(exName);
      }

      await database.transaction(() async {
        for (var workoutData in newWorkoutGroups) {
          final newLog = await workoutHelper.startWorkout(
            routineName: workoutData.title,
          );

          if (newLog.id == null) continue;

          await (database.update(database.workoutLogs)
                ..where((tbl) => tbl.localId.equals(newLog.id!)))
              .write(db.WorkoutLogsCompanion(
            startTime: drift.Value(workoutData.startTime),
            endTime: drift.Value(workoutData.endTime),
            status: const drift.Value('completed'),
            notes: drift.Value(workoutData.notes),
          ));

          for (var set in workoutData.sets) {
            final cachedExercise = exerciseCache[set.exerciseName];
            final setWithCorrectId = set.copyWith(workoutLogId: newLog.id!);
            await _insertSetLogWithCachedExercise(
              database,
              setWithCorrectId,
              cachedExercise,
            );
          }
          importedWorkouts++;
        }
      });

      return importedWorkouts;
    } catch (e) {
      debugPrint("External Import Error: $e");
      return -1;
    }
  }

  static Future<void> _insertSetLogWithCachedExercise(
    db.AppDatabase database,
    SetLog setLog,
    Exercise? cachedExercise,
  ) async {
    final workoutLogUuid = await (database.select(database.workoutLogs)
          ..where((tbl) => tbl.localId.equals(setLog.workoutLogId))
          ..limit(1))
        .getSingleOrNull();

    if (workoutLogUuid == null) return;

    final companion = db.SetLogsCompanion(
      workoutLogId: drift.Value(workoutLogUuid.id),
      exerciseId: drift.Value(cachedExercise?.uuid),
      exerciseNameSnapshot: drift.Value(setLog.exerciseName),
      weight: drift.Value(setLog.weightKg),
      reps: drift.Value(setLog.reps),
      setType: drift.Value(setLog.setType),
      restTimeSeconds: drift.Value(setLog.restTimeSeconds),
      isCompleted: drift.Value(setLog.isCompleted ?? false),
      logOrder: drift.Value(setLog.logOrder ?? 0),
      notes: drift.Value(setLog.notes),
      distance: drift.Value(setLog.distanceKm),
      durationSeconds: drift.Value(setLog.durationSeconds),
      rpe: drift.Value(setLog.rpe),
      rir: drift.Value(setLog.rir),
    );

    await database.into(database.setLogs).insert(companion);

    if (cachedExercise?.uuid != null) {
      try {
        await database.customUpdate(
          'UPDATE exercises SET usage_count = usage_count + 1 WHERE id = ?',
          variables: [drift.Variable.withString(cachedExercise!.uuid!)],
          updates: {database.exercises},
        );
      } catch (_) {}
    }
  }

  @visibleForTesting
  static Future<List<WorkoutImportData>> decodeAndGroupWorkouts(
    ImportBackgroundTaskParams params,
  ) async {
    try {
      await initializeDateFormatting();
    } catch (e) {
      debugPrint("Failed to initialize date formatting in isolate: $e");
    }

    final extension = params.extension;
    final isImperial = params.isImperial;
    final bytes = params.fileBytes;

    List<List<dynamic>> rows = [];

    try {
      if (extension == 'csv') {
        final content = utf8.decode(bytes);
        rows = csv.decode(content);
      } else if (extension == 'xlsx') {
        final excel = xl.Excel.decodeBytes(bytes);
        // Take first sheet
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName]!;
        for (var row in sheet.rows) {
          rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Decoding Error in Isolate: $e");
      return [];
    }

    if (rows.length < 2) return [];

    // Map header and normalize
    final rawHeader =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final headerMap = _mapHeader(rawHeader);

    // Group rows (one workout has multiple sets across multiple rows).
    final workoutGroupsMap = <String, List<Map<String, dynamic>>>{};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < rawHeader.length) continue;

      final rowData = <String, dynamic>{};
      for (var entry in headerMap.entries) {
        final index = entry.value;
        if (index < row.length) {
          rowData[entry.key] = row[index];
        }
      }

      final title = rowData['title']?.toString() ?? params.defaultWorkoutTitle;
      final startTimeRaw = rowData['start_time']?.toString() ?? '';

      if (startTimeRaw.trim().isEmpty) continue;

      final key = "${title}_$startTimeRaw";
      workoutGroupsMap.putIfAbsent(key, () => []).add(rowData);
    }

    final List<WorkoutImportData> result = [];

    for (var group in workoutGroupsMap.values) {
      final firstRow = group.first;
      final title = firstRow['title']?.toString() ?? params.defaultWorkoutTitle;
      final notes = firstRow['description']?.toString();
      final startTime = _parseDate(firstRow['start_time']);
      final endTime = _parseDate(firstRow['end_time']);

      final List<SetLog> sets = [];
      int setOrder = 0;
      for (var row in group) {
        final rawExerciseName =
            row['exercise']?.toString() ?? params.defaultExerciseName;

        double? weight = double.tryParse(row['weight']?.toString() ?? '');
        if (weight != null && isImperial) {
          weight = UnitService.lbsToKg(weight);
        }

        sets.add(SetLog(
          workoutLogId: 0,
          exerciseName: rawExerciseName,
          setType: _mapSetType(row['set_type']),
          weightKg: weight,
          reps: int.tryParse(row['reps']?.toString() ?? ''),
          distanceKm: double.tryParse(row['distance']?.toString() ?? ''),
          durationSeconds: int.tryParse(row['duration']?.toString() ?? ''),
          rpe: int.tryParse(row['rpe']?.toString() ?? ''),
          logOrder: setOrder++,
          notes: row['set_notes']?.toString(),
          isCompleted: true,
        ));
      }

      result.add(WorkoutImportData(
        title: title,
        notes: notes,
        startTime: startTime,
        endTime: endTime,
        sets: sets,
      ));
    }

    return result;
  }

  /// Maps generic headers to normalized internal keys.
  static Map<String, int> _mapHeader(List<String> header) {
    final map = <String, int>{};

    for (var i = 0; i < header.length; i++) {
      final h = header[i];

      // Workout Meta
      if (['title', 'routine', 'workout', 'name'].contains(h)) {
        map['title'] = i;
      } else if (['start_time', 'start', 'datum', 'date'].contains(h)) {
        map['start_time'] = i;
      } else if (['end_time', 'end'].contains(h)) {
        map['end_time'] = i;
      } else if (['description', 'notes', 'notiz'].contains(h)) {
        map['description'] = i;
      }
      // Exercise & Set
      else if (['exercise_title', 'exercise', 'übung', 'exercise_name']
          .contains(h)) {
        map['exercise'] = i;
      } else if (['set_type', 'type', 'typ'].contains(h)) {
        map['set_type'] = i;
      } else if (['weight_kg', 'weight', 'gewicht', 'mass', 'lbs']
          .contains(h)) {
        map['weight'] = i;
      } else if (['reps', 'wiederholungen', 'repetitionen', 'repetition']
          .contains(h)) {
        map['reps'] = i;
      } else if (['distance_km', 'distance', 'distanz', 'entfernung']
          .contains(h)) {
        map['distance'] = i;
      } else if (['duration_seconds', 'duration', 'dauer', 'zeit']
          .contains(h)) {
        map['duration'] = i;
      } else if (['rpe'].contains(h)) {
        map['rpe'] = i;
      } else if (['exercise_notes', 'set_notes'].contains(h)) {
        map['set_notes'] = i;
      }
    }
    return map;
  }

  static String _mapSetType(dynamic rawType) {
    final t = rawType?.toString().toLowerCase() ?? '';
    if (t.contains('warmup') || t == 'w') return 'warmup';
    if (t.contains('failure') || t == 'f') return 'failure';
    if (t.contains('dropset') || t.contains('drop_set') || t == 'd') {
      return 'dropset';
    }
    return 'normal';
  }

  static DateTime _parseDate(dynamic rawDateString) {
    final dateString = rawDateString?.toString().trim();
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    final patterns = [
      'dd MMMM yyyy, HH:mm',
      'dd MMM yyyy, HH:mm',
      'd MMMM yyyy, HH:mm',
      'd MMM yyyy, HH:mm',
      'dd. MMMM yyyy, HH:mm',
      'dd. MMM yyyy, HH:mm',
      'd. MMMM yyyy, HH:mm',
      'd. MMM yyyy, HH:mm',
      'MMM dd, yyyy, HH:mm',
      'MMMM dd, yyyy, HH:mm',
      'MMM d, yyyy, HH:mm',
      'MMMM d, yyyy, HH:mm',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-ddTHH:mm:ss',
      'dd.MM.yyyy, HH:mm',
      'dd.MM.yyyy HH:mm',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy, HH:mm',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy, HH:mm',
    ];

    final locales = ['de_DE', 'en_US', 'en_GB', 'fr_FR', 'es_ES', null];

    for (final pattern in patterns) {
      for (final locale in locales) {
        try {
          final format = DateFormat(pattern, locale);
          return format.parse(dateString);
        } catch (_) {
          continue;
        }
      }
    }

    // Try ISO8601 as last resort
    try {
      return DateTime.parse(dateString);
    } catch (_) {}

    return DateTime.now();
  }
}
