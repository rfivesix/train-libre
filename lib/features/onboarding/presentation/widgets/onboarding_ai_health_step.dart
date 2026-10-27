import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class OnboardingAiHealthStep extends StatelessWidget {
  const OnboardingAiHealthStep({
    super.key,
    required this.onOpenAiSettings,
    required this.onOpenHealthSettings,
  });

  final VoidCallback onOpenAiSettings;
  final VoidCallback onOpenHealthSettings;

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
          const SizedBox(height: DesignConstants.spacingXL),
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
                OnboardingSettingsTile(
                  icon: LucideIcons.sparkles,
                  title: l10n.aiSettingsTitle,
                  subtitle: l10n.aiSettingsDescription,
                  onTap: onOpenAiSettings,
                ),
                const Divider(height: 1),
                OnboardingSettingsTile(
                  key: const Key('onboarding_health_settings_link'),
                  icon: LucideIcons.heart_pulse,
                  title: l10n.healthSettingsTitle,
                  subtitle: l10n.onboardingHealthSettingsDescription,
                  onTap: onOpenHealthSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSettingsTile extends StatelessWidget {
  const OnboardingSettingsTile({
    super.key,
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
