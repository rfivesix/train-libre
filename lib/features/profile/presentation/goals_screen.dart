import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../domain/repositories/profile_repository.dart';

/// Operative calorie, nutrient, hydration, and step targets.
///
/// Nutrition goal direction and trajectory live exclusively in My Goals. The
/// former preference-backed bodyweight editor is intentionally not reachable
/// from this screen anymore.
class DailyTargetsScreen extends StatefulWidget {
  final AdaptiveNutritionRecommendationService? recommendationService;
  final IProfileRepository? repository;

  const DailyTargetsScreen({
    super.key,
    this.recommendationService,
    this.repository,
  });

  @override
  State<DailyTargetsScreen> createState() => _DailyTargetsScreenState();
}

/// Compatibility name for existing routes while callers migrate to the more
/// precise [DailyTargetsScreen] name.
class GoalsScreen extends DailyTargetsScreen {
  const GoalsScreen({
    super.key,
    super.recommendationService,
    super.repository,
  });
}

class _DailyTargetsScreenState extends State<DailyTargetsScreen> {
  late final IProfileRepository _repository =
      widget.repository ?? context.read<IProfileRepository>();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();
  final _stepsController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _saltController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.goalEditor));
    _loadSettings();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    _stepsController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = await _repository.getAppSettings();
      final targetSteps = await _repository.getCurrentTargetStepsOrDefault();
      var targetWater = settings?.targetWater ?? 3000;
      if (settings?.targetWater == null) {
        final weightData = await _repository.getChartDataForTypeAndRange(
          'weight',
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 365)),
            end: DateTime.now(),
          ),
        );
        if (weightData.isNotEmpty) {
          targetWater = ((weightData.last.value / 20.0) * 1000.0).round();
        }
      }

      if (!mounted) return;
      setState(() {
        _caloriesController.text =
            (settings?.targetCalories ?? 2500).toString();
        _proteinController.text = (settings?.targetProtein ?? 180).toString();
        _carbsController.text = (settings?.targetCarbs ?? 250).toString();
        _fatController.text = (settings?.targetFat ?? 80).toString();
        _waterController.text = targetWater.toString();
        _stepsController.text = targetSteps.toString();
        _sugarController.text = (prefs.getInt('targetSugar') ?? 50).toString();
        _fiberController.text = (prefs.getInt('targetFiber') ?? 30).toString();
        _saltController.text = (prefs.getInt('targetSalt') ?? 6).toString();
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('DailyTargetsScreen: failed to load settings: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final prefs = await SharedPreferences.getInstance();
    await _repository.saveUserGoals(
      calories: int.parse(_caloriesController.text),
      protein: int.parse(_proteinController.text),
      carbs: int.parse(_carbsController.text),
      fat: int.parse(_fatController.text),
      water: int.parse(_waterController.text),
      steps: int.parse(_stepsController.text),
    );
    await prefs.setInt('targetSugar', int.parse(_sugarController.text));
    await prefs.setInt('targetFiber', int.parse(_fiberController.text));
    await prefs.setInt('targetSalt', int.parse(_saltController.text));

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.snackbarGoalsSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.dailyOperatingTargetsTitle,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: DesignConstants.spacingS),
            child: TextButton(
              onPressed: _saveSettings,
              child: Text(l10n.buttonSave),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top +
                    MediaQuery.of(context).padding.top +
                    kToolbarHeight,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppSectionHeader(
                          key: const Key('goals_daily_section_title'),
                          title: l10n.profileDailyGoalsCL,
                        ),
                        AlgorithmInfoButton(
                          title: l10n.infoTdeeTitle,
                          explanation: l10n.infoTdeeExplanation,
                          keyPoints: l10n.infoTdeeKeyPoints.split('\n'),
                          technicalTitle: l10n.infoTdeeTechnicalTitle,
                          technicalExplanation:
                              l10n.infoTdeeTechnicalExplanation,
                          markdownAssetPath:
                              'documentation/features/bayesian_tdee_estimator.md',
                          citationUrl:
                              'https://trainlibre.com/docs/features/bayesian-tdee-estimator/#evidence',
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    _field(_caloriesController, l10n.calories),
                    _field(_proteinController, l10n.protein),
                    _field(_carbsController, l10n.carbs),
                    _field(_fatController, l10n.fat),
                    _field(_waterController, l10n.water),
                    _field(_stepsController, l10n.steps),
                    const SizedBox(height: DesignConstants.spacingL),
                    AppSectionHeader(title: l10n.detailedNutrientGoalsCL),
                    const SizedBox(height: DesignConstants.spacingM),
                    _field(_sugarController, l10n.sugar),
                    _field(_fiberController, l10n.fiber),
                    _field(_saltController, l10n.salt),
                    const SizedBox(height: DesignConstants.spacingL),
                    Text(
                      l10n.infoScientificDisclaimer,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (value) => value == null || num.tryParse(value) == null
            ? l10n.validatorPleaseEnterNumber
            : null,
      ),
    );
  }
}
