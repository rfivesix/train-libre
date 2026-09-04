import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/experience_level_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';

/// Features that are wired up but not yet exposed to everyone.
///
/// The experience level is the first of them: it is read across the app
/// already, but the question that should set it — during onboarding — does not
/// exist yet, so this is the only place it can be changed.
class DeveloperLabScreen extends StatelessWidget {
  const DeveloperLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final experienceLevelService = Provider.of<ExperienceLevelService>(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.developerLabTitle),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
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
