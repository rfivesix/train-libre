import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;

import '../../../data/drift_database.dart';
import '../../../services/health/workout_heart_rate_models.dart';
import '../../../services/health/workout_heart_rate_service.dart';
import '../../pulse/application/pulse_tracking_service.dart';
import '../../pulse/data/hrv_repository.dart';
import '../../pulse/data/pulse_repository.dart';
import '../../pulse/domain/pulse_models.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

/// Reads heart rate, resting heart rate, HRV (SDNN), and per-workout heart-rate
/// summaries for the AI assistant, with a bounded on-demand platform sync and
/// graceful fallback to locally cached SQLite aggregates.
class AssistantPulseActions implements AssistantDataAction {
  AssistantPulseActions({
    required this.database,
    PulseAnalysisRepository? pulseRepository,
    HealthHrvRepository? hrvRepository,
    WorkoutHeartRateService? workoutHeartRateService,
    PulseTrackingSettingsService? trackingService,
    this.syncTimeout = const Duration(seconds: 4),
    this.maxWorkoutsForLiveHr = 12,
  }) : _pulseRepository =
           pulseRepository ?? HealthPulseAnalysisRepository(database: database),
       _hrvRepository =
           hrvRepository ?? HealthHrvRepository(database: database),
       _workoutHeartRateService =
           workoutHeartRateService ?? const WorkoutHeartRateService(),
       _trackingService = trackingService ?? PulseTrackingService();

  final AppDatabase database;
  final PulseAnalysisRepository _pulseRepository;
  final HealthHrvRepository _hrvRepository;
  final WorkoutHeartRateService _workoutHeartRateService;
  final PulseTrackingSettingsService _trackingService;
  final Duration syncTimeout;
  final int maxWorkoutsForLiveHr;

  static const Map<String, Map<String, String>> tableColumnSchemas = {
    'pulse_daily_summary': {
      'date': 'TEXT',
      'avg_bpm': 'REAL',
      'min_bpm': 'REAL',
      'max_bpm': 'REAL',
      'resting_bpm': 'REAL',
      'resting_bpm_is_estimated': 'INTEGER',
      'sample_count': 'INTEGER',
      'quality': 'TEXT',
      'hrv_avg_sdnn_ms': 'REAL',
      'hrv_min_sdnn_ms': 'REAL',
      'hrv_max_sdnn_ms': 'REAL',
      'hrv_sample_count': 'INTEGER',
      'hrv_state': 'TEXT',
    },
    'pulse_hourly_aggregates': {
      'bucket_start_ms': 'INTEGER',
      'bucket_end_ms': 'INTEGER',
      'local_date': 'TEXT',
      'local_hour': 'INTEGER',
      'sample_count': 'INTEGER',
      'avg_bpm': 'REAL',
      'min_bpm': 'REAL',
      'max_bpm': 'REAL',
      'sum_bpm': 'REAL',
      'source': 'TEXT',
    },
    'pulse_hrv_samples': {
      'native_id': 'TEXT',
      'local_date': 'TEXT',
      'start_ms': 'INTEGER',
      'end_ms': 'INTEGER',
      'sdnn_ms': 'REAL',
      'source_id': 'TEXT',
    },
    'workout_heart_rate_summary': {
      'workout_log_id': 'TEXT',
      'workout_start_local': 'TEXT',
      'workout_end_local': 'TEXT',
      'routine_name': 'TEXT',
      'avg_bpm': 'REAL',
      'min_bpm': 'REAL',
      'max_bpm': 'REAL',
      'sample_count': 'INTEGER',
      'quality': 'TEXT',
      'source': 'TEXT',
    },
  };

  @override
  Set<AssistantDataCategory> get categories => const {
    AssistantDataCategory.pulse,
  };

  @override
  Future<AssistantActionResult> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    if (category != AssistantDataCategory.pulse) {
      throw ArgumentError.value(category);
    }
    final enabled = await _trackingService.isTrackingEnabled();
    if (!enabled) {
      return AssistantActionResult(
        category: category,
        status: AssistantActionStatus.unavailable,
        sourceStatus: const {
          'status': 'disabled',
          'tracking_enabled': 0,
          'permission_state': null,
          'last_synced_at': null,
          'detail': 'Pulse tracking is disabled in Health settings.',
        },
        error: 'Pulse tracking is disabled.',
      );
    }

    final startLocal = DateTime(
      scope!.start.year,
      scope.start.month,
      scope.start.day,
    );
    final endExclusiveLocal = DateTime(
      scope.end.year,
      scope.end.month,
      scope.end.day + 1,
    );
    final window = PulseAnalysisWindow(
      startUtc: startLocal.toUtc(),
      endUtc: endExclusiveLocal.toUtc(),
    );

