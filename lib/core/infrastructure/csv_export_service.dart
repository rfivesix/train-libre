import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database_helper.dart';
import '../../features/diary/data/sources/diary_local_data_source.dart';
import '../../features/diary/data/sources/product_local_data_source.dart';
import '../../features/diary/domain/models/food_item.dart';
import '../../features/profile/data/sources/profile_local_data_source.dart';
import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../services/telemetry/telemetry_service.dart';

class CsvExportService {
  static final CsvExportService instance = CsvExportService();

  final DatabaseHelper _dbHelper;
  final DiaryLocalDataSource _diaryDb;
  final ProductLocalDataSource _productDb;
  final WorkoutLocalDataSource _workoutDb;
  final ProfileLocalDataSource _profileDb;

  CsvExportService({
    DatabaseHelper? dbHelper,
    DiaryLocalDataSource? diaryDb,
    ProductLocalDataSource? productDb,
    WorkoutLocalDataSource? workoutDb,
    ProfileLocalDataSource? profileDb,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _diaryDb = diaryDb ??
            DiaryLocalDataSource(
                (dbHelper ?? DatabaseHelper.instance).dbInstance),
        _productDb = productDb ??
            ProductLocalDataSource(
                (dbHelper ?? DatabaseHelper.instance).dbInstance),
        _workoutDb = workoutDb ??
            WorkoutLocalDataSource(
                (dbHelper ?? DatabaseHelper.instance).dbInstance),
        _profileDb = profileDb ??
            ProfileLocalDataSource(
                (dbHelper ?? DatabaseHelper.instance).dbInstance);

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
        0, 0, math.max(1, logicalSize.width), math.max(1, logicalSize.height));
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Removing staged CSV export failed: $e');
    }
  }

  Future<Map<String, double>?> _getWorkoutHeartRate(
      String workoutLogId, DateTime startTime, DateTime endTime) async {
    final dbInst = _dbHelper.dbInstance;
    // 1. Try to read from cardio_samples
    try {
      final rows = await dbInst.customSelect('''
        SELECT s.data_json
        FROM cardio_activities a
        JOIN cardio_samples s ON a.id = s.cardio_activity_id
        WHERE a.workout_log_id = ? AND s.data_type = 'HeartRate'
      ''', variables: [drift.Variable<String>(workoutLogId)]).get();
      if (rows.isNotEmpty) {
        final dataJson = rows.first.read<String>('data_json');
        final decoded = jsonDecode(dataJson);
        if (decoded is List && decoded.isNotEmpty) {
          double min = double.infinity;
          double max = double.negativeInfinity;
          double sum = 0;
          int count = 0;
          for (final item in decoded) {
            double? bpm;
            if (item is num) {
              bpm = item.toDouble();
            } else if (item is Map) {
              bpm = (item['bpm'] ?? item['value'])?.toDouble();
            }
            if (bpm != null && bpm > 0) {
              min = math.min(min, bpm);
              max = math.max(max, bpm);
              sum += bpm;
              count++;
            }
          }
          if (count > 0) {
            return {'min': min, 'max': max, 'avg': sum / count};
          }
        }
      }
    } catch (e) {
      debugPrint('_getWorkoutHeartRate cardio_samples error: $e');
    }

    // 2. Fallback to overlapping pulse aggregates
    try {
      final startMs = startTime.millisecondsSinceEpoch;
      final endMs = endTime.millisecondsSinceEpoch;
      final rows = await dbInst.customSelect('''
        SELECT min_bpm, max_bpm, sum_bpm, sample_count
        FROM pulse_hourly_aggregates
        WHERE bucket_end_ms > ? AND bucket_start_ms < ?
      ''', variables: [
        drift.Variable<int>(startMs),
        drift.Variable<int>(endMs)
      ]).get();
      if (rows.isNotEmpty) {
        double min = double.infinity;
        double max = double.negativeInfinity;
        double sum = 0;
        int totalCount = 0;
        for (final r in rows) {
          final count = r.read<num>('sample_count').toInt();
          if (count > 0) {
            min = math.min(min, r.read<double>('min_bpm'));
            max = math.max(max, r.read<double>('max_bpm'));
            sum += r.read<double>('sum_bpm');
            totalCount += count;
          }
        }
        if (totalCount > 0) {
          return {'min': min, 'max': max, 'avg': sum / totalCount};
        }
      }
    } catch (e) {
      debugPrint('_getWorkoutHeartRate pulse_hourly_aggregates error: $e');
    }

    return null;
  }

  Future<bool> exportNutritionAsCsv() async {
    final entries = await _diaryDb.getAllFoodEntries();
    final fluidEntries = await _diaryDb.getAllFluidEntries();
    if (entries.isEmpty && fluidEntries.isEmpty) return false;

    // O(N) single-pass iteration to extract unique IDs without intermediate list allocations
    final Set<int> archiveIdsSet = {};
    final Set<String> barcodesSet = {};

    for (final entry in entries) {
      if (entry.archiveLocalId != null) {
        archiveIdsSet.add(entry.archiveLocalId!);
      } else {
        barcodesSet.add(entry.barcode);
      }
    }

    final Map<int, FoodItem> archiveProductsMap = {};
    final Map<String, FoodItem> legacyProductsMap = {};

    if (archiveIdsSet.isNotEmpty) {
      final archiveIds = archiveIdsSet.toList();
      final archivedProducts =
          await _productDb.getProductsByArchiveIds(archiveIds);
      archiveProductsMap.addAll(archivedProducts);
    }

    if (barcodesSet.isNotEmpty) {
      final barcodes = barcodesSet.toList();
      final legacyProducts = await _productDb.getProductsByBarcodes(barcodes);
      for (final p in legacyProducts) {
        legacyProductsMap[p.barcode] = p;
      }
    }

    List<List<dynamic>> rows = [
      [
        'date',
        'time',
        'food',
        'type',
        'grams_ml',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sugar_g',
        'fiber_g',
        'caffeine_mg',
        'water_liquids_ml'
      ]
    ];

    for (final e in entries) {
      final p = e.archiveLocalId != null
          ? archiveProductsMap[e.archiveLocalId!]
          : legacyProductsMap[e.barcode];
      if (p != null) {
        final ratio = e.quantityInGrams / 100.0;
        final calories = p.calories * ratio;
        final protein = p.protein * ratio;
        final carbs = p.carbs * ratio;
        final fat = p.fat * ratio;
        final sugar = (p.sugar ?? 0.0) * ratio;
        final fiber = (p.fiber ?? 0.0) * ratio;
        final caffeine =
            (p.caffeineMgPer100g ?? p.caffeineMgPer100ml ?? 0.0) * ratio;

        rows.add([
          DateFormat('yyyy-MM-dd').format(e.timestamp),
          DateFormat('HH:mm').format(e.timestamp),
          p.name,
          'Essen',
          e.quantityInGrams,
          calories.toStringAsFixed(1),
          protein.toStringAsFixed(1),
          carbs.toStringAsFixed(1),
          fat.toStringAsFixed(1),
          sugar.toStringAsFixed(1),
          fiber.toStringAsFixed(1),
          caffeine.toStringAsFixed(1),
          0
        ]);
      }
    }

    for (final f in fluidEntries) {
      final ratio = f.quantityInMl / 100.0;
      final calories = (f.kcal ?? 0) * ratio;
      final carbs = (f.carbsPer100ml ?? 0.0) * ratio;
      final sugar = (f.sugarPer100ml ?? 0.0) * ratio;
      final caffeine = (f.caffeinePer100ml ?? 0.0) * ratio;

      rows.add([
        DateFormat('yyyy-MM-dd').format(f.timestamp),
        DateFormat('HH:mm').format(f.timestamp),
        f.name,
        'Trinken',
        f.quantityInMl,
        calories.toStringAsFixed(1),
        0.0.toStringAsFixed(1),
        carbs.toStringAsFixed(1),
        0.0.toStringAsFixed(1),
        sugar.toStringAsFixed(1),
        0.0.toStringAsFixed(1),
        caffeine.toStringAsFixed(1),
        f.quantityInMl
      ]);
    }

    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/nutrition_history.csv');
    await file.writeAsString(csvData);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Nutrition History',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    await _deleteQuietly(file);
    final exported = res.status == ShareResultStatus.success;
    if (exported) {
      unawaited(TelemetryService.instance
          .trackFeatureUsed(featureKey: FeatureKey.csvExported));
    }
    return exported;
  }

  Future<bool> exportWorkoutsAsCsv() async {
    final logs = await _workoutDb.getFullWorkoutLogs();
    if (logs.isEmpty) return false;
    List<List<dynamic>> rows = [
      [
        'start_time',
        'end_time',
        'routine_name',
        'exercise_name',
        'set_type',
        'weight_kg',
        'reps',
        'rest_time_seconds',
        'is_completed',
        'log_order',
        'distance_km',
        'duration_seconds',
        'rpe',
        'rir',
        'set_notes',
        'workout_notes',
        'exercise_block',
        'workout_exercise_note'
      ]
    ];
    for (final l in logs) {
      for (final s in l.sets) {
        rows.add([
          l.startTime.toIso8601String(),
          l.endTime?.toIso8601String() ?? '',
          l.routineName ?? '',
          s.exerciseName,
          s.setType,
          s.weightKg ?? 0.0,
          s.reps ?? 0,
          s.restTimeSeconds ?? 0,
          s.isCompleted == true ? 1 : 0,
          s.logOrder ?? 0,
          s.distanceKm ?? 0.0,
          s.durationSeconds ?? 0,
          s.rpe ?? 0,
          s.rir ?? 0,
          s.notes ?? '',
          l.notes ?? '',
          s.exerciseBlock ?? '',
          l.exerciseNotesByBlock[s.exerciseBlock] ?? ''
        ]);
      }
    }

    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/workout_history.csv');
    await file.writeAsString(csvData);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Workout History',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    await _deleteQuietly(file);
    final exported = res.status == ShareResultStatus.success;
    if (exported) {
      unawaited(TelemetryService.instance
          .trackFeatureUsed(featureKey: FeatureKey.csvExported));
    }
    return exported;
  }

  Future<bool> exportMeasurementsAsCsv() async {
    final dbInst = _dbHelper.dbInstance;
    final tempDir = await getTemporaryDirectory();
    final List<XFile> shareFiles = [];

    // 1. Measurements CSV
    final sessions = await _profileDb.getMeasurementSessions();
    List<List<dynamic>> measurementRows = [
      ['date', 'type', 'value', 'unit']
    ];
    for (final s in sessions) {
      for (final m in s.measurements) {
        measurementRows.add([
          DateFormat('yyyy-MM-dd').format(s.timestamp),
          m.type,
          m.value,
          m.unit
        ]);
      }
    }
    final mCsv = csv.encode(measurementRows);
    final mFile = File('${tempDir.path}/measurements.csv');
    await mFile.writeAsString(mCsv);
    shareFiles.add(XFile(mFile.path, mimeType: 'text/csv'));

    // 2. Sleep History CSV
    try {
      final sleepRows = await dbInst.customSelect('''
        SELECT a.*, s.started_at, s.ended_at
        FROM sleep_nightly_analyses a
        JOIN sleep_canonical_sessions s ON a.session_id = s.id
        ORDER BY a.night_date ASC
      ''').get();

      final stageRows = await dbInst.customSelect('''
        SELECT session_id, stage, started_at, ended_at
        FROM sleep_canonical_stage_segments
      ''').get();

      final Map<String, Map<String, double>> sessionStages = {};
      for (final row in stageRows) {
        final sessionId = row.read<String>('session_id');
        final stage = row.read<String>('stage').toLowerCase();
        final startedAt = row.read<int>('started_at');
        final endedAt = row.read<int>('ended_at');
        final minutes = (endedAt - startedAt) / 60000.0;
        sessionStages.putIfAbsent(sessionId, () => {});

        String canonicalStage = 'light';
        if (stage.contains('deep')) {
          canonicalStage = 'deep';
        } else if (stage.contains('rem')) {
          canonicalStage = 'rem';
        } else if (stage.contains('awake') || stage.contains('wake')) {
          canonicalStage = 'awake';
        }

        sessionStages[sessionId]![canonicalStage] =
            (sessionStages[sessionId]![canonicalStage] ?? 0.0) + minutes;
      }

      List<List<dynamic>> sleepCsvRows = [
        [
          'Date',
          'Start Time',
          'End Time',
          'Total Minutes',
          'Deep Minutes',
          'Light Minutes',
          'REM Minutes',
          'Awake Minutes',
          'Sleep Score'
        ]
      ];
      for (final r in sleepRows) {
        final sessionId = r.read<String>('session_id');
        final startTime =
            DateTime.fromMillisecondsSinceEpoch(r.read<int>('started_at'));
        final endTime =
            DateTime.fromMillisecondsSinceEpoch(r.read<int>('ended_at'));
        final stages = sessionStages[sessionId] ?? {};

        sleepCsvRows.add([
          r.read<String>('night_date'),
          startTime.toIso8601String(),
          endTime.toIso8601String(),
          r.readNullable<int>('total_sleep_minutes') ?? 0,
          (stages['deep'] ?? 0.0).toStringAsFixed(1),
          (stages['light'] ?? 0.0).toStringAsFixed(1),
          (stages['rem'] ?? 0.0).toStringAsFixed(1),
          (stages['awake'] ?? 0.0).toStringAsFixed(1),
          r.readNullable<double>('score') ?? 0.0
        ]);
      }
      final sCsv = csv.encode(sleepCsvRows);
      final sFile = File('${tempDir.path}/sleep_history.csv');
      await sFile.writeAsString(sCsv);
      shareFiles.add(XFile(sFile.path, mimeType: 'text/csv'));
    } catch (_) {}

    // 3. Steps History CSV
    try {
      final stepRows = await dbInst.customSelect('''
        SELECT
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          SUM(step_count) AS total_steps,
          COALESCE(source_id, provider) AS source_key
        FROM health_step_segments
        GROUP BY day_local, source_key
        ORDER BY day_local ASC
      ''').get();

      List<List<dynamic>> stepsCsvRows = [
        ['Date', 'Total Steps', 'Core Source Origin']
      ];
      for (final r in stepRows) {
        stepsCsvRows.add([
          r.read<String>('day_local'),
          r.read<int>('total_steps'),
          r.read<String>('source_key')
        ]);
      }
      final stepsCsvStr = csv.encode(stepsCsvRows);
      final stepsFile = File('${tempDir.path}/steps_history.csv');
      await stepsFile.writeAsString(stepsCsvStr);
      shareFiles.add(XFile(stepsFile.path, mimeType: 'text/csv'));
    } catch (_) {}

    // 4. Heart Rate History CSV
    try {
      final baselineRows = await dbInst.customSelect('''
        SELECT bucket_start_ms, min_bpm, max_bpm, sum_bpm, sample_count
        FROM pulse_hourly_aggregates
        ORDER BY bucket_start_ms ASC
      ''').get();

      final workoutList = await dbInst.customSelect('''
        SELECT id, local_id, routine_name_snapshot, start_time, end_time
        FROM workout_logs
        WHERE status = 'completed' AND end_time IS NOT NULL
      ''').get();

      List<List<dynamic>> hrCsvRows = [
        ['Date/Timestamp', 'Context', 'Min BPM', 'Max BPM', 'Avg BPM']
      ];
      for (final r in baselineRows) {
        final t =
            DateTime.fromMillisecondsSinceEpoch(r.read<int>('bucket_start_ms'));
        final count = r.read<num>('sample_count').toInt();
        final avg = count > 0 ? r.read<double>('sum_bpm') / count : 0.0;
        hrCsvRows.add([
          t.toIso8601String(),
          'Daily Baseline',
          r.read<double>('min_bpm'),
          r.read<double>('max_bpm'),
          avg.toStringAsFixed(1)
        ]);
      }

      for (final w in workoutList) {
        final wId = w.read<String>('id');
        final startTime =
            DateTime.fromMillisecondsSinceEpoch(w.read<int>('start_time'));
        final endTime =
            DateTime.fromMillisecondsSinceEpoch(w.read<int>('end_time'));
        final hr = await _getWorkoutHeartRate(wId, startTime, endTime);
        if (hr != null) {
          hrCsvRows.add([
            startTime.toIso8601String(),
            'Workout Session ID: $wId',
            hr['min']!,
            hr['max']!,
            hr['avg']!.toStringAsFixed(1)
          ]);
        }
      }
      final hrCsvStr = csv.encode(hrCsvRows);
      final hrFile = File('${tempDir.path}/heart_rate_history.csv');
      await hrFile.writeAsString(hrCsvStr);
      shareFiles.add(XFile(hrFile.path, mimeType: 'text/csv'));
    } catch (_) {}

    if (shareFiles.isEmpty) return false;

    final res = await SharePlus.instance.share(
      ShareParams(
        files: shareFiles,
        subject: 'Measurements & Activity History',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    for (final f in shareFiles) {
      await _deleteQuietly(File(f.path));
    }
    final exported = res.status == ShareResultStatus.success;
    if (exported) {
      unawaited(TelemetryService.instance
          .trackFeatureUsed(featureKey: FeatureKey.csvExported));
    }
    return exported;
  }
}
