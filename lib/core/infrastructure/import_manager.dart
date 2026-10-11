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
  final Map<int, String> exerciseNotesByBlock;
  final WorkoutImportProfile sourceProfile;
  final int skippedInvalidRows;

  WorkoutImportData({
    required this.title,
    this.notes,
    required this.startTime,
    this.endTime,
    required this.sets,
    this.exerciseNotesByBlock = const {},
    this.sourceProfile = WorkoutImportProfile.generic,
    this.skippedInvalidRows = 0,
  });
}

enum WorkoutImportProfile { hevy, strong, generic }

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
    Future<bool> Function(List<WorkoutImportData> workouts, int duplicateCount)?
        confirmImport,
  }) async {
    try {
      // 1. Select file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result.isEmpty || result.single.path == null) return -2;

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

      if (workoutGroups.isEmpty) return -1;

      // 3. Query existing completed workouts for deduplication
      final workoutHelper = WorkoutLocalDataSource.instance;
      final database = await workoutHelper.database;

      final existingLogs = await (database.select(database.workoutLogs)
            ..where((tbl) => tbl.status.equals('completed')))
          .get();

      final existingSignatures = <String>{
        for (final log in existingLogs)
          '${log.startTime.millisecondsSinceEpoch}_${log.routineNameSnapshot}',
      };

      // Filter out duplicate workouts that already exist
      final newWorkoutGroups = workoutGroups.where((group) {
        final sig = '${group.startTime.millisecondsSinceEpoch}_${group.title}';
        return !existingSignatures.contains(sig);
      }).toList();

      if (newWorkoutGroups.isEmpty) return 0;
      if (confirmImport != null &&
          !await confirmImport(
            newWorkoutGroups,
            workoutGroups.length - newWorkoutGroups.length,
          )) {
        return -2;
      }

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
          for (final entry in workoutData.exerciseNotesByBlock.entries) {
            await workoutHelper.saveWorkoutExerciseNote(
              workoutLogId: newLog.id!,
              exerciseBlock: entry.key,
              exerciseName: workoutData.sets
                  .firstWhere((set) => set.exerciseBlock == entry.key)
                  .exerciseName,
              notes: entry.value,
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
      exerciseBlock: drift.Value(setLog.exerciseBlock),
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
    final rawHeader = rows.first
        .map((e) => e
            .toString()
            .replaceFirst('\uFEFF', '')
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[ -]+'), '_'))
        .toList();
    final sourceProfile = _detectProfile(rawHeader);
    final headerMap = _mapHeader(rawHeader, sourceProfile);

    // Group rows (one workout has multiple sets across multiple rows).
    final workoutGroupsMap = <String, List<Map<String, dynamic>>>{};
    var skippedInvalidRows = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < rawHeader.length) {
        skippedInvalidRows++;
        continue;
      }

      final rowData = <String, dynamic>{};
      for (var entry in headerMap.entries) {
        final index = entry.value;
        if (index < row.length) {
          rowData[entry.key] = row[index];
        }
      }
      rowData['weight_is_lbs'] = headerMap.containsKey('weight_is_lbs');
      rowData['weight_has_explicit_unit'] =
          headerMap.containsKey('weight_is_lbs') ||
              headerMap.containsKey('weight_is_kg');
      rowData['distance_is_miles'] = headerMap.containsKey('distance_is_miles');
      rowData['distance_is_meters'] =
          headerMap.containsKey('distance_is_meters');

      final title = rowData['title']?.toString() ?? params.defaultWorkoutTitle;
      final startTimeRaw = rowData['start_time']?.toString() ?? '';

      if (startTimeRaw.trim().isEmpty || _parseDate(startTimeRaw) == null) {
        skippedInvalidRows++;
        continue;
      }

      final key = '${title}_${_parseDate(startTimeRaw)!.toIso8601String()}';
      workoutGroupsMap.putIfAbsent(key, () => []).add(rowData);
    }

    final List<WorkoutImportData> result = [];

    for (var group in workoutGroupsMap.values) {
      final firstRow = group.first;
      final title = firstRow['title']?.toString() ?? params.defaultWorkoutTitle;
      final notes = firstRow['description']?.toString();
      final startTime = _parseDate(firstRow['start_time']);
      if (startTime == null) continue;
      final exportedWorkoutDuration =
          _parseDurationSeconds(firstRow['workout_duration']);
      final endTime = _parseDate(firstRow['end_time']) ??
          (exportedWorkoutDuration == null
              ? null
              : startTime.add(Duration(seconds: exportedWorkoutDuration)));

      final List<SetLog> sets = [];
      final exerciseNotesByBlock = <int, String>{};
      int setOrder = 0;
      var nextBlock = 0;
      String? previousExercise;
      int? contiguousBlock;
      for (var row in group) {
        final rawSetType = row['set_type']?.toString().trim().toLowerCase();
        if (rawSetType == 'rest' || rawSetType == 'ruhezeit') {
          final restTimeSeconds = _parseDurationSeconds(row['duration']);
          if (sets.isNotEmpty && restTimeSeconds != null) {
            sets[sets.length - 1] =
                sets.last.copyWith(restTimeSeconds: restTimeSeconds);
          }
          continue;
        }

        final rawExerciseName =
            row['exercise']?.toString() ?? params.defaultExerciseName;
        final explicitBlock =
            int.tryParse(row['exercise_block']?.toString() ?? '');
        if (explicitBlock == null && rawExerciseName != previousExercise) {
          contiguousBlock = nextBlock++;
        }
        final exerciseBlock = explicitBlock ?? contiguousBlock ?? nextBlock++;
        if (explicitBlock != null && explicitBlock >= nextBlock) {
          nextBlock = explicitBlock + 1;
        }
        previousExercise = rawExerciseName;
        final note = row['workout_exercise_note']?.toString().trim();
        if (note != null && note.isNotEmpty) {
          exerciseNotesByBlock[exerciseBlock] = note;
        }

        double? weight = _parseNumber(row['weight']);
        final explicitWeightUnit =
            row['weight_unit']?.toString().trim().toLowerCase();
        final hasWeightUnit = explicitWeightUnit != null &&
            explicitWeightUnit.isNotEmpty &&
            (explicitWeightUnit == 'lb' ||
                explicitWeightUnit == 'lbs' ||
                explicitWeightUnit == 'pound' ||
                explicitWeightUnit == 'pounds' ||
                explicitWeightUnit == 'kg' ||
                explicitWeightUnit == 'kgs' ||
                explicitWeightUnit == 'kilogram' ||
                explicitWeightUnit == 'kilograms');
        final weightIsImperial = row['weight_is_lbs'] == true ||
            explicitWeightUnit == 'lb' ||
            explicitWeightUnit == 'lbs' ||
            explicitWeightUnit == 'pound' ||
            explicitWeightUnit == 'pounds' ||
            (!hasWeightUnit &&
                row['weight_has_explicit_unit'] != true &&
                isImperial);
        if (weight != null && weightIsImperial) {
          weight = UnitService.lbsToKg(weight);
        }

        var distance = _parseNumber(row['distance']);
        final explicitDistanceUnit =
            row['distance_unit']?.toString().toLowerCase();
        final distanceIsMiles = row['distance_is_miles'] == true ||
            explicitDistanceUnit == 'mi' ||
            explicitDistanceUnit == 'mile' ||
            explicitDistanceUnit == 'miles';
        final distanceIsMeters = row['distance_is_meters'] == true ||
            explicitDistanceUnit == 'm' ||
            explicitDistanceUnit == 'meter' ||
            explicitDistanceUnit == 'meters';
        if (distance != null && distanceIsMiles) {
          distance *= 1.609344;
        } else if (distance != null && distanceIsMeters) {
          distance /= 1000;
        }

        final duration = _parseDurationSeconds(row['duration']);

        sets.add(SetLog(
          workoutLogId: 0,
          exerciseName: rawExerciseName,
          setType: _mapSetType(row['set_type']),
          weightKg: weight,
          reps: _parseNumber(row['reps'])?.round(),
          distanceKm: distance,
          durationSeconds: duration,
          rpe: _parseNumber(row['rpe'])?.round(),
          rir: _parseNumber(row['rir'])?.round(),
          logOrder: setOrder++,
          exerciseBlock: exerciseBlock,
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
        exerciseNotesByBlock: exerciseNotesByBlock,
        sourceProfile: sourceProfile,
        skippedInvalidRows: skippedInvalidRows,
      ));
    }

    return result;
  }

  /// Maps generic headers to normalized internal keys.
  static Map<String, int> _mapHeader(
    List<String> header,
    WorkoutImportProfile profile,
  ) {
    final map = <String, int>{};

    for (var i = 0; i < header.length; i++) {
      final h = header[i];

      // Workout Meta
      if (['title', 'routine', 'workout', 'name', 'workout_name'].contains(h)) {
        map['title'] = i;
      } else if (['start_time', 'start', 'datum', 'date', 'workout_date']
          .contains(h)) {
        map['start_time'] = i;
      } else if (['end_time', 'end'].contains(h)) {
        map['end_time'] = i;
      } else if (['description', 'notiz', 'workout_notizen'].contains(h)) {
        map['description'] = i;
      } else if (['workout_notes', 'workout_comments'].contains(h)) {
        map['description'] = i;
      }
      // Exercise & Set
      else if ([
        'exercise_title',
        'exercise',
        'übung',
        'exercise_name',
        'name_der_übung'
      ].contains(h)) {
        map['exercise'] = i;
      } else if (['set_type', 'type', 'typ', 'reihenfolge_festlegen']
          .contains(h)) {
        map['set_type'] = i;
      } else if (['weight_kg', 'weight_lbs', 'weight', 'gewicht', 'mass', 'lbs']
          .contains(h)) {
        map['weight'] = i;
        if (h == 'weight_lbs' || h == 'lbs') map['weight_is_lbs'] = i;
        if (h == 'weight_kg') map['weight_is_kg'] = i;
      } else if (['weight_unit', 'unit'].contains(h)) {
        map['weight_unit'] = i;
      } else if ([
        'reps',
        'wiederholungen',
        'wiederholungen.',
        'wiederh.',
        'repetitionen',
        'repetition'
      ].contains(h)) {
        map['reps'] = i;
      } else if ([
        'distance_km',
        'distance_miles',
        'distance_mi',
        'distance_meters',
        'distance_m',
        'distance',
        'distanz',
        'entfernung'
      ].contains(h)) {
        map['distance'] = i;
        if (h == 'distance_miles' || h == 'distance_mi') {
          map['distance_is_miles'] = i;
        }
        if (h == 'distance_meters' || h == 'distance_m') {
          map['distance_is_meters'] = i;
        }
      } else if (['distance_unit'].contains(h)) {
        map['distance_unit'] = i;
      } else if (profile == WorkoutImportProfile.strong &&
          ['duration', 'dauer'].contains(h)) {
        map['workout_duration'] = i;
      } else if ([
        'duration_seconds',
        'seconds',
        'sekunden',
        'duration',
        'dauer',
        'zeit'
      ].contains(h)) {
        map['duration'] = i;
      } else if (['rpe'].contains(h)) {
        map['rpe'] = i;
      } else if (['rir', 'reps_in_reserve'].contains(h)) {
        map['rir'] = i;
      } else if (['exercise_notes', 'workout_exercise_note'].contains(h)) {
        map['workout_exercise_note'] = i;
      } else if (['set_notes', 'notes', 'notizen'].contains(h)) {
        map['set_notes'] = i;
      } else if (['exercise_workout_note'].contains(h)) {
        map['workout_exercise_note'] = i;
      } else if (['exercise_block'].contains(h)) {
        map['exercise_block'] = i;
      }
    }
    return map;
  }

  static String _mapSetType(dynamic rawType) {
    final t = rawType?.toString().toLowerCase().replaceAll(
              RegExp(r'[ _-]'),
              '',
            ) ??
        '';
    if (t.contains('warmup') || t == 'w') return 'warmup';
    if (t.contains('failure') || t == 'f') return 'failure';
    if (t.contains('dropset') || t.contains('drop_set') || t == 'd') {
      return 'dropset';
    }
    return 'normal';
  }

  static WorkoutImportProfile _detectProfile(List<String> headers) {
    final names = headers.toSet();
    if (names.contains('exercise_title') && names.contains('start_time')) {
      return WorkoutImportProfile.hevy;
    }
    if (names.contains('workout_name') &&
        (names.contains('exercise_name') || names.contains('name_der_übung')) &&
        (names.contains('date') || names.contains('datum'))) {
      return WorkoutImportProfile.strong;
    }
    return WorkoutImportProfile.generic;
  }

  static DateTime? _parseDate(dynamic rawDateString) {
    final dateString = rawDateString?.toString().trim();
    if (dateString == null || dateString.isEmpty) return null;
    final normalizedDateString = dateString.replaceAll(
      RegExp(r'(?<=[A-Za-zÄÖÜäöü])\.(?=\s|,)'),
      '',
    );

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
          return format.parse(normalizedDateString);
        } catch (_) {
          continue;
        }
      }
    }

    // Hevy's German export uses abbreviated month names with a trailing dot
    // (for example, "14 Okt. 2025, 07:25"), which intl's German parser does
    // not accept consistently across SDK versions.
    final germanMonthDate = RegExp(
      r'^(\d{1,2})\s+([A-Za-zÄÖÜäöü]+)\.?\s+(\d{4}),?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$',
      caseSensitive: false,
    ).firstMatch(dateString);
    if (germanMonthDate != null) {
      const germanMonths = {
        'jan': 1,
        'feb': 2,
        'mär': 3,
        'märz': 3,
        'mrz': 3,
        'apr': 4,
        'mai': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'sept': 9,
        'okt': 10,
        'nov': 11,
        'dez': 12,
      };
      final month = germanMonths[germanMonthDate.group(2)!.toLowerCase()];
      if (month != null) {
        return DateTime(
          int.parse(germanMonthDate.group(3)!),
          month,
          int.parse(germanMonthDate.group(1)!),
          int.parse(germanMonthDate.group(4)!),
          int.parse(germanMonthDate.group(5)!),
          int.tryParse(germanMonthDate.group(6) ?? '') ?? 0,
        );
      }
    }

    // Try ISO8601 as last resort
    try {
      return DateTime.parse(dateString);
    } catch (_) {}

    return null;
  }

  static double? _parseNumber(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim().replaceAll(',', '.');
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  static int? _parseDurationSeconds(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) return seconds;
    final numericSeconds = _parseNumber(value);
    if (numericSeconds != null) return numericSeconds.round();
    final parts = value.split(':');
    if (parts.length == 2 || parts.length == 3) {
      final numbers = parts.map(int.tryParse).toList();
      if (numbers.any((part) => part == null)) return null;
      if (parts.length == 2) return numbers[0]! * 60 + numbers[1]!;
      return numbers[0]! * 3600 + numbers[1]! * 60 + numbers[2]!;
    }
    final hours =
        RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(value)?.group(1);
    final minutes =
        RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(value)?.group(1);
    final remainingSeconds =
        RegExp(r'(\d+)\s*s', caseSensitive: false).firstMatch(value)?.group(1);
    if (hours != null || minutes != null || remainingSeconds != null) {
      return (int.tryParse(hours ?? '') ?? 0) * 3600 +
          (int.tryParse(minutes ?? '') ?? 0) * 60 +
          (int.tryParse(remainingSeconds ?? '') ?? 0);
    }
    return null;
  }
}
