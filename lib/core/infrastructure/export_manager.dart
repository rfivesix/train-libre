// lib/core/infrastructure/export_manager.dart

import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../data/database_helper.dart';
import '../../services/health/steps_sync_service.dart';
import '../../services/health/health_models.dart';
import '../../features/diary/domain/models/food_item.dart';

// =============================================================================
// PURE DART DTOS FOR TYPE-SAFE ISOLATE MESSAGE PASSING
// =============================================================================

class NutritionRowDto {
  final String timestampStr;
  final String name;
  final String type;
  final int quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double caffeine;
  final int water;

  const NutritionRowDto({
    required this.timestampStr,
    required this.name,
    required this.type,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.caffeine,
    required this.water,
  });
}

class WorkoutRowDto {
  final String workoutName;
  final String exerciseName;
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final int? rpe;
  final String? setNotes;
  final String? workoutComments;

  const WorkoutRowDto({
    required this.workoutName,
    required this.exerciseName,
    required this.setIndex,
    this.weight,
    this.reps,
    this.rir,
    this.rpe,
    this.setNotes,
    this.workoutComments,
  });
}

class SleepRowDto {
  final String nightDate;
  final String startTimeIso;
  final String endTimeIso;
  final int totalSleepMinutes;
  final double deepMinutes;
  final double lightMinutes;
  final double remMinutes;
  final double awakeMinutes;
  final double score;

  const SleepRowDto({
    required this.nightDate,
    required this.startTimeIso,
    required this.endTimeIso,
    required this.totalSleepMinutes,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.score,
  });
}

class HealthStepSegmentDto {
  final String provider;
  final String? sourceId;
  final DateTime startAt;
  final DateTime endAt;
  final int stepCount;

  const HealthStepSegmentDto({
    required this.provider,
    this.sourceId,
    required this.startAt,
    required this.endAt,
    required this.stepCount,
  });
}

class PulseHourlyAggregateDto {
  final DateTime bucketStart;
  final double minBpm;
  final double maxBpm;
  final double sumBpm;
  final int sampleCount;

  const PulseHourlyAggregateDto({
    required this.bucketStart,
    required this.minBpm,
    required this.maxBpm,
    required this.sumBpm,
    required this.sampleCount,
  });
}

class WorkoutHeartRateDto {
  final double min;
  final double max;
  final double avg;

  const WorkoutHeartRateDto({
    required this.min,
    required this.max,
    required this.avg,
  });
}

class MeasurementRowDto {
  final DateTime timestamp;
  final String type;
  final double value;
  final String unit;

  const MeasurementRowDto({
    required this.timestamp,
    required this.type,
    required this.value,
    required this.unit,
  });
}

class ExcelExportData {
  final List<NutritionRowDto> nutritionRows;
  final List<WorkoutRowDto> workoutRows;
  final List<SleepRowDto> sleepRows;
  final List<HealthStepSegmentDto> stepSegments;
  final List<PulseHourlyAggregateDto> pulseAggregates;
  final Map<String, WorkoutHeartRateDto> workoutHeartRatesByDay;
  final StepsSourcePolicy stepsSourcePolicy;
  final List<MeasurementRowDto> measurementRows;

  const ExcelExportData({
    required this.nutritionRows,
    required this.workoutRows,
    required this.sleepRows,
    required this.stepSegments,
    required this.pulseAggregates,
    required this.workoutHeartRatesByDay,
    required this.stepsSourcePolicy,
    required this.measurementRows,
  });
}

// =============================================================================
// MAIN EXPORT MANAGER
// =============================================================================

