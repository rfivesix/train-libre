import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/platform_adaptive_slider.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/main_navigation_bar.dart';
import '../../diary/presentation/widgets/ai_camera_preview_fallbacks.dart';

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
        PlatformAdaptiveSlider(
          value: value.clamp(0, 1),
          min: 0,
          max: 1,
          label: '$percentage%',
          semanticLabel: label,
          semanticValue: '$percentage%',
          semanticFormatter: (value) => '${(value * 100).round()}%',
          onChanged: onChanged,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1B1B1E)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            right: 18,
            top: 22,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 0.72,
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: 108,
                    child: AiSimulatorCameraDemo(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 10,
            child: ExcludeSemantics(
              child: CustomPaint(
                key: const ValueKey('glass-preview-food-accent'),
                size: const Size(132, 134),
                painter: _FoodAccentPainter(colors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small herb sprig, echoing the simple shapes in the food illustration.
class _FoodAccentPainter extends CustomPainter {
  const _FoodAccentPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 112, size.height / 76);
    final stem = Path()
      ..moveTo(15, 67)
      ..quadraticBezierTo(49, 46, 94, 12);
    canvas.drawPath(
      stem,
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    void leaf(Offset center, double angle, Color color) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 30, height: 15),
        Paint()..color = color,
      );
      canvas.restore();
    }

    leaf(const Offset(37, 45), 0.45, const Color(0xFF678249));
    leaf(const Offset(52, 44), -0.65, accent.withValues(alpha: 0.75));
    leaf(const Offset(66, 24), 0.45, const Color(0xFF719352));
    leaf(const Offset(81, 23), -0.65, accent.withValues(alpha: 0.6));
    canvas.drawCircle(
      const Offset(24, 56),
      4,
      Paint()..color = const Color(0xFFE8AE58),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FoodAccentPainter oldDelegate) =>
      accent != oldDelegate.accent;
}
