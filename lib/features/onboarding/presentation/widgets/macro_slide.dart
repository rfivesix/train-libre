import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';

class OnboardingCaloriesSlide extends StatelessWidget {
  final TextEditingController calController;

  const OnboardingCaloriesSlide({
    super.key,
    required this.calController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingGoalsTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingGoalCalories,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          TextField(
            controller: calController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            decoration: InputDecoration(
              suffixText: l10n.unit_kcal,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: DesignConstants.spacingXL),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingMacrosSlide extends StatelessWidget {
  final TextEditingController protController;
  final TextEditingController carbController;
  final TextEditingController fatController;

  const OnboardingMacrosSlide({
    super.key,
    required this.protController,
    required this.carbController,
    required this.fatController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingMacrosStepTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingMacrosStepSubtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          _MacroInput(
            controller: protController,
            label: l10n.onboardingGoalProtein,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DesignConstants.spacingL),
          _MacroInput(
            controller: carbController,
            label: l10n.onboardingGoalCarbs,
            color: Colors.green,
          ),
          const SizedBox(height: DesignConstants.spacingL),
          _MacroInput(
            controller: fatController,
            label: l10n.onboardingGoalFat,
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}

class _MacroInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  const _MacroInput({
    required this.controller,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 1,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: InputDecoration(
              suffixText: l10n.unit_grams,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingM,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
