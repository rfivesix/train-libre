// lib/features/settings/presentation/developer_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/experience_level_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'developer_lab/nutrition_developer_lab_view.dart';
import 'performance_diagnostics_screen.dart';

/// The developer tools screen with dual tabs:
/// 1. General system & performance tools
/// 2. Nutrition Developer Lab for interactive testing of the adaptive engine
class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalAppBar(title: l10n.settingsDeveloperTitle),
        body: Column(
          children: [
            SizedBox(height: topPadding),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingL,
                vertical: DesignConstants.spacingS,
              ),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      iconMargin: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.settings_2, size: 16),
                          SizedBox(width: 8),
                          Text('Allgemein'),
                        ],
                      ),
                    ),
                    Tab(
                      iconMargin: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.apple, size: 16),
                          SizedBox(width: 8),
                          Text('Nutrition Lab'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGeneralTab(context, l10n, theme),
                  const NutritionDeveloperLabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final experienceLevelService = Provider.of<ExperienceLevelService>(context);

    return ListView(
      padding: DesignConstants.cardPadding,
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
                      child: PlatformAdaptiveDropdownFormField<ExperienceLevel>(
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
