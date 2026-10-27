import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../nutrition_recommendation/domain/goal_models.dart';
import '../../../nutrition_recommendation/presentation/prior_activity_help_block.dart';

class OnboardingActivityStep extends StatelessWidget {
  const OnboardingActivityStep({
    super.key,
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
            const SizedBox(height: DesignConstants.spacingXL),
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
                prefixIcon: const Icon(LucideIcons.activity),
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
            const SizedBox(height: DesignConstants.spacingL),
            PlatformAdaptiveDropdownFormField<ExtraCardioHoursOption>(
              key: const Key('onboarding_extra_cardio_dropdown'),
              initialValue: selectedExtraCardioHoursOption,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.timer),
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
