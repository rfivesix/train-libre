import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/main_navigation_bar.dart';

/// Controls the shared glass appearance and previews it over a colorful scene.
class LiquidGlassSettingsSection extends StatelessWidget {
  const LiquidGlassSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<ThemeService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.glassCustomizationTitle),
        const _GlassPreview(),
        const SizedBox(height: 16),
        _GlassSlider(
          label: l10n.glassTint,
          value: service.glassAppearance,
          clearLabel: l10n.glassTintClear,
          tintedLabel: l10n.glassTintTinted,
          resetLabel: l10n.glassReset,
          onChanged: service.setGlassAppearance,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.glassCustomizationDescription,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _GlassSlider extends StatelessWidget {
  const _GlassSlider({
    required this.label,
    required this.value,
    required this.clearLabel,
    required this.tintedLabel,
    required this.resetLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String clearLabel;
  final String tintedLabel;
  final String resetLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            TextButton(
              onPressed: value == 0.5 ? null : () => onChanged(0.5),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(resetLabel),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value.clamp(0, 1),
            min: 0,
            max: 1,
            label: '$percentage%',
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(clearLabel, style: theme.textTheme.bodySmall),
              Text(tintedLabel, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassPreview extends StatelessWidget {
  const _GlassPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 154,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _PreviewContent(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Material(
                      type: MaterialType.transparency,
                      child: DefaultTextStyle(
                        style: DesignConstants.floatingBarLabelStyle,
                        child: GlassAdaptiveScope(
                          maxQuality: DesignConstants.defaultGlassQuality,
                          minQuality: DesignConstants.minGlassQuality,
                          child: SizedBox(
                            height: DesignConstants.bottomNavigationBarHeight,
                            child: MainNavigationBar(
                              selectedIndex: 1,
                              onTabSelected: _ignoreTab,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _ignoreTab(int _) {}
}

/// A flat, app-like background with text and a small accent behind the glass.
class _PreviewContent extends StatelessWidget {
  const _PreviewContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1B1B1E)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExcludeSemantics(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.today,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.startWorkout,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SizedBox(
                        width: 42,
                        height: 28,
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  l10n.workout,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
