import 'package:material_ui/material_ui.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../util/glass_preferences.dart';

/// The shared four-tab navigation surface used by the app and its preview.
class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    required this.selectedIndex,
    required this.onTabSelected,
    this.diaryKey,
    this.workoutKey,
    this.statisticsKey,
    this.nutritionKey,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Key? diaryKey;
  final Key? workoutKey;
  final Key? statisticsKey;
  final Key? nutritionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final preferences = GlassPreferences.of(context);
    return GlassTabBar.bottom(
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      barHeight: DesignConstants.bottomNavigationBarHeight,
      barBorderRadius: GlassDefaults.capsuleRadius,
      indicatorBorderRadius: GlassDefaults.capsuleRadius,
      tabWidth: null,
      horizontalPadding: 0,
      verticalPadding: 0,
      quality: DesignConstants.defaultGlassQuality,
      indicatorExpansion: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      selectedIconColor: theme.colorScheme.primary,
      unselectedIconColor: isDark ? Colors.white : Colors.black,
      indicatorColor: DesignConstants.floatingBarPillColor(isDark),
      settings: preferences.apply(
        DesignConstants.liquidGlassSettings(isDark),
        premium: true,
      ),
      tabs: [
        GlassTab(
          label: l10n.diary,
          icon: Icon(LucideIcons.notebook, key: diaryKey),
          activeIcon: const Icon(LucideIcons.notebook),
        ),
        GlassTab(
          label: l10n.workout,
          icon: Icon(LucideIcons.dumbbell, key: workoutKey),
          activeIcon: const Icon(LucideIcons.dumbbell),
        ),
        GlassTab(
          label: l10n.statistics,
          icon: Icon(LucideIcons.chart_no_axes_column, key: statisticsKey),
          activeIcon: const Icon(LucideIcons.chart_no_axes_column),
        ),
        GlassTab(
          label: l10n.nutrition,
          icon: Icon(LucideIcons.utensils, key: nutritionKey),
          activeIcon: const Icon(LucideIcons.utensils),
        ),
      ],
    );
  }
}
