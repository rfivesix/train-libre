// lib/screens/onboarding_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../util/design_constants.dart';

import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/infrastructure/backup_manager.dart';
import '../../../core/infrastructure/basis_data_manager.dart';
import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../app/presentation/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../profile/data/legacy_goal_migration.dart';
import '../../nutrition_recommendation/presentation/body_fat_guidance_sheet.dart';
import '../../nutrition_recommendation/domain/goal_models.dart';
import '../../nutrition_recommendation/domain/recommendation_models.dart';
import '../../../services/app_tour_service.dart';
import '../../../services/unit_service.dart';
import '../../../services/profile_service.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../profile/domain/models/user_gender.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../settings/presentation/ai_settings_screen.dart';
import '../../settings/presentation/pulse_settings_screen.dart';
import '../../settings/presentation/sleep_settings_screen.dart';
import '../../settings/presentation/steps_settings_screen.dart';
import 'widgets/welcome_slide.dart';
import 'widgets/unit_system_slide.dart';
import 'widgets/profile_slide.dart';
import 'widgets/region_selection_slide.dart';
import '../../profile/data/goal_repository_impl.dart';
import '../../profile/domain/models/goal_model.dart';
import '../../profile/domain/repositories/goal_repository.dart';
import '../../profile/presentation/widgets/goal_flow/goal_flow_state.dart';
import '../../profile/presentation/widgets/goal_flow/goal_motivation_step.dart';
import '../../profile/presentation/widgets/goal_flow/goal_pace_timeline_step.dart';
import '../../profile/presentation/widgets/goal_flow/goal_preset_step.dart';
import '../../profile/presentation/widgets/goal_flow/goal_target_step.dart';
import '../../nutrition_recommendation/presentation/prior_activity_help_block.dart';
import '../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../services/off_catalog_country_service.dart';
import '../../../config/app_data_sources.dart';
import '../../../core/infrastructure/icloud_sync_service.dart';
import 'dart:io';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../../../widgets/common/long_running_operation_overlay.dart';
import '../../../util/permission_dialogs.dart';
import '../../../services/health/health_platform_steps.dart';
import '../../pulse/application/pulse_tracking_service.dart';
import '../../sleep/platform/permissions/sleep_permission_controller.dart';
import '../../sleep/platform/permissions/healthkit_sleep_permissions_service.dart';
import '../../sleep/platform/permissions/health_connect_sleep_permissions_service.dart';
import '../../sleep/platform/sleep_platform_channel.dart';
import '../../health_export/export_service.dart';
import '../../health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../../health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../../health_export/models/export_models.dart';
import 'package:uuid/uuid.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_ruler_picker.dart';
import '../../../widgets/common/app_restart.dart';

/// The initial setup flow for new users.
///
/// Collects user profile data (name, DOB, anthropometrics) and initial
/// nutrition/health goals to populate the database and preferences.
class OnboardingScreen extends StatefulWidget {
  final AdaptiveNutritionRecommendationService? recommendationService;
  final DatabaseHelper? databaseHelper;
  final IGoalRepository? goalRepository;
  final bool forceImportMode;
  final VoidCallback? onFinish;

  const OnboardingScreen({
    super.key,
    this.recommendationService,
    this.databaseHelper,
    this.goalRepository,
    this.forceImportMode = false,
    this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _unitSystemPageIndex = 1;
  static const int _regionSelectionPageIndex = 2;
  static const int _namePageIndex = 3;
  static const int _bioDataPageIndex = 4;
  static const int _heightPageIndex = 5;
  static const int _measurementsPageIndex = 6;
  static const int _activityPageIndex = 7;
  static const int _goalDecisionPageIndex = 8;
  static const int _goalPresetPageIndex = 9;
  static const int _goalTargetPageIndex = 10;
  static const int _goalPaceTimelinePageIndex = 11;
  static const int _goalMotivationPageIndex = 12;
  static const int _nutritionPageIndex = 13;
  static const int _permissionsPageIndex = 14;
  static const int _totalPageCount = 15;
  static const int _lastPageIndex = _permissionsPageIndex;

  bool _isImportedMode = false;
  bool _requiresHardRestart = false;
  bool _hasICloudBackup = false;

  String? _heightError;
  String? _dobError;
  String? _genderError;
  String? _weightError;

  String? _heightWarning;
  String? _weightWarning;

  String? _lastWarnedHeightValue;
  String? _lastWarnedWeightValue;

  final String _onboardingSessionId = const Uuid().v4();
  final Stopwatch _stepStopwatch = Stopwatch()..start();
  final Stopwatch _totalStopwatch = Stopwatch()..start();
  bool _onboardingCompletedSuccessfully = false;

  static const List<String> _stepNames = [
    'welcome',
    'unit_system',
    'region_selection',
    'name',
    'age_and_gender',
    'height',
    'body_measurements',
    'current_activity',
    'goal_decision',
    'goal_preset',
    'goal_target',
    'goal_pace_timeline',
    'goal_motivation',
    'nutrition_recommendation',
    'permissions_consent',
  ];

  OffCatalogCountry _selectedOffCountry = OffCatalogCountry.de;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRestoring = false;
  bool _isGeneratingOnboardingRecommendation = false;
  bool _isCheckingDatabase = false;
  Future<void>? _onboardingRecommendationFuture;

  late final AdaptiveNutritionRecommendationService _recommendationService;
  late final DatabaseHelper _databaseHelper;
  late final IGoalRepository _goalRepository;
  final GoalFlowState _goalFlowState = GoalFlowState();
  bool _skippedGoal = false;

  NutritionRecommendation? _onboardingRecommendation;

  // --- CONTROLLER ---
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _heightController = TextEditingController();
  // Keep the initially visible dropdown value and the submitted profile value
  // in sync. Otherwise the native control can show “Male” while validation
  // still sees a null selection.
  String? _selectedGender = 'male';
  final TextEditingController _bodyFatPercentController =
      TextEditingController();
  PriorActivityLevel _selectedPriorActivityLevel =
      PriorActivityLevelCatalog.defaultLevel;
  ExtraCardioHoursOption _selectedExtraCardioHoursOption =
      ExtraCardioHoursCatalog.defaultOption;

  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _calController = TextEditingController(
    text: '2500',
  );
  final TextEditingController _protController = TextEditingController(
    text: '180',
  );
  final TextEditingController _carbController = TextEditingController(
    text: '250',
  );
  final TextEditingController _fatController = TextEditingController(
    text: '80',
  );
  final TextEditingController _waterController = TextEditingController(
    text: '4500',
  );

  @override
  void initState() {
    super.initState();
    assert(_stepNames.length == _totalPageCount,
        'Every onboarding page must have exactly one telemetry step name.');
    _isImportedMode = widget.forceImportMode;
    _databaseHelper = widget.databaseHelper ?? DatabaseHelper.instance;
    _goalRepository = widget.goalRepository ??
        GoalRepositoryImpl(database: _databaseHelper.dbInstance);
    _recommendationService = widget.recommendationService ??
        AdaptiveNutritionRecommendationService(databaseHelper: _databaseHelper);
    _loadAdaptiveGoalSettings();
    _initSelectedCountry();

    _goalFlowState.onBaselineChanged = (weightKg) {
      final disp =
          _unitService.convertDisplayValue(weightKg, UnitDimension.weight);
      _weightController.text = disp.toStringAsFixed(1);
    };
    _goalFlowState.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isImportedMode) {
        _pageController.jumpToPage(_unitSystemPageIndex);
      } else {
        TelemetryService.instance.trackOnboardingStep(
          stepIndex: 0,
          stepName: _stepNames[0],
          screenName: _stepNames[0],
          durationSeconds: 0,
          sessionId: _onboardingSessionId,
        );
      }
    });

