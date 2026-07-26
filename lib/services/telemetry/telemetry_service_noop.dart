// lib/services/telemetry/telemetry_service_noop.dart

import 'telemetry_service.dart';

/// A zero-overhead, completely silent TelemetryService stub.
/// Contains ZERO tracking footprint and NO dependencies on posthog_flutter.
/// Used for F-Droid builds or when telemetry is disabled at compile time.
class NoOpTelemetryService implements TelemetryService {
  const NoOpTelemetryService();

  @override
  Future<void> init() async {}

  @override
  Future<void> optIn() async {}

  @override
  Future<void> optOut() async {}

  @override
  Future<bool> isOptedIn() async => false;

  @override
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  Future<void> trackAppLaunched({
    required String appVersion,
    required String osVersion,
    required String platform,
    required String locale,
    String? installSource,
  }) async {}

  @override
  Future<void> trackWorkoutCompleted({
    required String workoutType,
    required String durationBucket,
    required String exerciseCountBucket,
  }) async {}

  @override
  Future<void> trackAiMealScanRequested({
    required String requestId,
    required String provider,
  }) async {}

  @override
  Future<void> trackAiMealScanCompleted({
    required String requestId,
    required String provider,
    required String latencyBucket,
    required bool success,
    String? errorCode,
  }) async {}

  @override
  Future<void> trackDbMigrationStatus({
    required int fromVersion,
    required int toVersion,
    required bool success,
  }) async {}
}
