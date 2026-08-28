// lib/services/telemetry/telemetry_service.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'telemetry_service_noop.dart';
import 'telemetry_service_posthog.dart';

/// Class containing country and continent metadata for PostHog GeoIP mapping.
class CountryMetadata {
  final String countryCode;
  final String countryName;
  final String continentCode;
  final String continentName;

  const CountryMetadata({
    required this.countryCode,
    required this.countryName,
    required this.continentCode,
    required this.continentName,
  });
}

/// The surface a food entry was logged from, reported in the `sources` list of
/// the aggregated `daily_food_logged` event.
///
/// Values are a closed set so the event can never carry free-form text.
abstract class FoodLogSource {
  /// Picked from search, favourites or the recents list and logged individually.
  static const String manualSearch = 'manual_search';

  /// Resolved by scanning a product barcode.
  static const String barcodeScan = 'barcode_scan';

  /// Recognised by the AI meal scanner and confirmed in the review screen.
  static const String aiCapture = 'ai_capture';

  /// Logged in bulk as part of a saved meal or recipe.
  static const String meal = 'meal';

  static const Set<String> all = {manualSearch, barcodeScan, aiCapture, meal};

  /// Normalizes an arbitrary string to a known source, falling back to
  /// [manualSearch] so an unexpected caller can never leak text into telemetry.
  static String sanitize(String? raw) =>
      all.contains(raw) ? raw! : manualSearch;
}

/// Closed set of `feature_key` values for the `feature_used` event.
///
/// Using constants rather than string literals at the call sites keeps the
/// values in lockstep with the catalog in TELEMETRY.md and makes it impossible
/// to accidentally send user-authored text as a feature key.
abstract class FeatureKey {
  // Workout
  static const String routineCreated = 'routine_created';
  static const String routineStarted = 'routine_started';

  /// Sharing is text/image based. The catalog previously named this
  /// `routine_shared_qr`, but the app has no QR sharing — only the share sheet
  /// in [ShareService], so the key reflects what actually happens.
  static const String routineShared = 'routine_shared';
  static const String workoutImported = 'workout_imported';
  static const String customExerciseCreated = 'custom_exercise_created';

  // Nutrition & AI
  static const String barcodeScanned = 'barcode_scanned';
  static const String customFoodCreated = 'custom_food_created';
  static const String recipeCreated = 'recipe_created';
  static const String supplementLogged = 'supplement_logged';
  static const String voiceDictationUsed = 'voice_dictation_used';
  static const String lidarDepthCaptured = 'lidar_depth_captured';
  static const String lidarDepthVisualized = 'lidar_depth_visualized';
  static const String aiMealCorrectionSubmitted =
      'ai_meal_correction_submitted';
  static const String offCatalogInstalled = 'off_catalog_installed';
  static const String offCatalogUpdated = 'off_catalog_updated';

  // Body & health
  static const String bodyMeasurementLogged = 'body_measurement_logged';
  static const String appleHealthExported = 'apple_health_exported';
  static const String healthConnectExported = 'health_connect_exported';

  // Data management
  static const String jsonBackupCreated = 'json_backup_created';
  static const String jsonBackupRestored = 'json_backup_restored';
  static const String icloudSyncTriggered = 'icloud_sync_triggered';
  static const String csvExported = 'csv_exported';

  // Onboarding & guidance
  static const String appTourStarted = 'app_tour_started';
  static const String appTourCompleted = 'app_tour_completed';

  /// Emitted only for the automatic post-update presentation, not when the
  /// user opens the release history from the About screen — otherwise the
  /// metric would no longer describe update reach.
  static const String whatsNewViewed = 'whats_new_viewed';

  static const Set<String> all = {
    routineCreated,
    routineStarted,
    routineShared,
    workoutImported,
    customExerciseCreated,
    barcodeScanned,
    customFoodCreated,
    recipeCreated,
    supplementLogged,
    voiceDictationUsed,
    lidarDepthCaptured,
    lidarDepthVisualized,
    aiMealCorrectionSubmitted,
    offCatalogInstalled,
    offCatalogUpdated,
    bodyMeasurementLogged,
    appleHealthExported,
    healthConnectExported,
    jsonBackupCreated,
    jsonBackupRestored,
    icloudSyncTriggered,
    csvExported,
    appTourStarted,
    appTourCompleted,
    whatsNewViewed,
  };
}