    PulseAnalysisSummary? liveSummary;
    var syncTimedOut = false;
    try {
      liveSummary = await _pulseRepository
          .getAnalysis(window: window)
          .timeout(syncTimeout);
    } on TimeoutException {
      syncTimedOut = true;
    } catch (_) {
      // Fall back to locally cached SQLite aggregates below.
    }

    // Read cached hourly heart-rate buckets & HRV samples from SQLite.
    final hourlyRows = await _readHourlyAggregates(
      window.startUtc.millisecondsSinceEpoch,
      window.endUtc.millisecondsSinceEpoch,
    );
    final hrvRows = await _readHrvSamples(
      window.startUtc.millisecondsSinceEpoch,
      window.endUtc.millisecondsSinceEpoch,
    );

    // If live HRV samples were returned but not yet cached (or in tests with a
    // fake repository), include them as well.
    final hrvById = <String, Map<String, dynamic>>{
      for (final row in hrvRows) row['native_id'] as String: row,
    };
    if (liveSummary?.hrv != null) {
      for (final sample in liveSummary!.hrv!.samples) {
        final local = sample.startUtc.toLocal();
        hrvById.putIfAbsent(
          sample.nativeId,
          () => {
            'native_id': sample.nativeId,
            'local_date': _day(local),
            'start_ms': sample.startUtc.millisecondsSinceEpoch,
            'end_ms': sample.endUtc.millisecondsSinceEpoch,
            'sdnn_ms': sample.sdnnMs,
            'source_id': sample.sourceId,
          },
        );
      }
    } else if (!syncTimedOut) {
      // Attempt direct HRV summary if pulseRepository didn't attach it.
      try {
        final hrv = await _hrvRepository
            .getSummary(fromUtc: window.startUtc, toUtc: window.endUtc)
            .timeout(const Duration(seconds: 2));
        for (final sample in hrv.samples) {
          final local = sample.startUtc.toLocal();
          hrvById.putIfAbsent(
            sample.nativeId,
            () => {
              'native_id': sample.nativeId,
              'local_date': _day(local),
              'start_ms': sample.startUtc.millisecondsSinceEpoch,
              'end_ms': sample.endUtc.millisecondsSinceEpoch,
              'sdnn_ms': sample.sdnnMs,
              'source_id': sample.sourceId,
            },
          );
        }
      } catch (_) {
        // Non-fatal: HRV is iOS-only and optional.
      }
    }
    final allHrvRows = hrvById.values.toList()
      ..sort((a, b) => (a['start_ms'] as int).compareTo(b['start_ms'] as int));

    // Build daily resting-HR map from live platform readings when available.
    final liveRestingByDay = <String, double>{};
    if (liveSummary != null &&
        liveSummary.restingBpm != null &&
        !liveSummary.restingBpmIsEstimated) {
      if (!window.isMultiDay) {
        liveRestingByDay[_day(startLocal)] = liveSummary.restingBpm!;
      } else if (liveSummary.chartSamples.isNotEmpty) {
        for (final point in liveSummary.chartSamples) {
          liveRestingByDay[_day(point.sampledAtUtc.toLocal())] = point.bpm;
        }
      }
    }

    // Group hourly buckets and HRV samples by local calendar day.
    final hourlyByDay = <String, List<Map<String, dynamic>>>{};
    for (final row in hourlyRows) {
      final date = row['local_date'] as String;
      hourlyByDay.putIfAbsent(date, () => []).add(row);
    }
    final hrvByDay = <String, List<Map<String, dynamic>>>{};
    for (final row in allHrvRows) {
      final date = row['local_date'] as String;
      hrvByDay.putIfAbsent(date, () => []).add(row);
    }

    final allDays = <String>{
      ...hourlyByDay.keys,
      ...liveRestingByDay.keys,
      ...hrvByDay.keys,
    }.toList()..sort();

    // If a single-day live analysis returned samples directly (single-day reads
    // bypass the hourly cache in HealthPulseAnalysisRepository), ensure that day
    // is still represented accurately in pulse_daily_summary.
    final singleDayKey = _day(startLocal);
    if (!window.isMultiDay &&
        liveSummary != null &&
        liveSummary.hasData &&
        !allDays.contains(singleDayKey)) {
      allDays.add(singleDayKey);
      allDays.sort();
    }

    final dailySummaryRows = <Map<String, dynamic>>[];
    final semanticRecords = <Map<String, dynamic>>[];
    final hrvStateLabel = liveSummary?.hrv?.state.name;