class ExportManager {
  static Future<Map<String, double>?> _getWorkoutHeartRate(
    String workoutLogId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final dbInst = DatabaseHelper.instance.dbInstance;
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
    } catch (_) {}

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
    } catch (_) {}

    return null;
  }

  static Future<void> exportToExcel() async {
    final foodHelper = DatabaseHelper.instance;
    final dbInst = foodHelper.dbInstance;

    // -------------------------------------------------------------------------
    // 1. Pre-fetch Nutrition Sheet Data
    // -------------------------------------------------------------------------
    final entries = await foodHelper.getAllFoodEntries();
    final fluidEntries = await foodHelper.getAllFluidEntries();

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
      final archivedProducts = await foodHelper.productLocalDataSource
          .getProductsByArchiveIds(archiveIds);
      archiveProductsMap.addAll(archivedProducts);
    }

    if (barcodesSet.isNotEmpty) {
      final barcodes = barcodesSet.toList();
      final legacyProducts = await foodHelper.productLocalDataSource
          .getProductsByBarcodes(barcodes);
      for (final p in legacyProducts) {
        legacyProductsMap[p.barcode] = p;
      }
    }

    final List<NutritionRowDto> nutritionRows = [];
    for (var entry in entries) {
      final p = entry.archiveLocalId != null
          ? archiveProductsMap[entry.archiveLocalId!]
          : legacyProductsMap[entry.barcode];
      if (p != null) {
        final ratio = entry.quantityInGrams / 100.0;
        nutritionRows.add(NutritionRowDto(
          timestampStr: DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp),
          name: p.name,
          type: 'Essen',
          quantity: entry.quantityInGrams.toInt(),
          calories: p.calories * ratio,
          protein: p.protein * ratio,
          carbs: p.carbs * ratio,
          fat: p.fat * ratio,
          sugar: (p.sugar ?? 0.0) * ratio,
          fiber: (p.fiber ?? 0.0) * ratio,
          caffeine:
              (p.caffeineMgPer100g ?? p.caffeineMgPer100ml ?? 0.0) * ratio,
          water: 0,
        ));
      }
    }

    for (var entry in fluidEntries) {
      final ratio = entry.quantityInMl / 100.0;
      nutritionRows.add(NutritionRowDto(
        timestampStr: DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp),
        name: entry.name,
        type: 'Trinken',
        quantity: entry.quantityInMl.toInt(),
        calories: (entry.kcal ?? 0) * ratio,
        protein: 0.0,
        carbs: (entry.carbsPer100ml ?? 0.0) * ratio,
        fat: 0.0,
        sugar: (entry.sugarPer100ml ?? 0.0) * ratio,
        fiber: 0.0,
        caffeine: (entry.caffeinePer100ml ?? 0.0) * ratio,
        water: entry.quantityInMl.toInt(),
      ));
    }

    // -------------------------------------------------------------------------
    // 2. Pre-fetch Workouts Sheet Data
    // -------------------------------------------------------------------------
    final workoutHelper = WorkoutLocalDataSource.instance;
    final allWorkoutLogs = await workoutHelper.getFullWorkoutLogs();

    final List<WorkoutRowDto> workoutRows = [];
    for (var log in allWorkoutLogs) {
      final workoutName = log.routineName != null
          ? "${log.routineName} (${DateFormat('yyyy-MM-dd').format(log.startTime)})"
          : "Workout (${DateFormat('yyyy-MM-dd HH:mm').format(log.startTime)})";

      final exerciseSetCounts = <String, int>{};
      for (var set in log.sets) {
        final exercise = set.exerciseName;
        final setIndex = (exerciseSetCounts[exercise] ?? 0) + 1;
        exerciseSetCounts[exercise] = setIndex;

        workoutRows.add(WorkoutRowDto(
          workoutName: workoutName,
          exerciseName: set.exerciseName,
          setIndex: setIndex,
          weight: set.weightKg,
          reps: set.reps,
          rir: set.rir,
          rpe: set.rpe,
          setNotes: set.notes,
          workoutComments: log.notes,
        ));
      }
    }

    // -------------------------------------------------------------------------
    // 3. Pre-fetch Sleep Sheet Data
    // -------------------------------------------------------------------------
    final List<SleepRowDto> sleepRows = [];
    try {
      final sleepRowsFromDb = await dbInst.customSelect('''
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

      for (final r in sleepRowsFromDb) {
        final sessionId = r.read<String>('session_id');
        final startTime =
            DateTime.fromMillisecondsSinceEpoch(r.read<int>('started_at'));
        final endTime =
            DateTime.fromMillisecondsSinceEpoch(r.read<int>('ended_at'));
        final stages = sessionStages[sessionId] ?? {};

        sleepRows.add(SleepRowDto(
          nightDate: r.read<String>('night_date'),
          startTimeIso: startTime.toIso8601String(),
          endTimeIso: endTime.toIso8601String(),
          totalSleepMinutes: r.readNullable<int>('total_sleep_minutes') ?? 0,
          deepMinutes: (stages['deep'] ?? 0.0),
          lightMinutes: (stages['light'] ?? 0.0),
          remMinutes: (stages['rem'] ?? 0.0),
          awakeMinutes: (stages['awake'] ?? 0.0),
          score: r.readNullable<double>('score') ?? 0.0,
        ));
      }
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 4. Pre-fetch Activity & Biometrics Sheet Data
    // -------------------------------------------------------------------------
    List<HealthStepSegmentDto> stepSegments = [];
    List<PulseHourlyAggregateDto> pulseAggregates = [];
    Map<String, WorkoutHeartRateDto> workoutHeartRatesByDay = {};
    StepsSourcePolicy stepsSourcePolicy = StepsSourcePolicy.autoDominant;

    try {
      final stepSegmentsRows =
          await dbInst.select(dbInst.healthStepSegments).get();
      stepSegments = stepSegmentsRows
          .map((s) => HealthStepSegmentDto(
                provider: s.provider,
                sourceId: s.sourceId,
                startAt: s.startAt,
                endAt: s.endAt,
                stepCount: s.stepCount,
              ))
          .toList();

      final pulseRows = await dbInst.customSelect('''
        SELECT bucket_start_ms, min_bpm, max_bpm, sum_bpm, sample_count
        FROM pulse_hourly_aggregates
      ''').get();
      pulseAggregates = pulseRows
          .map((r) => PulseHourlyAggregateDto(
                bucketStart: DateTime.fromMillisecondsSinceEpoch(
                    r.read<int>('bucket_start_ms')),
                minBpm: r.read<double>('min_bpm'),
                maxBpm: r.read<double>('max_bpm'),
                sumBpm: r.read<double>('sum_bpm'),
                sampleCount: r.read<num>('sample_count').toInt(),
              ))
          .toList();

      final workoutListForHr = await dbInst.customSelect('''
        SELECT id, start_time, end_time
        FROM workout_logs
        WHERE status = 'completed' AND end_time IS NOT NULL
      ''').get();

      final Map<String, List<Map<String, double>>> workoutHrByDate = {};
      for (final w in workoutListForHr) {
        final wId = w.read<String>('id');
        final startTime =
            DateTime.fromMillisecondsSinceEpoch(w.read<int>('start_time'));
        final endTime =
            DateTime.fromMillisecondsSinceEpoch(w.read<int>('end_time'));
        final day = DateFormat('yyyy-MM-dd')
            .format(startTime.toLocal()); // local timezone date

        final hr = await _getWorkoutHeartRate(wId, startTime, endTime);
        if (hr != null) {
          workoutHrByDate.putIfAbsent(day, () => []).add(hr);
        }
      }

      for (final entry in workoutHrByDate.entries) {
        final day = entry.key;
        double min = double.infinity;
        double max = double.negativeInfinity;
        double sum = 0;
        int count = 0;
        for (final hr in entry.value) {
          min = math.min(min, hr['min']!);
          max = math.max(max, hr['max']!);
          sum += hr['avg']!;
          count++;
        }
        if (count > 0) {
          workoutHeartRatesByDay[day] = WorkoutHeartRateDto(
            min: min,
            max: max,
            avg: sum / count,
          );
        }
      }

      try {
        stepsSourcePolicy = await StepsSyncService().getSourcePolicy();
      } catch (_) {}
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 5. Pre-fetch Measurements Sheet Data
    // -------------------------------------------------------------------------
    final List<MeasurementRowDto> measurementRows = [];
    try {
      final sessions = await foodHelper.getMeasurementSessions();
      for (final s in sessions) {
        for (final m in s.measurements) {
          measurementRows.add(MeasurementRowDto(
            timestamp: s.timestamp,
            type: m.type,
            value: m.value,
            unit: m.unit,
          ));
        }
      }
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 6. Package and Spawn Background Isolate
    // -------------------------------------------------------------------------
    final data = ExcelExportData(
      nutritionRows: nutritionRows,
      workoutRows: workoutRows,
      sleepRows: sleepRows,
      stepSegments: stepSegments,
      pulseAggregates: pulseAggregates,
      workoutHeartRatesByDay: workoutHeartRatesByDay,
      stepsSourcePolicy: stepsSourcePolicy,
      measurementRows: measurementRows,
    );

    final bytes = await compute(_generateExcelIsolate, data);

    // Save and Share
    if (bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/train_libre_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          ],
          subject: 'Train Libre Excel Export',
          sharePositionOrigin: _sharePositionOrigin(),
        ),
      );
    }
  }

  // =============================================================================
  // BACKGROUND ISOLATE GENERATOR
  // =============================================================================

  static List<int>? _generateExcelIsolate(ExcelExportData data) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Remove default sheet

    void writeCell(Sheet sheet, int col, int row, CellValue? value) {
      if (value != null) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value = value;
      }
    }

    // -------------------------------------------------------------------------
    // 1. Nutrition Sheet
    // -------------------------------------------------------------------------
    final nutritionSheet = excel['Nutrition'];
    final nutritionHeaders = [
      'Zeitpunkt',
      'Name/Food',
      'Typ (Essen/Trinken)',
      'Menge (g/ml)',
      'Kalorien (kcal)',
      'Protein (g)',
      'Kohlenhydrate (g)',
      'Fett (g)',
      'Zucker (g)',
      'Ballaststoffe (g)',
      'Koffein (mg)',
      'Wasser/Flüssigkeit (ml)'
    ];
    for (int col = 0; col < nutritionHeaders.length; col++) {
      writeCell(nutritionSheet, col, 0, TextCellValue(nutritionHeaders[col]));
    }

    for (int r = 0; r < data.nutritionRows.length; r++) {
      final rowData = data.nutritionRows[r];
      final rowIndex = r + 1;
      writeCell(
          nutritionSheet, 0, rowIndex, TextCellValue(rowData.timestampStr));
      writeCell(nutritionSheet, 1, rowIndex, TextCellValue(rowData.name));
      writeCell(nutritionSheet, 2, rowIndex, TextCellValue(rowData.type));
      writeCell(nutritionSheet, 3, rowIndex, IntCellValue(rowData.quantity));
      writeCell(nutritionSheet, 4, rowIndex, DoubleCellValue(rowData.calories));
      writeCell(nutritionSheet, 5, rowIndex, DoubleCellValue(rowData.protein));
      writeCell(nutritionSheet, 6, rowIndex, DoubleCellValue(rowData.carbs));
      writeCell(nutritionSheet, 7, rowIndex, DoubleCellValue(rowData.fat));
      writeCell(nutritionSheet, 8, rowIndex, DoubleCellValue(rowData.sugar));
      writeCell(nutritionSheet, 9, rowIndex, DoubleCellValue(rowData.fiber));
      writeCell(
          nutritionSheet, 10, rowIndex, DoubleCellValue(rowData.caffeine));
      writeCell(nutritionSheet, 11, rowIndex, IntCellValue(rowData.water));
    }

    // -------------------------------------------------------------------------
    // 2. Workouts & Exercises Sheet (Holy Grail of Data Fidelity)
    // -------------------------------------------------------------------------
    final workoutSheet = excel['Workouts & Exercises'];
    final workoutHeaders = [
      'Workout Name',
      'Exercise',
      'Set Index',
      'Weight',
      'Reps',
      'RIR',
      'RPE',
      'Set Notes',
      'Workout Comments'
    ];
    for (int col = 0; col < workoutHeaders.length; col++) {
      writeCell(workoutSheet, col, 0, TextCellValue(workoutHeaders[col]));
    }

    for (int r = 0; r < data.workoutRows.length; r++) {
      final rowData = data.workoutRows[r];
      final rowIndex = r + 1;
      writeCell(workoutSheet, 0, rowIndex, TextCellValue(rowData.workoutName));
      writeCell(workoutSheet, 1, rowIndex, TextCellValue(rowData.exerciseName));
      writeCell(workoutSheet, 2, rowIndex, IntCellValue(rowData.setIndex));

      // Explicit type safety checks & safe conversion
      if (rowData.weight != null) {
        writeCell(workoutSheet, 3, rowIndex,
            DoubleCellValue(rowData.weight!.toDouble()));
      }
      if (rowData.reps != null) {
        writeCell(
            workoutSheet, 4, rowIndex, IntCellValue(rowData.reps!.toInt()));
      }

      // CRITICAL COMPLIANCE: RIR/RPE must write empty text cell when null (no ?? 0)
      if (rowData.rir != null) {
        writeCell(
            workoutSheet, 5, rowIndex, IntCellValue(rowData.rir!.toInt()));
      } else {
        writeCell(workoutSheet, 5, rowIndex, TextCellValue(''));
      }

      if (rowData.rpe != null) {
        writeCell(
            workoutSheet, 6, rowIndex, IntCellValue(rowData.rpe!.toInt()));
      } else {
        writeCell(workoutSheet, 6, rowIndex, TextCellValue(''));
      }

      writeCell(
          workoutSheet, 7, rowIndex, TextCellValue(rowData.setNotes ?? ''));
      writeCell(workoutSheet, 8, rowIndex,
          TextCellValue(rowData.workoutComments ?? ''));
    }

    // -------------------------------------------------------------------------
    // 3. Sleep Sheet
    // -------------------------------------------------------------------------
    final sleepSheet = excel['Sleep'];
    final sleepHeaders = [
      'Datum',
      'Startzeit',
      'Endzeit',
      'Gesamtdauer (Min)',
      'Tiefschlaf (Min)',
      'Leichtschlaf (Min)',
      'REM-Schlaf (Min)',
      'Wach/Unterbrechungen (Min)',
      'Schlaf-Score'
    ];
    for (int col = 0; col < sleepHeaders.length; col++) {
      writeCell(sleepSheet, col, 0, TextCellValue(sleepHeaders[col]));
    }

    for (int r = 0; r < data.sleepRows.length; r++) {
      final rowData = data.sleepRows[r];
      final rowIndex = r + 1;
      writeCell(sleepSheet, 0, rowIndex, TextCellValue(rowData.nightDate));
      writeCell(sleepSheet, 1, rowIndex, TextCellValue(rowData.startTimeIso));
      writeCell(sleepSheet, 2, rowIndex, TextCellValue(rowData.endTimeIso));
      writeCell(sleepSheet, 3, rowIndex,
          IntCellValue(rowData.totalSleepMinutes.toInt()));
      writeCell(
          sleepSheet,
          4,
          rowIndex,
          DoubleCellValue(
              double.parse(rowData.deepMinutes.toStringAsFixed(1))));
      writeCell(
          sleepSheet,
          5,
          rowIndex,
          DoubleCellValue(
              double.parse(rowData.lightMinutes.toStringAsFixed(1))));
      writeCell(sleepSheet, 6, rowIndex,
          DoubleCellValue(double.parse(rowData.remMinutes.toStringAsFixed(1))));
      writeCell(
          sleepSheet,
          7,
          rowIndex,
          DoubleCellValue(
              double.parse(rowData.awakeMinutes.toStringAsFixed(1))));
      writeCell(
          sleepSheet, 8, rowIndex, DoubleCellValue(rowData.score.toDouble()));
    }

    // -------------------------------------------------------------------------
    // 4. Biometrics & Wearables Sheet (Matrix Overhaul & Dynamic Layout)
    // -------------------------------------------------------------------------
    final activitySheet = excel['Biometrics & Wearables'];
    final activityHeaders = [
      'Datum',
      'Schritte (Gesamt)',
      'Schritte-Quelle',
      'Ruhepuls Min (BPM)',
      'Ruhepuls Max (BPM)',
      'Ruhepuls Avg (BPM)',
      'Workout Puls Min (BPM)',
      'Workout Puls Max (BPM)',
      'Workout Puls Avg (BPM)',
      'Weight (kg)',
      'Body Fat (%)'
    ];
    for (int col = 0; col < activityHeaders.length; col++) {
      writeCell(activitySheet, col, 0, TextCellValue(activityHeaders[col]));
    }

    // Chronologically aligned Outer-Join Matrix grouped by local date YYYY-MM-DD
    final allDates = <String>{};

    final stepSegmentsByDay = <String, List<HealthStepSegmentDto>>{};
    for (final seg in data.stepSegments) {
      final day = _formatDateLocal(seg.startAt);
      allDates.add(day);
      stepSegmentsByDay.putIfAbsent(day, () => []).add(seg);
    }

    final pulseByDay = <String, List<PulseHourlyAggregateDto>>{};
    for (final pulse in data.pulseAggregates) {
      final day = _formatDateLocal(pulse.bucketStart);
      allDates.add(day);
      pulseByDay.putIfAbsent(day, () => []).add(pulse);
    }

    allDates.addAll(data.workoutHeartRatesByDay.keys);

    // Group weight and body fat measurements by day for daily averaging / sparse mapping
    final weightValuesByDay = <String, List<double>>{};
    final bodyFatValuesByDay = <String, List<double>>{};

    for (final row in data.measurementRows) {
      final day = _formatDateLocal(row.timestamp);
      allDates.add(day);

      final typeLower = row.type.toLowerCase().trim();
      if (typeLower == 'weight') {
        weightValuesByDay.putIfAbsent(day, () => []).add(row.value);
      } else if (typeLower == 'body_fat' ||
          typeLower == 'bodyfat' ||
          typeLower == 'body fat') {
        bodyFatValuesByDay.putIfAbsent(day, () => []).add(row.value);
      }
    }

    final sortedDates = allDates.toList()..sort();

    for (int r = 0; r < sortedDates.length; r++) {
      final d = sortedDates[r];
      final rowIndex = r + 1;
      writeCell(activitySheet, 0, rowIndex, TextCellValue(d));

      // Steps Outer-Join with Policy resolution
      final dayStepsSegments = stepSegmentsByDay[d] ?? [];
      if (dayStepsSegments.isNotEmpty) {
        if (data.stepsSourcePolicy == StepsSourcePolicy.maxPerHour) {
          final stepsTotal = _calculateMaxPerHourSteps(dayStepsSegments);
          writeCell(activitySheet, 1, rowIndex, IntCellValue(stepsTotal));
          writeCell(activitySheet, 2, rowIndex,
              TextCellValue('Merge (max per hour)'));
        } else {
          final domResult = _calculateAutoDominantSteps(dayStepsSegments);
          writeCell(activitySheet, 1, rowIndex, IntCellValue(domResult.value));
          writeCell(activitySheet, 2, rowIndex, TextCellValue(domResult.key));
        }
      } else {
        writeCell(activitySheet, 1, rowIndex, TextCellValue(''));
        writeCell(activitySheet, 2, rowIndex, TextCellValue(''));
      }

      // Resting Heart Rate Outer-Join aggregation
      final dayPulses = pulseByDay[d] ?? [];
      if (dayPulses.isNotEmpty) {
        double minHr = double.infinity;
        double maxHr = double.negativeInfinity;
        double sumHr = 0;
        int totalSamples = 0;
        for (final p in dayPulses) {
          minHr = math.min(minHr, p.minBpm);
          maxHr = math.max(maxHr, p.maxBpm);
          sumHr += p.sumBpm;
          totalSamples += p.sampleCount;
        }
        if (totalSamples > 0) {
          final avgHr = sumHr / totalSamples;
          writeCell(activitySheet, 3, rowIndex, DoubleCellValue(minHr));
          writeCell(activitySheet, 4, rowIndex, DoubleCellValue(maxHr));
          writeCell(activitySheet, 5, rowIndex,
              DoubleCellValue(double.parse(avgHr.toStringAsFixed(1))));
        } else {
          writeCell(activitySheet, 3, rowIndex, TextCellValue(''));
          writeCell(activitySheet, 4, rowIndex, TextCellValue(''));
          writeCell(activitySheet, 5, rowIndex, TextCellValue(''));
        }
      } else {
        writeCell(activitySheet, 3, rowIndex, TextCellValue(''));
        writeCell(activitySheet, 4, rowIndex, TextCellValue(''));
        writeCell(activitySheet, 5, rowIndex, TextCellValue(''));
      }

      // Workout Heart Rate Outer-Join aggregation
      final workoutHr = data.workoutHeartRatesByDay[d];
      if (workoutHr != null) {
        writeCell(activitySheet, 6, rowIndex, DoubleCellValue(workoutHr.min));
        writeCell(activitySheet, 7, rowIndex, DoubleCellValue(workoutHr.max));
        writeCell(activitySheet, 8, rowIndex,
            DoubleCellValue(double.parse(workoutHr.avg.toStringAsFixed(1))));
      } else {
        writeCell(activitySheet, 6, rowIndex, TextCellValue(''));
        writeCell(activitySheet, 7, rowIndex, TextCellValue(''));
        writeCell(activitySheet, 8, rowIndex, TextCellValue(''));
      }

      // Upgraded columns: Weight (kg) & Body Fat (%)
      final dayWeights = weightValuesByDay[d] ?? [];
      if (dayWeights.isNotEmpty) {
        final avgWeight =
            dayWeights.reduce((a, b) => a + b) / dayWeights.length;
        writeCell(activitySheet, 9, rowIndex,
            DoubleCellValue(double.parse(avgWeight.toStringAsFixed(1))));
      } else {
        writeCell(activitySheet, 9, rowIndex, TextCellValue(''));
      }

      final dayBodyFats = bodyFatValuesByDay[d] ?? [];
      if (dayBodyFats.isNotEmpty) {
        final avgBodyFat =
            dayBodyFats.reduce((a, b) => a + b) / dayBodyFats.length;
        writeCell(activitySheet, 10, rowIndex,
            DoubleCellValue(double.parse(avgBodyFat.toStringAsFixed(1))));
      } else {
        writeCell(activitySheet, 10, rowIndex, TextCellValue(''));
      }
    }

    // -------------------------------------------------------------------------
    // 5. Measurements Sheet (Sheet 5 - Raw chronological log)
    // -------------------------------------------------------------------------
    final measurementsSheet = excel['Measurements'];
    final measurementHeaders = [
      'Date',
      'Time',
      'Measurement Type',
      'Value',
      'Unit'
    ];
    for (int col = 0; col < measurementHeaders.length; col++) {
      writeCell(
          measurementsSheet, col, 0, TextCellValue(measurementHeaders[col]));
    }

    final sortedMeasurements =
        List<MeasurementRowDto>.from(data.measurementRows)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int r = 0; r < sortedMeasurements.length; r++) {
      final rowData = sortedMeasurements[r];
      final rowIndex = r + 1;

      final dateStr =
          DateFormat('yyyy-MM-dd').format(rowData.timestamp.toLocal());
      final timeStr = DateFormat('HH:mm').format(rowData.timestamp.toLocal());

      writeCell(measurementsSheet, 0, rowIndex, TextCellValue(dateStr));
      writeCell(measurementsSheet, 1, rowIndex, TextCellValue(timeStr));
      writeCell(measurementsSheet, 2, rowIndex, TextCellValue(rowData.type));
      writeCell(measurementsSheet, 3, rowIndex,
          DoubleCellValue(rowData.value.toDouble()));
      writeCell(measurementsSheet, 4, rowIndex, TextCellValue(rowData.unit));
    }

    return excel.encode();
  }

  // =============================================================================
  // UTILITY ISOLATE HELPERS
  // =============================================================================

  static String _formatDateLocal(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static int _calculateMaxPerHourSteps(
      List<HealthStepSegmentDto> segmentsForDay) {
    final hourlySourceSteps = <int, Map<String, int>>{};
    for (final seg in segmentsForDay) {
      final localStart = seg.startAt.toLocal();
      final hour = localStart.hour;
      final sourceKey = seg.sourceId ?? seg.provider;
      hourlySourceSteps.putIfAbsent(hour, () => {});
      hourlySourceSteps[hour]![sourceKey] =
          (hourlySourceSteps[hour]![sourceKey] ?? 0) + seg.stepCount;
    }

    int totalSteps = 0;
    for (final hour in hourlySourceSteps.keys) {
      final sourceMap = hourlySourceSteps[hour]!;
      if (sourceMap.isNotEmpty) {
        final maxVal = sourceMap.values.reduce(math.max);
        totalSteps += maxVal;
      }
    }
    return totalSteps;
  }

  static MapEntry<String, int> _calculateAutoDominantSteps(
      List<HealthStepSegmentDto> segmentsForDay) {
    final sourceTotals = <String, int>{};
    for (final seg in segmentsForDay) {
      final sourceKey = seg.sourceId ?? seg.provider;
      sourceTotals[sourceKey] = (sourceTotals[sourceKey] ?? 0) + seg.stepCount;
    }

    if (sourceTotals.isEmpty) return const MapEntry('', 0);

    String dominantSource = '';
    int maxSteps = -1;
    for (final entry in sourceTotals.entries) {
      if (entry.value > maxSteps) {
        maxSteps = entry.value;
        dominantSource = entry.key;
      } else if (entry.value == maxSteps) {
        if (entry.key.compareTo(dominantSource) < 0) {
          dominantSource = entry.key;
        }
      }
    }

    return MapEntry(dominantSource, maxSteps);
  }

  static ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }
}
