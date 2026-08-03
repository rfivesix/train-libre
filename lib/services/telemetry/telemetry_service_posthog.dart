// lib/services/telemetry/telemetry_service_posthog.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'telemetry_service.dart';

/// PostHog EU TelemetryService implementation with strict opt-in,
/// IP anonymization, 2-ID strategy (DAU/MAU vs in-app events), and no PII capture.
class PostHogTelemetryService implements TelemetryService {
  static const String _prefOptInKey = 'telemetry_opt_in';
  static const String _prefDeviceIdKey = 'telemetry_persistent_device_id';
  static const String _prefFoodLogCountKey = 'telemetry_daily_food_count';
  static const String _prefFoodLogSourcesKey = 'telemetry_daily_food_sources';

  static const String _defaultApiKey = String.fromEnvironment('POSTHOG_API_KEY',
      defaultValue: 'phc_vmLGxjjWfVB58y7smThJX9mQte9Y97Kff62EmLDtNWTB');
  static const String _postHogEuHost = 'https://eu.i.posthog.com';

  bool _initialized = false;
  bool _optedIn = false;
  String? _persistentDeviceId;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _optedIn = prefs.getBool(_prefOptInKey) ?? false;

      // Ensure persistent device ID exists (generated locally, stored in prefs, never hardware derived)
      _persistentDeviceId = prefs.getString(_prefDeviceIdKey);
      if (_persistentDeviceId == null || _persistentDeviceId!.isEmpty) {
        _persistentDeviceId = const Uuid().v4();
        await prefs.setString(_prefDeviceIdKey, _persistentDeviceId!);
      }

      final config = PostHogConfig(_defaultApiKey)
        ..host = _postHogEuHost
        ..captureApplicationLifecycleEvents = false
        ..debug = kDebugMode
        ..beforeSend = [
          (event) {
            if (event.event == r'$rageclick' ||
                event.event == r'$autocapture' ||
                event.event.startsWith(r'$rage')) {
              return null;
            }
            // Enforce strict zero-geolocation and zero-person-profiling on all SDK events
            final props = event.properties ??= <String, Object>{};
            props[r'$ip'] = '0.0.0.0';
            props[r'$geoip_disable'] = true;
            props[r'$process_person_profile'] = false;
            return event;
          },
        ];

      await Posthog().setup(config);

      // Rotate in-app SDK distinct_id on every app launch for privacy
      final ephemeralSessionId = const Uuid().v4();
      await Posthog().identify(userId: ephemeralSessionId);

