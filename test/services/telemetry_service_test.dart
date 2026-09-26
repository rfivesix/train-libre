// test/services/telemetry_service_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/icloud_sync_service.dart';
import 'package:train_libre/services/telemetry/telemetry_service.dart';
import 'package:train_libre/services/telemetry/telemetry_buckets.dart';
import 'package:train_libre/services/telemetry/telemetry_service_noop.dart';
import 'package:train_libre/services/telemetry/telemetry_service_posthog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelemetryService Tests', () {
    late TelemetryService postHogService;
    late TelemetryService noOpService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      postHogService = PostHogTelemetryService();
      noOpService = const NoOpTelemetryService();
    });

    test(
        'NoOpTelemetryService defaults to opted out and performs no-ops without throwing',
        () async {
      expect(await noOpService.isOptedIn(), isFalse);

      await noOpService.init();
      await noOpService.optIn();
      await noOpService.optOut();
      await noOpService.trackScreenView(screenName: 'test_screen');
      await noOpService.trackWorkoutCompleted(
        workoutType: 'routine',
        exerciseCount: 5,
        setCount: 20,
        durationMinutes: 45,
        hasRestTimer: true,
        restTimerCount: 15,
        hasRir: true,
        rirSetsCount: 10,
        hasSupersets: true,
        supersetCount: 2,
        hasWarmupSets: true,
        hasDropSets: false,
        hasFailureSets: false,
      );
      await noOpService.incrementFoodLogCount(source: 'barcode_scan');
      await noOpService.flushDailyFoodLog();
      await noOpService.trackAppReviewPromptResponded(response: 'later');
      await noOpService.trackTrainingPlanCreated(
        kind: 'week',
        dayCount: 7,
        workoutDaysCount: 4,
        restDaysCount: 3,
        isActive: true,
      );
      await noOpService.trackTrainingPlanUpdated(
        kind: 'sequence',
        dayCount: 5,
        workoutDaysCount: 3,
        restDaysCount: 2,
        effectiveTiming: 'from_today',
      );
      await noOpService.trackTrainingPlanToggled(
        action: 'activated',
        kind: 'week',
      );
      await noOpService.trackTrainingPlanDeleted(kind: 'week');
      await noOpService.trackTrainingPlanSessionStarted(
        kind: 'week',
        isRestDayOverride: false,
        dayIndex: 1,
      );
      await noOpService.trackNutritionGoalCreated(
        preset: 'lose_weight',
        trackingMode: 'weekly_rate',
        isNutritionDriver: true,
        hasTargetDate: true,
        hasNumericTarget: true,
        rateDirection: 'deficit',
        source: 'profile',
      );
      await noOpService.trackNutritionGoalAdjusted(
        adjustmentType: 'pace',
        isNutritionDriver: true,
        rateDirection: 'deficit',
      );
      await noOpService.trackNutritionGoalRetired(
        reason: 'completed',
        durationDaysBucket: '1-3m',
      );
      await noOpService.trackWeeklyGoalReviewCompleted(
        trajectoryStatus: 'on_track',
        confidenceLevel: 'high',
        decision: 'applied',
        weightObservationCountBucket: '3-5',
        loggedIntakeDaysBucket: '6+',
        calorieAdjustmentDirection: 'maintain',
        hasMacroAdjustments: true,
      );
    });

    test(
        'PostHogTelemetryService handles opt-in, persistent device ID and daily food logging state',
        () async {
      final prefs = await SharedPreferences.getInstance();

      expect(await postHogService.isOptedIn(), isFalse);

      await postHogService.optIn();
      expect(await postHogService.isOptedIn(), isTrue);
      expect(prefs.getBool('telemetry_opt_in'), isTrue);

      // Increment food log counter
      await postHogService.incrementFoodLogCount(source: 'barcode_scan');
      await postHogService.incrementFoodLogCount(source: 'manual_search');

      expect(prefs.getInt('telemetry_daily_food_count'), 2);
      expect(prefs.getStringList('telemetry_daily_food_sources'),
          containsAll(['barcode_scan', 'manual_search']));

      // Flush daily food log
      await postHogService.flushDailyFoodLog();

      expect(prefs.getInt('telemetry_daily_food_count'), 0);
      expect(prefs.getStringList('telemetry_daily_food_sources'), isEmpty);

      // Opt out
      await postHogService.optOut();
      expect(await postHogService.isOptedIn(), isFalse);
      expect(prefs.getBool('telemetry_opt_in'), isFalse);
    });

    test('PostHogTelemetryService tracks workout completed without PII',
        () async {
      await postHogService.optIn();

      await postHogService.trackWorkoutCompleted(
        workoutType:
            'My Custom Leg Day Workout Name', // Should be sanitized to 'custom'
        exerciseCount: 6,
        setCount: 24,
        durationMinutes: 60,
        hasRestTimer: true,
        restTimerCount: 18,
        hasRir: true,
        rirSetsCount: 12,
        hasSupersets: true,
        supersetCount: 3,
        hasWarmupSets: true,
        hasDropSets: true,
        hasFailureSets: false,
      );
    });

    test('PostHogTelemetryService onboarding step and completion tracking',
        () async {
      await postHogService.optIn();

      const sessionId = 'test-session-uuid-1234';
      await postHogService.trackOnboardingStep(
        stepIndex: 0,
        stepName: 'welcome',
        screenName: 'welcome',
        durationSeconds: 15,
        sessionId: sessionId,
      );

      await postHogService.trackOnboardingCompleted(
        totalDurationSeconds: 120,
        restoredFromBackup: false,
        sessionId: sessionId,
      );
    });

    test(
        'PostHogTelemetryService resetLocalData clears persistent device ID and counters',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await postHogService.optIn();

      await postHogService.incrementFoodLogCount(source: 'barcode_scan');
      expect(prefs.getInt('telemetry_daily_food_count'), 1);

      await postHogService.resetLocalData();

      expect(prefs.getInt('telemetry_daily_food_count'), null);
      expect(prefs.getString('telemetry_persistent_device_id'), isNotNull);
    });

    test(
        'TelemetryService resolves system locale and country metadata accurately',
        () {
      final (locale, country) =
          TelemetryService.resolveSystemLocaleAndCountry();
      expect(locale, isNotEmpty);
      expect(country, isNotEmpty);
      expect(country.length, 2);

      final metaDE = TelemetryService.getCountryMetadata('DE');
      expect(metaDE.countryCode, 'DE');
      expect(metaDE.countryName, 'Germany');
      expect(metaDE.continentCode, 'EU');
      expect(metaDE.continentName, 'Europe');

      final metaUS = TelemetryService.getCountryMetadata('US');
      expect(metaUS.countryCode, 'US');
      expect(metaUS.countryName, 'United States');
      expect(metaUS.continentCode, 'NA');
      expect(metaUS.continentName, 'North America');
    });

    test('PostHogTelemetryService tracks app launched with country and locale',
        () async {
      await postHogService.optIn();
      await postHogService.trackAppLaunched(
        appVersion: '1.0.0',
        osVersion: 'iOS 17.5',
        platform: 'ios',
        locale: 'de_DE',
        country: 'DE',
      );
    });

    test(
        'PostHogTelemetryService tracks recommendation generated and feedback report submitted',
        () async {
      await postHogService.optIn();
      await postHogService.trackRecommendationGenerated(
        weightLogCount: 12,
        intakeLoggedDays: 14,
        windowDays: 14,
        effectiveSampleSize: 3.5,
        hasSlope: true,
        hasIntake: true,
        confidence: 'high',
        confidenceScoreBucket: '0.75-1.00',
        warningLevel: 'none',
        qualityFlags: ['bayesian_recursive_filter'],
        isPriorOnly: false,
      );

      await postHogService.trackFeedbackReportSubmitted(
        includedSections: ['adaptive_nutrition', 'backup_restore'],
        hasUserNote: false,
        userNoteLength: 0,
        submissionMethod: 'posthog_direct',
      );
    });

    test(
        'concurrent food log increments are not lost to interleaved read-modify-write',
        () async {
      await postHogService.optIn();

      // Mirrors logging a saved meal / confirming an AI meal scan: every item is
      // inserted in a tight loop and each insert fires an unawaited increment.
      await Future.wait([
        for (var i = 0; i < 25; i++)
          postHogService.incrementFoodLogCount(
            source: FoodLogSource.manualSearch,
          ),
      ]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('telemetry_daily_food_count'), 25);
    });

    test('food log sources are recorded distinctly and sanitized', () async {
      await postHogService.optIn();

      await postHogService.incrementFoodLogCount(
        source: FoodLogSource.barcodeScan,
      );
      await postHogService.incrementFoodLogCount(
        source: FoodLogSource.aiCapture,
      );
      await postHogService.incrementFoodLogCount(
        source: FoodLogSource.barcodeScan,
      );
      // An unknown source must never reach PostHog verbatim.
      await postHogService.incrementFoodLogCount(source: 'Arme + Schultern');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('telemetry_daily_food_count'), 4);
      expect(
        prefs.getStringList('telemetry_daily_food_sources'),
        [
          FoodLogSource.barcodeScan,
          FoodLogSource.aiCapture,
          FoodLogSource.manualSearch,
        ],
      );
    });

    test('food log counter stays untouched while opted out', () async {
      await postHogService.optOut();
      await postHogService.incrementFoodLogCount(
        source: FoodLogSource.manualSearch,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('telemetry_daily_food_count'), isNull);
    });

    test('FoodLogSource.sanitize falls back to manual search', () {
      expect(FoodLogSource.sanitize(null), FoodLogSource.manualSearch);
      expect(FoodLogSource.sanitize(''), FoodLogSource.manualSearch);
      expect(FoodLogSource.sanitize('diary_entry'), FoodLogSource.manualSearch);
      expect(
        FoodLogSource.sanitize(FoodLogSource.aiCapture),
        FoodLogSource.aiCapture,
      );
    });

    test('AppReviewPromptResponse only permits the documented responses', () {
      expect(AppReviewPromptResponse.sanitize('yes'), 'yes');
      expect(AppReviewPromptResponse.sanitize('no'), 'no');
      expect(AppReviewPromptResponse.sanitize('later'), 'later');
      expect(AppReviewPromptResponse.sanitize('unexpected'), 'later');
    });

    test('init does not touch the PostHog SDK while opted out', () async {
      // Posthog().setup() unconditionally triggers the native remote-config
      // fetch, which ignores the opt-out state — so setup itself would open a
      // connection to PostHog EU before any consent exists. In the test
      // environment every SDK call raises MissingPluginException, which the
      // service logs; the absence of those logs is what proves nothing was
      // called. Captured here so a regression is visible rather than silent.
      final logs = <String>[];
      await runZoned(
        () async {
          SharedPreferences.setMockInitialValues({});
          final service = PostHogTelemetryService();
          await service.init();
          expect(await service.isOptedIn(), isFalse);
          // Events must be dropped, not queued.
          await service.trackScreenView(screenName: 'diary_tab');
          await service.trackFeatureUsed(featureKey: 'routine_created');
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );

      expect(
        logs.where((l) => l.contains('MissingPluginException')),
        isEmpty,
        reason: 'no PostHog SDK call may happen before opt-in, but got: $logs',
      );
    });

    test('a persistent device ID is created without contacting PostHog',
        () async {
      final service = PostHogTelemetryService();
      await service.init();

      // The ID is generated locally so DAU counting works the moment a user
      // opts in; generating it must not imply any transmission.
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('telemetry_persistent_device_id');
      expect(deviceId, isNotNull);
      expect(deviceId, isNotEmpty);
      expect(await service.isOptedIn(), isFalse);
    });

    test('screen and feature catalogs contain no user-authored text', () {
      final identifierPattern = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final key in FeatureKey.all) {
        expect(identifierPattern.hasMatch(key), isTrue, reason: key);
      }
      for (final source in FoodLogSource.all) {
        expect(identifierPattern.hasMatch(source), isTrue, reason: source);
      }
    });

    test('TelemetryBuckets handles voice durations and item counts accurately',
        () {
      expect(
          TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 2)),
          '<5s');
      expect(
          TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 10)),
          '5-15s');
      expect(
          TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 20)),
          '15-30s');
      expect(
          TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 45)),
          '>30s');

      expect(TelemetryBuckets.getItemCountBucket(0), '0');
      expect(TelemetryBuckets.getItemCountBucket(2), '1-2');
      expect(TelemetryBuckets.getItemCountBucket(4), '3-5');
      expect(TelemetryBuckets.getItemCountBucket(8), '6+');
    });

    test(
        'PostHogTelemetryService tracks AI meal scan, voice dictation, and corrections',
        () async {
      await postHogService.optIn();

      await postHogService.trackAiMealScanRequested(
        requestId: 'scan-req-123',
        provider: 'gemini',
        inputMode: 'multimodal',
        photoCount: 2,
        hasLidar: true,
        hasVoiceInput: true,
        hasTextInput: true,
      );

      await postHogService.trackAiMealScanCompleted(
        requestId: 'scan-req-123',
        provider: 'gemini',
        latencyBucket: '2-5s',
        success: true,
        inputMode: 'multimodal',
        photoCount: 2,
        hasLidar: true,
        hasVoiceInput: true,
        hasTextInput: true,
        validationPassed: true,
        repairAttemptsCount: 0,
        suggestedItemsCountBucket: '3-5',
      );

      await postHogService.trackVoiceDictationCompleted(
        durationBucket: '5-15s',
        aiTidyUpEnabled: true,
        surface: 'ai_meal_capture',
        success: true,
      );

      await postHogService.trackAiMealCorrectionCompleted(
        hasImages: true,
        latencyBucket: '2-5s',
        success: true,
        repairAttemptsCount: 1,
      );
      await postHogService.trackAppReviewPromptResponded(response: 'later');
    });

    test(
        'ICloudSyncService.setSyncEnabled tracks setting_toggled and feature_used on toggle',
        () async {
      final trackedEvents = <Map<String, dynamic>>[];
      final testTelemetry =
          TestTelemetryService((event) => trackedEvents.add(event));
      TelemetryService.instance = testTelemetry;

      await ICloudSyncService.instance.setSyncEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(trackedEvents, hasLength(2));
      expect(trackedEvents[0]['type'], equals('setting_toggled'));
      expect(trackedEvents[0]['setting_key'], equals('icloud_sync_enabled'));
      expect(trackedEvents[0]['value'], equals(true));
      expect(trackedEvents[1]['type'], equals('feature_used'));
      expect(trackedEvents[1]['feature_key'],
          equals(FeatureKey.icloudSyncTriggered));

      trackedEvents.clear();

      await ICloudSyncService.instance.setSyncEnabled(false);
      await Future<void>.delayed(Duration.zero);
      expect(trackedEvents, hasLength(1));
      expect(trackedEvents[0]['type'], equals('setting_toggled'));
      expect(trackedEvents[0]['setting_key'], equals('icloud_sync_enabled'));
      expect(trackedEvents[0]['value'], equals(false));
    });

    test(
        'TelemetryBuckets handles observation counts and goal duration buckets accurately',
        () {
      expect(TelemetryBuckets.getObservationCountBucket(0), '0');
      expect(TelemetryBuckets.getObservationCountBucket(1), '1-2');
      expect(TelemetryBuckets.getObservationCountBucket(2), '1-2');
      expect(TelemetryBuckets.getObservationCountBucket(4), '3-5');
      expect(TelemetryBuckets.getObservationCountBucket(5), '3-5');
      expect(TelemetryBuckets.getObservationCountBucket(10), '6+');

      expect(
          TelemetryBuckets.getGoalDurationBucket(const Duration(days: 3)), '<7d');
      expect(TelemetryBuckets.getGoalDurationBucket(const Duration(days: 14)),
          '1-4w');
      expect(TelemetryBuckets.getGoalDurationBucket(const Duration(days: 60)),
          '1-3m');
      expect(TelemetryBuckets.getGoalDurationBucket(const Duration(days: 120)),
          '3-6m');
      expect(TelemetryBuckets.getGoalDurationBucket(const Duration(days: 300)),
          '>6m');
    });

    test(
        'PostHogTelemetryService tracks training plan events without PII',
        () async {
      final recorder = TestRecordingPostHogService();

      await recorder.trackTrainingPlanCreated(
        kind: 'week',
        dayCount: 7,
        workoutDaysCount: 4,
        restDaysCount: 3,
        isActive: true,
      );
      expect(recorder.recorded.last.event, 'training_plan_created');
      expect(recorder.recorded.last.properties?['kind'], 'week');
      expect(recorder.recorded.last.properties?['day_count'], 7);
      expect(recorder.recorded.last.properties?['workout_days_count'], 4);
      expect(recorder.recorded.last.properties?['rest_days_count'], 3);
      expect(recorder.recorded.last.properties?['is_active'], isTrue);

      await recorder.trackTrainingPlanUpdated(
        kind: 'sequence',
        dayCount: 6,
        workoutDaysCount: 4,
        restDaysCount: 2,
        effectiveTiming: 'next_cycle',
      );
      expect(recorder.recorded.last.event, 'training_plan_updated');
      expect(recorder.recorded.last.properties?['kind'], 'sequence');
      expect(recorder.recorded.last.properties?['effective_timing'], 'next_cycle');

      await recorder.trackTrainingPlanToggled(action: 'activated', kind: 'week');
      expect(recorder.recorded.last.event, 'training_plan_toggled');
      expect(recorder.recorded.last.properties?['action'], 'activated');

      await recorder.trackTrainingPlanDeleted(kind: 'week');
      expect(recorder.recorded.last.event, 'training_plan_deleted');

      await recorder.trackTrainingPlanSessionStarted(
        kind: 'sequence',
        isRestDayOverride: true,
        dayIndex: 2,
      );
      expect(recorder.recorded.last.event, 'training_plan_session_started');
      expect(recorder.recorded.last.properties?['is_rest_day_override'], isTrue);
      expect(recorder.recorded.last.properties?['day_index'], 2);
    });

    test(
        'PostHogTelemetryService tracks nutrition goal and review events without PII',
        () async {
      final recorder = TestRecordingPostHogService();

      await recorder.trackNutritionGoalCreated(
        preset: 'lose_weight',
        trackingMode: 'weekly_rate',
        isNutritionDriver: true,
        hasTargetDate: true,
        hasNumericTarget: true,
        rateDirection: 'deficit',
        source: 'profile',
      );
      expect(recorder.recorded.last.event, 'nutrition_goal_created');
      expect(recorder.recorded.last.properties?['preset'], 'lose_weight');
      expect(recorder.recorded.last.properties?['tracking_mode'], 'weekly_rate');
      expect(recorder.recorded.last.properties?['is_nutrition_driver'], isTrue);
      expect(recorder.recorded.last.properties?['rate_direction'], 'deficit');
      // Verify no target weight or baseline numbers leak
      expect(recorder.recorded.last.properties?.containsKey('target_weight'), isFalse);
      expect(recorder.recorded.last.properties?.containsKey('baseline_weight'), isFalse);

      await recorder.trackNutritionGoalAdjusted(
        adjustmentType: 'pace',
        isNutritionDriver: true,
        rateDirection: 'deficit',
      );
      expect(recorder.recorded.last.event, 'nutrition_goal_adjusted');
      expect(recorder.recorded.last.properties?['adjustment_type'], 'pace');

      await recorder.trackNutritionGoalRetired(
        reason: 'completed',
        durationDaysBucket: '1-3m',
      );
      expect(recorder.recorded.last.event, 'nutrition_goal_retired');
      expect(recorder.recorded.last.properties?['reason'], 'completed');
      expect(recorder.recorded.last.properties?['duration_days_bucket'], '1-3m');

      await recorder.trackWeeklyGoalReviewCompleted(
        trajectoryStatus: 'on_track',
        confidenceLevel: 'high',
        decision: 'applied',
        weightObservationCountBucket: '3-5',
        loggedIntakeDaysBucket: '6+',
        calorieAdjustmentDirection: 'increase',
        hasMacroAdjustments: true,
      );
      expect(recorder.recorded.last.event, 'weekly_goal_review_completed');
      expect(recorder.recorded.last.properties?['trajectory_status'], 'on_track');
      expect(recorder.recorded.last.properties?['decision'], 'applied');
      expect(recorder.recorded.last.properties?['calorie_adjustment_direction'],
          'increase');
      // Verify no raw kcal or kg leak
      expect(recorder.recorded.last.properties?.containsKey('calories'), isFalse);
      expect(recorder.recorded.last.properties?.containsKey('weight'), isFalse);
    });
  });
}

class TestRecordingPostHogService extends PostHogTelemetryService {
  final List<({String event, Map<String, dynamic>? properties})> recorded = [];

  @override
  Future<void> track(String eventName,
      {Map<String, dynamic>? properties}) async {
    recorded.add((event: eventName, properties: properties));
  }
}

class TestTelemetryService extends NoOpTelemetryService {
  final void Function(Map<String, dynamic> event) onTrack;
  TestTelemetryService(this.onTrack);

  @override
  Future<void> trackSettingToggled({
    required String settingKey,
    required dynamic value,
  }) async {
    onTrack(
        {'type': 'setting_toggled', 'setting_key': settingKey, 'value': value});
  }

  @override
  Future<void> trackFeatureUsed({
    required String featureKey,
    Map<String, dynamic>? extraProps,
  }) async {
    onTrack({
      'type': 'feature_used',
      'feature_key': featureKey,
      if (extraProps != null) ...extraProps,
    });
  }
}
