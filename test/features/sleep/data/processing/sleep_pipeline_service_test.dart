import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/sleep/data/processing/sleep_pipeline_service.dart';
import 'package:train_libre/features/sleep/platform/ingestion/sleep_ingestion_models.dart';

void main() {
  test(
    'pipeline imports, persists analyses and supports forced recompute',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final batch = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'session-1',
            startAtUtc: DateTime.utc(2026, 3, 1, 22),
            endAtUtc: DateTime.utc(2026, 3, 2, 6),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: [
          SleepIngestionStageSegment(
            recordId: 'seg-1',
            sessionRecordId: 'session-1',
            startAtUtc: DateTime.utc(2026, 3, 1, 22),
            endAtUtc: DateTime.utc(2026, 3, 2, 2),
            platformStage: 'core',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionStageSegment(
            recordId: 'seg-2',
            sessionRecordId: 'session-1',
            startAtUtc: DateTime.utc(2026, 3, 2, 2),
            endAtUtc: DateTime.utc(2026, 3, 2, 2, 5),
            platformStage: 'awake',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionStageSegment(
            recordId: 'seg-3',
            sessionRecordId: 'session-1',
            startAtUtc: DateTime.utc(2026, 3, 2, 2, 5),
            endAtUtc: DateTime.utc(2026, 3, 2, 6),
            platformStage: 'core',
            sourcePlatform: 'healthkit',
          ),
        ],
        heartRateSamples: [
          SleepIngestionHeartRateSample(
            recordId: 'hr-1',
            sessionRecordId: 'session-1',
            sampledAtUtc: DateTime.utc(2026, 3, 2, 1),
            bpm: 52,
            sourcePlatform: 'healthkit',
          ),
        ],
      );

      final first = await service.runImport(batch: batch);
      expect(first.importedSessions, 1);
      expect(first.analyzedNights, 1);

      final second = await service.runImport(
        batch: batch,
        forceRecompute: true,
      );
      expect(second.importedSessions, 1);
      expect(second.analyzedNights, 1);

      final analysesCount = await db
          .customSelect('SELECT COUNT(*) c FROM sleep_nightly_analyses')
          .getSingle();
      expect(analysesCount.read<int>('c'), 1);

      final analysis = await db.customSelect('''
      SELECT
        analysis_version,
        score,
        interruptions_count,
        interruptions_wake_minutes,
        score_completeness,
        regularity_sri,
        regularity_valid_days,
        regularity_is_stable
      FROM sleep_nightly_analyses
      LIMIT 1
      ''').getSingle();
      expect(
        analysis.read<String>('analysis_version'),
        'sleep-health-score-v3',
      );
      expect(analysis.readNullable<double>('score'), isNotNull);
      expect(analysis.readNullable<int>('interruptions_count'), 1);
      expect(analysis.readNullable<int>('interruptions_wake_minutes'), 5);
      expect(
        analysis.readNullable<double>('score_completeness'),
        closeTo(0.65, 0.0001),
      );
      expect(analysis.readNullable<double>('regularity_sri'), isNull);
      expect(analysis.readNullable<int>('regularity_valid_days'), lessThan(5));
      expect(analysis.readNullable<int>('regularity_is_stable'), 0);

      await db.close();
    },
  );

  test(
    'pipeline gracefully excludes architecture from completeness when stages are missing',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final batch = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'withings-session-1',
            startAtUtc: DateTime.utc(2026, 3, 1, 22),
            endAtUtc: DateTime.utc(2026, 3, 2, 6),
            platformSessionType: 'sleep',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
        ],
        stageSegments: [
          SleepIngestionStageSegment(
            recordId: 'withings-seg-1',
            sessionRecordId: 'withings-session-1',
            startAtUtc: DateTime.utc(2026, 3, 1, 22),
            endAtUtc: DateTime.utc(2026, 3, 2, 5, 10),
            platformStage: 'light',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
          SleepIngestionStageSegment(
            recordId: 'withings-seg-2',
            sessionRecordId: 'withings-session-1',
            startAtUtc: DateTime.utc(2026, 3, 2, 5, 10),
            endAtUtc: DateTime.utc(2026, 3, 2, 6),
            platformStage: 'deep',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
        ],
        heartRateSamples: const [],
      );

      await service.runImport(batch: batch);

      final analysis = await db.customSelect('''
      SELECT score, score_completeness
      FROM sleep_nightly_analyses
      WHERE session_id = 'withings-session-1'
      LIMIT 1
      ''').getSingle();

      final score = analysis.readNullable<double>('score');
      expect(score, isNotNull);
      expect(
        analysis.readNullable<double>('score_completeness'),
        closeTo(0.65, 0.0001),
      );

      await db.close();
    },
  );

  test(
    'forced recompute deletes raw imports for sessions in target window',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final batchOne = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'session-1',
            startAtUtc: DateTime.utc(2026, 3, 1, 22),
            endAtUtc: DateTime.utc(2026, 3, 2, 6),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      final batchTwo = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'session-2',
            startAtUtc: DateTime.utc(2026, 3, 10, 22),
            endAtUtc: DateTime.utc(2026, 3, 11, 6),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      await service.runImport(batch: batchOne);

      await service.runImport(
        batch: batchTwo,
        forceRecompute: true,
        recomputeFromInclusive: DateTime.utc(2026, 3, 1),
        recomputeToExclusive: DateTime.utc(2026, 3, 3),
      );

      final rows = await db
          .customSelect('SELECT id FROM sleep_raw_imports ORDER BY id')
          .get();
      final ids = rows.map((row) => row.read<String>('id')).toList();
      expect(ids, ['raw:session-2']);

      await db.close();
    },
  );

  test(
    'pipeline uses regularity in score when enough valid days exist',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final sessions = <SleepIngestionSession>[];
      final segments = <SleepIngestionStageSegment>[];
      for (var i = 0; i < 7; i++) {
        final start = DateTime.utc(2026, 3, 1 + i, 22);
        final end = DateTime.utc(2026, 3, 2 + i, 6);
        final sessionId = 'session-$i';
        sessions.add(
          SleepIngestionSession(
            recordId: sessionId,
            startAtUtc: start,
            endAtUtc: end,
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        );
        segments.addAll([
          SleepIngestionStageSegment(
            recordId: 'seg-$i-1',
            sessionRecordId: sessionId,
            startAtUtc: start,
            endAtUtc: start.add(const Duration(hours: 4)),
            platformStage: 'core',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionStageSegment(
            recordId: 'seg-$i-2',
            sessionRecordId: sessionId,
            startAtUtc: start.add(const Duration(hours: 4)),
            endAtUtc: start.add(const Duration(hours: 4, minutes: 10)),
            platformStage: 'awake',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionStageSegment(
            recordId: 'seg-$i-3',
            sessionRecordId: sessionId,
            startAtUtc: start.add(const Duration(hours: 4, minutes: 10)),
            endAtUtc: end,
            platformStage: 'core',
            sourcePlatform: 'healthkit',
          ),
        ]);
      }
      final batch = SleepRawIngestionBatch(
        sessions: sessions,
        stageSegments: segments,
        heartRateSamples: const [],
      );
      await service.runImport(batch: batch);

      final latest = await db.customSelect('''
      SELECT
        score,
        score_completeness,
        regularity_sri,
        regularity_valid_days,
        regularity_is_stable
      FROM sleep_nightly_analyses
      WHERE night_date = '2026-03-08'
      LIMIT 1
      ''').getSingle();
      expect(latest.readNullable<double>('score'), isNotNull);
      expect(
        latest.readNullable<double>('score_completeness'),
        closeTo(0.75, 0.0001),
      );
      expect(latest.readNullable<double>('regularity_sri'), isNotNull);
      expect(
        latest.readNullable<int>('regularity_valid_days'),
        greaterThanOrEqualTo(7),
      );
      expect(latest.readNullable<int>('regularity_is_stable'), 1);

      await db.close();
    },
  );

  test(
    'pipeline keeps the longest session for identical starts from the same source',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final start = DateTime.utc(2026, 3, 1, 23);
      final shortEnd = DateTime.utc(2026, 3, 2, 1);
      final longEnd = DateTime.utc(2026, 3, 2, 5, 30);
      final batch = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'session-short',
            startAtUtc: start,
            endAtUtc: shortEnd,
            platformSessionType: 'sleep',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
          SleepIngestionSession(
            recordId: 'session-long',
            startAtUtc: start,
            endAtUtc: longEnd,
            platformSessionType: 'sleep',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
        ],
        stageSegments: [
          SleepIngestionStageSegment(
            recordId: 'seg-short',
            sessionRecordId: 'session-short',
            startAtUtc: start,
            endAtUtc: shortEnd,
            platformStage: 'light',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
          SleepIngestionStageSegment(
            recordId: 'seg-long',
            sessionRecordId: 'session-long',
            startAtUtc: start,
            endAtUtc: longEnd,
            platformStage: 'light',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
        ],
        heartRateSamples: const [],
      );

      await service.runImport(batch: batch);

      final sessions = await db
          .customSelect(
            'SELECT id, ended_at FROM sleep_canonical_sessions ORDER BY id',
          )
          .get();
      expect(sessions.length, 1);
      expect(sessions.first.read<String>('id'), 'session-long');
      expect(
        sessions.first.read<int>('ended_at'),
        longEnd.millisecondsSinceEpoch,
      );

      final segments = await db
          .customSelect('SELECT COUNT(*) c FROM sleep_canonical_stage_segments')
          .getSingle();
      expect(segments.read<int>('c'), 1);

      await db.close();
    },
  );

  test(
    'pipeline preserves non-overlapping daytime naps from different records',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final napOne = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'nap-1',
            startAtUtc: DateTime.utc(2026, 3, 1, 13),
            endAtUtc: DateTime.utc(2026, 3, 1, 13, 30),
            platformSessionType: 'sleep',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      final napTwo = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'nap-2',
            startAtUtc: DateTime.utc(2026, 3, 1, 14),
            endAtUtc: DateTime.utc(2026, 3, 1, 14, 30),
            platformSessionType: 'sleep',
            sourcePlatform: 'health_connect',
            sourceAppId: 'com.withings.mobile',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      await service.runImport(batch: napOne);
      await service.runImport(batch: napTwo);

      final sessions = await db
          .customSelect('SELECT COUNT(*) c FROM sleep_canonical_sessions')
          .getSingle();
      expect(sessions.read<int>('c'), 2);

      await db.close();
    },
  );

  test(
    'pipeline handles multi-session sleep: classifies core vs. nap, sets nap score to null, aggregates volume metrics linearly, and dedupes overlaps by duration',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      final batch = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'core-session',
            startAtUtc: DateTime.utc(2026, 3, 1, 21),
            endAtUtc: DateTime.utc(2026, 3, 2, 5),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionSession(
            recordId: 'nap-session',
            startAtUtc: DateTime.utc(2026, 3, 2, 13),
            endAtUtc: DateTime.utc(2026, 3, 2, 13, 45),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: [
          SleepIngestionStageSegment(
            recordId: 'core-seg-1',
            sessionRecordId: 'core-session',
            startAtUtc: DateTime.utc(2026, 3, 1, 21),
            endAtUtc: DateTime.utc(2026, 3, 2, 1),
            platformStage: 'deep',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionStageSegment(
            recordId: 'core-seg-2',
            sessionRecordId: 'core-session',
            startAtUtc: DateTime.utc(2026, 3, 2, 1),
            endAtUtc: DateTime.utc(2026, 3, 2, 5),
            platformStage: 'core',
            sourcePlatform: 'healthkit',
          ),
          SleepIngestionStageSegment(
            recordId: 'nap-seg-1',
            sessionRecordId: 'nap-session',
            startAtUtc: DateTime.utc(2026, 3, 2, 13),
            endAtUtc: DateTime.utc(2026, 3, 2, 13, 45),
            platformStage: 'core',
            sourcePlatform: 'healthkit',
          ),
        ],
        heartRateSamples: const [],
      );

      final result = await service.runImport(batch: batch);
      expect(result.importedSessions, 2);
      expect(result.analyzedNights, 2);

      final dbSessions = await db.customSelect(
        'SELECT id, session_type FROM sleep_canonical_sessions ORDER BY id'
      ).get();
      expect(dbSessions.length, 2);
      expect(dbSessions[0].read<String>('id'), 'core-session');
      expect(dbSessions[0].read<String>('session_type'), 'mainSleep');
      expect(dbSessions[1].read<String>('id'), 'nap-session');
      expect(dbSessions[1].read<String>('session_type'), 'nap');

      final dbAnalyses = await db.customSelect(
        'SELECT id, session_id, score, total_sleep_minutes FROM sleep_nightly_analyses ORDER BY session_id'
      ).get();
      expect(dbAnalyses.length, 2);

      final coreAnalysis = dbAnalyses.firstWhere((a) => a.read<String>('session_id') == 'core-session');
      expect(coreAnalysis.readNullable<double>('score'), isNotNull);
      expect(coreAnalysis.readNullable<int>('total_sleep_minutes'), 525);

      final napAnalysis = dbAnalyses.firstWhere((a) => a.read<String>('session_id') == 'nap-session');
      expect(napAnalysis.readNullable<double>('score'), isNull);

      final shorterOverlappingNap = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'shorter-nap-session',
            startAtUtc: DateTime.utc(2026, 3, 2, 13, 10),
            endAtUtc: DateTime.utc(2026, 3, 2, 13, 40),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      final resultShort = await service.runImport(batch: shorterOverlappingNap);
      expect(resultShort.importedSessions, 0);

      final longerOverlappingNap = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'longer-nap-session',
            startAtUtc: DateTime.utc(2026, 3, 2, 12, 30),
            endAtUtc: DateTime.utc(2026, 3, 2, 14, 0),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      final resultLong = await service.runImport(batch: longerOverlappingNap);
      expect(resultLong.importedSessions, 1);

      final finalSessions = await db.customSelect(
        'SELECT id FROM sleep_canonical_sessions ORDER BY id'
      ).get();
      expect(finalSessions.length, 2);
      final finalIds = finalSessions.map((s) => s.read<String>('id')).toList();
      expect(finalIds.contains('core-session'), isTrue);
      expect(finalIds.contains('longer-nap-session'), isTrue);
      expect(finalIds.contains('nap-session'), isFalse);

      await db.close();
    },
  );

  test(
    'pipeline allows non-enveloping overlaps to coexist (e.g. nap starting before main sleep ends)',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      final service = SleepPipelineService(database: db);

      // 1. Main Sleep: 22:00 to 06:00 (8 hours)
      final mainSleep = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'main-sleep',
            startAtUtc: DateTime.utc(2026, 3, 1, 22),
            endAtUtc: DateTime.utc(2026, 3, 2, 6),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      // 2. Overlapping Nap: 05:30 to 07:00 (1.5 hours) - overlaps but not enveloped
      final overlappingNap = SleepRawIngestionBatch(
        sessions: [
          SleepIngestionSession(
            recordId: 'overlapping-nap',
            startAtUtc: DateTime.utc(2026, 3, 2, 5, 30),
            endAtUtc: DateTime.utc(2026, 3, 2, 7),
            platformSessionType: 'sleep',
            sourcePlatform: 'healthkit',
          ),
        ],
        stageSegments: const [],
        heartRateSamples: const [],
      );

      await service.runImport(batch: mainSleep);
      final secondResult = await service.runImport(batch: overlappingNap);

      // In the new logic, both should be imported because neither envelopes the other
      expect(secondResult.importedSessions, 1);

      final sessions = await db
          .customSelect('SELECT COUNT(*) c FROM sleep_canonical_sessions')
          .getSingle();
      expect(sessions.read<int>('c'), 2);

      await db.close();
    },
  );
}
