import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/experience_level_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'performance_diagnostics_screen.dart';

/// The tools that only matter while building the app.
///
/// Settings used to link straight to the performance log; everything of this
/// kind now collects here so the main list stays about the app rather than
/// about its development.
class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final experienceLevelService = Provider.of<ExperienceLevelService>(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.settingsDeveloperTitle),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(title: l10n.settingsDeveloperTitle),
          SummaryCard(
            child: ListTile(
              key: const Key('developer_performance_log'),
              contentPadding: DesignConstants.screenPadding,
              leading: Icon(
                LucideIcons.activity,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                l10n.settingsPerformanceLogTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(l10n.settingsPerformanceLogSubtitle),
              trailing: const Icon(LucideIcons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PerformanceDiagnosticsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          // The experience level is read across the app already; the question
          // that should set it — during onboarding — does not exist yet, so
          // this is the only place it can be changed at all.
          AppSectionHeader(title: l10n.developerLabExperienceSection),
          SummaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignConstants.spacingL),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.graduation_cap),
                      const SizedBox(width: DesignConstants.spacingL),
                      Expanded(
                        child:
                            PlatformAdaptiveDropdownFormField<ExperienceLevel>(
                          key: ValueKey(experienceLevelService.level),
                          value: experienceLevelService.level,
                          decoration: InputDecoration(
                            labelText: l10n.developerLabExperienceLabel,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.spacingM,
                              vertical: DesignConstants.spacingS,
                            ),
                          ),
                          items: ExperienceLevel.values
                              .map(
                                (level) => DropdownMenuItem<ExperienceLevel>(
                                  value: level,
                                  child: Text(_levelLabel(l10n, level)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            experienceLevelService.setLevel(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(DesignConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _levelDescription(l10n, experienceLevelService.level),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      Text(
                        l10n.developerLabExperienceHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _levelLabel(AppLocalizations l10n, ExperienceLevel level) {
    return switch (level) {
      ExperienceLevel.beginner => l10n.experienceLevelBeginner,
      ExperienceLevel.advanced => l10n.experienceLevelAdvanced,
      ExperienceLevel.pro => l10n.experienceLevelPro,
    };
  }

  String _levelDescription(AppLocalizations l10n, ExperienceLevel level) {
    return switch (level) {
      ExperienceLevel.beginner => l10n.experienceLevelBeginnerDescription,
      ExperienceLevel.advanced => l10n.experienceLevelAdvancedDescription,
      ExperienceLevel.pro => l10n.experienceLevelProDescription,
    };
  }
}
