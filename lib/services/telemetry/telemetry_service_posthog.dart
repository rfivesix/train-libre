// lib/services/telemetry/telemetry_service_posthog.dart

import 'dart:async';
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

  /// Reported as `$lib_version` on the direct-HTTP `app_launched` payload so it
  /// lines up with what the SDK stamps on its own events. Keep in sync with the
  /// `posthog_flutter` constraint in pubspec.yaml.
  static const String _libVersion = '5.36.0';

  /// Events that must never leave the device. All of these are emitted by the
  /// native iOS/Android SDKs or by PostHog's own subsystems and would carry
  /// touch coordinates, view hierarchies or person-profile writes that this
  /// app's privacy contract forbids (see TELEMETRY.md section 3).
  static const Set<String> _deniedEvents = {
    r'$rageclick',
    r'$autocapture',
    r'$identify',
    r'$set',
    r'$create_alias',
    r'$groupidentify',
    r'$feature_flag_called',
    r'$snapshot',
    r'$push_notification_opened',
    r'$web_vitals',
    'survey shown',
    'survey sent',
    'survey dismissed',
  };

  bool _initialized = false;

  /// Whether `Posthog().setup()` has run. Stays false for the entire lifetime of
  /// an install that never opts in, so the SDK never opens a connection.
  bool _sdkConfigured = false;
  bool _optedIn = false;
  String? _persistentDeviceId;
  CountryMetadata? _cachedCountryMetadata;

  /// Privacy properties that must ride along on *every* payload, whether it is
  /// captured through the SDK or posted directly to the PostHog EU capture API.
  ///
  /// `$geoip_disable` is what actually stops PostHog's server-side GeoIP
  /// transformation from resolving city / postal code / lat-long out of the
  /// request IP. `$ip: 0.0.0.0` alone does NOT prevent that.
  Map<String, Object> get _privacyProperties {
    final meta = _cachedCountryMetadata;
    return {
      r'$process_person_profile': false,
      r'$ip': '0.0.0.0',
      r'$geoip_disable': true,
      if (meta != null) ...{
        r'$geoip_country_code': meta.countryCode,
        r'$geoip_country_name': meta.countryName,
        r'$geoip_continent_code': meta.continentCode,
        r'$geoip_continent_name': meta.continentName,
        'country': meta.countryCode,
        'country_code': meta.countryCode,
      },
    };
  }

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

      final (_, countryCode) = TelemetryService.resolveSystemLocaleAndCountry();
      _cachedCountryMetadata = TelemetryService.getCountryMetadata(countryCode);

      _initialized = true;

      // The SDK is deliberately NOT touched for users who have not opted in.
      // `Posthog().setup()` unconditionally triggers the native SDK's remote
      // config fetch — `PostHogRemoteConfig.preloadRemoteConfig()` is gated only
      // by a testing flag and ignores the opt-out state entirely — so merely
      // setting it up would open a connection to PostHog EU and expose the
      // device's IP address before any consent was given. Setup is deferred to
      // [optIn].
      if (_optedIn) {
        await _configureSdk();
        unawaited(flushDailyFoodLog());
      }
    } catch (e) {
      debugPrint('PostHogTelemetryService init error: $e');
    }
  }

  /// Performs the one-time PostHog SDK setup. Only ever called once the user has
  /// opted in; the native SDK ignores a second `setup()` call, so the flag also
  /// guards an opt-out/opt-in cycle within the same app session.
  Future<void> _configureSdk() async {
    if (_sdkConfigured) return;
    try {
      final config = PostHogConfig(_defaultApiKey)
        ..host = _postHogEuHost
        ..captureApplicationLifecycleEvents = false
        // Never let PostHog build person profiles, identity graphs or user
        // timelines from our events.
        ..personProfiles = PostHogPersonProfiles.never
        // Every one of these subsystems emits its own events that bypass
        // `beforeSend` (they are native-initiated), so they are switched off at
        // the source rather than filtered after the fact.
        ..sessionReplay = false
        ..surveys = false
        ..sendFeatureFlagEvents = false
        ..preloadFeatureFlags = false
        ..capturePushNotificationSubscriptions = false
        ..capturePushNotificationOpened = false
        ..debug = kDebugMode
        ..beforeSend = [
          (event) {
            if (_deniedEvents.contains(event.event) ||
                event.event.startsWith(r'$rage') ||
                event.event.startsWith(r'$auto') ||
                event.event.startsWith('survey ')) {
              return null;
            }
            final props = _privacyProperties;
            if (event.event == r'$delete_person') {
              // Person processing is what performs the deletion — suppressing
              // it here would make the deletion request a no-op.
              props.remove(r'$process_person_profile');
            }
            (event.properties ??= <String, Object>{}).addAll(props);
            return event;
          },
        ];

      // iOS/macCatalyst rage-click autocapture is ON by default in the native
      // SDK and emits `$rageclick` with raw touch coordinates through a channel
      // `beforeSend` cannot reach. It has to be disabled in the config itself.
      config.rageClickConfig.enabled = false;

      await Posthog().setup(config);
      _sdkConfigured = true;

      // Rotate the in-app SDK distinct_id on every app launch for privacy.
      // `reset()` discards the stored anonymous ID and the native SDK mints a
      // fresh one — unlike `identify()`, which marks the user as identified and
      // makes PostHog create a person profile complete with IP-derived city,
      // postal code and coordinates.
      await Posthog().reset();
      await Posthog().enable();
    } catch (e) {
      debugPrint('PostHogTelemetryService _configureSdk error: $e');
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
              // `$process_person_profile` is deliberately NOT set to false here:
              // it would tell the ingestion pipeline to skip person processing,
              // which is exactly the step that carries out the deletion.
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

      // Only meaningful when the SDK was ever configured; an install that never
      // opted in has no SDK-side events to erase.
      if (_sdkConfigured) {
        try {
          await Posthog().capture(
            eventName: r'$delete_person',
            properties: {
              r'$ip': '0.0.0.0',
              r'$geoip_disable': true,
              r'$delete_person': true,
            },
          );
        } catch (e) {
          debugPrint('PostHog capture delete_person error: $e');
        }
      }

      // Clear local SharedPreferences storage
      await prefs.remove(_prefDeviceIdKey);
      await prefs.remove(_prefFoodLogCountKey);
      await prefs.remove(_prefFoodLogSourcesKey);

      // Re-generate fresh persistent device ID and reset PostHog SDK identity
      _persistentDeviceId = const Uuid().v4();
      await prefs.setString(_prefDeviceIdKey, _persistentDeviceId!);

      // Discards the stored anonymous ID; the native SDK mints a fresh one.
      if (_sdkConfigured) {
        await Posthog().reset();
      }
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
      // First contact with PostHog happens here, never earlier.
      await _configureSdk();
      if (_sdkConfigured) {
        await Posthog().enable();
      }
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
      if (_sdkConfigured) {
        await Posthog().disable();
      }
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
    if (!_optedIn || !_sdkConfigured) return;
    try {
      // Privacy properties are applied centrally in `beforeSend`, so every
      // Dart-captured event gets them regardless of which helper produced it.
      await Posthog().capture(
        eventName: eventName,
        properties: {
          if (properties != null)
            ...properties.map((key, value) => MapEntry(key, value as Object)),
        },
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

      final meta = TelemetryService.getCountryMetadata(country);
      _cachedCountryMetadata = meta;

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
          ..._privacyProperties,

          // PostHog Native Feature / Metadata fields for GeoIP & Locale
          r'$locale': locale,

          // Environment metadata. Only values we can actually observe are sent —
          // device manufacturer/model/name and the TestFlight/sideload flags
          // used to be filled in with guesses derived from `platform`, which put
          // fabricated hardware data ("Apple"/"arm64"/"iPhone" for every iOS
          // device, "Android"/"Mobile" for every Android one) into analytics.
          if (appBuild != null) r'$app_build': appBuild,
          r'$app_name': 'Train Libre',
          r'$app_version': appVersion,
          r'$app_namespace': 'com.rfivesix.trainlibre',
          r'$device_type': 'Mobile',
          r'$is_emulator': isEmulator,
          r'$lib': 'posthog-flutter',
          r'$lib_version': _libVersion,
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

  /// Shape every enum-like telemetry value must have: lower_snake_case ASCII.
  ///
  /// User-authored text (routine names, food names) never matches, so this
  /// catches the class of leak that once sent a routine title as
  /// `workout_type`. Checking the shape rather than a hard-coded allow-list
  /// keeps the guard from silently rotting as [ScreenName] gains entries.
  static final RegExp _enumValuePattern = RegExp(r'^[a-z][a-z0-9_]*$');

  static String _sanitizeEnumValue(String value) =>
      _enumValuePattern.hasMatch(value) ? value : 'unknown';

  @override
  Future<void> trackScreenView({
    required String screenName,
  }) async {
    await track('screen_viewed', properties: {
      'screen_name': _sanitizeEnumValue(screenName),
    });
  }

  @override
  Future<void> trackFeatureUsed({
    required String featureKey,
    Map<String, dynamic>? extraProps,
  }) async {
    await track('feature_used', properties: {
      'feature_key': _sanitizeEnumValue(featureKey),
      if (extraProps != null) ...extraProps,
    });
  }

  /// Serializes the read-modify-write cycles on the food-log counter.
  ///
  /// Logging a saved meal or confirming an AI meal scan inserts every item in a
  /// tight loop, and each insert fires an unawaited increment. Without this
  /// queue those increments interleave — several of them read the same starting
  /// value and write back the same result, so a five-item meal is recorded as a
  /// single entry. It also stops a flush from zeroing the counter while an
  /// increment is still in flight.
  Future<void> _foodLogQueue = Future<void>.value();

  Future<void> _serializeFoodLog(Future<void> Function() action) {
    final completer = Completer<void>();
    _foodLogQueue = _foodLogQueue.then((_) async {
      try {
        await action();
      } catch (e) {
        debugPrint('food log counter error: $e');
      } finally {
        completer.complete();
      }
    });
    return completer.future;
  }

  @override
  Future<void> incrementFoodLogCount({
    required String source,
  }) {
    if (!_optedIn) return Future<void>.value();
    // Sanitized here rather than trusting callers, so no code path can put
    // free-form text (a routine name, a food name) into the sources list.
    final safeSource = FoodLogSource.sanitize(source);
    return _serializeFoodLog(() async {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_prefFoodLogCountKey) ?? 0;
      final currentSources =
          prefs.getStringList(_prefFoodLogSourcesKey) ?? <String>[];

      await prefs.setInt(_prefFoodLogCountKey, currentCount + 1);
      if (!currentSources.contains(safeSource)) {
        currentSources.add(safeSource);
        await prefs.setStringList(_prefFoodLogSourcesKey, currentSources);
      }
    });
  }

  @override
  Future<void> flushDailyFoodLog() {
    if (!_optedIn) return Future<void>.value();
    return _serializeFoodLog(() async {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_prefFoodLogCountKey) ?? 0;
      if (count <= 0) return;

      final sources = prefs.getStringList(_prefFoodLogSourcesKey) ?? <String>[];

      // Clear before sending: a failed capture is preferable to double counting
      // the same entries on the next flush.
      await prefs.setInt(_prefFoodLogCountKey, 0);
      await prefs.setStringList(_prefFoodLogSourcesKey, <String>[]);

      await track('daily_food_logged', properties: {
        'count': count,
        'sources': sources,
      });
      // The app is usually on its way to the background at this point, so hand
      // the batch to the network instead of leaving it in the SDK queue.
      if (_sdkConfigured) {
        await Posthog().flush();
      }
    });
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