/// Closed set of `screen_name` values for the `screen_viewed` event.
abstract class ScreenName {
  // Tabs
  static const String workoutTab = 'workout_tab';
  static const String diaryTab = 'diary_tab';
  static const String analyticsTab = 'analytics_tab';
  static const String nutritionTab = 'nutrition_tab';

  // Workout
  static const String liveWorkout = 'live_workout';
  static const String routineEditor = 'routine_editor';
  static const String routineList = 'routine_list';
  static const String workoutSummary = 'workout_summary';
  static const String workoutHistory = 'workout_history';
  static const String workoutDetail = 'workout_detail';
  static const String exerciseCatalog = 'exercise_catalog';
  static const String exerciseDetail = 'exercise_detail';
  static const String createExercise = 'create_exercise';

  // Diary
  static const String mealList = 'meal_list';
  static const String addFoodSearch = 'add_food_search';
  static const String foodDetail = 'food_detail';
  static const String createFood = 'create_food';
  static const String aiMealCapture = 'ai_meal_capture';
  static const String aiMealReview = 'ai_meal_review';
  static const String mealAnalysis = 'meal_analysis';
  static const String barcodeScanner = 'barcode_scanner';
  static const String mealEditor = 'meal_editor';
  static const String foodExplorer = 'food_explorer';

  // Analytics
  static const String muscleGroupAnalytics = 'muscle_group_analytics';
  static const String prDashboard = 'pr_dashboard';
  static const String consistencyTracker = 'consistency_tracker';
  static const String bodyNutritionCorrelation = 'body_nutrition_correlation';
  static const String recoveryTracker = 'recovery_tracker';

  // Health & utilities
  static const String bodyMeasurements = 'body_measurements';
  static const String goalEditor = 'goal_editor';
  static const String pulseOverview = 'pulse_overview';
  static const String sleepOverview = 'sleep_overview';
  static const String stepsOverview = 'steps_overview';
  static const String supplementsOverview = 'supplements_overview';
  static const String settingsMain = 'settings_main';
  static const String aiSettings = 'ai_settings';
  static const String voiceDictationSettings = 'voice_dictation_settings';

