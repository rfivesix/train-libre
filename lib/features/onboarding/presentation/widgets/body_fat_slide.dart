import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';

class BodyFatSlide extends StatelessWidget {
  final TextEditingController bodyFatPercentController;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenHelp;

  const BodyFatSlide({
    super.key,
    required this.bodyFatPercentController,
    required this.onChanged,
    required this.onOpenHelp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('onboarding_body_fat_page'),
      padding: const EdgeInsets.all(DesignConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignConstants.spacingXL),
          Text(
            l10n.onboardingBodyFatPageTitle,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingBodyFatPageSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('onboarding_body_fat_text_field'),
            controller: bodyFatPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: l10n.onboardingBodyFatOptionalLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.onboardingBodyFatOptionalHelper,
            key: const Key('onboarding_body_fat_helper_text'),
            style: theme.textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('onboarding_body_fat_help_button'),
              onPressed: onOpenHelp,
              child: Text(l10n.onboardingBodyFatHelpAction),
            ),
          ),
        ],
      ),
    );
  }
}
