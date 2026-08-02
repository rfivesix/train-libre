// lib/services/telemetry/telemetry_service.dart

import 'telemetry_service_noop.dart';
import 'telemetry_service_posthog.dart';

/// Abstract TelemetryService defining the contract for tracking anonymous,
/// privacy-friendly usage metrics.
abstract class TelemetryService {
  static TelemetryService? _instance;

  /// Global singleton instance of TelemetryService.
  static TelemetryService get instance =>
      _instance ??= TelemetryService.create();

  /// Allows overriding the singleton instance (e.g. for unit testing).
  static set instance(TelemetryService customInstance) {
    _instance = customInstance;
  }

  /// Creates either a [PostHogTelemetryService] or a [NoOpTelemetryService]
  /// depending on compile-time flag `--dart-define=DISABLE_TELEMETRY=true`.
  static TelemetryService create() {
    const isTelemetryDisabled =
        bool.fromEnvironment('DISABLE_TELEMETRY', defaultValue: false);
    if (isTelemetryDisabled) {
      return const NoOpTelemetryService();
    }
    return PostHogTelemetryService();
  }

  /// Initializes telemetry configuration and restores opt-in status.
  Future<void> init();

  /// Explicitly opt-in to telemetry.
  Future<void> optIn();

  /// Explicitly opt-out of telemetry.
  Future<void> optOut();

  /// Returns true if telemetry is currently opted in.
  Future<bool> isOptedIn();

  /// Resets and clears all local persistent telemetry IDs and cached data.
  Future<void> resetLocalData();

  /// Low-level track call for custom anonymous events.
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  });

  /// Event 1: app_launched (DAU/MAU via isolated persistent device UUID)
  Future<void> trackAppLaunched({
    required String appVersion,
    required String osVersion,
    required String platform,
    required String locale,
    String? installSource,
  });

  /// Event 2: workout_completed (Aggregated counts and subfeature usage flags, ZERO PII)
  Future<void> trackWorkoutCompleted({
    required String workoutType, // 'routine' or 'custom' ONLY (no custom titles)
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
  });

  /// Event 3: screen_viewed
  Future<void> trackScreenView({
    required String screenName,
  });

  /// Event 4: feature_used
  Future<void> trackFeatureUsed({
    required String featureKey,
    Map<String, dynamic>? extraProps,
  });

  /// Event 5: daily_food_logged counter increment & flush
  Future<void> incrementFoodLogCount({
    required String source,
  });

  Future<void> flushDailyFoodLog();

  /// Event 6: setting_toggled
  Future<void> trackSettingToggled({
    required String settingKey,
    required dynamic value,
  });

  /// Event 7a: onboarding_step_viewed
  Future<void> trackOnboardingStep({
    required int stepIndex,
    required String stepName,
    required int durationSeconds,
    required String sessionId,
  });

  /// Event 7b: onboarding_completed
  Future<void> trackOnboardingCompleted({
    required int totalDurationSeconds,
    required bool restoredFromBackup,
    required String sessionId,
  });

  /// Event 7c: onboarding_abandoned
  Future<void> trackOnboardingAbandoned({
    required int lastStepIndex,
    required String lastStepName,
    required String sessionId,
  });

  /// Event 8a: ai_meal_scan_requested
  Future<void> trackAiMealScanRequested({
    required String requestId,
    required String provider,
  });

  /// Event 8b: ai_meal_scan_completed
  Future<void> trackAiMealScanCompleted({
    required String requestId,
    required String provider,
    required String latencyBucket,
    required bool success,
    String? errorCode,
  });

  /// Event 9: db_migration_status
  Future<void> trackDbMigrationStatus({
    required int fromVersion,
    required int toVersion,
    required bool success,
  });
}

