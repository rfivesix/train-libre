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

    test('NoOpTelemetryService defaults to opted out and performs no-ops without throwing', () async {
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
    });

    test('PostHogTelemetryService handles opt-in, persistent device ID and daily food logging state', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(await postHogService.isOptedIn(), isFalse);

      await postHogService.optIn();
      expect(await postHogService.isOptedIn(), isTrue);
      expect(prefs.getBool('telemetry_opt_in'), isTrue);

      // Increment food log counter
      await postHogService.incrementFoodLogCount(source: 'barcode_scan');
      await postHogService.incrementFoodLogCount(source: 'manual_search');

      expect(prefs.getInt('telemetry_daily_food_count'), 2);
      expect(prefs.getStringList('telemetry_daily_food_sources'), containsAll(['barcode_scan', 'manual_search']));

      // Flush daily food log
      await postHogService.flushDailyFoodLog();

      expect(prefs.getInt('telemetry_daily_food_count'), 0);
      expect(prefs.getStringList('telemetry_daily_food_sources'), isEmpty);

      // Opt out
      await postHogService.optOut();
      expect(await postHogService.isOptedIn(), isFalse);
      expect(prefs.getBool('telemetry_opt_in'), isFalse);
    });

    test('PostHogTelemetryService tracks workout completed without PII', () async {
      await postHogService.optIn();

      await postHogService.trackWorkoutCompleted(
        workoutType: 'My Custom Leg Day Workout Name', // Should be sanitized to 'custom'
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

    test('PostHogTelemetryService onboarding step and completion tracking', () async {
      await postHogService.optIn();

      const sessionId = 'test-session-uuid-1234';
      await postHogService.trackOnboardingStep(
        stepIndex: 0,
        stepName: 'welcome',
        durationSeconds: 15,
        sessionId: sessionId,
      );

      await postHogService.trackOnboardingCompleted(
        totalDurationSeconds: 120,
        restoredFromBackup: false,
        sessionId: sessionId,
      );
    });

    test('PostHogTelemetryService resetLocalData clears persistent device ID and counters', () async {
      final prefs = await SharedPreferences.getInstance();
      await postHogService.optIn();

      await postHogService.incrementFoodLogCount(source: 'barcode_scan');
      expect(prefs.getInt('telemetry_daily_food_count'), 1);

      await postHogService.resetLocalData();

      expect(prefs.getInt('telemetry_daily_food_count'), null);
      expect(prefs.getString('telemetry_persistent_device_id'), isNotNull);
    });

    test('TelemetryService resolves system locale and country metadata accurately', () {
      final (locale, country) = TelemetryService.resolveSystemLocaleAndCountry();
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

    test('PostHogTelemetryService tracks app launched with country and locale', () async {
      await postHogService.optIn();
      await postHogService.trackAppLaunched(
        appVersion: '1.0.0',
        osVersion: 'iOS 17.5',
        platform: 'ios',
        locale: 'de_DE',
        country: 'DE',
      );
    });

    test('PostHogTelemetryService tracks recommendation generated and feedback report submitted', () async {
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

    test('TelemetryBuckets handles voice durations and item counts accurately', () {
      expect(TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 2)), '<5s');
      expect(TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 10)), '5-15s');
      expect(TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 20)), '15-30s');
      expect(TelemetryBuckets.getVoiceDurationBucket(const Duration(seconds: 45)), '>30s');

      expect(TelemetryBuckets.getItemCountBucket(0), '0');
      expect(TelemetryBuckets.getItemCountBucket(2), '1-2');
      expect(TelemetryBuckets.getItemCountBucket(4), '3-5');
      expect(TelemetryBuckets.getItemCountBucket(8), '6+');
    });

    test('PostHogTelemetryService tracks AI meal scan, voice dictation, and corrections', () async {
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
    });

    test('ICloudSyncService.setSyncEnabled tracks setting_toggled and feature_used on toggle', () async {
      final trackedEvents = <Map<String, dynamic>>[];
      final testTelemetry = TestTelemetryService((event) => trackedEvents.add(event));
      TelemetryService.instance = testTelemetry;

      await ICloudSyncService.instance.setSyncEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(trackedEvents, hasLength(2));
      expect(trackedEvents[0]['type'], equals('setting_toggled'));
      expect(trackedEvents[0]['setting_key'], equals('icloud_sync_enabled'));
      expect(trackedEvents[0]['value'], equals(true));
      expect(trackedEvents[1]['type'], equals('feature_used'));
      expect(trackedEvents[1]['feature_key'], equals(FeatureKey.icloudSyncTriggered));

      trackedEvents.clear();

      await ICloudSyncService.instance.setSyncEnabled(false);
      await Future<void>.delayed(Duration.zero);
      expect(trackedEvents, hasLength(1));
      expect(trackedEvents[0]['type'], equals('setting_toggled'));
      expect(trackedEvents[0]['setting_key'], equals('icloud_sync_enabled'));
      expect(trackedEvents[0]['value'], equals(false));
    });
  });
}

class TestTelemetryService extends NoOpTelemetryService {
  final void Function(Map<String, dynamic> event) onTrack;
  TestTelemetryService(this.onTrack);

  @override
  Future<void> trackSettingToggled({
    required String settingKey,
    required dynamic value,
  }) async {
    onTrack({'type': 'setting_toggled', 'setting_key': settingKey, 'value': value});
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
