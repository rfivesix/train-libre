import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/media/app_media_store.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/ai_assistant/application/assistant_chat_service.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_analytics_actions.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_database_snapshot_reader.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_diary_actions.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_health_actions.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_history_repository.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_pulse_actions.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_sql_sandbox.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_training_actions.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_action.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_request.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_intent_planner.dart';
import 'package:train_libre/features/diary/data/nutrition_repository.dart';
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/data/profile_repository.dart';
import 'package:train_libre/features/profile/data/sources/profile_local_data_source.dart';
import 'package:train_libre/features/pulse/application/pulse_tracking_service.dart';
import 'package:train_libre/features/pulse/data/hrv_repository.dart';
import 'package:train_libre/features/pulse/data/pulse_repository.dart';
import 'package:train_libre/features/pulse/domain/pulse_models.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_controller.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:train_libre/features/sleep/platform/sleep_sync_service.dart';
import 'package:train_libre/features/steps/data/steps_aggregation_repository.dart';
import 'package:train_libre/features/steps/domain/steps_models.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/services/health/health_platform_heart_rate.dart';
import 'package:train_libre/services/health/workout_heart_rate_service.dart';
import 'package:train_libre/util/cancellation_token.dart';

class _FakePulseTrackingService implements PulseTrackingSettingsService {
  _FakePulseTrackingService(this.enabled);
  bool enabled;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<bool> requestPermissions() async => enabled;

  @override
  Future<void> setTrackingEnabled(bool value) async {
    enabled = value;
  }
}

class _FakePulseRepository implements PulseAnalysisRepository {
  _FakePulseRepository({required this.enabled, required this.summary});
  final bool enabled;
  final PulseAnalysisSummary summary;
  int calls = 0;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  }) async {
    calls++;
    return summary;
  }
}

class _FakeHeartRateSource implements HealthHeartRateDataSource {
  _FakeHeartRateSource(this.samples);
  final List<HealthHeartRateSampleDto> samples;

  @override
  Future<List<HealthHeartRateSampleDto>> readHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async => samples;
}

class _FakeStepsRepo implements StepsAggregationRepository {
  _FakeStepsRepo({required this.enabled, this.daily = const []});
  bool enabled;
  final List<StepsBucket> daily;
  int refreshCalls = 0;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<StepsRefreshResult> refresh({
    bool force = false,
    DateTime? now,
  }) async {
    refreshCalls++;
    return StepsRefreshResult(
      didRun: true,
      permissionGranted: true,
      skipped: false,
      fetchedCount: 0,
      upsertedCount: 0,
      lastUpdatedAtUtc: DateTime.utc(2026, 11, 20, 10),
    );
  }

  @override
  Future<DateTime?> getEarliestAvailableDate() async =>
      daily.isEmpty ? null : daily.first.start;

  @override
  Future<RangeStepsAggregation> getRangeAggregation({
    required DateTime endDate,
    required int daysBack,
  }) async {
    final total = daily.fold<int>(0, (sum, b) => sum + b.steps);
    return RangeStepsAggregation(
      start: daily.isEmpty ? endDate : daily.first.start,
      end: endDate,
      dailyTotals: daily,
      totalSteps: total,
      averageDailySteps: daily.isEmpty ? 0 : total / daily.length,
    );
  }

  @override
  Future<DayStepsAggregation> getDayAggregation(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    return DayStepsAggregation(
      date: normalized,
      hourlyBuckets: [
        StepsBucket(start: normalized.add(const Duration(hours: 8)), steps: 2200),
        StepsBucket(start: normalized.add(const Duration(hours: 17)), steps: 4300),
      ],
      totalSteps: 6500,
    );
  }

  @override
  Future<int> getCurrentTargetStepsOrDefault() async => 10000;

  @override
  Future<DateTime?> getLastUpdatedAt() async => DateTime.utc(2026, 11, 20, 10);

  @override
  Future<MonthStepsAggregation> getMonthAggregation(DateTime dateInMonth) =>
      throw UnimplementedError();

  @override
  Future<WeekStepsAggregation> getWeekAggregation(DateTime dateInWeek) =>
      throw UnimplementedError();

  @override
  Stream<DayStepsAggregation> watchDayAggregation(DateTime date) =>
      Stream.fromFuture(getDayAggregation(date));
}

class _FakeSleepPermissions implements SleepPermissionsService {
  @override
  Future<SleepPermissionOutcome> checkStatus() async =>
      const SleepPermissionOutcome.ready();

  @override
  Future<SleepPermissionOutcome> requestAccess() => checkStatus();
}

class _FakeSleepSyncService implements SleepSettingsService {
  _FakeSleepSyncService({required this.enabled});
  bool enabled;
  int importIfDueCalls = 0;

  @override
  SleepPermissionController buildPermissionController() =>
      SleepPermissionController(_FakeSleepPermissions());

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<void> setTrackingEnabled(bool value) async {
    enabled = value;
  }

