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
import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../data/database_helper.dart';

class ExportManager {
  static Future<Map<String, double>?> _getWorkoutHeartRate(String workoutLogId, DateTime startTime, DateTime endTime) async {
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
      ''', variables: [drift.Variable<int>(startMs), drift.Variable<int>(endMs)]).get();
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
    final excel = Excel.createExcel();
    final foodHelper = DatabaseHelper.instance;

    // -------------------------------------------------------------------------
    // 1. Nutrition Sheet
    // -------------------------------------------------------------------------
    final nutritionSheet = excel['Nutrition'];
    excel.delete('Sheet1'); // Remove default sheet

    nutritionSheet.appendRow([
      TextCellValue('Zeitpunkt'),
      TextCellValue('Name/Food'),
      TextCellValue('Typ (Essen/Trinken)'),
      TextCellValue('Menge (g/ml)'),
      TextCellValue('Kalorien (kcal)'),
      TextCellValue('Protein (g)'),
      TextCellValue('Kohlenhydrate (g)'),
      TextCellValue('Fett (g)'),
      TextCellValue('Zucker (g)'),
      TextCellValue('Ballaststoffe (g)'),
      TextCellValue('Koffein (mg)'),
      TextCellValue('Wasser/Flüssigkeit (ml)'),
    ]);

    final entries = await foodHelper.getAllFoodEntries();
    final fluidEntries = await foodHelper.getAllFluidEntries();
    final barcodes = entries.map((e) => e.barcode).toSet().toList();
    final products = await foodHelper.productLocalDataSource.getProductsByBarcodes(barcodes);
    final pMap = {for (var p in products) p.barcode: p};

    for (var entry in entries) {
      final p = pMap[entry.barcode];
      if (p != null) {
        final ratio = entry.quantityInGrams / 100.0;
        nutritionSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)),
          TextCellValue(p.name),
          TextCellValue('Essen'),
          IntCellValue(entry.quantityInGrams),
          DoubleCellValue(p.calories * ratio),
          DoubleCellValue(p.protein * ratio),
          DoubleCellValue(p.carbs * ratio),
          DoubleCellValue(p.fat * ratio),
          DoubleCellValue((p.sugar ?? 0.0) * ratio),
          DoubleCellValue((p.fiber ?? 0.0) * ratio),
          DoubleCellValue((p.caffeineMgPer100g ?? p.caffeineMgPer100ml ?? 0.0) * ratio),
          IntCellValue(0),
        ]);
      }
    }

    for (var entry in fluidEntries) {
      final ratio = entry.quantityInMl / 100.0;
      nutritionSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)),
        TextCellValue(entry.name),
        TextCellValue('Trinken'),
        IntCellValue(entry.quantityInMl),
        DoubleCellValue((entry.kcal ?? 0) * ratio),
        DoubleCellValue(0.0),
        DoubleCellValue((entry.carbsPer100ml ?? 0.0) * ratio),
        DoubleCellValue(0.0),
        DoubleCellValue((entry.sugarPer100ml ?? 0.0) * ratio),
        DoubleCellValue(0.0),
        DoubleCellValue((entry.caffeinePer100ml ?? 0.0) * ratio),
        IntCellValue(entry.quantityInMl),
      ]);
    }

    // -------------------------------------------------------------------------
    // 2. Workouts Sheet
    // -------------------------------------------------------------------------
    final workoutSheet = excel['Workouts'];
    workoutSheet.appendRow([
      TextCellValue('Datum'),
      TextCellValue('Workout Name'),
      TextCellValue('Übung'),
      TextCellValue('Satz Typ'),
      TextCellValue('Gewicht (kg)'),
      TextCellValue('Wdh'),
      TextCellValue('Pause (s)'),
      TextCellValue('Erfolgreich'),
      TextCellValue('Satz-Reihenfolge'),
      TextCellValue('Distanz (km)'),
      TextCellValue('Dauer (s)'),
      TextCellValue('RPE'),
      TextCellValue('RIR'),
      TextCellValue('Satz Notizen'),
      TextCellValue('Workout Notizen'),
    ]);

    final workoutHelper = WorkoutLocalDataSource.instance;
    final allWorkoutLogs = await workoutHelper.getFullWorkoutLogs();

    for (var log in allWorkoutLogs) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(log.startTime);
      for (var set in log.sets) {
        workoutSheet.appendRow([
          TextCellValue(dateStr),
          TextCellValue(log.routineName ?? 'Importiertes Workout'),
          TextCellValue(set.exerciseName),
          TextCellValue(set.setType),
          DoubleCellValue(set.weightKg ?? 0.0),
          IntCellValue(set.reps ?? 0),
          IntCellValue(set.restTimeSeconds ?? 0),
          IntCellValue(set.isCompleted == true ? 1 : 0),
          IntCellValue(set.logOrder ?? 0),
          DoubleCellValue(set.distanceKm ?? 0.0),
          IntCellValue(set.durationSeconds ?? 0),
          IntCellValue(set.rpe ?? 0),
          IntCellValue(set.rir ?? 0),
          TextCellValue(set.notes ?? ''),
          TextCellValue(log.notes ?? ''),
        ]);
      }
    }

    // -------------------------------------------------------------------------
    // 3. Sleep Sheet
    // -------------------------------------------------------------------------
    final sleepSheet = excel['Sleep'];
    sleepSheet.appendRow([
      TextCellValue('Datum'),
      TextCellValue('Startzeit'),
      TextCellValue('Endzeit'),
      TextCellValue('Gesamtdauer (Min)'),
      TextCellValue('Tiefschlaf (Min)'),
      TextCellValue('Leichtschlaf (Min)'),
      TextCellValue('REM-Schlaf (Min)'),
      TextCellValue('Wach/Unterbrechungen (Min)'),
      TextCellValue('Schlaf-Score'),
    ]);

    try {
      final dbInst = foodHelper.dbInstance;
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
        
        sessionStages[sessionId]![canonicalStage] = (sessionStages[sessionId]![canonicalStage] ?? 0.0) + minutes;
      }

      for (final r in sleepRows) {
        final sessionId = r.read<String>('session_id');
        final startTime = DateTime.fromMillisecondsSinceEpoch(r.read<int>('started_at'));
        final endTime = DateTime.fromMillisecondsSinceEpoch(r.read<int>('ended_at'));
        final stages = sessionStages[sessionId] ?? {};
        
        sleepSheet.appendRow([
          TextCellValue(r.read<String>('night_date')),
          TextCellValue(startTime.toIso8601String()),
          TextCellValue(endTime.toIso8601String()),
          IntCellValue(r.readNullable<int>('total_sleep_minutes') ?? 0),
          DoubleCellValue(double.parse((stages['deep'] ?? 0.0).toStringAsFixed(1))),
          DoubleCellValue(double.parse((stages['light'] ?? 0.0).toStringAsFixed(1))),
          DoubleCellValue(double.parse((stages['rem'] ?? 0.0).toStringAsFixed(1))),
          DoubleCellValue(double.parse((stages['awake'] ?? 0.0).toStringAsFixed(1))),
          DoubleCellValue(r.readNullable<double>('score') ?? 0.0),
        ]);
      }
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 4. Activity & Biometrics Sheet
    // -------------------------------------------------------------------------
    final activitySheet = excel['Activity & Biometrics'];
    activitySheet.appendRow([
      TextCellValue('Datum'),
      TextCellValue('Schritte (Gesamt)'),
      TextCellValue('Schritte-Quelle'),
      TextCellValue('Ruhepuls Min (BPM)'),
      TextCellValue('Ruhepuls Max (BPM)'),
      TextCellValue('Ruhepuls Avg (BPM)'),
      TextCellValue('Workout Puls Min (BPM)'),
      TextCellValue('Workout Puls Max (BPM)'),
      TextCellValue('Workout Puls Avg (BPM)'),
    ]);

    try {
      final dbInst = foodHelper.dbInstance;
      final stepRows = await dbInst.customSelect('''
        SELECT 
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          SUM(step_count) AS total_steps,
          COALESCE(source_id, provider) AS source_key
        FROM health_step_segments
        GROUP BY day_local, source_key
      ''').get();

      final baselineRows = await dbInst.customSelect('''
        SELECT 
          date(datetime(bucket_start_ms / 1000, 'unixepoch', 'localtime')) AS day_local,
          MIN(min_bpm) AS min_bpm,
          MAX(max_bpm) AS max_bpm,
          SUM(sum_bpm) AS total_sum,
          SUM(sample_count) AS total_count
        FROM pulse_hourly_aggregates
        GROUP BY day_local
      ''').get();

      final workoutListForHr = await dbInst.customSelect('''
        SELECT id, start_time, end_time
        FROM workout_logs
        WHERE status = 'completed' AND end_time IS NOT NULL
      ''').get();

      final allDates = <String>{};
      final Map<String, Map<String, dynamic>> dateData = {};

      for (final row in stepRows) {
        final day = row.read<String>('day_local');
        allDates.add(day);
        dateData.putIfAbsent(day, () => {});
        dateData[day]!['steps'] = row.read<int>('total_steps');
        dateData[day]!['steps_source'] = row.read<String>('source_key');
      }

      for (final row in baselineRows) {
        final day = row.read<String>('day_local');
        allDates.add(day);
        dateData.putIfAbsent(day, () => {});
        dateData[day]!['pulse_min'] = row.read<double>('min_bpm');
        dateData[day]!['pulse_max'] = row.read<double>('max_bpm');
        final count = row.read<num>('total_count').toDouble();
        dateData[day]!['pulse_avg'] = count > 0 ? row.read<double>('total_sum') / count : 0.0;
      }

      final Map<String, List<Map<String, double>>> workoutHrByDate = {};
      for (final w in workoutListForHr) {
        final wId = w.read<String>('id');
        final startTime = DateTime.fromMillisecondsSinceEpoch(w.read<int>('start_time'));
        final endTime = DateTime.fromMillisecondsSinceEpoch(w.read<int>('end_time'));
        final day = DateFormat('yyyy-MM-dd').format(startTime);

        final hr = await _getWorkoutHeartRate(wId, startTime, endTime);
        if (hr != null) {
          workoutHrByDate.putIfAbsent(day, () => []).add(hr);
        }
      }

      for (final entry in workoutHrByDate.entries) {
        final day = entry.key;
        allDates.add(day);
        dateData.putIfAbsent(day, () => {});
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
          dateData[day]!['workout_min'] = min;
          dateData[day]!['workout_max'] = max;
          dateData[day]!['workout_avg'] = sum / count;
        }
      }

      final sortedDates = allDates.toList()..sort();
      for (final d in sortedDates) {
        final data = dateData[d] ?? {};
        activitySheet.appendRow([
          TextCellValue(d),
          data['steps'] != null ? IntCellValue(data['steps'] as int) : TextCellValue(''),
          TextCellValue((data['steps_source'] as String?) ?? ''),
          data['pulse_min'] != null ? DoubleCellValue(data['pulse_min'] as double) : TextCellValue(''),
          data['pulse_max'] != null ? DoubleCellValue(data['pulse_max'] as double) : TextCellValue(''),
          data['pulse_avg'] != null ? DoubleCellValue(double.parse((data['pulse_avg'] as double).toStringAsFixed(1))) : TextCellValue(''),
          data['workout_min'] != null ? DoubleCellValue(data['workout_min'] as double) : TextCellValue(''),
          data['workout_max'] != null ? DoubleCellValue(data['workout_max'] as double) : TextCellValue(''),
          data['workout_avg'] != null ? DoubleCellValue(double.parse((data['workout_avg'] as double).toStringAsFixed(1))) : TextCellValue(''),
        ]);
      }
    } catch (_) {}

    // Save and Share
    final bytes = excel.encode();
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