    // Silently check if an iCloud backup is available for restore on iOS.
    if (Platform.isIOS || Platform.isMacOS) {
      ICloudSyncService.instance.hasICloudBackup().then((found) {
        if (mounted) setState(() => _hasICloudBackup = found);
      });
    }

    _heightController.addListener(() {
      if (_heightError != null || _heightWarning != null) {
        setState(() {
          _heightError = null;
          _heightWarning = null;
        });
      }
    });
    _weightController.addListener(() {
      if (_weightError != null || _weightWarning != null) {
        setState(() {
          _weightError = null;
          _weightWarning = null;
        });
      }
    });
  }

  Future<void> _initSelectedCountry() async {
    final active = await OffCatalogCountryService.readActiveCountry();
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(OffCatalogCountryService.preferenceKey)) {
      final detected = _detectDeviceCountry();
      setState(() {
        _selectedOffCountry = detected;
      });
    } else {
      setState(() {
        _selectedOffCountry = active;
      });
    }
  }

  OffCatalogCountry _detectDeviceCountry() {
    try {
      final locale = Platform.localeName.toLowerCase();
      final parts = locale.split(RegExp('[_-]'));
      if (parts.length > 1) {
        final countryPart = parts[1];
        final code = countryPart == 'gb' ? 'uk' : countryPart;
        for (final c in AppDataSources.supportedOffCatalogCountries) {
          if (c.code == code) {
            return c;
          }
        }
      }
      final langPart = parts.first;
      for (final c in AppDataSources.supportedOffCatalogCountries) {
        if (c.code == langPart) {
          return c;
        }
      }
    } catch (_) {}
    return AppDataSources.defaultOffCatalogCountry;
  }

  @override
  void dispose() {
    if (!_onboardingCompletedSuccessfully) {
      TelemetryService.instance.trackOnboardingAbandoned(
        lastStepIndex: _currentPage,
        lastStepName: _stepNames[_currentPage.clamp(0, _stepNames.length - 1)],
        sessionId: _onboardingSessionId,
      );
    }
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _bodyFatPercentController.dispose();
    _weightController.dispose();
    _calController.dispose();
    _protController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    _goalFlowState.disposeControllers();
    super.dispose();
  }

  // --- LOGIC ---

  UnitService get _unitService => context.read<UnitService>();

  // lib/screens/onboarding_screen.dart

  BodyweightGoal _resolveEffectiveGoal() {
    if (_skippedGoal) {
      return BodyweightGoal.maintainWeight;
    }
    switch (_goalFlowState.preset) {
      case GoalPreset.loseWeight:
        return BodyweightGoal.loseWeight;
      case GoalPreset.gainWeight:
        return BodyweightGoal.gainWeight;
      case GoalPreset.maintainWeight:
      case GoalPreset.recomposition:
        return BodyweightGoal.maintainWeight;
      case GoalPreset.custom:
        switch (_goalFlowState.customDirection) {
          case 'lose':
            return BodyweightGoal.loseWeight;
          case 'gain':
            return BodyweightGoal.gainWeight;
          default:
            return BodyweightGoal.maintainWeight;
        }
    }
  }

  double _resolveEffectiveTargetRate() {
    if (_skippedGoal) return 0.0;
    if (_goalFlowState.preset == GoalPreset.maintainWeight ||
        _goalFlowState.preset == GoalPreset.recomposition) {
      return 0.0;
    }
    if (_goalFlowState.preset == GoalPreset.custom &&
        _goalFlowState.customDirection == 'maintain') {
      return 0.0;
    }
    return _goalFlowState.weeklyRateKg;
  }

  Future<void> _loadAdaptiveGoalSettings() async {
    final goal = await _recommendationService.getGoal();
    final rate = await _recommendationService.getTargetRateKgPerWeek();
    final priorActivityLevel =
        await _recommendationService.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _recommendationService.getExtraCardioHoursOption();
    if (!mounted) return;
    setState(() {
      _selectedPriorActivityLevel = priorActivityLevel;
      _selectedExtraCardioHoursOption = extraCardioHoursOption;
      switch (goal) {
        case BodyweightGoal.loseWeight:
          _goalFlowState.preset = GoalPreset.loseWeight;
          _goalFlowState.weeklyRateKg = rate > 0 ? rate : 0.5;
          break;
        case BodyweightGoal.gainWeight:
          _goalFlowState.preset = GoalPreset.gainWeight;
          _goalFlowState.weeklyRateKg = rate > 0 ? rate : 0.25;
          break;
        case BodyweightGoal.maintainWeight:
          _goalFlowState.preset = GoalPreset.maintainWeight;
          _goalFlowState.weeklyRateKg = 0.0;
          break;
      }
    });
  }

  Future<void> _refreshOnboardingRecommendationPreview() async {
    if (_isGeneratingOnboardingRecommendation &&
        _onboardingRecommendationFuture != null) {
      return _onboardingRecommendationFuture!;
    }

    _onboardingRecommendationFuture = _performRefreshOnboardingRecommendation();
    return _onboardingRecommendationFuture!;
  }

  Future<void> _performRefreshOnboardingRecommendation() async {
    setState(() => _isGeneratingOnboardingRecommendation = true);

    final unitService = _unitService;
    final weightInput = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final heightInput = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final weight = weightInput == null
        ? null
        : unitService.convertToMetric(weightInput, UnitDimension.weight);
    final height = heightInput == null
        ? null
        : unitService
            .convertToMetric(heightInput, UnitDimension.height)
            .round();
    final bodyFatPercent =
        double.tryParse(_bodyFatPercentController.text.replaceAll(',', '.'));

    final effectiveGoal = _resolveEffectiveGoal();
    final effectiveTargetRate = _resolveEffectiveTargetRate();

    try {
      final preview =
          await _recommendationService.generateOnboardingRecommendationPreview(
        goal: effectiveGoal,
        targetRateKgPerWeek: effectiveTargetRate,
        weightKg: weight,
        heightCm: height,
        birthday: _selectedDate,
        gender: _selectedGender,
        bodyFatPercent: bodyFatPercent,
        declaredActivityLevel: _selectedPriorActivityLevel,
        extraCardioHoursOption: _selectedExtraCardioHoursOption,
        persistGenerated: false,
        markAsApplied: false,
      );

      if (!mounted) return;
      setState(() {
        _onboardingRecommendation = preview.recommendation;
      });
      _applyOnboardingRecommendationToGoals();
    } catch (e) {
      debugPrint('Error refreshing onboarding recommendation: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingOnboardingRecommendation = false);
      }
    }
  }

  void _applyOnboardingRecommendationToGoals() {
    final recommendation = _onboardingRecommendation;
    if (recommendation == null) return;

    final unitService = _unitService;
    final weightInput = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final weightKg = weightInput == null
        ? null
        : unitService.convertToMetric(weightInput, UnitDimension.weight);

    setState(() {
      _calController.text = recommendation.recommendedCalories.toString();
      _protController.text = recommendation.recommendedProteinGrams.toString();
      _carbController.text = recommendation.recommendedCarbsGrams.toString();
      _fatController.text = recommendation.recommendedFatGrams.toString();

      if (weightKg != null) {
        final waterMl = (weightKg / 20.0) * 1000.0;
        final displayWater = unitService.convertDisplayValue(
          waterMl,
          UnitDimension.liquid,
        );
        _waterController.text = displayWater.round().toString();
      }
    });
  }

  bool _activeGoalInputsMatchRecommendation(
      NutritionRecommendation recommendation) {
    return (int.tryParse(_calController.text) ?? -1) ==
            recommendation.recommendedCalories &&
        (int.tryParse(_protController.text) ?? -1) ==
            recommendation.recommendedProteinGrams &&
        (int.tryParse(_carbController.text) ?? -1) ==
            recommendation.recommendedCarbsGrams &&
        (int.tryParse(_fatController.text) ?? -1) ==
            recommendation.recommendedFatGrams;
  }

  Future<void> _finishOnboarding() async {
    final db = _databaseHelper;
    final prefs = await SharedPreferences.getInstance();
    final unitService = _unitService;

    // Explicitly persist selected unit system to SharedPreferences and Database
    await unitService.setUnitSystem(unitService.unitSystem);

    final int calories = int.tryParse(_calController.text) ?? 2500;
    final int protein = int.tryParse(_protController.text) ?? 180;
    final int carbs = int.tryParse(_carbController.text) ?? 250;
    final int fat = int.tryParse(_fatController.text) ?? 80;
    final double? waterInput = double.tryParse(
      _waterController.text.replaceAll(',', '.'),
    );
    final double? heightInput = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final double? weightInput = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final double? bodyFatPercent = double.tryParse(
      _bodyFatPercentController.text.replaceAll(',', '.'),
    );
    final int? height = heightInput == null
        ? null
        : unitService
            .convertToMetric(heightInput, UnitDimension.height)
            .round();
    final double? weight = weightInput == null
        ? null
        : unitService.convertToMetric(weightInput, UnitDimension.weight);

    final int water = waterInput == null
        ? (weight != null ? ((weight / 20.0) * 1000.0).round() : 3000)
        : unitService.convertToMetric(waterInput, UnitDimension.liquid).round();

    final effectiveGoal = _resolveEffectiveGoal();
    final effectiveTargetRate = _resolveEffectiveTargetRate();

    final onboardingRecommendation = _onboardingRecommendation ??
        await _recommendationService.generateOnboardingRecommendation(
          goal: effectiveGoal,
          targetRateKgPerWeek: effectiveTargetRate,
          weightKg: weight,
          heightCm: height,
          birthday: _selectedDate,
          gender: _selectedGender,
          bodyFatPercent: bodyFatPercent,
          declaredActivityLevel: _selectedPriorActivityLevel,
          extraCardioHoursOption: _selectedExtraCardioHoursOption,
          persistGenerated: false,
          markAsApplied: false,
        );

    // 1. Save profile (DB)
    await db.saveUserProfile(
      name: _nameController.text.trim(),
      birthday: _selectedDate,
      height: height,
      gender: _selectedGender,
    );

    if (_selectedGender != null && mounted) {
      try {
        await context.read<ProfileService>().updateGender(
              UserGender.fromString(_selectedGender),
              context.read<IProfileRepository>(),
            );
      } catch (_) {
        // Safe fallback in widget tests where ProfileService is omitted
      }
    }

    // Also cache height briefly in prefs for GoalsScreen fallback (optional).
    if (height != null) await prefs.setInt('userHeight', height);

    // 2. Startgewicht (DB)
    if (weight != null) {
      await db.saveInitialWeight(weight);
    }
    if (bodyFatPercent != null && bodyFatPercent > 0 && bodyFatPercent <= 100) {
      await db.saveInitialBodyFatPercentage(bodyFatPercent);
    }

    await _recommendationService.saveGoalAndTargetRate(
      goal: effectiveGoal,
      targetRateKgPerWeek: effectiveTargetRate,
    );

    // Exactly one active goal: create canonical goal in userGoals first,
    // so LegacyGoalMigration won't double-create.
    final activeGoal = await _goalRepository.getActiveNutritionGoal();
    if (activeGoal == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (_skippedGoal) {
        await _goalRepository.createGoal(
          preset: GoalPreset.maintainWeight,
          title: l10n.goalPresetMaintainWeight,
          startDate: DateTime.now(),
          trackingMode: GoalTrackingMode.open,
          baselineValueKg: weight,
          desiredWeeklyRateKg: 0.0,
          isNutritionDriver: true,
        );
      } else {
        await _goalFlowState.submitGoal(
          context: context,
          repository: _goalRepository,
          unitService: unitService,
          l10n: l10n,
          checkConfirmation: false,
        );
      }
    }

    await LegacyGoalMigration(
      database: _databaseHelper.dbInstance,
      goalRepository: _goalRepository is GoalRepositoryImpl
          ? _goalRepository as GoalRepositoryImpl
          : null,
    ).run();

    await _recommendationService.savePriorActivityLevel(
      _selectedPriorActivityLevel,
    );
    await _recommendationService.saveExtraCardioHoursOption(
      _selectedExtraCardioHoursOption,
    );

    await _recommendationService.persistGeneratedRecommendation(
      recommendation: onboardingRecommendation,
      markAsApplied: _activeGoalInputsMatchRecommendation(
        onboardingRecommendation,
      ),
    );

    // 3. Save goals (DB - this is now the source for everything).
    await db.saveUserGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      water: water,
      steps: 8000,
    );

    // 4. Store default extra values (sugar/fiber/salt) in prefs because they are not in the DB schema yet.
    if (prefs.getInt('targetSugar') == null) {
      await prefs.setInt('targetSugar', 50);
    }
    if (prefs.getInt('targetFiber') == null) {
      await prefs.setInt('targetFiber', 30);
    }
    if (prefs.getInt('targetSalt') == null) await prefs.setInt('targetSalt', 6);

    // 5. Fertig markieren
    await prefs.setBool('hasSeenOnboarding', true);
    await AppTourService.instance.queuePostOnboardingOffer();

    _onboardingCompletedSuccessfully = true;
    unawaited(TelemetryService.instance.trackOnboardingCompleted(
      totalDurationSeconds: _totalStopwatch.elapsed.inSeconds,
      restoredFromBackup: _isImportedMode,
      sessionId: _onboardingSessionId,
    ));

    if (!mounted) return;

    if (_requiresHardRestart) {
      restartApp();
      return;
    }

    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  /// Downloads the iCloud backup and replaces the local database, then
  /// navigates directly to [MainScreen] (skipping the rest of onboarding).
  Future<void> _restoreFromICloud() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isRestoring = true);

    bool success = false;
    try {
      success = await LongRunningOperationOverlay.run(
        context: context,
        title: l10n.onboardingRestoreFromICloud,
        initialStatus: 'Downloading backup...',
        icon: LucideIcons.cloud_download,
        operation: (token, updateProgress) async {
          final res = await ICloudSyncService.instance.downloadAndRestore(
            onProgress: (progress) {
              final normProgress = progress > 1.0 ? progress / 100.0 : progress;
              final percent = (normProgress * 100).toStringAsFixed(0);
              updateProgress('Downloading... $percent%', normProgress);
            },
          );
          if (!res) throw Exception('Restore failed');
        },
      );
    } catch (e) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingRestoreICloudSuccess)),
      );

      // The restore copies the backup into the live database rather than
      // swapping the file underneath it, so the connection every provider
      // holds is still the right one and the rest of onboarding — region,
      // catalog download, permissions — carries on against restored data.
      await context.read<UnitService>().reload();
      await _loadAdaptiveGoalSettings();

      if (!mounted) return;
      setState(() {
        _isImportedMode = true;
        _requiresHardRestart = true;
      });

      _pageController.animateToPage(
        _unitSystemPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.onboardingRestoreICloudFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Picks a JSON backup file and imports it, skipping onboarding.
  Future<void> _restoreFromBackup() async {
    final l10n = AppLocalizations.of(context)!;

    final wgerInitialized =
        await BasisDataManager.instance.isExerciseCatalogInitialized();

    if (!wgerInitialized) {
      if (!mounted) return;
      await BasisDataManager.instance
          .promptOffDatabaseDownloadIfFirstTime(context);
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      // `json` stays allowed: backups written before the archive format are
      // still valid and still restore.
      allowedExtensions: ['zip', 'json'],
    );
    if (result.isEmpty || result.single.path == null) return;

    setState(() => _isRestoring = true);
    final filePath = result.single.path!;

    bool success = false;
    try {
      if (!mounted) return;
      success = await LongRunningOperationOverlay.run(
        context: context,
        title: l10n.backupImportTitle,
        initialStatus: l10n.backupImportTitle,
        icon: LucideIcons.download,
        operation: (token, updateProgress) async {
          final res = await BackupManager.instance.importFullBackupAuto(
            filePath,
            token: token,
            onProgress: (tableName, progress) {
              final statusText = l10n.progressImportingTable(tableName);
              updateProgress(statusText, progress);
            },
          );
          if (!res) throw Exception('Import failed');
        },
      );
    } catch (e) {
      success = false;
    }

    // If plain import failed, the file might be encrypted — ask for password.
    if (!success && mounted) {
      final pw = await _askRestorePassword(l10n);
      if (pw != null) {
        try {
          if (!mounted) return;
          success = await LongRunningOperationOverlay.run(
            context: context,
            title: l10n.backupImportTitle,
            initialStatus: 'Decrypting...',
            icon: LucideIcons.download,
            operation: (token, updateProgress) async {
              final res = await BackupManager.instance.importFullBackupAuto(
                filePath,
                passphrase: pw,
                token: token,
                onProgress: (tableName, progress) {
                  final statusText = l10n.progressImportingTable(tableName);
                  updateProgress(statusText, progress);
                },
              );
              if (!res) throw Exception('Import failed');
            },
          );
        } catch (e) {
          success = false;
        }
      }
    }

    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (success) {
      if (!mounted) return;
      await context.read<UnitService>().reload();
      await _loadAdaptiveGoalSettings();
      if (!mounted) return;
      setState(() {
        _isImportedMode = true;
        _requiresHardRestart = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.onboardingRestoreSuccess)));
      _pageController.animateToPage(
        _unitSystemPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.onboardingRestoreFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _askRestorePassword(AppLocalizations l10n) async {
    final controller = TextEditingController();
    return showGlassBottomMenu<String?>(
      context: context,
      title: l10n.dialogEnterPasswordImport,
      contentBuilder: (ctx, close) => Column(
        key: const Key('onboarding_restore_password_sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  label: l10n.cancel,
                  tooltip: l10n.cancel,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: AppButton.primary(
                  onPressed: () =>
                      Navigator.of(ctx).pop(controller.text.trim()),
                  label: l10n.onboardingNext,
                  tooltip: l10n.onboardingNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _nextPage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPage == _regionSelectionPageIndex) {
      await OffCatalogCountryService.writeActiveCountry(_selectedOffCountry);
      if (mounted) {
        final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
        if (!isTesting) {
          setState(() => _isCheckingDatabase = true);
          try {
            await BasisDataManager.instance
                .promptOffDatabaseDownloadIfFirstTime(context);
          } finally {
            if (mounted) {
              setState(() => _isCheckingDatabase = false);
            }
          }
        }
      }
      if (_isImportedMode) {
        _pageController.animateToPage(
          _lastPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
    }

    if (!_isImportedMode) {
      if (_currentPage == _namePageIndex) {
        if (_nameController.text.trim().isEmpty) return;
      }

      if (_currentPage == _bioDataPageIndex) {
        bool hasProfileErrors = false;
        _dobError = null;
        _genderError = null;

        if (_selectedDate == null) {
          _dobError = l10n.onboardingFieldCannotBeEmpty;
          hasProfileErrors = true;
        }
        if (_selectedGender == null) {
          _genderError = l10n.onboardingFieldCannotBeEmpty;
          hasProfileErrors = true;
        }
        if (hasProfileErrors) {
          setState(() {});
          return;
        }
      }

      if (_currentPage == _heightPageIndex) {
        _heightError = null;
        if (_heightController.text.trim().isEmpty) {
          setState(() {
            _heightError = l10n.onboardingFieldCannotBeEmpty;
            _heightWarning = null;
            _lastWarnedHeightValue = null;
          });
          return;
        }
        final heightInput =
            double.tryParse(_heightController.text.replaceAll(',', '.'));
        if (heightInput != null) {
          final heightCm =
              _unitService.convertToMetric(heightInput, UnitDimension.height);
          if (heightCm < 100 || heightCm > 250) {
            if (_lastWarnedHeightValue != _heightController.text) {
              setState(() {
                _heightWarning = l10n.onboardingPhysiologicalRangeWarning;
                _lastWarnedHeightValue = _heightController.text;
              });
              return;
            }
          } else {
            _heightWarning = null;
            _lastWarnedHeightValue = null;
          }
        } else {
          _heightWarning = null;
          _lastWarnedHeightValue = null;
        }
      }

      if (_currentPage == _measurementsPageIndex) {
        final weightText = _weightController.text.trim();
        if (weightText.isEmpty) {
          setState(() {
            _weightError = l10n.onboardingFieldCannotBeEmpty;
            _weightWarning = null;
            _lastWarnedWeightValue = null;
          });
          return;
        } else {
          _weightError = null;
        }

        final weightInput = double.tryParse(weightText.replaceAll(',', '.'));
        if (weightInput != null) {
          final weightKg =
              _unitService.convertToMetric(weightInput, UnitDimension.weight);
          if (weightKg < 35 || weightKg > 250) {
            if (_lastWarnedWeightValue != _weightController.text) {
              setState(() {
                _weightWarning = l10n.onboardingPhysiologicalRangeWarning;
                _lastWarnedWeightValue = _weightController.text;
              });
              return;
            }
          } else {
            _weightWarning = null;
            _lastWarnedWeightValue = null;
          }

          _goalFlowState.initBaselineFromKnownWeight(
            weightKg: weightKg,
            unitService: _unitService,
          );
        } else {
          _weightWarning = null;
          _lastWarnedWeightValue = null;
        }
      }

      if (_currentPage == _activityPageIndex) {
        // Activity inputs are pre-selected with valid defaults.
      }

      if (_currentPage == _goalDecisionPageIndex) {
        _skippedGoal = false;
        _goalFlowState.prepareTargetDefaults(_unitService);
      }

      if (_currentPage == _goalPresetPageIndex) {
        _goalFlowState.prepareTargetDefaults(_unitService);
      }

      if (_currentPage == _goalTargetPageIndex) {
        final error = _goalFlowState.validateTargetStep(_unitService, l10n);
        if (error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }

      if (_currentPage == _goalPaceTimelinePageIndex) {
        // Pace and timeline step validated.
      }

      if (_currentPage == _goalMotivationPageIndex) {
        _refreshOnboardingRecommendationPreview();
      }
    }

    if (_currentPage < _lastPageIndex) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_isImportedMode) {
        await _runAutomatedPermissionSequence();
      } else {
        await _finishOnboarding();
      }
    }
  }

  void _setupGoalNow() {
    setState(() {
      _skippedGoal = false;
    });
    _goalFlowState.prepareTargetDefaults(_unitService);
    _pageController.animateToPage(
      _goalPresetPageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipGoalSetup() {
    setState(() {
      _skippedGoal = true;
      _goalFlowState.preset = GoalPreset.maintainWeight;
      _goalFlowState.weeklyRateKg = 0.0;
    });
    _refreshOnboardingRecommendationPreview();
    _pageController.animateToPage(
      _nutritionPageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_isImportedMode && _currentPage == _lastPageIndex) {
      _pageController.animateToPage(
        _regionSelectionPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (_currentPage == _nutritionPageIndex && _skippedGoal) {
      _pageController.animateToPage(
        _goalDecisionPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _runAutomatedPermissionSequence() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    // 1. Apple Health / Health Connect Export
    final appleExportEnabled =
        prefs.getBool('health_export_apple_enabled') ?? false;
    final googleExportEnabled =
        prefs.getBool('health_export_health_connect_enabled') ?? false;
    if (appleExportEnabled || googleExportEnabled) {
      final title = Platform.isIOS
          ? l10n.healthExportAppleHealthTitle
          : l10n.healthExportHealthConnectTitle;
      final body = Platform.isIOS
          ? l10n.healthExportAppleHealthSubtitle
          : l10n.healthExportHealthConnectSubtitle;
      final confirmed = await showPrePermissionDialog(
        context: context,
        title: title,
        body: body,
        continueLabel: l10n.health_permission_continue,
        cancelLabel: l10n.health_permission_not_now,
      );
      if (confirmed && mounted) {
        final service = HealthExportService(adapters: [
          AppleHealthExportAdapter(),
          HealthConnectExportAdapter()
        ]);
        await service.requestPermissions(Platform.isIOS
            ? HealthExportPlatform.appleHealth
            : HealthExportPlatform.healthConnect);
      }
    }

    if (!mounted) return;

    // 2. Steps Tracking
    final stepsEnabled = prefs.getBool('steps_tracking_enabled') ?? false;
    if (stepsEnabled) {
      final confirmed = await showPrePermissionDialog(
        context: context,
        title: l10n.health_permission_dialog_title,
        body: l10n.health_permission_dialog_body,
        continueLabel: l10n.health_permission_continue,
        cancelLabel: l10n.health_permission_not_now,
      );
      if (confirmed && mounted) {
        const platform = HealthPlatformSteps();
        await platform.requestPermissions();
      }
    }

    if (!mounted) return;

    // 3. Pulse Tracking
    final pulseEnabled = prefs.getBool('pulse_tracking_enabled') ?? false;
    if (pulseEnabled) {
      final confirmed = await showPrePermissionDialog(
        context: context,
        title: l10n.pulseSettingsPermissionTitle,
        body: l10n.pulseSettingsPermissionSubtitle,
        continueLabel: l10n.health_permission_continue,
        cancelLabel: l10n.health_permission_not_now,
      );
      if (confirmed && mounted) {
        final service = PulseTrackingService();
        await service.requestPermissions();
      }
    }

    if (!mounted) return;

    // 4. Sleep Tracking
    final sleepEnabled = prefs.getBool('sleep_tracking_enabled') ?? false;
    if (sleepEnabled) {
      final controller = SleepPermissionController(Platform.isIOS
          ? const HealthKitSleepPermissionsService(
              HealthKitSleepMethodChannelBridge())
          : const HealthConnectSleepPermissionsService(
              HealthConnectSleepMethodChannelBridge()));
      await controller.requestAccess(context);
    }

    if (!mounted) return;

    await prefs.setBool('hasSeenOnboarding', true);
    await AppTourService.instance.queuePostOnboardingOffer();

    _onboardingCompletedSuccessfully = true;
    unawaited(TelemetryService.instance.trackOnboardingCompleted(
      totalDurationSeconds: _totalStopwatch.elapsed.inSeconds,
      restoredFromBackup: _isImportedMode,
      sessionId: _onboardingSessionId,
    ));

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  double get _progressValue {
    if (_skippedGoal) {
      final effectiveIndex = _currentPage <= _goalDecisionPageIndex
          ? _currentPage
          : (_currentPage == _nutritionPageIndex ? 7 : 8);
      return (effectiveIndex + 1) / 9.0;
    }
    return (_currentPage + 1) / _totalPageCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _prevPage();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 4,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    final durationSec = _stepStopwatch.elapsed.inSeconds;
                    _stepStopwatch.reset();
                    _stepStopwatch.start();

                    TelemetryService.instance.trackOnboardingStep(
                      stepIndex: i,
                      stepName: _stepNames[i.clamp(0, _stepNames.length - 1)],
                      screenName: _stepNames[i.clamp(0, _stepNames.length - 1)],
                      durationSeconds: durationSec,
                      sessionId: _onboardingSessionId,
                    );

                    setState(() => _currentPage = i);
                    if (i == _nutritionPageIndex) {
                      _refreshOnboardingRecommendationPreview();
                    }
                  },
                  children: [
                    WelcomeSlide(
                      isRestoring: _isRestoring,
                      onContinue: _nextPage,
                      onRestore: _restoreFromBackup,
                      onRestoreICloud: _restoreFromICloud,
                      hasICloudBackup: _hasICloudBackup,
                    ),
                    UnitSystemSlide(
                      selectedSystem: _unitService.unitSystem,
                      onSelectSystem: (system) async {
                        await context.read<UnitService>().setUnitSystem(system);
                        setState(() {});
                      },
                    ),
                    RegionSelectionSlide(
                      selectedCountry: _selectedOffCountry,
                      onSelectCountry: (country) {
                        setState(() {
                          _selectedOffCountry = country;
                        });
                      },
                    ),
                    NameSlide(
                      nameController: _nameController,
                    ),
                    BioDataSlide(
                      selectedDate: _selectedDate,
                      selectedGender: _selectedGender,
                      dobError: _dobError,
                      genderError: _genderError,
                      onSelectDate: (picked) {
                        setState(() {
                          _selectedDate = picked;
                          _dobError = null;
                        });
                        if (_currentPage >= _nutritionPageIndex) {
                          _refreshOnboardingRecommendationPreview();
                        }
                      },
                      onSelectGender: (val) {
                        setState(() {
                          _selectedGender = val;
                          _genderError = null;
                        });
                      },
                    ),
                    HeightSlide(
                      heightController: _heightController,
                      heightError: _heightError,
                      heightWarning: _heightWarning,
                    ),
                    _OnboardingMeasurementsStep(
                      weightController: _weightController,
                      bodyFatPercentController: _bodyFatPercentController,
                      onBodyFatChanged: (_) {
                        if (_currentPage >= _nutritionPageIndex) {
                          _refreshOnboardingRecommendationPreview();
                        }
                      },
                      onOpenBodyFatHelp: _openBodyFatHelperEntryPoint,
                      weightError: _weightError,
                      weightWarning: _weightWarning,
                    ),
                    _OnboardingActivityStep(
                      selectedPriorActivityLevel: _selectedPriorActivityLevel,
                      selectedExtraCardioHoursOption:
                          _selectedExtraCardioHoursOption,
                      onPriorActivityLevelChanged: (level) {
                        setState(() {
                          _selectedPriorActivityLevel = level;
                        });
                        if (_currentPage >= _nutritionPageIndex) {
                          _refreshOnboardingRecommendationPreview();
                        }
                      },
                      onExtraCardioHoursOptionChanged: (option) {
                        setState(() {
                          _selectedExtraCardioHoursOption = option;
                        });
                        if (_currentPage >= _nutritionPageIndex) {
                          _refreshOnboardingRecommendationPreview();
                        }
                      },
                    ),
                    _OnboardingGoalDecisionStep(
                      onSetupNow: _setupGoalNow,
                      onSetupLater: _skipGoalSetup,
                    ),
                    GoalPresetStep(
                      state: _goalFlowState,
                      padding: const EdgeInsets.fromLTRB(
                        DesignConstants.spacingXL,
                        DesignConstants.spacingXL + DesignConstants.spacingM,
                        DesignConstants.spacingXL,
                        DesignConstants.spacingXL,
                      ),
                    ),
                    GoalTargetStep(
                      state: _goalFlowState,
                      horizontalPadding: DesignConstants.spacingXL,
                      topPadding:
                          DesignConstants.spacingXL + DesignConstants.spacingM,
                      bottomPadding: DesignConstants.spacingXL,
                    ),
                    GoalPaceTimelineStep(
                      state: _goalFlowState,
                      horizontalPadding: DesignConstants.spacingXL,
                      topPadding:
                          DesignConstants.spacingXL + DesignConstants.spacingM,
                      bottomPadding: DesignConstants.spacingXL,
                    ),
                    GoalMotivationStep(
                      state: _goalFlowState,
                      padding: const EdgeInsets.fromLTRB(
                        DesignConstants.spacingXL,
                        DesignConstants.spacingXL + DesignConstants.spacingM,
                        DesignConstants.spacingXL,
                        DesignConstants.spacingXL,
                      ),
                    ),
                    _OnboardingNutritionStep(
                      calController: _calController,
                      protController: _protController,
                      carbController: _carbController,
                      fatController: _fatController,
                      waterController: _waterController,
                    ),
                    _OnboardingAiHealthStep(
                      onOpenAiSettings: _openAiSettings,
                      onOpenStepsSettings: _openStepsSettings,
                      onOpenSleepSettings: _openSleepSettings,
                      onOpenPulseSettings: _openPulseSettings,
                    ),
                  ],
                ),
              ),
              // Hide bottom nav on the welcome page (page 0) — it has its own buttons.
              if (_currentPage > 0)
                Padding(
                  padding: const EdgeInsets.all(DesignConstants.spacingXL),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: MaterialLocalizations.of(context)
                            .previousPageTooltip,
                        onPressed: _isCheckingDatabase ? null : _prevPage,
                        icon: const Icon(LucideIcons.arrow_left),
                      ),
                      const Spacer(),
                      AppButton.primary(
                        key: const Key('onboarding_bottom_next_button'),
                        onPressed: _isGeneratingOnboardingRecommendation ||
                                _isCheckingDatabase
                            ? null
                            : _nextPage,
                        label: _currentPage == _lastPageIndex
                            ? l10n.onboardingFinish.toUpperCase()
                            : l10n.onboardingNext.toUpperCase(),
                        tooltip: _currentPage == _lastPageIndex
                            ? l10n.onboardingFinish.toUpperCase()
                            : l10n.onboardingNext.toUpperCase(),
                        isLoading: (_isGeneratingOnboardingRecommendation &&
                                _currentPage == _nutritionPageIndex) ||
                            _isCheckingDatabase,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBodyFatHelperEntryPoint() async {
    await showBodyFatGuidanceSheet(context);
  }

  Future<void> _openAiSettings() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
    );
  }

  Future<void> _openStepsSettings() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const StepsSettingsScreen()),
    );
  }

  Future<void> _openSleepSettings() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SleepSettingsScreen()),
    );
  }

  Future<void> _openPulseSettings() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const PulseSettingsScreen()),
    );
  }
}

class _OnboardingMeasurementsStep extends StatefulWidget {
  const _OnboardingMeasurementsStep({
    required this.weightController,
    required this.bodyFatPercentController,
    required this.onBodyFatChanged,
    required this.onOpenBodyFatHelp,
    this.weightError,
    this.weightWarning,
  });

  final TextEditingController weightController;
  final TextEditingController bodyFatPercentController;
  final ValueChanged<String> onBodyFatChanged;
  final VoidCallback onOpenBodyFatHelp;
  final String? weightError;
  final String? weightWarning;

  @override
  State<_OnboardingMeasurementsStep> createState() =>
      _OnboardingMeasurementsStepState();
}

class _OnboardingMeasurementsStepState
    extends State<_OnboardingMeasurementsStep> {
  bool _bodyFatExpanded = false;

  double _valueFor(TextEditingController controller, double fallback) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final weightSuffix = unitService.suffixFor(UnitDimension.weight);
    final weightValue = _valueFor(widget.weightController, 75.0);
    final bodyFatValue = _valueFor(widget.bodyFatPercentController, 20.0);

    return SingleChildScrollView(
      key: const Key('onboarding_measurements_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingMeasurementsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingMeasurementsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          _OnboardingMeasurementRuler(
            value: weightValue,
            controller: widget.weightController,
            title: l10n.onboardingWeightTitle,
            unit: weightSuffix,
            editorKey: const Key('onboarding_weight_edit_button'),
            manualInputKey: const Key('onboarding_weight_text_field'),
            rulerKey: const Key('onboarding_weight_ruler'),
            errorText: widget.weightError,
            builder: (value, onChanged) => AppRulerPicker.weight(
              key: const Key('onboarding_weight_ruler'),
              value: value,
              imperial: unitService.isImperial,
              label: '${l10n.onboardingWeightTitle} ($weightSuffix)',
              onChanged: onChanged,
            ),
          ),
          if (widget.weightWarning != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.weightWarning!,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: DesignConstants.spacingM),
          ExpansionTileTheme(
            data: ExpansionTileThemeData(
              textColor: theme.colorScheme.onSurface,
              collapsedTextColor: theme.colorScheme.onSurface,
              iconColor: theme.colorScheme.onSurfaceVariant,
              collapsedIconColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: ExpansionTile(
              key: const Key('onboarding_body_fat_expansion'),
              initiallyExpanded: _bodyFatExpanded,
              onExpansionChanged: (expanded) =>
                  setState(() => _bodyFatExpanded = expanded),
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.onboardingBodyFatOptionalLabel),
              subtitle: Text(l10n.onboardingBodyFatOptionalHelper),
              children: [
                _OnboardingMeasurementRuler(
                  value: bodyFatValue.clamp(3.0, 60.0),
                  controller: widget.bodyFatPercentController,
                  title: l10n.onboardingBodyFatOptionalLabel,
                  unit: '%',
                  editorKey: const Key('onboarding_body_fat_edit_button'),
                  manualInputKey: const Key('onboarding_body_fat_text_field'),
                  rulerKey: const Key('onboarding_body_fat_ruler'),
                  onValueChanged: widget.onBodyFatChanged,
                  builder: (value, onChanged) => AppRulerPicker(
                    key: const Key('onboarding_body_fat_ruler'),
                    value: value,
                    minValue: 3,
                    maxValue: 60,
                    step: 0.1,
                    // Mirror the metric weight ruler exactly: 0.1-unit ticks
                    // every 7px, a medium tick at 0.5 and a labelled major
                    // tick at each whole unit.
                    pixelsPerUnit: 70,
                    majorInterval: 1,
                    minorInterval: 0.5,
                    fractionDigits: 1,
                    label: l10n.onboardingBodyFatOptionalLabel,
                    unit: '%',
                    onChanged: onChanged,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('onboarding_body_fat_help_button'),
                    onPressed: widget.onOpenBodyFatHelp,
                    child: Text(l10n.onboardingBodyFatHelpAction),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _OnboardingInfoBox(text: l10n.onboardingMeasurementsDisclaimer),
        ],
      ),
    );
  }
}

class _OnboardingMeasurementRuler extends StatefulWidget {
  const _OnboardingMeasurementRuler({
    required this.value,
    required this.controller,
    required this.title,
    required this.unit,
    required this.editorKey,
    required this.manualInputKey,
    required this.rulerKey,
    required this.builder,
    this.errorText,
    this.onValueChanged,
  });

  final double value;
  final TextEditingController controller;
  final String title;
  final String unit;
  final Key editorKey;
  final Key manualInputKey;
  final Key rulerKey;
  final String? errorText;
  final ValueChanged<String>? onValueChanged;
  final Widget Function(double value, ValueChanged<double> onChanged) builder;

  @override
  State<_OnboardingMeasurementRuler> createState() =>
      _OnboardingMeasurementRulerState();
}

class _OnboardingMeasurementRulerState
    extends State<_OnboardingMeasurementRuler> {
  bool _editing = false;

  void _setValue(double value) {
    widget.controller.text = value.toStringAsFixed(1);
    widget.onValueChanged?.call(widget.controller.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value =
        double.tryParse(widget.controller.text.replaceAll(',', '.')) ??
            widget.value;
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_editing)
              SizedBox(
                width: 180,
                child: TextField(
                  key: widget.manualInputKey,
                  controller: widget.controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: widget.unit,
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    if (parsed != null) widget.onValueChanged?.call(text);
                    setState(() {});
                  },
                  onSubmitted: (_) => setState(() => _editing = false),
                ),
              )
            else
              Text('${value.toStringAsFixed(1)} ${widget.unit}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            IconButton(
              key: widget.editorKey,
              tooltip: widget.title,
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? LucideIcons.check : LucideIcons.pencil),
            ),
          ],
        ),
        widget.builder(value, _setValue),
        if (widget.errorText != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                )),
          ),
      ],
    );
  }
}