  @override
  Future<SleepSyncResult> importRecent({
    int lookbackDays = 90,
    bool forceFullSync = false,
    CancellationToken? token,
    void Function(int index, int total)? onProgress,
  }) async => const SleepSyncResult(
    success: true,
    permissionState: SleepPermissionState.ready,
    importedSessions: 0,
  );

  @override
  Future<SleepSyncResult?> importRecentIfDue({
    int lookbackDays = 90,
    Duration minInterval = const Duration(hours: 6),
    bool force = false,
  }) async {
    importIfDueCalls++;
    return const SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: 0,
    );
  }

  @override
  Future<void> dispose() async {}
}

class _StubModel implements AssistantModelClient {
  final decisions = Queue<String>();
  final responses = Queue<String>();
  final seenPrompts = <String>[];

  @override
  Future<AssistantModelIdentity> identity() async =>
      const AssistantModelIdentity('test', 'model', null);

  @override
  Future<String> interpret({
    required String prompt,
    required AssistantModelIdentity identity,
  }) async => decisions.removeFirst();

  @override
  Stream<String> answer({
    required String prompt,
    required AssistantModelIdentity identity,
    required Future<void> Function() onDispatch,
  }) async* {
    seenPrompts.add(prompt);
    await onDispatch();
    yield responses.removeFirst();
  }
}

class _ScopedWorkoutsAction implements AssistantDataAction {
  final seenScopes = <AssistantDateScope?>[];

  @override
  Set<AssistantDataCategory> get categories => const {
    AssistantDataCategory.workouts,
  };

  @override
  Future<AssistantActionResult> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    seenScopes.add(scope);
    return AssistantActionResult(
      category: category,
      status: AssistantActionStatus.success,
      records: [
        {
          'ref': 'workout:${scope?.start.toIso8601String() ?? 'all'}',
          'startedAt': (scope?.start ?? DateTime(2026, 11, 20)).toIso8601String(),
        },
      ],
    );
  }
}

class _UnavailableStepsAction implements AssistantDataAction {
  @override
  Set<AssistantDataCategory> get categories => const {
    AssistantDataCategory.steps,
  };