    for (final date in allDays) {
      final dayBuckets = hourlyByDay[date] ?? const [];
      final dayHrv = hrvByDay[date] ?? const [];

      double? avgBpm;
      double? minBpm;
      double? maxBpm;
      int sampleCount = 0;
      double? restingBpm = liveRestingByDay[date];
      var restingIsEstimated = restingBpm == null ? 1 : 0;
      String quality = 'noData';

      if (dayBuckets.isNotEmpty) {
        var sum = 0.0;
        var minVal = double.infinity;
        var maxVal = double.negativeInfinity;
        final avgList = <double>[];
        for (final bucket in dayBuckets) {
          final count = (bucket['sample_count'] as num).toInt();
          final bucketSum = (bucket['sum_bpm'] as num).toDouble();
          final bucketMin = (bucket['min_bpm'] as num).toDouble();
          final bucketMax = (bucket['max_bpm'] as num).toDouble();
          sampleCount += count;
          sum += bucketSum;
          if (bucketMin < minVal) minVal = bucketMin;
          if (bucketMax > maxVal) maxVal = bucketMax;
          if (count > 0) avgList.add(bucketSum / count);
        }
        if (sampleCount > 0) {
          avgBpm = _round1(sum / sampleCount);
          minBpm = _round1(minVal);
          maxBpm = _round1(maxVal);
          quality = sampleCount >= 8
              ? 'ready'
              : sampleCount >= 3
              ? 'limited'
              : 'insufficient';
          if (restingBpm == null && avgList.isNotEmpty) {
            avgList.sort();
            final lowCount = math.max(1, (avgList.length * 0.2).ceil());
            final mid = lowCount ~/ 2;
            restingBpm = lowCount.isOdd
                ? avgList[mid]
                : (avgList[mid - 1] + avgList[mid]) / 2;
            restingIsEstimated = 1;
          }
        }
      } else if (!window.isMultiDay &&
          date == singleDayKey &&
          liveSummary != null &&
          liveSummary.hasData) {
        avgBpm = liveSummary.averageBpm == null
            ? null
            : _round1(liveSummary.averageBpm!);
        minBpm = liveSummary.minBpm == null
            ? null
            : _round1(liveSummary.minBpm!);
        maxBpm = liveSummary.maxBpm == null
            ? null
            : _round1(liveSummary.maxBpm!);
        sampleCount = liveSummary.sampleCount;
        restingBpm ??= liveSummary.restingBpm;
        restingIsEstimated = liveSummary.restingBpmIsEstimated ? 1 : 0;
        quality = liveSummary.quality.name;
      }

      if (restingBpm != null) {
        restingBpm = _round1(restingBpm);
      }

      double? hrvAvg;
      double? hrvMin;
      double? hrvMax;
      if (dayHrv.isNotEmpty) {
        var sum = 0.0;
        var minVal = double.infinity;
        var maxVal = double.negativeInfinity;
        for (final row in dayHrv) {
          final sdnn = (row['sdnn_ms'] as num).toDouble();
          sum += sdnn;
          if (sdnn < minVal) minVal = sdnn;
          if (sdnn > maxVal) maxVal = sdnn;
        }
        hrvAvg = _round1(sum / dayHrv.length);
        hrvMin = _round1(minVal);
        hrvMax = _round1(maxVal);
      }

      final summaryRow = <String, dynamic>{
        'date': date,
        'avg_bpm': avgBpm,
        'min_bpm': minBpm,
        'max_bpm': maxBpm,
        'resting_bpm': restingBpm,
        'resting_bpm_is_estimated': restingBpm == null
            ? null
            : restingIsEstimated,
        'sample_count': sampleCount,
        'quality': quality,
        'hrv_avg_sdnn_ms': hrvAvg,
        'hrv_min_sdnn_ms': hrvMin,
        'hrv_max_sdnn_ms': hrvMax,
        'hrv_sample_count': dayHrv.length,
        'hrv_state': dayHrv.isNotEmpty ? 'available' : hrvStateLabel,
      };
      dailySummaryRows.add(summaryRow);
      semanticRecords.add({'ref': 'pulse:$date', ...summaryRow});
    }

    // Build per-workout heart-rate summaries for completed workouts in scope.
    final workoutHrRows = await _readWorkoutHeartRates(
      startLocal: startLocal,
      endExclusiveLocal: endExclusiveLocal,
      hourlyRows: hourlyRows,
      allowLiveFetch: !syncTimedOut,
    );