class _OnboardingActivityStep extends StatelessWidget {
  const _OnboardingActivityStep({
    required this.selectedPriorActivityLevel,
    required this.selectedExtraCardioHoursOption,
    required this.onPriorActivityLevelChanged,
    required this.onExtraCardioHoursOptionChanged,
  });

  final PriorActivityLevel selectedPriorActivityLevel;
  final ExtraCardioHoursOption selectedExtraCardioHoursOption;
  final ValueChanged<PriorActivityLevel> onPriorActivityLevelChanged;
  final ValueChanged<ExtraCardioHoursOption> onExtraCardioHoursOptionChanged;

  static String _priorActivityLabel(
      AppLocalizations l10n, PriorActivityLevel level) {
    switch (level) {
      case PriorActivityLevel.low:
        return l10n.adaptivePriorActivityLow;
      case PriorActivityLevel.moderate:
        return l10n.adaptivePriorActivityModerate;
      case PriorActivityLevel.high:
        return l10n.adaptivePriorActivityHigh;
      case PriorActivityLevel.veryHigh:
        return l10n.adaptivePriorActivityVeryHigh;
    }
  }

  static String _extraCardioLabel(
      AppLocalizations l10n, ExtraCardioHoursOption option) {
    switch (option) {
      case ExtraCardioHoursOption.h0:
        return l10n.adaptiveExtraCardioOption0;
      case ExtraCardioHoursOption.h1:
        return l10n.adaptiveExtraCardioOption1;
      case ExtraCardioHoursOption.h2:
        return l10n.adaptiveExtraCardioOption2;
      case ExtraCardioHoursOption.h3:
        return l10n.adaptiveExtraCardioOption3;
      case ExtraCardioHoursOption.h5:
        return l10n.adaptiveExtraCardioOption5;
      case ExtraCardioHoursOption.h7Plus:
        return l10n.adaptiveExtraCardioOption7Plus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return KeyedSubtree(
      key: const Key('onboarding_adaptive_goal_page'),
      child: SingleChildScrollView(
        key: const Key('onboarding_activity_page'),
        padding: const EdgeInsets.all(DesignConstants.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignConstants.spacingM),
            Text(
              l10n.onboardingActivityTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.onboardingActivitySubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            PlatformAdaptiveDropdownFormField<PriorActivityLevel>(
              key: const Key('onboarding_prior_activity_dropdown'),
              initialValue: selectedPriorActivityLevel,
              decoration: InputDecoration(
                labelText: l10n.adaptivePriorActivityLabel,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
              items: PriorActivityLevel.values
                  .map(
                    (level) => DropdownMenuItem<PriorActivityLevel>(
                      value: level,
                      child: Text(_priorActivityLabel(l10n, level)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (level) {
                if (level != null) onPriorActivityLevelChanged(level);
              },
            ),
            const SizedBox(height: DesignConstants.spacingL),
            PriorActivityHelpBlock(
              key: const Key('onboarding_prior_activity_help_block'),
              l10n: l10n,
            ),
            const SizedBox(height: 20),
            PlatformAdaptiveDropdownFormField<ExtraCardioHoursOption>(
              key: const Key('onboarding_extra_cardio_dropdown'),
              initialValue: selectedExtraCardioHoursOption,
              decoration: InputDecoration(
                labelText: l10n.adaptiveExtraCardioLabel,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
              ),
              items: ExtraCardioHoursCatalog.supportedOptions
                  .map(
                    (option) => DropdownMenuItem<ExtraCardioHoursOption>(
                      value: option,
                      child: Text(_extraCardioLabel(l10n, option)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (option) {
                if (option != null) onExtraCardioHoursOptionChanged(option);
              },
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.adaptiveExtraCardioHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingGoalDecisionStep extends StatelessWidget {
  const _OnboardingGoalDecisionStep({
    required this.onSetupNow,
    required this.onSetupLater,
  });

  final VoidCallback onSetupNow;
  final VoidCallback onSetupLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_goal_decision_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingGoalDecisionTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingGoalDecisionSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          SummaryCard(
            key: const Key('onboarding_goal_decision_now_button'),
            onTap: onSetupNow,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.target,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingGoalDecisionSetupNow,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.goalPresetLoseWeight,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            key: const Key('onboarding_goal_decision_later_button'),
            onTap: onSetupLater,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.calendar_clock,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingGoalDecisionSetupLater,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.goalPresetMaintainWeight,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingNutritionStep extends StatelessWidget {
  const _OnboardingNutritionStep({
    required this.calController,
    required this.protController,
    required this.carbController,
    required this.fatController,
    required this.waterController,
  });

  final TextEditingController calController;
  final TextEditingController protController;
  final TextEditingController carbController;
  final TextEditingController fatController;
  final TextEditingController waterController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final liquidSuffix = context.watch<UnitService>().suffixFor(
          UnitDimension.liquid,
        );

    return SingleChildScrollView(
      key: const Key('onboarding_nutrition_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.onboardingGoalsTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AlgorithmInfoButton(
                title: l10n.infoTdeeTitle,
                explanation: l10n.infoTdeeExplanation,
                keyPoints: l10n.infoTdeeKeyPoints.split('\n'),
                technicalTitle: l10n.infoTdeeTechnicalTitle,
                technicalExplanation: l10n.infoTdeeTechnicalExplanation,
                markdownAssetPath:
                    'documentation/features/bayesian_tdee_estimator.md',
                citationUrl:
                    'https://trainlibre.com/docs/features/bayesian-tdee-estimator/#evidence',
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingGoalsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _OnboardingNumberField(
            controller: calController,
            label: l10n.onboardingGoalCalories,
            suffix: l10n.unit_kcal,
          ),
          const SizedBox(height: 14),
          _OnboardingNumberField(
            controller: protController,
            label: l10n.onboardingGoalProtein,
            suffix: l10n.unit_grams,
          ),
          const SizedBox(height: 14),
          _OnboardingNumberField(
            controller: carbController,
            label: l10n.onboardingGoalCarbs,
            suffix: l10n.unit_grams,
          ),
          const SizedBox(height: 14),
          _OnboardingNumberField(
            controller: fatController,
            label: l10n.onboardingGoalFat,
            suffix: l10n.unit_grams,
          ),
          const SizedBox(height: 14),
          _OnboardingNumberField(
            controller: waterController,
            label: l10n.onboardingWaterNeedLabel(liquidSuffix),
            suffix: liquidSuffix,
          ),
        ],
      ),
    );
  }
}

class _OnboardingNumberField extends StatelessWidget {
  const _OnboardingNumberField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
      ),
    );
  }
}

class _OnboardingInfoBox extends StatelessWidget {
  const _OnboardingInfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _OnboardingAiHealthStep extends StatelessWidget {
  const _OnboardingAiHealthStep({
    required this.onOpenAiSettings,
    required this.onOpenStepsSettings,
    required this.onOpenSleepSettings,
    required this.onOpenPulseSettings,
  });

  final VoidCallback onOpenAiSettings;
  final VoidCallback onOpenStepsSettings;
  final VoidCallback onOpenSleepSettings;
  final VoidCallback onOpenPulseSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_ai_health_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingAiHealthTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingAiHealthSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          SummaryCard(
            child: Column(
              children: [
                _OnboardingSettingsTile(
                  icon: LucideIcons.sparkles,
                  title: l10n.aiSettingsTitle,
                  subtitle: l10n.aiSettingsDescription,
                  onTap: onOpenAiSettings,
                ),
                const Divider(height: 1),
                _OnboardingSettingsTile(
                  icon: LucideIcons.footprints,
                  title: l10n.steps,
                  subtitle: l10n.settingsStepsSubtitle,
                  onTap: onOpenStepsSettings,
                ),
                const Divider(height: 1),
                _OnboardingSettingsTile(
                  icon: LucideIcons.moon,
                  title: l10n.sleepSettingsSectionTitle,
                  subtitle: l10n.settingsSleepSubtitle,
                  onTap: onOpenSleepSettings,
                ),
                const Divider(height: 1),
                _OnboardingSettingsTile(
                  icon: LucideIcons.heart_pulse,
                  title: l10n.pulseTitle,
                  subtitle: l10n.settingsPulseSubtitle,
                  onTap: onOpenPulseSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSettingsTile extends StatelessWidget {
  const _OnboardingSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(LucideIcons.chevron_right),
        label: Text(l10n.onboardingOpenSettings),
      ),
      onTap: onTap,
    );
  }
}
