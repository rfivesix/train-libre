import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'developer_lab_screen.dart';
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
            child: Column(
              children: [
                _DeveloperRow(
                  tileKey: const Key('developer_lab'),
                  icon: LucideIcons.flask_conical,
                  title: l10n.developerLabTitle,
                  subtitle: l10n.developerLabSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeveloperLabScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _DeveloperRow(
                  tileKey: const Key('developer_performance_log'),
                  icon: LucideIcons.activity,
                  title: l10n.settingsPerformanceLogTitle,
                  subtitle: l10n.settingsPerformanceLogSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const PerformanceDiagnosticsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperRow extends StatelessWidget {
  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DeveloperRow({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      contentPadding: DesignConstants.screenPadding,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(LucideIcons.chevron_right),
      onTap: onTap,
    );
  }
}
