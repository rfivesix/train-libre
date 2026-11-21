import 'package:material_ui/material_ui.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'ai_overlay_demo_screen.dart';
import 'developer_lab/nutrition_developer_lab_view.dart';
import 'developer_lab/statistics_sample_data_seeder.dart';
import 'performance_diagnostics_screen.dart';
import 'widgets/ai_meal_scan_logs_section.dart';

/// Entry point for developer tools. Individual tools live on their own pages.
class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.settingsDeveloperTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.spacingL,
          MediaQuery.paddingOf(context).top +
              kToolbarHeight +
              DesignConstants.spacingS,
          DesignConstants.spacingL,
          DesignConstants.spacingXL,
        ),
        children: [
          AppSettingsRow.navigation(
            key: const Key('developer_nutrition_lab'),
            title: 'Nutrition Lab',
            subtitle: l10n.developerNutritionLabSubtitle,
            leading: Icon(
              LucideIcons.apple,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _NutritionDeveloperLabScreen(),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AppSettingsRow.navigation(
            key: const Key('developer_ai_meal_scan_logs'),
            title: l10n.aiScanLogsTitle,
            subtitle: l10n.aiScanLogsPrivacy,
            leading: Icon(
              LucideIcons.scan_search,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _AiMealScanLogsScreen(),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AppSettingsRow.navigation(
            key: const Key('developer_ai_overlay_demo'),
            title: l10n.developerAiOverlayDemoTitle,
            subtitle: l10n.developerAiOverlayDemoSubtitle,
            leading: Icon(
              LucideIcons.sparkles,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AiOverlayDemoScreen(),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AppSettingsRow.navigation(
            key: const Key('developer_performance_log'),
            title: l10n.settingsPerformanceLogTitle,
            subtitle: l10n.settingsPerformanceLogSubtitle,
            leading: Icon(
              LucideIcons.activity,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PerformanceDiagnosticsScreen(),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AppSettingsRow.navigation(
            key: const Key('developer_seed_statistics_sample'),
            title: 'Statistik-Beispieldaten laden',
            subtitle:
                'Fügt 45 Tage Beispieldaten für alle Statistik-Hub-Karten und Screens ein',
            leading: Icon(
              LucideIcons.database,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            onTap: () async {
              await StatisticsSampleDataSeeder.seedAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistik-Beispieldaten wurden eingefügt.'),
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingS),
          AppSettingsRow.navigation(
            key: const Key('developer_clear_statistics_sample'),
            title: 'Statistik-Beispieldaten entfernen',
            subtitle:
                'Entfernt nur die eingefügten Emulator-/Simulator-Beispieldaten',
            leading: Icon(
              LucideIcons.trash,
              size: 24,
              color: theme.colorScheme.error,
            ),
            onTap: () async {
              await StatisticsSampleDataSeeder.clearSampleData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistik-Beispieldaten wurden entfernt.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NutritionDeveloperLabScreen extends StatelessWidget {
  const _NutritionDeveloperLabScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GlobalAppBar(title: 'Nutrition Lab'),
    body: const NutritionDeveloperLabView(),
  );
}

class _AiMealScanLogsScreen extends StatelessWidget {
  const _AiMealScanLogsScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.aiScanLogsTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.spacingL,
          MediaQuery.paddingOf(context).top +
              kToolbarHeight +
              DesignConstants.spacingS,
          DesignConstants.spacingL,
          DesignConstants.spacingXL,
        ),
        children: const [AiMealScanLogsSection(showHeader: false)],
      ),
    );
  }
}
