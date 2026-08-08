import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_data_sources.dart';
import '../../../core/infrastructure/user_preferences_repository.dart';
import '../../feedback_report/presentation/feedback_report_screen.dart';
import '../../sleep/platform/permissions/sleep_permission_controller.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../services/base_food_language_service.dart';
import '../../../services/off_catalog_country_service.dart';
import '../../../services/unit_service.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'ai_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'data_management_screen.dart';
import 'health_export_settings_screen.dart';
import 'pulse_settings_screen.dart';
import 'sleep_settings_screen.dart';
import 'steps_settings_screen.dart';
import '../../../services/local_app_data_reset_service.dart';
import '../../workout/presentation/live_workout_view_model.dart';
import '../../../widgets/common/common.dart';
import '../../app/presentation/app_initializer_screen.dart';
import '../../onboarding/presentation/initial_consent_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/telemetry/telemetry_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    SleepSettingsService? sleepSyncService,
    SleepPermissionController? sleepPermissionController,
  })  : _sleepSyncService = sleepSyncService,
        _sleepPermissionController = sleepPermissionController;

  final SleepSettingsService? _sleepSyncService;
  final SleepPermissionController? _sleepPermissionController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _overviewExtraNutrient = 'fiber';
  OffCatalogCountry _activeOffCatalogCountry =
      AppDataSources.defaultOffCatalogCountry;
  BaseFoodLanguage _baseFoodLanguage = BaseFoodLanguage.auto;

  late final SleepSettingsService _sleepSyncService;
  late final SleepPermissionController _sleepPermissionController;
  late final bool _ownsSleepSyncService;
  late final bool _ownsSleepPermissionController;

  bool hasStepsSettingsChanged = false;
  bool _isLocalResetRunning = false;
  bool _isTelemetryOptedIn = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController = widget._sleepPermissionController ??
        _sleepSyncService.buildPermissionController();

    _loadDiaryOverviewSettings();
    _loadOffCatalogSettings();
    _loadBaseFoodLanguage();
    _loadTelemetryOptIn();
    unawaited(TelemetryService.instance.trackScreenView(screenName: ScreenName.settingsMain));
  }


  Future<void> _loadTelemetryOptIn() async {
    final optedIn = await TelemetryService.instance.isOptedIn();
    if (!mounted) return;
    setState(() => _isTelemetryOptedIn = optedIn);
  }

  @override
  void dispose() {
    if (_ownsSleepPermissionController) {
      _sleepPermissionController.state.dispose();
    }
    if (_ownsSleepSyncService) {
      unawaited(_sleepSyncService.dispose());
    }
    super.dispose();
  }

  Future<void> _loadDiaryOverviewSettings() async {
    final nutrient =
        await UserPreferencesRepository.instance.getOverviewExtraNutrient();
    if (!mounted) return;
    setState(() {
      _overviewExtraNutrient = nutrient;
    });
  }

  Future<void> _loadOffCatalogSettings() async {
    final country = await OffCatalogCountryService.readActiveCountry();
    if (!mounted) return;
    setState(() => _activeOffCatalogCountry = country);
  }

  Future<void> _loadBaseFoodLanguage() async {
    final choice = await BaseFoodLanguageService.readChoice();
    if (!mounted) return;
    setState(() => _baseFoodLanguage = choice);
  }

  String _baseFoodLanguageLabel(
    BaseFoodLanguage language,
    AppLocalizations l10n,
  ) {
    return switch (language) {
      BaseFoodLanguage.auto => l10n.settingsBaseFoodLanguageFollowApp,
      BaseFoodLanguage.en => l10n.settingsBaseFoodLanguageEnglish,
      BaseFoodLanguage.de => l10n.settingsBaseFoodLanguageGerman,
      BaseFoodLanguage.fr => l10n.settingsBaseFoodLanguageFrench,
      BaseFoodLanguage.it => l10n.settingsBaseFoodLanguageItalian,
      BaseFoodLanguage.ja => l10n.settingsBaseFoodLanguageJapanese,
    };
  }

  Future<void> _showBaseFoodLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showGlassBottomMenu<BaseFoodLanguage>(
      context: context,
      title: l10n.settingsBaseFoodLanguageTitle,
      contentBuilder: (dialogContext, close) {
        var draft = _baseFoodLanguage;
        return StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsBaseFoodLanguageSubtitle),
              const SizedBox(height: DesignConstants.spacingM),
              RadioGroup<BaseFoodLanguage>(
                groupValue: draft,
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => draft = value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final lang in BaseFoodLanguage.values)
                      RadioListTile<BaseFoodLanguage>(
                        contentPadding: EdgeInsets.zero,
                        value: lang,
                        title: Text(_baseFoodLanguageLabel(lang, l10n)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(draft),
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    if (selected == _baseFoodLanguage) return;

    await BaseFoodLanguageService.writeChoice(selected);
    // Force a base-food re-import on next startup so both name columns
    // are populated according to the new preference.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('installed_food_version');
    if (!mounted) return;
    setState(() => _baseFoodLanguage = selected);
    hasStepsSettingsChanged = true;

    final l10nNow = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10nNow.settingsFoodDbRegionChanged(
          _baseFoodLanguageLabel(selected, l10nNow),
        )),
      ),
    );
  }

  String _offCountryLabel(OffCatalogCountry country, AppLocalizations l10n) {
    return switch (country) {
      OffCatalogCountry.de => l10n.settingsFoodDbRegionGermany,
      OffCatalogCountry.ch => l10n.settingsFoodDbRegionSwitzerland,
      OffCatalogCountry.us => l10n.settingsFoodDbRegionUnitedStates,
      OffCatalogCountry.uk => l10n.settingsFoodDbRegionUnitedKingdom,
      OffCatalogCountry.fr => l10n.settingsFoodDbRegionFrance,
      OffCatalogCountry.it => l10n.settingsFoodDbRegionItaly,
      OffCatalogCountry.jp => l10n.settingsFoodDbRegionJapan,
      OffCatalogCountry.at => l10n.settingsFoodDbRegionAustria,
    };
  }

  Future<void> _showOffCatalogRegionPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedCountry = await showGlassBottomMenu<OffCatalogCountry>(
      context: context,
      title: l10n.settingsFoodDbRegionDialogTitle,
      contentBuilder: (dialogContext, close) {
        return _OffCatalogRegionPickerContent(
          initialSelection: _activeOffCatalogCountry,
          countryLabelResolver: _offCountryLabel,
        );
      },
    );

    if (!mounted || selectedCountry == null) return;
    if (selectedCountry == _activeOffCatalogCountry) return;

    await OffCatalogCountryService.writeActiveCountry(selectedCountry);
    if (!mounted) return;

    setState(() => _activeOffCatalogCountry = selectedCountry);
    hasStepsSettingsChanged = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.settingsFoodDbRegionChanged(
            _offCountryLabel(selectedCountry, l10n),
          ),
        ),
      ),
    );
  }



  bool _settingsChildMayHaveChanged(bool? result) {
    // iOS interactive back-swipe completes a route with a null result. These
    // settings sub-screens are safe to swipe away from, so refresh
    // conservatively instead of blocking the native gesture with PopScope.
    return result == true ||
        (result == null && Theme.of(context).platform == TargetPlatform.iOS);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.settingsTitle,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(hasStepsSettingsChanged),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(
            key: const Key('settings_section_app'),
            title: l10n.settingsSectionApp,
          ),
          SummaryCard(
            child: Column(
              children: [
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.palette,
                  title: l10n.settingsAppearance,
                  subtitle: l10n.settingsAppearanceSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AppearanceSettingsScreen(),
                      ),
                    );
                  },
                  tileKey: const Key('settings_appearance_entry'),
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                PlatformAdaptivePopupMenu<String>(
                  selectedValue: _overviewExtraNutrient,
                  onSelected: (value) async {
                    if (value == _overviewExtraNutrient) return;
                    setState(() {
                      _overviewExtraNutrient = value;
                    });
                    await UserPreferencesRepository.instance
                        .setOverviewExtraNutrient(value);
                    unawaited(TelemetryService.instance.trackSettingToggled(
                      settingKey: 'overview_extra_nutrient',
                      value: value,
                    ));
                  },
                  items: [
                    PlatformAdaptivePopupMenuItem(
                      value: 'fiber',
                      label: l10n.fiber,
                      icon: LucideIcons.wheat,
                    ),
                    PlatformAdaptivePopupMenuItem(
                      value: 'sugar',
                      label: l10n.sugar,
                      icon: LucideIcons.candy,
                    ),
                    PlatformAdaptivePopupMenuItem(
                      value: 'salt',
                      label: l10n.salt,
                      icon: LucideIcons.cooking_pot,
                    ),
                  ],
                  icon: ListTile(
                    contentPadding: DesignConstants.screenPadding,
                    leading: Icon(
                      LucideIcons.sparkles,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      l10n.settingsOverviewExtraNutrientTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _getExtraNutrientLabel(l10n, _overviewExtraNutrient),
                    ),
                    trailing: const Icon(LucideIcons.chevron_right),
                  ),
                ),
                const Divider(height: 1),
                PlatformAdaptivePopupMenu<UnitSystem>(
                  selectedValue: unitService.unitSystem,
                  onSelected: (value) {
                    unitService.setUnitSystem(value);
                    unawaited(TelemetryService.instance.trackSettingToggled(
                      settingKey: 'unit_system',
                      value: value.name,
                    ));
                  },
                  items: [
                    PlatformAdaptivePopupMenuItem(
                      value: UnitSystem.metric,
                      label: 'Metric (kg, cm, ml)',
                    ),
                    PlatformAdaptivePopupMenuItem(
                      value: UnitSystem.imperial,
                      label: 'Imperial (lbs, in, fl oz)',
                    ),
                  ],
                  icon: ListTile(
                    contentPadding: DesignConstants.screenPadding,
                    leading: Icon(
                      LucideIcons.ruler_dimension_line,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text(
                      'Unit System',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      unitService.isMetric
                          ? 'Metric (kg, cm, ml)'
                          : 'Imperial (lbs, in, fl oz)',
                    ),
                    trailing: const Icon(LucideIcons.chevron_right),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(
            key: const Key('settings_section_health_tracking'),
            title: l10n.settingsSectionHealthTracking,
          ),
          SummaryCard(
            child: Column(
              children: [
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.footprints,
                  title: l10n.steps,
                  subtitle: l10n.settingsStepsSubtitle,
                  tileKey: const Key('settings_steps_entry'),
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const StepsSettingsScreen(),
                      ),
                    );
                    if (_settingsChildMayHaveChanged(changed)) {
                      hasStepsSettingsChanged = true;
                    }
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.moon,
                  title: l10n.sleepSettingsSectionTitle,
                  subtitle: l10n.settingsSleepSubtitle,
                  tileKey: const Key('settings_sleep_entry'),
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => SleepSettingsScreen(
                          sleepSyncService: _sleepSyncService,
                          sleepPermissionController: _sleepPermissionController,
                        ),
                      ),
                    );
                    if (_settingsChildMayHaveChanged(changed)) {
                      hasStepsSettingsChanged = true;
                    }
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.heart_pulse,
                  title: l10n.pulseTitle,
                  subtitle: l10n.settingsPulseSubtitle,
                  tileKey: const Key('settings_pulse_entry'),
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const PulseSettingsScreen(),
                      ),
                    );
                    if (_settingsChildMayHaveChanged(changed)) {
                      hasStepsSettingsChanged = true;
                    }
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.heart,
                  title: l10n.healthExportTitle,
                  subtitle: l10n.settingsHealthExportSubtitle,
                  tileKey: const Key('settings_health_export_entry'),
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) =>
                            const HealthExportSettingsScreen(),
                      ),
                    );
                    if (_settingsChildMayHaveChanged(changed)) {
                      hasStepsSettingsChanged = true;
                    }
                  },
                  wrapInCard: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(
            key: const Key('settings_section_nutrition_data'),
            title: l10n.settingsSectionNutritionAndData,
          ),
          SummaryCard(
            child: Column(
              children: [
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.sparkles,
                  title: l10n.aiSettingsTitle,
                  subtitle: l10n.aiSettingsDescription,
                  useGradientIcon: true,
                  tileKey: const Key('settings_ai_entry'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AiSettingsScreen(),
                      ),
                    );
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.database_backup,
                  title: l10n.backup_and_import,
                  subtitle: l10n.backup_and_import_description,
                  tileKey: const Key('settings_backup_import_entry'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DataManagementScreen(),
                      ),
                    );
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.cloud_download,
                  title: l10n.settingsUpdateFoodDatabase,
                  subtitle: l10n.settingsUpdateFoodDatabaseSubtitle,
                  tileKey: const Key('settings_sync_off_database'),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AppInitializerScreen(
                          forceUpdate: true,
                          isModal: true,
                        ),
                      ),
                    );

                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.settingsUpdateFoodDatabaseSuccess),
                        ),
                      );
                    }
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    LucideIcons.earth,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.settingsFoodDbRegionTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${l10n.settingsFoodDbRegionSubtitle}\n'
                    '${l10n.settingsFoodDbRegionCurrent}: '
                    '${_offCountryLabel(_activeOffCatalogCountry, l10n)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: _showOffCatalogRegionPicker,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    LucideIcons.languages,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.settingsBaseFoodLanguageTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _baseFoodLanguageLabel(_baseFoodLanguage, l10n),
                  ),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: _showBaseFoodLanguagePicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(
            key: const Key('settings_section_support_about'),
            title: l10n.settingsSectionSupportAbout,
          ),
          SummaryCard(
            child: Column(
              children: [
                _buildNavigationCard(
                  context: context,
                  icon: LucideIcons.message_square,
                  title: l10n.feedbackReportSettingsEntryTitle,
                  subtitle: l10n.feedbackReportSettingsEntrySubtitle,
                  tileKey: const Key('settings_feedback_entry'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FeedbackReportScreen(),
                      ),
                    );
                  },
                  wrapInCard: false,
                ),
                const Divider(height: 1),
                PlatformAdaptiveSwitchListTile(
                  secondary: Icon(
                    LucideIcons.chart_bar,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Anonyme Nutzungsstatistiken teilen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Hilft bei der Verbesserung der App. Vollständig anonymisiert, ohne personenbezogene Daten.',
                  ),
                  value: _isTelemetryOptedIn,
                  onChanged: (value) async {
                    if (value) {
                      await TelemetryService.instance.optIn();
                    } else {
                      await TelemetryService.instance.optOut();
                    }
                    unawaited(TelemetryService.instance.trackSettingToggled(
                      settingKey: 'telemetry_opt_in',
                      value: value,
                    ));
                    if (!mounted) return;
                    setState(() => _isTelemetryOptedIn = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AppLinkRow(
            key: const Key('settings_reset_telemetry_data'),
            title: 'Telemetrie-Daten löschen',
            subtitle: 'Löscht alle gespeicherten IDs lokal und auf dem PostHog-Server',
            trailingIcon: LucideIcons.trash_2,
            onTap: () async {
              final confirmed = await _showTelemetryDeletionConfirmation();
              if (!confirmed) return;
              await TelemetryService.instance.resetLocalData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Telemetrie-IDs & Daten wurden lokal und vom Server gelöscht.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          AppSectionHeader(
            key: const Key('settings_section_reset'),
            title: l10n.localDataDeletionCardTitle,
          ),
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localDataDeletionCardTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    l10n.localDataDeletionCardDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.danger(
                      onPressed: _isLocalResetRunning
                          ? null
                          : _confirmAndDeleteLocalData,
                      label: l10n.deleteAllLocalAppData,
                      tooltip: l10n.deleteAllLocalAppData,
                      icon: LucideIcons.trash_2,
                      isLoading: _isLocalResetRunning,
                    ),
                  ),
                  if (_isLocalResetRunning)
                    const Padding(
                      padding: EdgeInsets.only(top: DesignConstants.spacingL),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteLocalData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showLocalDataDeletionConfirmation(l10n);
    if (!confirmed || !mounted) return;

    LiveWorkoutViewModel? sessionManager;
    try {
      sessionManager = context.read<LiveWorkoutViewModel>();
    } catch (_) {
      sessionManager = null;
    }

    setState(() => _isLocalResetRunning = true);
    try {
      final resetter = LocalAppDataResetService();
      await resetter.deleteAllLocalAppData();
      await sessionManager?.clearLocalSessionState();

      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);

      await showGlassBottomMenu<void>(
        context: context,
        title: l10n.localDataDeletionSuccessTitle,
        isDismissible: false,
        enableDrag: false,
        contentBuilder: (ctx, close) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.localDataDeletionSuccessBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                onPressed: () => Navigator.of(ctx).pop(),
                label: l10n.snackbarButtonOK,
                tooltip: l10n.snackbarButtonOK,
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => InitialConsentScreen(
            nextScreen: const AppInitializerScreen(),
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.localDataDeletionFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _showTelemetryDeletionConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.telemetryDeleteDialogTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.telemetryDeleteDialogBody,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: AppButton.danger(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    label: l10n.telemetryDeleteConfirmButton,
                    tooltip: l10n.telemetryDeleteDialogTitle,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<bool> _showLocalDataDeletionConfirmation(
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    final result = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.localDataDeletionConfirmTitle,
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final canConfirm = controller.text.trim() == 'DELETE';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.localDataDeletionConfirmBody,
                ),
                const SizedBox(height: DesignConstants.spacingL),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.localDataDeletionTypeDeleteLabel,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: AppButton.danger(
                        onPressed: canConfirm
                            ? () => Navigator.of(ctx).pop(true)
                            : null,
                        label: l10n.delete,
                        tooltip: l10n.delete,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Key? tileKey,
    bool useGradientIcon = false,
    bool wrapInCard = true,
  }) {
    Widget iconWidget = Icon(
      icon,
      size: 36,
      color: Theme.of(context).colorScheme.primary,
    );

    if (useGradientIcon) {
      iconWidget = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            DesignConstants.createAiGradientShader(bounds),
        child: Icon(icon, size: 36),
      );
    }

    final tile = ListTile(
      key: tileKey,
      contentPadding: DesignConstants.screenPadding,
      leading: iconWidget,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(LucideIcons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );

    if (!wrapInCard) {
      return tile;
    }

    return SummaryCard(
      child: tile,
    );
  }

  String _getExtraNutrientLabel(AppLocalizations l10n, String key) {
    switch (key.toLowerCase()) {
      case 'sugar':
        return l10n.sugar;
      case 'salt':
        return l10n.salt;
      case 'fiber':
      default:
        return l10n.fiber;
    }
  }


}

class _OffCatalogRegionPickerContent extends StatefulWidget {
  final OffCatalogCountry initialSelection;
  final String Function(OffCatalogCountry, AppLocalizations)
      countryLabelResolver;

  const _OffCatalogRegionPickerContent({
    required this.initialSelection,
    required this.countryLabelResolver,
  });

  @override
  State<_OffCatalogRegionPickerContent> createState() =>
      __OffCatalogRegionPickerContentState();
}

class __OffCatalogRegionPickerContentState
    extends State<_OffCatalogRegionPickerContent> {
  late OffCatalogCountry _draftSelection;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _draftSelection = widget.initialSelection;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final query = _searchQuery.toLowerCase().trim();
    final filteredCountries =
        AppDataSources.supportedOffCatalogCountries.where((country) {
      if (query.isEmpty) return true;
      final label = widget.countryLabelResolver(country, l10n).toLowerCase();
      final code = country.code.toLowerCase();
      return label.contains(query) || code.contains(query);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsFoodDbRegionDialogSubtitle),
        const SizedBox(height: DesignConstants.spacingM),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.settingsFoodDbRegionSearchPlaceholder,
            prefixIcon: Icon(
              LucideIcons.search,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: l10n.clearSearch,
                    icon: Icon(
                      LucideIcons.x,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
        const SizedBox(height: DesignConstants.spacingM),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: filteredCountries.isEmpty
              ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    l10n.settingsFoodDbRegionNoResults,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : SingleChildScrollView(
                  child: RadioGroup<OffCatalogCountry>(
                    groupValue: _draftSelection,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _draftSelection = value);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final country in filteredCountries)
                          RadioListTile<OffCatalogCountry>(
                            contentPadding: EdgeInsets.zero,
                            value: country,
                            title: Text(
                                widget.countryLabelResolver(country, l10n)),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.settingsFoodDbRegionIssueHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_draftSelection),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
