import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final themeService = Provider.of<ThemeService>(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.settingsAppearance),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          AppSectionHeader(title: l10n.settingsAppearance),
          Column(
            children: [
              PlatformAdaptivePopupMenu<ThemeMode>(
                selectedValue: themeService.themeMode,
                onSelected: (mode) => themeService.setThemeMode(mode),
                items: ThemeMode.values
                    .map(
                      (mode) => PlatformAdaptivePopupMenuItem<ThemeMode>(
                        value: mode,
                        label: _themeModeLabel(l10n, mode),
                      ),
                    )
                    .toList(growable: false),
                icon: AppSettingsRow.navigation(
                  title: l10n.settingsAppearance,
                  subtitle: _themeModeLabel(l10n, themeService.themeMode),
                  leading: Icon(
                    LucideIcons.sun_moon,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (isAndroid) ...[
                const Divider(height: 1),
                AppSettingsRow.switchTile(
                  title: l10n.settingsMaterialColorsTitle,
                  subtitle: l10n.settingsMaterialColorsSubtitle,
                  leading: Icon(
                    LucideIcons.palette,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  value: themeService.materialColorsEnabled,
                  onChanged: (value) =>
                      themeService.setMaterialColorsEnabled(value),
                ),
              ],
              const Divider(height: 1),
              AppSettingsRow.switchTile(
                title: l10n.settingsHapticFeedbackTitle,
                subtitle: l10n.settingsHapticFeedbackSubtitle,
                leading: Icon(
                  LucideIcons.vibrate,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                value: themeService.hapticsEnabled,
                onChanged: (value) => themeService.setHapticsEnabled(value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
  }
}