    final permissionDenied =
        liveSummary?.noDataReason == PulseNoDataReason.permissionDenied;
    final platformUnavailable =
        liveSummary?.noDataReason == PulseNoDataReason.platformUnavailable;
    final hasAnyData =
        dailySummaryRows.isNotEmpty ||
        hourlyRows.isNotEmpty ||
        allHrvRows.isNotEmpty ||
        workoutHrRows.isNotEmpty;

    if (!hasAnyData && (permissionDenied || platformUnavailable)) {
      return AssistantActionResult(
        category: category,
        status: AssistantActionStatus.unavailable,
        sourceStatus: {
          'status': permissionDenied
              ? 'permission_denied'
              : 'platform_unavailable',
          'tracking_enabled': 1,
          'permission_state': permissionDenied ? 'denied' : 'unavailable',
          'last_synced_at': await _lastSyncedIso(),
          'detail': permissionDenied
              ? 'Heart-rate read permission has not been granted in Health settings.'
              : 'Platform health heart-rate data is unavailable on this device.',
        },
        error: permissionDenied
            ? 'Heart-rate permission denied.'
            : 'Heart-rate platform unavailable.',
      );
    }

    final tables = <String, List<Map<String, dynamic>>>{
      'pulse_daily_summary': dailySummaryRows,
      'pulse_hourly_aggregates': hourlyRows,
      'pulse_hrv_samples': allHrvRows,
      if (workoutHrRows.isNotEmpty) 'workout_heart_rate_summary': workoutHrRows,
    };
    final tableColumns = <String, Map<String, String>>{
      for (final key in tables.keys)
        key: Map<String, String>.from(tableColumnSchemas[key]!),
    };

