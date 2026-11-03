import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../theme/app_color_choice.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'app_color_settings_screen.dart';

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
              AppSettingsRow(
                title: l10n.settingsAppColorTitle,
                subtitle: _appColorLabel(l10n, themeService),
                leading: Icon(
                  LucideIcons.palette,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AppColorSettingsScreen(showSystemColors: isAndroid),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ColorPreview(
                      choice: themeService.appColorChoice,
                      customColor: themeService.customAppColor,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevron_right,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
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

  String _appColorLabel(AppLocalizations l10n, ThemeService service) {
    if (service.appColorChoice == AppColorChoice.custom) {
      final value = service.customAppColor.toARGB32().toRadixString(16);
      return '#${value.substring(value.length - 6).toUpperCase()}';
    }
    return switch (service.appColorChoice) {
      AppColorChoice.trainLibre => l10n.appColorPresetTrainLibre,
      AppColorChoice.monochrome => l10n.appColorPresetMonochrome,
      AppColorChoice.blue => l10n.appColorPresetBlue,
      AppColorChoice.teal => l10n.appColorPresetTeal,
      AppColorChoice.purple => l10n.appColorPresetPurple,
      AppColorChoice.orange => l10n.appColorPresetOrange,
      AppColorChoice.rose => l10n.appColorPresetRose,
      AppColorChoice.custom => l10n.appColorPresetCustom,
      AppColorChoice.system => l10n.appColorPresetSystem,
    };
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.choice, required this.customColor});

  final AppColorChoice choice;
  final Color customColor;

  @override
  Widget build(BuildContext context) {
    final light = choice.primary(
      brightness: Brightness.light,
      customColor: customColor,
      systemColor: Theme.of(context).colorScheme.primary,
    );
    final dark = choice.primary(
      brightness: Brightness.dark,
      customColor: customColor,
      systemColor: Theme.of(context).colorScheme.primary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ColorDot(color: light, size: 15),
        const SizedBox(width: 4),
        _ColorDot(color: dark, size: 15),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