  /// Backup, CSV export, import and local-data deletion all live on one screen
  /// ([DataManagementScreen]), so the catalog's separate `export_data`,
  /// `import_data` and `cloud_backup` names had no screen to attach to.
  static const String dataManagement = 'data_management';
  static const String aboutApp = 'about_app';
  static const String whatsNew = 'whats_new';
  static const String legalPrivacy = 'legal_privacy';
  static const String feedbackReport = 'feedback_report';
}

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

  /// Resolves the current system locale string (e.g. 'de_DE') and 2-letter ISO country code (e.g. 'DE').
  static (String locale, String country) resolveSystemLocaleAndCountry() {
    String localeStr = 'de_DE';
    try {
      localeStr = Platform.localeName;
    } catch (_) {}

    String? countryCode;

    // 1. Try PlatformDispatcher locales
    try {
      final locales = ui.PlatformDispatcher.instance.locales;
      for (final l in locales) {
        if (l.countryCode != null &&
            l.countryCode!.isNotEmpty &&
            l.countryCode!.length == 2) {
          countryCode = l.countryCode!.toUpperCase();
          break;
        }
      }
    } catch (_) {}

    // 2. Parse Platform.localeName with Regex
    if (countryCode == null || countryCode.isEmpty) {
      final match =
          RegExp(r'[_-]([a-zA-Z]{2})(?:[._@-]|$)').firstMatch(localeStr);
      if (match != null) {
        final code = match.group(1)!.toUpperCase();
        if (code != 'HANS' &&
            code != 'HANT' &&
            code != 'LATN' &&
            code != 'CYRL') {
          countryCode = code;
        }
      }
    }

    // 3. Language fallback map
    if (countryCode == null || countryCode.isEmpty || countryCode.length != 2) {
      final lang = localeStr.split(RegExp(r'[_-]')).first.toLowerCase();
      const languageToCountry = <String, String>{
        'de': 'DE',
        'en': 'US',
        'fr': 'FR',
        'it': 'IT',
        'es': 'ES',
        'ja': 'JP',
        'nl': 'NL',
        'pl': 'PL',
        'pt': 'PT',
        'ru': 'RU',
        'zh': 'CN',
        'uk': 'UA',
        'cs': 'CZ',
        'da': 'DK',
        'fi': 'FI',
        'sv': 'SE',
        'nb': 'NO',
        'nn': 'NO',
        'no': 'NO',
        'tr': 'TR',
        'ko': 'KR',
      };
      countryCode = languageToCountry[lang] ?? 'DE';
    }

    return (localeStr, countryCode);
  }

  /// Maps an ISO 3166-1 alpha-2 country code to full PostHog GeoIP country & continent metadata.
  static CountryMetadata getCountryMetadata(String rawCountryCode) {
    final code = rawCountryCode.trim().toUpperCase();
    switch (code) {
      case 'DE':
        return const CountryMetadata(
            countryCode: 'DE',
            countryName: 'Germany',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'US':
        return const CountryMetadata(
            countryCode: 'US',
            countryName: 'United States',
            continentCode: 'NA',
            continentName: 'North America');
      case 'GB':
        return const CountryMetadata(
            countryCode: 'GB',
            countryName: 'United Kingdom',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'AT':
        return const CountryMetadata(
            countryCode: 'AT',
            countryName: 'Austria',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'CH':
        return const CountryMetadata(
            countryCode: 'CH',
            countryName: 'Switzerland',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'FR':
        return const CountryMetadata(
            countryCode: 'FR',
            countryName: 'France',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'IT':
        return const CountryMetadata(
            countryCode: 'IT',
            countryName: 'Italy',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'ES':
        return const CountryMetadata(
            countryCode: 'ES',
            countryName: 'Spain',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'NL':
        return const CountryMetadata(
            countryCode: 'NL',
            countryName: 'Netherlands',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'BE':
        return const CountryMetadata(
            countryCode: 'BE',
            countryName: 'Belgium',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'PL':
        return const CountryMetadata(
            countryCode: 'PL',
            countryName: 'Poland',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'CZ':
        return const CountryMetadata(
            countryCode: 'CZ',
            countryName: 'Czechia',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'DK':
        return const CountryMetadata(
            countryCode: 'DK',
            countryName: 'Denmark',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'SE':
        return const CountryMetadata(
            countryCode: 'SE',
            countryName: 'Sweden',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'NO':
        return const CountryMetadata(
            countryCode: 'NO',
            countryName: 'Norway',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'FI':
        return const CountryMetadata(
            countryCode: 'FI',
            countryName: 'Finland',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'PT':
        return const CountryMetadata(
            countryCode: 'PT',
            countryName: 'Portugal',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'GR':
        return const CountryMetadata(
            countryCode: 'GR',
            countryName: 'Greece',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'IE':
        return const CountryMetadata(
            countryCode: 'IE',
            countryName: 'Ireland',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'HU':
        return const CountryMetadata(
            countryCode: 'HU',
            countryName: 'Hungary',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'RO':
        return const CountryMetadata(
            countryCode: 'RO',
            countryName: 'Romania',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'UA':
        return const CountryMetadata(
            countryCode: 'UA',
            countryName: 'Ukraine',
            continentCode: 'EU',
            continentName: 'Europe');
      case 'CA':
        return const CountryMetadata(
            countryCode: 'CA',
            countryName: 'Canada',
            continentCode: 'NA',
            continentName: 'North America');
      case 'MX':
        return const CountryMetadata(
            countryCode: 'MX',
            countryName: 'Mexico',
            continentCode: 'NA',
            continentName: 'North America');
      case 'JP':
        return const CountryMetadata(
            countryCode: 'JP',
            countryName: 'Japan',
            continentCode: 'AS',
            continentName: 'Asia');
      case 'CN':
        return const CountryMetadata(
            countryCode: 'CN',
            countryName: 'China',
            continentCode: 'AS',
            continentName: 'Asia');
      case 'KR':
        return const CountryMetadata(
            countryCode: 'KR',
            countryName: 'South Korea',
            continentCode: 'AS',
            continentName: 'Asia');
      case 'IN':
        return const CountryMetadata(
            countryCode: 'IN',
            countryName: 'India',
            continentCode: 'AS',
            continentName: 'Asia');
      case 'SG':
        return const CountryMetadata(
            countryCode: 'SG',
            countryName: 'Singapore',
            continentCode: 'AS',
            continentName: 'Asia');
      case 'AU':
        return const CountryMetadata(
            countryCode: 'AU',
            countryName: 'Australia',
            continentCode: 'OC',
            continentName: 'Oceania');
      case 'NZ':
        return const CountryMetadata(
            countryCode: 'NZ',
            countryName: 'New Zealand',
            continentCode: 'OC',
            continentName: 'Oceania');
      case 'BR':
        return const CountryMetadata(
            countryCode: 'BR',
            countryName: 'Brazil',
            continentCode: 'SA',
            continentName: 'South America');
      case 'AR':
        return const CountryMetadata(
            countryCode: 'AR',
            countryName: 'Argentina',
            continentCode: 'SA',
            continentName: 'South America');
      case 'ZA':
        return const CountryMetadata(
            countryCode: 'ZA',
            countryName: 'South Africa',
            continentCode: 'AF',
            continentName: 'Africa');
      case 'EG':
        return const CountryMetadata(
            countryCode: 'EG',
            countryName: 'Egypt',
            continentCode: 'AF',
            continentName: 'Africa');
      case 'IL':
        return const CountryMetadata(
            countryCode: 'IL',
            countryName: 'Israel',
            continentCode: 'AS',
            continentName: 'Asia');
      case 'TR':
        return const CountryMetadata(
            countryCode: 'TR',
            countryName: 'Turkey',
            continentCode: 'EU',
            continentName: 'Europe');
      default:
        return CountryMetadata(
          countryCode: code.isNotEmpty ? code : 'DE',
          countryName: code.isNotEmpty ? code : 'Germany',
          continentCode: 'EU',
          continentName: 'Europe',
        );
    }
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
    required String country,
    String? installSource,
  });

  /// Event 2: workout_completed (Aggregated counts and subfeature usage flags, ZERO PII)
  Future<void> trackWorkoutCompleted({
    required String
        workoutType, // 'routine' or 'custom' ONLY (no custom titles)
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
    String? inputMode,
    int? photoCount,
    bool? hasLidar,
    bool? hasVoiceInput,
    bool? hasTextInput,
  });

  /// Event 8b: ai_meal_scan_completed
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
  });

  /// Event 12: voice_dictation_completed
  Future<void> trackVoiceDictationCompleted({
    required String durationBucket,
    required bool aiTidyUpEnabled,
    required String surface,
    required bool success,
    String? errorCode,
  });

  /// Event 13: ai_meal_correction_completed
  Future<void> trackAiMealCorrectionCompleted({
    required bool hasImages,
    required String latencyBucket,
    required bool success,
    int? repairAttemptsCount,
    String? errorCode,
  });

  /// Event 9: db_migration_status
  Future<void> trackDbMigrationStatus({
    required int fromVersion,
    required int toVersion,
    required bool success,
  });

  /// Event 10: recommendation_generated (TDEE confidence, quality flags & log counts, ZERO PII)
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
  });

  /// Event 11: feedback_report_submitted (Voluntary diagnostic report submission, ZERO PII)
  Future<void> trackFeedbackReportSubmitted({
    required List<String> includedSections,
    required bool hasUserNote,
    required int userNoteLength,
    required String submissionMethod,
    Map<String, dynamic>? diagnosticsSummary,
  });

  /// Event 8: performance_stall
  ///
  /// Reported when the UI isolate stopped answering long enough for the user
  /// to notice. Properties are built by `PerformanceTelemetry.stallProperties`
  /// and carry only hardware identifiers, Dart class names and counters.
  Future<void> trackPerformanceStall({
    required Map<String, dynamic> properties,
  });
}
