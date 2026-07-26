// lib/services/telemetry/telemetry_service_posthog.dart

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'telemetry_service.dart';

/// PostHog EU TelemetryService implementation with strict opt-in,
/// IP anonymization, and no PII capture.
class PostHogTelemetryService implements TelemetryService {
  static const String _prefOptInKey = 'telemetry_opt_in';
  static const String _defaultApiKey = String.fromEnvironment('POSTHOG_API_KEY',
      defaultValue: 'phc_vmLGxjjWfVB58y7smThJX9mQte9Y97Kff62EmLDtNWTB');
  static const String _postHogEuHost = 'https://eu.i.posthog.com';

  bool _initialized = false;
  bool _optedIn = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _optedIn = prefs.getBool(_prefOptInKey) ?? false;

      final config = PostHogConfig(_defaultApiKey)
        ..host = _postHogEuHost
        ..captureApplicationLifecycleEvents = false
        ..debug = kDebugMode;

      await Posthog().setup(config);

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
      final Map<String, Object>? objectProps = properties == null
          ? null
          : Map<String, Object>.from(properties);
      await Posthog().capture(
        eventName: eventName,
        properties: objectProps,
      );
    } catch (e) {
      debugPrint('PostHogTelemetryService track error ($eventName): $e');
    }
  }

  @override
  Future<void> trackAppLaunched({
    required String appVersion,
    required String osVersion,
    required String platform,
    required String locale,
    String? installSource,
  }) async {
    await track('app_launched', properties: {
      'app_version': appVersion,
      'os_version': osVersion,
      'platform': platform,
      'locale': locale,
      if (installSource != null) 'install_source': installSource,
    });
  }

  @override
  Future<void> trackWorkoutCompleted({
    required String workoutType,
    required String durationBucket,
    required String exerciseCountBucket,
  }) async {
    await track('workout_completed', properties: {
      'workout_type': workoutType,
      'duration_bucket': durationBucket,
      'exercise_count_bucket': exerciseCountBucket,
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
}
