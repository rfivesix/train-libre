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
  Future<void> resetLocalData() async {}

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
    required String country,
    String? installSource,
  }) async {}

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
  }) async {}

  @override
  Future<void> trackScreenView({
    required String screenName,
  }) async {}

  @override
  Future<void> trackFeatureUsed({
    required String featureKey,
    Map<String, dynamic>? extraProps,
  }) async {}

  @override
  Future<void> incrementFoodLogCount({
    required String source,
  }) async {}

  @override
  Future<void> flushDailyFoodLog() async {}

  @override
  Future<void> trackSettingToggled({
    required String settingKey,
    required dynamic value,
  }) async {}

  @override
  Future<void> trackOnboardingStep({
    required int stepIndex,
    required String stepName,
    required int durationSeconds,
    required String sessionId,
  }) async {}

  @override
  Future<void> trackOnboardingCompleted({
    required int totalDurationSeconds,
    required bool restoredFromBackup,
    required String sessionId,
  }) async {}

  @override
  Future<void> trackOnboardingAbandoned({
    required int lastStepIndex,
    required String lastStepName,
    required String sessionId,
  }) async {}

  @override
  Future<void> trackAiMealScanRequested({
    required String requestId,
    required String provider,
    String? inputMode,
    int? photoCount,
    bool? hasLidar,
    bool? hasVoiceInput,
    bool? hasTextInput,
  }) async {}

  @override
  Future<void> trackAiMealScanCompleted({
    required String requestId,
    required String provider,
    required String latencyBucket,
    required bool success,
    String? errorCode,
    String? inputMode,
    int? photoCount,
    bool? hasLidar,
    bool? hasVoiceInput,
    bool? hasTextInput,
    bool? validationPassed,
    int? repairAttemptsCount,
    String? suggestedItemsCountBucket,
  }) async {}

  @override
  Future<void> trackVoiceDictationCompleted({
    required String durationBucket,
    required bool aiTidyUpEnabled,
    required String surface,
    required bool success,
    String? errorCode,
  }) async {}

  @override
  Future<void> trackAiMealCorrectionCompleted({
    required bool hasImages,
    required String latencyBucket,
    required bool success,
    int? repairAttemptsCount,
    String? errorCode,
  }) async {}

  @override
  Future<void> trackDbMigrationStatus({
    required int fromVersion,
    required int toVersion,
    required bool success,
  }) async {}

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
  }) async {}

  @override
  Future<void> trackFeedbackReportSubmitted({
    required List<String> includedSections,
    required bool hasUserNote,
    required int userNoteLength,
    required String submissionMethod,
    Map<String, dynamic>? diagnosticsSummary,
  }) async {}
}
