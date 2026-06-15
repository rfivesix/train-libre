import 'package:flutter/material.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A floating action button with a premium glass aesthetic.
///
/// Can be displayed as a circle (icon only) or a pill (icon and [label]).
class GlassFab extends StatefulWidget {
  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// The icon to display.
  final IconData icon;

  /// Optional label to display next to the icon, turning the FAB into a pill.
  final String? label;

  const GlassFab({
    super.key,
    required this.onPressed,
    this.icon = LucideIcons.plus,
    this.label,
  });

  @override
  State<GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<GlassFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedbackService.instance.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLabel = widget.label != null;
    final Color neutralTint = DesignConstants.glassNeutralTint(isDark);

    final iconAndText = Padding(
      padding: hasLabel
          ? const EdgeInsets.symmetric(horizontal: 24.0)
          : EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: 30,
            color: isDark ? Colors.white : Colors.black,
          ),
          if (hasLabel) ...[
            const SizedBox(width: 12),
            Text(
              widget.label!,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ],
      ),
    );

    final double effectiveRadius = hasLabel ? 37.0 : 999.0;
    final Widget content = Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: ShadowOuterClipper(
              borderRadius: effectiveRadius,
              isOval: !hasLabel,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(effectiveRadius),
                boxShadow: DesignConstants.glassShadow,
              ),
            ),
          ),
        ),
        GlassAdaptiveScope(
          minQuality: GlassQuality.premium,
          maxQuality: GlassQuality.premium,
          child: RepaintBoundary(
            child: AdaptiveGlass(
              settings: DesignConstants.liquidGlassSettings(isDark),
              shape: hasLabel
                  ? const LiquidRoundedSuperellipse(borderRadius: 37)
                  : const LiquidOval(),
              quality: GlassQuality.premium,
              child: GlassGlow(
                glowColor: Colors.white.withValues(alpha: isDark ? 0.24 : 0.18),
                glowRadius: 1.0,
                child: Container(
                  height: 74.0, // Match main screen bottom bar height
                  width: hasLabel ? null : 74.0,
                  decoration: BoxDecoration(
                    color: neutralTint,
                    borderRadius: BorderRadius.circular(effectiveRadius),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(effectiveRadius),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: hasLabel
                      ? iconAndText
                      : Center(
                          child: Icon(
                            widget.icon,
                            size: 30,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: IntrinsicWidth(child: content),
      ),
    );
  }
}
