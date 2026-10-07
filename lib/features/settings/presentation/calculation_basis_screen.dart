import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../nutrition_recommendation/domain/goal_models.dart';
import '../../nutrition_recommendation/presentation/prior_activity_help_block.dart';

class CalculationBasisScreen extends StatefulWidget {
  final AdaptiveNutritionRecommendationService? recommendationService;

  const CalculationBasisScreen({super.key, this.recommendationService});

  @override
  State<CalculationBasisScreen> createState() => _CalculationBasisScreenState();
}

class _CalculationBasisScreenState extends State<CalculationBasisScreen> {
  late final AdaptiveNutritionRecommendationService _service =
      widget.recommendationService ?? AdaptiveNutritionRecommendationService();
  PriorActivityLevel _activity = PriorActivityLevelCatalog.defaultLevel;
  ExtraCardioHoursOption _cardio = ExtraCardioHoursCatalog.defaultOption;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _service.getPriorActivityLevel(),
      _service.getExtraCardioHoursOption(),
    ]);
    if (!mounted) return;
    setState(() {
      _activity = values[0] as PriorActivityLevel;
      _cardio = values[1] as ExtraCardioHoursOption;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.savePriorActivityLevel(_activity);
    await _service.saveExtraCardioHoursOption(_cardio);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.calculationBasisTitle,
        actions: [
          TextButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: DesignConstants.cardPadding,
              children: [
                PlatformAdaptiveDropdownFormField<PriorActivityLevel>(
                  key: const Key('calculation_basis_activity'),
                  initialValue: _activity,
                  decoration: InputDecoration(
                    labelText: l10n.adaptivePriorActivityLabel,
                  ),
                  items: PriorActivityLevel.values
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_activityLabel(l10n, value)),
                          ))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _activity = value);
                  },
                ),
                const SizedBox(height: DesignConstants.spacingS),
                PriorActivityHelpBlock(l10n: l10n),
                const SizedBox(height: DesignConstants.spacingL),
                PlatformAdaptiveDropdownFormField<ExtraCardioHoursOption>(
                  key: const Key('calculation_basis_cardio'),
                  initialValue: _cardio,
                  decoration: InputDecoration(
                    labelText: l10n.adaptiveExtraCardioLabel,
                  ),
                  items: ExtraCardioHoursCatalog.supportedOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_cardioLabel(l10n, value)),
                          ))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _cardio = value);
                  },
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Text(l10n.adaptiveExtraCardioHelp),
              ],
            ),
    );
  }

  String _activityLabel(AppLocalizations l10n, PriorActivityLevel value) =>
      switch (value) {
        PriorActivityLevel.low => l10n.adaptivePriorActivityLow,
        PriorActivityLevel.moderate => l10n.adaptivePriorActivityModerate,
        PriorActivityLevel.high => l10n.adaptivePriorActivityHigh,
        PriorActivityLevel.veryHigh => l10n.adaptivePriorActivityVeryHigh,
      };

  String _cardioLabel(AppLocalizations l10n, ExtraCardioHoursOption value) =>
      switch (value) {
        ExtraCardioHoursOption.h0 => l10n.adaptiveExtraCardioOption0,
        ExtraCardioHoursOption.h1 => l10n.adaptiveExtraCardioOption1,
        ExtraCardioHoursOption.h2 => l10n.adaptiveExtraCardioOption2,
        ExtraCardioHoursOption.h3 => l10n.adaptiveExtraCardioOption3,
        ExtraCardioHoursOption.h5 => l10n.adaptiveExtraCardioOption5,
        ExtraCardioHoursOption.h7Plus => l10n.adaptiveExtraCardioOption7Plus,
      };
}