  @override
  Future<AssistantActionResult> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async => const AssistantActionResult(
    category: AssistantDataCategory.steps,
    status: AssistantActionStatus.unavailable,
    sourceStatus: {
      'status': 'disabled',
      'tracking_enabled': 0,
      'permission_state': null,
      'last_synced_at': null,
      'detail': 'Step tracking is disabled in Health settings.',
    },
    error: 'Step tracking is disabled.',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1: SQL Sandbox JSON & CTE upgrades + data_source_status', () {
    test('supports safe scalar JSON functions and CTE multi-reference comparisons while rejecting unsafe SQL', () async {
      final sandbox = await AssistantSqlSandbox.create([
        const AssistantActionResult(
          category: AssistantDataCategory.workouts,
          status: AssistantActionStatus.success,
          records: [
            {
              'ref': 'w1',
              'week': 'current',
              'meta': '{"rpe":8,"tags":["heavy","pr"]}',
              'volume': 1200,
            },
            {
              'ref': 'w2',
              'week': 'previous',
              'meta': '{"rpe":7,"tags":["normal"]}',
              'volume': 1000,
            },
          ],
        ),
        const AssistantActionResult(
          category: AssistantDataCategory.pulse,
          status: AssistantActionStatus.unavailable,
          sourceStatus: {
            'status': 'disabled',
            'tracking_enabled': 0,
            'permission_state': null,
            'last_synced_at': null,
            'detail': 'Pulse tracking is disabled in Health settings.',
          },
          error: 'Pulse tracking is disabled.',
        ),
      ]);
      addTearDown(sandbox.close);

      final jsonQuery = await sandbox.query('''
        SELECT ref,
               json_extract(meta, '\$.rpe') AS rpe,
               json_array_length(meta, '\$.tags') AS tag_count
        FROM data_workouts
        ORDER BY ref
      ''');
      expect(jsonQuery.rows, [
        {'ref': 'w1', 'rpe': 8, 'tag_count': 2},
        {'ref': 'w2', 'rpe': 7, 'tag_count': 1},
      ]);

      final cteCompare = await sandbox.query('''
        WITH cur AS (SELECT SUM(volume) AS v FROM data_workouts WHERE week = 'current'),
             prev AS (SELECT SUM(volume) AS v FROM data_workouts WHERE week = 'previous')
        SELECT cur.v - prev.v AS delta FROM cur JOIN prev ON 1 = 1
      ''');
      expect(cteCompare.rows.single['delta'], 200);

      final statusQuery = await sandbox.query(
        'SELECT category, status, tracking_enabled FROM data_source_status',
      );
      expect(statusQuery.rows.single['category'], 'pulse');
      expect(statusQuery.rows.single['status'], 'disabled');
      expect(statusQuery.rows.single['tracking_enabled'], 0);

      // Table-valued JSON functions and >3 table references remain blocked.
      await expectLater(
        sandbox.query(
          "SELECT value FROM data_workouts, json_each(data_workouts.meta)",
        ),
        throwsA(isA<AssistantSqlQueryException>()),
      );
      await expectLater(
        sandbox.query('''
          WITH a AS (SELECT ref FROM data_workouts),
               b AS (SELECT ref FROM data_workouts),
               c AS (SELECT ref FROM data_workouts),
               d AS (SELECT ref FROM data_workouts)
          SELECT a.ref FROM a JOIN b ON a.ref = b.ref JOIN c ON b.ref = c.ref JOIN d ON c.ref = d.ref
        '''),
        throwsA(isA<AssistantSqlQueryException>()),
      );
    });
  });

  group('Phase 1 & 6: Chat Service partial availability, multi-scope, and scope widening', () {
    late Directory tempDir;
    late db.AppDatabase database;
    late AssistantHistoryRepository history;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('assistant_expanded_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tempDir.path,
          );
      AppMediaStore.instance.resetForTesting();
      database = db.AppDatabase(NativeDatabase.memory());
      history = AssistantHistoryRepository(database);
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      AppMediaStore.instance.resetForTesting();
      await database.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('partial availability keeps working when one health source is disabled', () async {
      final workoutsAction = _ScopedWorkoutsAction();
      final model = _StubModel();
      final chat = AssistantChatService(
        history: history,
        data: AssistantDataGateway([workoutsAction, _UnavailableStepsAction()]),
        model: model,
      );

      model.decisions.add(
        jsonEncode({
          'kind': 'data',
          'categories': ['workouts', 'steps'],
          'scope': {
            'start': '2026-11-14',
            'end': '2026-11-20',
            'label': 'last 7 days',
          },
        }),
      );
      model.responses.addAll([
        jsonEncode({
          'type': 'query',
          'sql': 'SELECT category, status FROM data_source_status',
        }),
        jsonEncode({
          'type': 'answer',
          'answer': 'Workouts loaded; step tracking is disabled.',
        }),
      ]);

      final submission = await chat.submit(
        'How were my workouts and steps this week?',
        now: DateTime(2026, 11, 20, 12),
        locale: 'en',
      );
      final answer = await chat
          .approveAndAnswer(
            submission.access!.id,
            submission.userMessage.content,
            locale: 'en',
          )
          .join();
      expect(answer, contains('step tracking is disabled'));
      expect(model.seenPrompts.first, contains('data_source_status'));
    });

    test('single unavailable category returns a clear local status without calling the model', () async {
      final model = _StubModel();
      final chat = AssistantChatService(
        history: history,
        data: AssistantDataGateway([_UnavailableStepsAction()]),
        model: model,
      );
      model.decisions.add(
        jsonEncode({
          'kind': 'data',
          'categories': ['steps'],
          'scope': {
            'start': '2026-11-14',
            'end': '2026-11-20',
            'label': 'last 7 days',
          },
        }),
      );
      final submission = await chat.submit(
        'Wie viele Schritte hatte ich?',
        now: DateTime(2026, 11, 20, 12),
        locale: 'de-DE',
      );
      final answer = await chat
          .approveAndAnswer(
            submission.access!.id,
            submission.userMessage.content,
            locale: 'de-DE',
          )
          .join();
      expect(answer, contains('Schritte'));
      expect(model.seenPrompts, isEmpty);
    });

    test('request_data allows widening an already-approved category scope after fresh approval', () async {
      final workoutsAction = _ScopedWorkoutsAction();
      final model = _StubModel();
      final chat = AssistantChatService(
        history: history,
        data: AssistantDataGateway([workoutsAction]),
        model: model,
      );

      model.decisions.add(
        jsonEncode({
          'kind': 'data',
          'categories': ['workouts'],
          'scope': {
            'start': '2026-11-14',
            'end': '2026-11-20',
            'label': 'last 7 days',
          },
        }),
      );
      model.responses.addAll([
        jsonEncode({
          'type': 'request_data',
          'categories': ['workouts'],
          'scope': {
            'start': '2026-10-20',
            'end': '2026-11-20',
            'label': 'last 30 days',
          },
        }),
        jsonEncode({
          'type': 'answer',
          'answer': 'Widened to 30 days successfully.',
        }),
      ]);

      final submission = await chat.submit(
        'Compare my workouts over the month',
        now: DateTime(2026, 11, 20, 12),
        locale: 'en',
      );
      var additionalApproved = 0;
      final answer = await chat
          .approveAndAnswer(
            submission.access!.id,
            submission.userMessage.content,
            locale: 'en',
            onAdditionalAccess: (_) async {
              additionalApproved++;
              return true;
            },
          )
          .join();
      expect(additionalApproved, 1);
      expect(workoutsAction.seenScopes, hasLength(2));
      expect(workoutsAction.seenScopes.last!.start, DateTime(2026, 10, 20));
      expect(answer, contains('Widened to 30 days'));
    });

    test('intent planner parses per-category scopes and optional analytics scope', () {
      const planner = AssistantIntentPlanner();
      final now = DateTime(2026, 11, 20, 12);
      final mixed = planner.parse(
        jsonEncode({
          'kind': 'data',
          'categories': ['diary', 'workouts', 'analytics'],
          'categoryScopes': {
            'diary': {
              'start': '2026-11-20',
              'end': '2026-11-20',
              'label': 'today',
            },
            'workouts': {
              'start': '2026-10-22',
              'end': '2026-11-20',
              'label': 'last 30 days',
            },
          },
        }),
        now: now,
        locale: 'en',
      );
      expect(mixed.kind, AssistantIntentKind.data);
      expect(
        mixed.request!.scopeFor(AssistantDataCategory.diary)!.start,
        DateTime(2026, 11, 20),
      );
      expect(
        mixed.request!.scopeFor(AssistantDataCategory.workouts)!.start,
        DateTime(2026, 10, 22),
      );

      final analyticsWithScope = planner.parse(
        jsonEncode({
          'kind': 'data',
          'categories': ['analytics'],
          'scope': {
            'start': '2026-10-22',
            'end': '2026-11-20',
            'label': 'last 30 days',
          },
        }),
        now: now,
        locale: 'en',
      );
      expect(analyticsWithScope.kind, AssistantIntentKind.data);
      expect(analyticsWithScope.request!.categories, {
        AssistantDataCategory.analytics,
      });
    });
  });

  group('Phase 2: Pulse, Resting HR, HRV & Workout Heart Rate', () {
    late db.AppDatabase database;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    test('returns unavailable status when pulse tracking is disabled', () async {
      final action = AssistantPulseActions(
        database: database,
        trackingService: _FakePulseTrackingService(false),
      );
      final result = await action.read(
        AssistantDataCategory.pulse,
        AssistantDateScope(
          DateTime(2026, 11, 18),
          DateTime(2026, 11, 20),
          'last 3 days',
        ),
      );
      expect(result.status, AssistantActionStatus.unavailable);
      expect(result.sourceStatus?['status'], 'disabled');
    });

    test('reads pulse_daily_summary, hourly buckets, HRV samples, and workout heart rate', () async {
      final dayStart = DateTime(2026, 11, 19, 8);
      final workoutStart = DateTime(2026, 11, 19, 9);
      final workoutEnd = DateTime(2026, 11, 19, 10);

      await database.customStatement(
        '''
        INSERT INTO pulse_hourly_aggregates
          (bucket_start_ms, bucket_end_ms, sample_count, min_bpm, max_bpm, sum_bpm,
           first_sample_ms, last_sample_ms, source, aggregation_version, updated_at_ms)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'platform', 1, ?)
        ''',
        [
          dayStart.toUtc().millisecondsSinceEpoch,
          dayStart.add(const Duration(hours: 1)).toUtc().millisecondsSinceEpoch,
          10,
          54.0,
          78.0,
          640.0,
          dayStart.toUtc().millisecondsSinceEpoch,
          dayStart.add(const Duration(minutes: 50)).toUtc().millisecondsSinceEpoch,
          dayStart.toUtc().millisecondsSinceEpoch,
        ],
      );
      await database.customStatement(
        '''
        INSERT INTO pulse_hrv_samples (native_id, source_id, start_ms, end_ms, sdnn_ms)
        VALUES ('hrv-1', 'watch', ?, ?, 62.4)
        ''',
        [
          dayStart.toUtc().millisecondsSinceEpoch,
          dayStart.add(const Duration(minutes: 1)).toUtc().millisecondsSinceEpoch,
        ],
      );
      final workout = await database
          .into(database.workoutLogs)
          .insertReturning(
            db.WorkoutLogsCompanion.insert(
              startTime: workoutStart,
              endTime: drift.Value(workoutEnd),
              status: const drift.Value('completed'),
              routineNameSnapshot: const drift.Value('Push Day'),
            ),
          );

      final fakeWindow = PulseAnalysisWindow(
        startUtc: DateTime(2026, 11, 19).toUtc(),
        endUtc: DateTime(2026, 11, 20).toUtc(),
      );
      final action = AssistantPulseActions(
        database: database,
        trackingService: _FakePulseTrackingService(true),
        pulseRepository: _FakePulseRepository(
          enabled: true,
          summary: PulseAnalysisSummary(
            window: fakeWindow,
            samples: const [],
            chartSamples: const [],
            sampleCount: 10,
            averageBpm: 64.0,
            minBpm: 54.0,
            maxBpm: 78.0,
            restingBpm: 52.0,
            restingBpmIsEstimated: false,
            quality: PulseDataQuality.ready,
            noDataReason: PulseNoDataReason.none,
            hrv: HrvSummary(
              state: HrvState.available,
              samples: [
                HrvSample(
                  startUtc: dayStart.toUtc(),
                  endUtc: dayStart.add(const Duration(minutes: 1)).toUtc(),
                  sdnnMs: 62.4,
                  sourceId: 'watch',
                  nativeId: 'hrv-1',
                ),
              ],
            ),
          ),
        ),
        workoutHeartRateService: WorkoutHeartRateService(
          dataSource: _FakeHeartRateSource([
            HealthHeartRateSampleDto(
              sampledAtUtc: workoutStart.add(const Duration(minutes: 10)).toUtc(),
              bpm: 128,
            ),
            HealthHeartRateSampleDto(
              sampledAtUtc: workoutStart.add(const Duration(minutes: 30)).toUtc(),
              bpm: 152,
            ),
            HealthHeartRateSampleDto(
              sampledAtUtc: workoutStart.add(const Duration(minutes: 50)).toUtc(),
              bpm: 140,
            ),
          ]),
        ),
      );

      final result = await action.read(
        AssistantDataCategory.pulse,
        AssistantDateScope(
          DateTime(2026, 11, 19),
          DateTime(2026, 11, 19),
          'explicit date',
        ),
      );
      expect(result.status, AssistantActionStatus.success);
      final daily = result.tables['pulse_daily_summary']!.single;
      expect(daily['resting_bpm'], 52.0);
      expect(daily['resting_bpm_is_estimated'], 0);
      expect(daily['hrv_avg_sdnn_ms'], 62.4);

      final workoutHr = result.tables['workout_heart_rate_summary']!.single;
      expect(workoutHr['workout_log_id'], workout.id);
      expect(workoutHr['avg_bpm'], 140.0);
      expect(workoutHr['max_bpm'], 152.0);
    });
  });

  group('Phase 3, 4 & 5: Sleep, Steps, Nutrition, Goals/TDEE, Recipes, Sequence Plans & Analytics', () {
    late db.AppDatabase database;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'targetSugar': 45,
        'targetFiber': 35,
        'targetSalt': 6,
        'targetCaffeine': 300,
        'overviewExtraNutrient': 'fiber',
        'steps_tracking_enabled': true,
        'sleep_tracking_enabled': true,
        'pulse_tracking_enabled': false,
      });
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    test('sleep_nightly_summary deduplicates primary night, aggregates stages, and excludes sleep_raw_imports', () async {
      final bedtime = DateTime(2026, 11, 18, 23, 0);
      final wake = DateTime(2026, 11, 19, 7, 0);
      final nowMs = DateTime(2026, 11, 19, 8, 0).millisecondsSinceEpoch;

      await database.customStatement(
        '''
        INSERT INTO sleep_raw_imports
          (id, source_platform, source_record_hash, import_status, imported_at, payload_json)
        VALUES ('raw-1', 'iosHealthKit', 'h1', 'imported', ?, '{"huge":"blob"}')
        ''',
        [nowMs],
      );
      await database.customStatement(
        '''
        INSERT INTO sleep_canonical_sessions
          (id, raw_import_id, source_platform, source_record_hash, normalization_version,
           session_type, started_at, ended_at, imported_at, normalized_at)
        VALUES
          ('sess-main', 'raw-1', 'iosHealthKit', 'h1', 'v1', 'mainSleep', ?, ?, ?, ?),
          ('sess-nap', 'raw-1', 'iosHealthKit', 'h2', 'v1', 'nap', ?, ?, ?, ?)
        ''',
        [
          bedtime.millisecondsSinceEpoch,
          wake.millisecondsSinceEpoch,
          nowMs,
          nowMs,
          DateTime(2026, 11, 19, 14, 0).millisecondsSinceEpoch,
          DateTime(2026, 11, 19, 14, 30).millisecondsSinceEpoch,
          nowMs,
          nowMs,
        ],
      );
      await database.customStatement(
        '''
        INSERT INTO sleep_canonical_stage_segments
          (id, session_id, source_platform, source_record_hash, normalization_version,
           stage, started_at, ended_at, imported_at, normalized_at)
        VALUES
          ('seg-1', 'sess-main', 'iosHealthKit', 'h1', 'v1', 'deep', ?, ?, ?, ?),
          ('seg-2', 'sess-main', 'iosHealthKit', 'h1', 'v1', 'rem', ?, ?, ?, ?),
          ('seg-3', 'sess-main', 'iosHealthKit', 'h1', 'v1', 'light', ?, ?, ?, ?),
          ('seg-4', 'sess-main', 'iosHealthKit', 'h1', 'v1', 'awake', ?, ?, ?, ?)
        ''',
        [
          bedtime.millisecondsSinceEpoch,
          bedtime.add(const Duration(minutes: 90)).millisecondsSinceEpoch,
          nowMs,
          nowMs,
          bedtime.add(const Duration(minutes: 90)).millisecondsSinceEpoch,
          bedtime.add(const Duration(minutes: 200)).millisecondsSinceEpoch,
          nowMs,
          nowMs,
          bedtime.add(const Duration(minutes: 200)).millisecondsSinceEpoch,
          bedtime.add(const Duration(minutes: 460)).millisecondsSinceEpoch,
          nowMs,
          nowMs,
          bedtime.add(const Duration(minutes: 460)).millisecondsSinceEpoch,
          bedtime.add(const Duration(minutes: 480)).millisecondsSinceEpoch,
          nowMs,
          nowMs,
        ],
      );
      await database.customStatement(
        '''
        INSERT INTO sleep_canonical_heart_rate_samples
          (id, session_id, source_platform, source_record_hash, normalization_version,
           sampled_at, bpm, imported_at, normalized_at)
        VALUES
          ('hr-1', 'sess-main', 'iosHealthKit', 'h1', 'v1', ?, 48.0, ?, ?),
          ('hr-2', 'sess-main', 'iosHealthKit', 'h1', 'v1', ?, 56.0, ?, ?)
        ''',
        [
          bedtime.add(const Duration(hours: 2)).millisecondsSinceEpoch,
          nowMs,
          nowMs,
          bedtime.add(const Duration(hours: 5)).millisecondsSinceEpoch,
          nowMs,
          nowMs,
        ],
      );
      final breakdown = jsonEncode({
        'score': 88.0,
        'durationScore': 0.96,
        'continuityScore': 0.90,
        'deepScore': 1.0,
        'remScore': 1.0,
        'regularityScore': 0.82,
      });
      await database.customStatement(
        '''
        INSERT INTO sleep_nightly_analyses
          (id, session_id, source_platform, source_record_hash, normalization_version,
           analysis_version, night_date, score, total_sleep_minutes, sleep_efficiency_pct,
           resting_heart_rate_bpm, interruptions_count, interruptions_wake_minutes,
           score_completeness, score_breakdown_json, analyzed_at)
        VALUES
          ('an-main', 'sess-main', 'iosHealthKit', 'h1', 'v1', 'sleep-health-score-v4',
           '2026-11-19', 88.0, 460, 95.8, 52.0, 1, 20, 1.0, ?, ?),
          ('an-dup', 'sess-nap', 'iosHealthKit', 'h2', 'v1', 'sleep-health-score-v4',
           '2026-11-19', NULL, 30, NULL, NULL, NULL, NULL, NULL, NULL, ?)
        ''',
        [breakdown, nowMs, nowMs],
      );

      final reader = AssistantDatabaseSnapshotReader(database);
      final tables = await reader.read(
        AssistantDataCategory.sleep,
        AssistantDateScope(
          DateTime(2026, 11, 19),
          DateTime(2026, 11, 19),
          'explicit date',
        ),
      );
      expect(tables.containsKey('sleep_raw_imports'), isFalse);
      final summary = tables['sleep_nightly_summary']!.single;
      expect(summary['session_id'], 'sess-main');
      expect(summary['deep_minutes'], 90);
      expect(summary['rem_minutes'], 110);
      expect(summary['light_minutes'], 260);
      expect(summary['awake_minutes'], 20);
      expect(summary['avg_sleep_heart_rate_bpm'], 52.0);
      expect(summary['min_sleep_heart_rate_bpm'], 48.0);
      expect(summary['max_sleep_heart_rate_bpm'], 56.0);
      expect(summary['nap_count'], 1);
      expect(summary['nap_total_minutes'], 30);
      expect(summary['duration_subscore'], 0.96);

      // Long range (> 7 days) omits raw nocturnal HR samples to stay compact.
      final longTables = await reader.read(
        AssistantDataCategory.sleep,
        AssistantDateScope(
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 20),
          'last 20 days',
        ),
      );
      expect(
        longTables.containsKey('sleep_canonical_heart_rate_samples'),
        isFalse,
      );
      expect(longTables['sleep_nightly_summary'], hasLength(1));
    });

    test('steps_daily_summary and steps_hourly_summary trigger refresh and include step targets', () async {
      final stepsRepo = _FakeStepsRepo(
        enabled: true,
        daily: [StepsBucket(start: DateTime(2026, 11, 20), steps: 11200)],
      );
      final sleepSync = _FakeSleepSyncService(enabled: true);
      final action = AssistantHealthActions(
        database: database,
        steps: stepsRepo,
        profile: ProfileRepository(
          localDataSource: ProfileLocalDataSource(database),
        ),
        goals: GoalRepositoryImpl(database: database),
        sleepSync: sleepSync,
      );

      final result = await action.read(
        AssistantDataCategory.steps,
        AssistantDateScope(
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 20),
          'today',
        ),
      );
      expect(stepsRepo.refreshCalls, 1);
      expect(result.status, AssistantActionStatus.success);
      final daily = result.tables['steps_daily_summary']!.single;
      expect(daily['steps'], 11200);
      expect(daily['target_steps'], 10000);
      expect(daily['goal_met'], 1);
      expect(daily['delta_to_target'], 1200);
      expect(result.tables['steps_hourly_summary'], hasLength(2));
    });

    test('nutrition includes incomplete days, extra nutrient targets, supplement caffeine, adaptive TDEE, favorites & custom foods', () async {
      final day = DateTime(2026, 11, 20);
      await database
          .into(database.incompleteNutritionDays)
          .insert(const db.IncompleteNutritionDaysCompanion(day: drift.Value('2026-11-20')));
      await database
          .into(database.products)
          .insert(
            const db.ProductsCompanion(
              barcode: drift.Value('custom-oats'),
              name: drift.Value('My Protein Oats'),
              calories: drift.Value(350),
              protein: drift.Value(20),
              carbs: drift.Value(50),
              fat: drift.Value(7),
              sugar: drift.Value(5),
              fiber: drift.Value(10),
              salt: drift.Value(0.5),
              source: drift.Value('user'),
            ),
          );
      await database
          .into(database.favorites)
          .insert(const db.FavoritesCompanion(barcode: drift.Value('custom-oats')));
      await database
          .into(database.nutritionLogs)
          .insert(
            db.NutritionLogsCompanion.insert(
              legacyBarcode: const drift.Value('custom-oats'),
              consumedAt: DateTime(2026, 11, 20, 8),
              amount: 100,
            ),
          );
      final caffeineSupp = await database
          .into(database.supplements)
          .insertReturning(
            db.SupplementsCompanion.insert(
              code: const drift.Value('caffeine'),
              name: 'Caffeine',
              dose: 100,
              unit: 'mg',
            ),
          );
      await database
          .into(database.supplementLogs)
          .insert(
            db.SupplementLogsCompanion.insert(
              supplementId: caffeineSupp.id,
              takenAt: DateTime(2026, 11, 20, 9),
              amount: 160,
            ),
          );

      // Seed adaptive TDEE recommendation snapshot in SharedPreferences.
      final recRepo = RecommendationRepository();
      final rec = NutritionRecommendation(
        recommendedCalories: 2300,
        recommendedProteinGrams: 170,
        recommendedCarbsGrams: 240,
        recommendedFatGrams: 70,
        estimatedMaintenanceCalories: 2800,
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        confidence: RecommendationConfidence.high,
        warningState: RecommendationWarningState.none,
        generatedAt: DateTime(2026, 11, 18),
        windowStart: DateTime(2026, 11, 1),
        windowEnd: DateTime(2026, 11, 17),
        algorithmVersion: 'test_v1',
        inputSummary: const RecommendationInputSummary(
          windowDays: 17,
          weightLogCount: 12,
          intakeLoggedDays: 16,
          smoothedWeightSlopeKgPerWeek: -0.45,
          avgLoggedCalories: 2350,
        ),
        baselineCalories: 2800,
        dueWeekKey: '2026-11-16',
      );
      final est = const BayesianMaintenanceEstimate(
        posteriorMaintenanceCalories: 2810,
        posteriorStdDevCalories: 85,
        profilePriorMaintenanceCalories: 2700,
        priorMeanUsedCalories: 2750,
        priorStdDevUsedCalories: 120,
        priorSource: BayesianPriorSource.chainedPosterior,
        observedIntakeCalories: 2350,
        observedWeightSlopeKgPerWeek: -0.45,
        observationImpliedMaintenanceCalories: 2845,
        effectiveSampleSize: 4.5,
        confidence: RecommendationConfidence.high,
        qualityFlags: ['sufficient_data'],
        debugInfo: {},
        dueWeekKey: '2026-11-16',
      );
      await recRepo.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: rec,
          maintenanceEstimate: est,
          dueWeekKey: '2026-11-16',
          algorithmVersion: 'test_v1',
        ),
      );

      final comprehensive = AssistantComprehensiveDataAction(
        reader: AssistantDatabaseSnapshotReader(database),
        actions: [
          AssistantDiaryActions(
            NutritionRepository(localDataSource: DiaryLocalDataSource(database)),
            database: database,
          ),
          AssistantHealthActions(
            database: database,
            steps: _FakeStepsRepo(enabled: true),
            profile: ProfileRepository(
              localDataSource: ProfileLocalDataSource(database),
            ),
            goals: GoalRepositoryImpl(database: database),
            sleepSync: _FakeSleepSyncService(enabled: true),
            recommendations: recRepo,
          ),
        ],
      );

      final nutritionResult = await comprehensive.read(
        AssistantDataCategory.nutrition,
        AssistantDateScope(day, day, 'today'),
      );
      final summary = nutritionResult.tables['nutrition_daily_summary']!.single;
      expect(summary['sugar_g'], 5.0);
      expect(summary['fiber_g'], 10.0);
      expect(summary['salt_g'], 0.5);
      expect(summary['caffeine_mg'], 160.0);
      expect(summary['target_sugar_g'], 45);
      expect(summary['target_fiber_g'], 35);
      expect(summary['target_caffeine_mg'], 300);
      expect(summary['is_incomplete_day'], 1);
      expect(nutritionResult.tables['incomplete_nutrition_days'], hasLength(1));

      final goalsResult = await comprehensive.read(
        AssistantDataCategory.goals,
        null,
      );
      final adaptive = goalsResult.tables['adaptive_nutrition_state']!.single;
      expect(adaptive['estimated_tdee_kcal'], 2810);
      expect(adaptive['recommended_calories'], 2300);
      expect(adaptive['tdee_confidence'], 'high');

      final recipesResult = await comprehensive.read(
        AssistantDataCategory.recipes,
        null,
      );
      expect(recipesResult.tables['favorite_foods']!.single['name'], 'My Protein Oats');
      expect(recipesResult.tables['custom_foods']!.single['barcode'], 'custom-oats');

      final profileResult = await comprehensive.read(
        AssistantDataCategory.profile,
        null,
      );
      final prefsSummary = profileResult.tables['user_preferences_summary']!.single;
      expect(prefsSummary['target_fiber_g'], 35);
      expect(prefsSummary['steps_tracking_enabled'], 1);
      expect(prefsSummary['pulse_tracking_enabled'], 0);
    });

    test('sequence training plans, analytics PRs/overview, and historical recovery tables work end-to-end', () async {
      // Sequence training plan
      final plan = await database
          .into(database.trainingPlans)
          .insertReturning(
            db.TrainingPlansCompanion.insert(
              name: 'PPL Rolling',
              kind: 'sequence',
              lengthDays: 3,
              isActive: const drift.Value(true),
              sequenceCursor: const drift.Value(1),
              sequenceCycle: const drift.Value(2),
            ),
          );
      await database
          .into(database.trainingPlanRevisions)
          .insert(
            db.TrainingPlanRevisionsCompanion.insert(
              planId: plan.id,
              number: 1,
              effectiveOn: DateTime(2026, 11, 1),
              daysJson: jsonEncode([
                {
                  'routineUuid': 'r-push',
                  'routineSnapshot': {'name': 'Push'},
                },
                {
                  'routineUuid': 'r-pull',
                  'routineSnapshot': {'name': 'Pull'},
                },
                {'routineUuid': null, 'routineSnapshot': null},
              ]),
            ),
          );

      // Completed workout + set for PRs & historical recovery
      final workoutDate = DateTime(2026, 11, 15, 10);
      final workout = await database
          .into(database.workoutLogs)
          .insertReturning(
            db.WorkoutLogsCompanion.insert(
              startTime: workoutDate,
              endTime: drift.Value(workoutDate.add(const Duration(hours: 1))),
              status: const drift.Value('completed'),
              routineNameSnapshot: const drift.Value('Push'),
            ),
          );
      await database
          .into(database.setLogs)
          .insert(
            db.SetLogsCompanion.insert(
              workoutLogId: workout.id,
              exerciseNameSnapshot: const drift.Value('Bench Press'),
              reps: const drift.Value(5),
              weight: const drift.Value(105),
              isCompleted: const drift.Value(true),
            ),
          );

      final reader = AssistantDatabaseSnapshotReader(database);
      final planTables = await reader.read(
        AssistantDataCategory.trainingPlans,
        null,
      );
      final schedule = planTables['active_plan_schedule']!;
      expect(schedule, hasLength(3));
      expect(schedule[1]['routine_name'], 'Pull');
      expect(schedule[1]['is_next_slot'], 1);
      expect(schedule[1]['sequence_cycle'], 2);
      expect(schedule[2]['is_rest'], 1);

      final analytics = AssistantAnalyticsActions(
        database: database,
        nowProvider: () => DateTime(2026, 11, 20, 12),
      );
      final analyticsResult = await analytics.read(
        AssistantDataCategory.analytics,
        null,
      );
      expect(analyticsResult.status, AssistantActionStatus.success);
      expect(
        analyticsResult.tables['training_overview_stats']!.single['total_workouts'],
        1,
      );
      expect(
        analyticsResult.tables['personal_records']!.any(
          (row) => row['exercise_name'] == 'Bench Press' && row['weight_kg'] == 105.0,
        ),
        isTrue,
      );

      // Historical recovery asOf 2026-11-16 (1 day after workout)
      final comprehensive = AssistantComprehensiveDataAction(
        reader: reader,
        actions: [
          AssistantTrainingActions(
            workouts: WorkoutRepository(
              localDataSource: WorkoutLocalDataSource(database),
            ),
            database: database,
          ),
        ],
      );
      final recoveryResult = await comprehensive.read(
        AssistantDataCategory.recovery,
        AssistantDateScope(
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 16),
          'as of Nov 16',
        ),
      );
      expect(recoveryResult.status, AssistantActionStatus.success);
      expect(
        recoveryResult.tables['recovery_overview']!.single['as_of'],
        '2026-11-16',
      );
    });
  });
}