    return AssistantActionResult(
      category: category,
      status: AssistantActionStatus.success,
      records: semanticRecords,
      tables: tables,
      tableColumns: tableColumns,
      sourceStatus: {
        'status': syncTimedOut ? 'cached_timeout' : 'available',
        'tracking_enabled': 1,
        'permission_state': permissionDenied ? 'denied' : 'granted',
        'last_synced_at': await _lastSyncedIso(),
        'detail': syncTimedOut
            ? 'Used cached pulse aggregates after platform sync timeout.'
            : (hasAnyData
                  ? 'Pulse data loaded.'
                  : 'No pulse samples recorded in the approved range.'),
      },
    );
  }

  Future<List<Map<String, dynamic>>> _readHourlyAggregates(
    int startMs,
    int endMs,
  ) async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT bucket_start_ms, bucket_end_ms, sample_count,
                   min_bpm, max_bpm, sum_bpm, source
            FROM pulse_hourly_aggregates
            WHERE bucket_end_ms > ? AND bucket_start_ms < ?
            ORDER BY bucket_start_ms ASC
            ''',
            variables: [
              drift.Variable.withInt(startMs),
              drift.Variable.withInt(endMs),
            ],
          )
          .get();
      return [
        for (final row in rows)
          () {
            final bucketStartMs = row.read<int>('bucket_start_ms');
            final local = DateTime.fromMillisecondsSinceEpoch(
              bucketStartMs,
              isUtc: true,
            ).toLocal();
            final count = row.read<int>('sample_count');
            final sum = row.read<double>('sum_bpm');
            return <String, dynamic>{
              'bucket_start_ms': bucketStartMs,
              'bucket_end_ms': row.read<int>('bucket_end_ms'),
              'local_date': _day(local),
              'local_hour': local.hour,
              'sample_count': count,
              'avg_bpm': count > 0 ? _round1(sum / count) : null,
              'min_bpm': _round1(row.read<double>('min_bpm')),
              'max_bpm': _round1(row.read<double>('max_bpm')),
              'sum_bpm': sum,
              'source': row.read<String>('source'),
            };
          }(),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _readHrvSamples(
    int startMs,
    int endMs,
  ) async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT native_id, source_id, start_ms, end_ms, sdnn_ms
            FROM pulse_hrv_samples
            WHERE start_ms >= ? AND start_ms < ?
            ORDER BY start_ms ASC
            ''',
            variables: [
              drift.Variable.withInt(startMs),
              drift.Variable.withInt(endMs),
            ],
          )
          .get();
      return [
        for (final row in rows)
          () {
            final sMs = row.read<int>('start_ms');
            final local = DateTime.fromMillisecondsSinceEpoch(
              sMs,
              isUtc: true,
            ).toLocal();
            return <String, dynamic>{
              'native_id': row.read<String>('native_id'),
              'local_date': _day(local),
              'start_ms': sMs,
              'end_ms': row.read<int>('end_ms'),
              'sdnn_ms': _round1(row.read<double>('sdnn_ms')),
              'source_id': row.read<String>('source_id'),
            };
          }(),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _readWorkoutHeartRates({
    required DateTime startLocal,
    required DateTime endExclusiveLocal,
    required List<Map<String, dynamic>> hourlyRows,
    required bool allowLiveFetch,
  }) async {
    try {
      final startSec = startLocal.millisecondsSinceEpoch ~/ 1000;
      final endSec = endExclusiveLocal.millisecondsSinceEpoch ~/ 1000;
      final workouts = await database
          .customSelect(
            '''
            SELECT w.id, w.start_time, w.end_time,
                   COALESCE(NULLIF(r.name, ''), w.routine_name_snapshot) AS routine_name
            FROM workout_logs w
            LEFT JOIN routines r ON r.id = w.routine_id AND r.deleted_at IS NULL
            WHERE w.deleted_at IS NULL
              AND w.end_time IS NOT NULL
              AND w.start_time >= ? AND w.start_time < ?
            ORDER BY w.start_time DESC
            LIMIT ?
            ''',
            variables: [
              drift.Variable.withInt(startSec),
              drift.Variable.withInt(endSec),
              drift.Variable.withInt(maxWorkoutsForLiveHr),
            ],
          )
          .get();
      if (workouts.isEmpty) return const [];

      final results = <Map<String, dynamic>>[];
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      for (final workout in workouts) {
        final workoutId = workout.read<String>('id');
        final startTime = _fromEpoch(workout.read<int>('start_time'));
        final endTime = _fromEpoch(workout.read<int>('end_time'));
        final routineName = workout.readNullable<String>('routine_name');

        WorkoutHeartRateSummary? live;
        if (allowLiveFetch && DateTime.now().isBefore(deadline)) {
          try {
            live = await _workoutHeartRateService
                .loadForWorkoutWindow(startTime: startTime, endTime: endTime)
                .timeout(const Duration(milliseconds: 800));
          } catch (_) {
            live = null;
          }
        }
        if (live != null && live.hasData) {
          results.add({
            'workout_log_id': workoutId,
            'workout_start_local': startTime.toIso8601String(),
            'workout_end_local': endTime.toIso8601String(),
            'routine_name': routineName,
            'avg_bpm': live.averageBpm == null
                ? null
                : _round1(live.averageBpm!),
            'min_bpm': live.minBpm == null ? null : _round1(live.minBpm!),
            'max_bpm': live.maxBpm == null ? null : _round1(live.maxBpm!),
            'sample_count': live.sampleCount,
            'quality': live.quality.name,
            'source': 'platform_workout_window',
          });
          continue;
        }

        // Fallback to overlapping hourly aggregates if available.
        final startMs = startTime.toUtc().millisecondsSinceEpoch;
        final endMs = endTime.toUtc().millisecondsSinceEpoch;
        final overlapping = hourlyRows.where((bucket) {
          final bStart = bucket['bucket_start_ms'] as int;
          final bEnd = bucket['bucket_end_ms'] as int;
          return bEnd > startMs && bStart < endMs;
        }).toList();
        if (overlapping.isNotEmpty) {
          var count = 0;
          var sum = 0.0;
          var minVal = double.infinity;
          var maxVal = double.negativeInfinity;
          for (final bucket in overlapping) {
            final c = (bucket['sample_count'] as num).toInt();
            count += c;
            sum += (bucket['sum_bpm'] as num).toDouble();
            minVal = math.min(minVal, (bucket['min_bpm'] as num).toDouble());
            maxVal = math.max(maxVal, (bucket['max_bpm'] as num).toDouble());
          }
          if (count > 0) {
            results.add({
              'workout_log_id': workoutId,
              'workout_start_local': startTime.toIso8601String(),
              'workout_end_local': endTime.toIso8601String(),
              'routine_name': routineName,
              'avg_bpm': _round1(sum / count),
              'min_bpm': _round1(minVal),
              'max_bpm': _round1(maxVal),
              'sample_count': count,
              'quality': 'estimated_hourly',
              'source': 'hourly_aggregate_fallback',
            });
          }
        }
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _lastSyncedIso() async {
    try {
      final row = await database
          .customSelect(
            "SELECT value FROM pulse_aggregate_metadata WHERE key = 'last_aggregated_sample_at_ms'",
          )
          .getSingleOrNull();
      final ms = int.tryParse(row?.read<String>('value') ?? '');
      if (ms == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        ms,
        isUtc: true,
      ).toIso8601String();
    } catch (_) {
      return null;
    }
  }

  DateTime _fromEpoch(int raw) {
    final ms = raw.abs() < 100000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  }

  double _round1(double value) => (value * 10).roundToDouble() / 10;

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
