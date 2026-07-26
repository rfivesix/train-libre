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

  /// Low-level track call for custom anonymous events.
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  });

  /// Event 1: app_launched
  Future<void> trackAppLaunched({
    required String appVersion,
    required String osVersion,
    required String platform,
    required String locale,
    String? installSource,
  });

  /// Event 2: workout_completed
  Future<void> trackWorkoutCompleted({
    required String workoutType,
    required String durationBucket,
    required String exerciseCountBucket,
  });

  /// Event 3a: ai_meal_scan_requested
  Future<void> trackAiMealScanRequested({
    required String requestId,
    required String provider,
  });

  /// Event 3b: ai_meal_scan_completed
  Future<void> trackAiMealScanCompleted({
    required String requestId,
    required String provider,
    required String latencyBucket,
    required bool success,
    String? errorCode,
  });

  /// Event 4: db_migration_status
  Future<void> trackDbMigrationStatus({
    required int fromVersion,
    required int toVersion,
    required bool success,
  });
}