      if (_optedIn) {
        await Posthog().enable();
      } else {
        await Posthog().disable();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('PostHogTelemetryService init error: $e');
    }
  }

  @override
  Future<void> resetLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistentDeviceId ??= prefs.getString(_prefDeviceIdKey);

      // Send deletion requests to PostHog EU server for the persistent device ID
      // and active SDK distinct ID before wiping locally
      if (_persistentDeviceId != null && _persistentDeviceId!.isNotEmpty) {
        try {
          final url = Uri.parse('$_postHogEuHost/capture/');
          final body = jsonEncode({
            'api_key': _defaultApiKey,
            'event': r'$delete_person',
            'distinct_id': _persistentDeviceId,
            'properties': {
              'token': _defaultApiKey,
              r'$process_person_profile': false,
              r'$ip': '0.0.0.0',
              r'$geoip_disable': true,
              r'$delete_person': true,
            },
          });
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );
        } catch (e) {
          debugPrint('PostHog delete_person HTTP error: $e');
        }
      }

      try {
        await Posthog().capture(
          eventName: r'$delete_person',
          properties: {
            r'$process_person_profile': false,
            r'$ip': '0.0.0.0',
            r'$geoip_disable': true,
            r'$delete_person': true,
          },
        );
      } catch (e) {
        debugPrint('PostHog capture delete_person error: $e');
      }

      // Clear local SharedPreferences storage
      await prefs.remove(_prefDeviceIdKey);
      await prefs.remove(_prefFoodLogCountKey);
      await prefs.remove(_prefFoodLogSourcesKey);

      // Re-generate fresh persistent device ID and reset PostHog SDK identity
      _persistentDeviceId = const Uuid().v4();
      await prefs.setString(_prefDeviceIdKey, _persistentDeviceId!);

      await Posthog().reset();
      final ephemeralSessionId = const Uuid().v4();
      await Posthog().identify(userId: ephemeralSessionId);
    } catch (e) {
      debugPrint('PostHogTelemetryService resetLocalData error: $e');
    }
  }

  @override
  Future<void> optIn() async {
    try {
      _optedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefOptInKey, true);
      await Posthog().enable();
    } catch (e) {
      debugPrint('PostHogTelemetryService optIn error: $e');
    }
  }

  @override
  Future<void> optOut() async {
    try {
      _optedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefOptInKey, false);
      await Posthog().disable();
    } catch (e) {
      debugPrint('PostHogTelemetryService optOut error: $e');
    }
  }

  @override
  Future<bool> isOptedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _optedIn = prefs.getBool(_prefOptInKey) ?? false;
    return _optedIn;
  }

  @override
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_optedIn) return;
    try {
      // Enforce strict zero-profiling, zero-geolocation privacy flags
      final Map<String, Object> enrichedProps = {
        r'$process_person_profile': false,
        r'$ip': '0.0.0.0',
        r'$geoip_disable': true,
        if (properties != null)
          ...properties.map((key, value) => MapEntry(key, value as Object)),
      };

      await Posthog().capture(
        eventName: eventName,
        properties: enrichedProps,
      );


    } catch (e) {
      debugPrint('PostHogTelemetryService track error ($eventName): $e');
    }
  }

  bool _isEmulator() {
    if (kIsWeb) return false;
    try {
      final tempPath = Directory.systemTemp.path;
      if (tempPath.contains('CoreSimulator') ||
          tempPath.contains('Simulator') ||
          tempPath.contains('simulator')) {
        return true;
      }
      final osVersion = Platform.operatingSystemVersion.toLowerCase();
      if (osVersion.contains('simulator') ||
          osVersion.contains('emulator') ||
          osVersion.contains('sdk') ||
          osVersion.contains('gphone') ||
          osVersion.contains('goldfish') ||
          osVersion.contains('ranchu') ||
          osVersion.contains('vbox86') ||
          osVersion.contains('x86')) {
        return true;
      }
      final env = Platform.environment;
      for (final key in env.keys) {
        if (key.toUpperCase().contains('SIMULATOR') ||
            key.toUpperCase().contains('EMULATOR')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<void> trackAppLaunched({
    required String appVersion,
    required String osVersion,
    required String platform,
    required String locale,
    required String country,
    String? installSource,
  }) async {
    if (!_optedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistentDeviceId ??= prefs.getString(_prefDeviceIdKey);
      if (_persistentDeviceId == null || _persistentDeviceId!.isEmpty) {
        _persistentDeviceId = const Uuid().v4();
        await prefs.setString(_prefDeviceIdKey, _persistentDeviceId!);
      }

      PackageInfo? packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (_) {}

      final appBuild = packageInfo != null
          ? (int.tryParse(packageInfo.buildNumber) ?? packageInfo.buildNumber)
          : null;
      final isEmulator = _isEmulator();
      final timeZone = DateTime.now().timeZoneName;
      final osName = platform == 'ios'
          ? 'iOS'
          : (platform == 'android' ? 'Android' : platform);
      final deviceManufacturer = platform == 'ios' ? 'Apple' : 'Android';
      final deviceModel = platform == 'ios' ? 'arm64' : 'Mobile';
      final deviceName = platform == 'ios' ? 'iPhone' : 'Mobile Device';

      // Option B: Direct HTTP POST call to PostHog EU with isolated persistent device ID
      // This allows PostHog to calculate DAU/MAU uniqueness without building Person Profiles
      // and without contaminating the SDK state for in-app events.
      final url = Uri.parse('$_postHogEuHost/capture/');
      final body = jsonEncode({
        'api_key': _defaultApiKey,
        'event': 'app_launched',
        'distinct_id': _persistentDeviceId,
        'properties': {
          'token': _defaultApiKey,
          r'$process_person_profile': false,
          r'$ip': '0.0.0.0',
          r'$geoip_disable': true,

          // PostHog Native Feature / Metadata fields for GeoIP & Locale
          r'$geoip_country_code': country,
          r'$locale': locale,

          // Full standard environment & device metadata matching SDK events
          if (appBuild != null) r'$app_build': appBuild,
          r'$app_name': 'Train Libre',
          r'$app_version': appVersion,
          r'$app_namespace': 'com.rfivesix.trainlibre',
          r'$device_manufacturer': deviceManufacturer,
          r'$device_model': deviceModel,
          r'$device_name': deviceName,
          r'$device_type': 'Mobile',
          r'$is_emulator': isEmulator,
          r'$is_sideloaded': false,
          r'$is_testflight': false,
          r'$lib': 'posthog-flutter',
          r'$lib_version': '5.34.2',
          r'$os': osName,
          r'$os_name': osName,
          r'$os_version': osVersion,
          r'$sent_at': DateTime.now().toUtc().toIso8601String(),
          r'$timezone': timeZone,

          'app_version': appVersion,
          'os_version': osVersion,
          'platform': platform,
          'locale': locale,
          'country': country,
          if (installSource != null) 'install_source': installSource,
        },
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (kDebugMode && response.statusCode != 200) {
        debugPrint(
            'trackAppLaunched PostHog response code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PostHogTelemetryService trackAppLaunched error: $e');
    }
  }

  @override
  Future<void> trackWorkoutCompleted({
    required String workoutType,
    required int exerciseCount,
    required int setCount,
    required int durationMinutes,
    bool hasRestTimer = false,
    int restTimerCount = 0,
    bool hasRir = false,
    int rirSetsCount = 0,
    bool hasSupersets = false,
    int supersetCount = 0,
    bool hasWarmupSets = false,
    bool hasDropSets = false,
    bool hasFailureSets = false,
    bool usedPlateCalculator = false,
    bool hasWorkoutNotes = false,
  }) async {
    // Force workoutType to enum 'routine' or 'custom' ONLY to prevent custom title leaks
    final safeType = workoutType == 'routine' ? 'routine' : 'custom';
    await track('workout_completed', properties: {
      'workout_type': safeType,
      'exercise_count': exerciseCount,
      'set_count': setCount,
      'duration_minutes': durationMinutes,
      'has_rest_timer': hasRestTimer,
      'rest_timer_count': restTimerCount,
      'has_rir': hasRir,
      'rir_sets_count': rirSetsCount,
      'has_supersets': hasSupersets,
      'superset_count': supersetCount,
      'has_warmup_sets': hasWarmupSets,
      'has_drop_sets': hasDropSets,
      'has_failure_sets': hasFailureSets,
      'used_plate_calculator': usedPlateCalculator,
      'has_workout_notes': hasWorkoutNotes,
    });
  }

  @override
  Future<void> trackScreenView({
    required String screenName,
  }) async {
    await track('screen_viewed', properties: {
      'screen_name': screenName,
    });
  }

  @override
  Future<void> trackFeatureUsed({
    required String featureKey,
    Map<String, dynamic>? extraProps,
  }) async {
    await track('feature_used', properties: {
      'feature_key': featureKey,
      if (extraProps != null) ...extraProps,
    });
  }

  @override
  Future<void> incrementFoodLogCount({
    required String source,
  }) async {
    if (!_optedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_prefFoodLogCountKey) ?? 0;
      final currentSources =
          prefs.getStringList(_prefFoodLogSourcesKey) ?? <String>[];

      await prefs.setInt(_prefFoodLogCountKey, currentCount + 1);
      if (!currentSources.contains(source)) {
        currentSources.add(source);
        await prefs.setStringList(_prefFoodLogSourcesKey, currentSources);
      }
    } catch (e) {
      debugPrint('incrementFoodLogCount error: $e');
    }
  }

  @override
  Future<void> flushDailyFoodLog() async {
    if (!_optedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_prefFoodLogCountKey) ?? 0;
      if (count > 0) {
        final sources =
            prefs.getStringList(_prefFoodLogSourcesKey) ?? <String>[];
        await track('daily_food_logged', properties: {
          'count': count,
          'sources': sources,
        });

        await prefs.setInt(_prefFoodLogCountKey, 0);
        await prefs.setStringList(_prefFoodLogSourcesKey, <String>[]);
      }
    } catch (e) {
      debugPrint('flushDailyFoodLog error: $e');
    }
  }

  @override
  Future<void> trackSettingToggled({
    required String settingKey,
    required dynamic value,
  }) async {
    await track('setting_toggled', properties: {
      'setting_key': settingKey,
      'value': value,
    });
  }

  @override
  Future<void> trackOnboardingStep({
    required int stepIndex,
    required String stepName,
    required int durationSeconds,
    required String sessionId,
  }) async {
    await track('onboarding_step_viewed', properties: {
      'step_index': stepIndex,
      'step_name': stepName,
      'duration_seconds': durationSeconds,
      'session_id': sessionId,
    });
  }

  @override
  Future<void> trackOnboardingCompleted({
    required int totalDurationSeconds,
    required bool restoredFromBackup,
    required String sessionId,
  }) async {
    await track('onboarding_completed', properties: {
      'total_duration_seconds': totalDurationSeconds,
      'restored_from_backup': restoredFromBackup,
      'session_id': sessionId,
    });
  }

  @override
  Future<void> trackOnboardingAbandoned({
    required int lastStepIndex,
    required String lastStepName,
    required String sessionId,
  }) async {
    await track('onboarding_abandoned', properties: {
      'last_step_index': lastStepIndex,
      'last_step_name': lastStepName,
      'session_id': sessionId,
    });
  }

  @override
  Future<void> trackAiMealScanRequested({
    required String requestId,
    required String provider,
  }) async {
    await track('ai_meal_scan_requested', properties: {
      'request_id': requestId,
      'provider': provider,
    });
  }

  @override
  Future<void> trackAiMealScanCompleted({
    required String requestId,
    required String provider,
    required String latencyBucket,
    required bool success,
    String? errorCode,
  }) async {
    await track('ai_meal_scan_completed', properties: {
      'request_id': requestId,
      'provider': provider,
      'latency_bucket': latencyBucket,
      'success': success,
      if (errorCode != null) 'error_code': errorCode,
    });
  }

  @override
  Future<void> trackDbMigrationStatus({
    required int fromVersion,
    required int toVersion,
    required bool success,
  }) async {
    await track('db_migration_status', properties: {
      'from_version': fromVersion,
      'to_version': toVersion,
      'success': success,
    });
  }

  @override
  Future<void> trackRecommendationGenerated({
    required int weightLogCount,
    required int intakeLoggedDays,
    required int windowDays,
    required double effectiveSampleSize,
    required bool hasSlope,
    required bool hasIntake,
    required String confidence,
    required String confidenceScoreBucket,
    required String warningLevel,
    required List<String> qualityFlags,
    required bool isPriorOnly,
  }) async {
    await track('recommendation_generated', properties: {
      'weight_log_count': weightLogCount,
      'intake_logged_days': intakeLoggedDays,
      'window_days': windowDays,
      'effective_sample_size':
          double.parse(effectiveSampleSize.toStringAsFixed(1)),
      'has_slope': hasSlope,
      'has_intake': hasIntake,
      'confidence': confidence,
      'confidence_score_bucket': confidenceScoreBucket,
      'warning_level': warningLevel,
      'quality_flags': qualityFlags,
      'is_prior_only': isPriorOnly,
    });
  }

  @override
  Future<void> trackFeedbackReportSubmitted({
    required List<String> includedSections,
    required bool hasUserNote,
    required int userNoteLength,
    required String submissionMethod,
    Map<String, dynamic>? diagnosticsSummary,
  }) async {
    await track('feedback_report_submitted', properties: {
      'included_sections': includedSections,
      'has_user_note': hasUserNote,
      'user_note_length': userNoteLength,
      'submission_method': submissionMethod,
      if (diagnosticsSummary != null) ...diagnosticsSummary,
    });
  }
}
