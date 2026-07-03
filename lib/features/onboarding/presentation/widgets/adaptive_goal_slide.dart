import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../nutrition_recommendation/domain/goal_models.dart';
import '../../../nutrition_recommendation/presentation/prior_activity_help_block.dart';
import 'springy_scale.dart';
import '../../../../widgets/common/common.dart';

class AdaptiveGoalSlide extends StatelessWidget {
  final BodyweightGoal selectedGoal;
  final PriorActivityLevel selectedPriorActivityLevel;
  final ExtraCardioHoursOption selectedExtraCardioHoursOption;
  final double selectedTargetRateKgPerWeek;

  final ValueChanged<BodyweightGoal> onGoalChanged;
  final ValueChanged<PriorActivityLevel> onPriorActivityLevelChanged;
  final ValueChanged<ExtraCardioHoursOption> onExtraCardioHoursOptionChanged;
  final ValueChanged<double> onTargetRateKgPerWeekChanged;

  const AdaptiveGoalSlide({
    super.key,
    required this.selectedGoal,
    required this.selectedPriorActivityLevel,
    required this.selectedExtraCardioHoursOption,
    required this.selectedTargetRateKgPerWeek,
    required this.onGoalChanged,
    required this.onPriorActivityLevelChanged,
    required this.onExtraCardioHoursOptionChanged,
    required this.onTargetRateKgPerWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_adaptive_goal_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.onboardingAdaptiveGoalTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingAdaptiveGoalSubtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          PlatformAdaptiveDropdownFormField<BodyweightGoal>(
            initialValue: selectedGoal,
            decoration: InputDecoration(
              labelText: l10n.adaptiveGoalDirectionLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: BodyweightGoal.values
                .map(
                  (goal) => DropdownMenuItem<BodyweightGoal>(
                    value: goal,
                    child: Text(_goalLabel(l10n, goal)),
                  ),
                )
                .toList(growable: false),
            onChanged: (goal) {
              if (goal != null) onGoalChanged(goal);
            },
          ),
          const SizedBox(height: 20),
          PlatformAdaptiveDropdownFormField<PriorActivityLevel>(
            key: const Key('onboarding_prior_activity_dropdown'),
            initialValue: selectedPriorActivityLevel,
            decoration: InputDecoration(
              labelText: l10n.adaptivePriorActivityLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          Text(
            l10n.adaptiveRatePerWeekLabel,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: WeeklyTargetRateCatalog.optionsForGoal(selectedGoal)
                .map((option) {
              final isSelected =
                  option.kgPerWeek == selectedTargetRateKgPerWeek;
              return SpringyScale(
                isSelected: isSelected,
                onTap: () => onTargetRateKgPerWeekChanged(option.kgPerWeek),
                child: ChoiceChip(
                  label: Text(
                    _rateLabel(l10n, option.kgPerWeek),
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      onTargetRateKgPerWeekChanged(option.kgPerWeek),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.spacingM,
                      vertical: DesignConstants.spacingS),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM)),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
        ],
      ),
    );
  }

  String _goalLabel(AppLocalizations l10n, BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return l10n.adaptiveGoalLose;
      case BodyweightGoal.maintainWeight:
        return l10n.adaptiveGoalMaintain;
      case BodyweightGoal.gainWeight:
        return l10n.adaptiveGoalGain;
    }
  }

  String _rateLabel(AppLocalizations l10n, double kgPerWeek) {
    final sign = kgPerWeek > 0 ? '+' : '';
    return l10n.adaptiveRatePerWeek('$sign${kgPerWeek.toStringAsFixed(2)}');
  }

  String _priorActivityLabel(
    AppLocalizations l10n,
    PriorActivityLevel level,
  ) {
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

  String _extraCardioLabel(
    AppLocalizations l10n,
    ExtraCardioHoursOption option,
  ) {
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
}
