import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
          SummaryCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignConstants.spacingL),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sun_moon),
                      const SizedBox(width: DesignConstants.spacingL),
                      Expanded(
                        child: PlatformAdaptiveDropdownFormField<ThemeMode>(
                          key: ValueKey(themeService.themeMode),
                          value: themeService.themeMode,
                          decoration: InputDecoration(
                            labelText: l10n.settingsAppearance,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.spacingM,
                              vertical: DesignConstants.spacingS,
                            ),
                          ),
                          items: ThemeMode.values
                              .map(
                                (mode) => DropdownMenuItem<ThemeMode>(
                                  value: mode,
                                  child: Text(_themeModeLabel(l10n, mode)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            themeService.setThemeMode(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAndroid) ...[
                  const Divider(height: 1),
                  PlatformAdaptiveSwitchListTile(
                    secondary: const Icon(LucideIcons.palette),
                    title: Text(
                      l10n.settingsMaterialColorsTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.settingsMaterialColorsSubtitle),
                    value: themeService.materialColorsEnabled,
                    onChanged: (value) =>
                        themeService.setMaterialColorsEnabled(value),
                  ),
                ],
                const Divider(height: 1),
                PlatformAdaptiveSwitchListTile(
                  secondary: const Icon(LucideIcons.vibrate),
                  title: Text(
                    l10n.settingsHapticFeedbackTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(l10n.settingsHapticFeedbackSubtitle),
                  value: themeService.hapticsEnabled,
                  onChanged: (value) => themeService.setHapticsEnabled(value),
                ),
              ],
            ),
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
