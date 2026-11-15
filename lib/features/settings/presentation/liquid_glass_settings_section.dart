import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/app_settings_row.dart';
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
          label: l10n.glassBlur,
          value: service.glassBlur,
          zeroLabel: l10n.glassBlurOff,
          resetLabel: l10n.glassReset,
          onChanged: service.setGlassBlur,
        ),
        _GlassSlider(
          label: l10n.glassOpacity,
          value: service.glassOpacity,
          zeroLabel: l10n.glassOpacityClear,
          resetLabel: l10n.glassReset,
          onChanged: service.setGlassOpacity,
        ),
        AppSettingsRow.switchTile(
          title: l10n.glassLiquid,
          value: service.liquidGlassEnabled,
          onChanged: service.setLiquidGlassEnabled,
        ),
        AppSettingsRow.switchTile(
          title: l10n.glassRemoveBorder,
          value: service.glassBorderRemoved,
          onChanged: service.setGlassBorderRemoved,
        ),
        const SizedBox(height: 4),
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
    required this.zeroLabel,
    required this.resetLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String zeroLabel;
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
              onPressed: value == 1 ? null : () => onChanged(1),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(resetLabel),
            ),
            Text(
              percentage == 0 ? zeroLabel : '$percentage%',
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
            value: value.clamp(0, 2),
            min: 0,
            max: 2,
            divisions: 20,
            label: percentage == 0 ? zeroLabel : '$percentage%',
            onChanged: onChanged,
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
            const _PreviewDashboard(),
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

/// An abstract diary card: aligned rows and progress bars give the glass
/// meaningful, app-like content to blur without relying on personal data.
class _PreviewDashboard extends StatelessWidget {
  const _PreviewDashboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF30342D) : const Color(0xFFF7F5EC);
    final line = isDark ? Colors.white : Colors.black;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF20291B), const Color(0xFF101713)]
              : [const Color(0xFFDCE8BF), const Color(0xFFB6CCBA)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PreviewLine(
                      width: 80,
                      color: line.withValues(alpha: 0.65),
                    ),
                    const Spacer(),
                    _PreviewLine(width: 32, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PreviewMacro(
                          color: theme.colorScheme.primary,
                          fraction: .76,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: _PreviewMacro(
                          color: Color(0xFF72B5E5),
                          fraction: .57,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: _PreviewMacro(
                          color: Color(0xFFF1A96B),
                          fraction: .68,
                        ),
                      ),
                    ],
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

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.width, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 5,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class _PreviewMacro extends StatelessWidget {
  const _PreviewMacro({required this.color, required this.fraction});
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewLine(width: 24, color: color.withValues(alpha: .8)),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    ),
  );
}
