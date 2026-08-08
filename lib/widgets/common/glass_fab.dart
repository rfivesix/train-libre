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

    final iconAndText = Padding(
      padding: hasLabel
          ? const EdgeInsets.symmetric(horizontal: DesignConstants.spacingXL)
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
            const SizedBox(width: DesignConstants.spacingM),
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

    final Widget content = GlassAdaptiveScope(
      maxQuality: DesignConstants.defaultGlassQuality,
      minQuality: DesignConstants.minGlassQuality,
      child: RepaintBoundary(
        child: GlassContainer(
          useOwnLayer: true,
          height: DesignConstants.fabSize,
          width: hasLabel ? null : DesignConstants.fabSize,
          shape: hasLabel
              ? LiquidRoundedSuperellipse(borderRadius: DesignConstants.fabSize / 2)
              : const LiquidOval(),
          quality: DesignConstants.defaultGlassQuality,
          settings: DesignConstants.liquidGlassSettings(isDark),
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
