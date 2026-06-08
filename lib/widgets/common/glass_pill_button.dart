import 'package:flutter/material.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Reusable liquid-glass Pill / Bubble.
/// - Use [child] to place arbitrary content (icon, text, multiple elements).
/// - When [onTap] is set: light scale effect + HapticFeedback.
/// - When [onTap] is null: surface only; inner widgets can have their own gestures.
/// A reusable pill-shaped button with a glass aesthetic.
///
/// Supports both simple icons and complex [child] layouts with optional [onTap] feedback.
class GlassPillButton extends StatefulWidget {
  /// The content to display inside the pill.
  final Widget child;

  /// Optional callback for tap events; if null, the button is non-interactive.
  final VoidCallback? onTap;

  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// Fixed height of the pill.
  final double height;

  /// Corner radius for the pill shape.
  final double borderRadius;

  const GlassPillButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.height = 32,
    this.borderRadius = 99,
  });

  @override
  State<GlassPillButton> createState() => _GlassPillButtonState();
}

class _GlassPillButtonState extends State<GlassPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _hasTap => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.10,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_hasTap) _controller.forward();
  }

  void _onTapCancel() {
    if (_hasTap) _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    if (_hasTap) {
      _controller.reverse();
      HapticFeedbackService.instance.lightImpact();
      widget.onTap!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rimColor = cs.onSurface.withValues(alpha: 0.08);

    final Color neutralTint = DesignConstants.glassNeutralTint(isDark);

    // The radius is half the height to create a stadium (pill) shape.
    final double effectiveRadius = widget.height / 2;

    Widget surface = Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: ShadowOuterClipper(borderRadius: effectiveRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(effectiveRadius),
                boxShadow: DesignConstants.glassShadow,
              ),
            ),
          ),
        ),
        AdaptiveGlass(
          settings: DesignConstants.liquidGlassSettings(isDark),
          shape: LiquidRoundedSuperellipse(borderRadius: effectiveRadius),
          quality: GlassQuality.premium,
          child: GlassGlow(
            glowColor: Colors.white.withValues(alpha: isDark ? 0.24 : 0.18),
            glowRadius: 1.0,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: neutralTint,
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(effectiveRadius),
                border: Border.all(
                  color: rimColor,
                  width: 1.2,
                ),
              ),
              child: Center(
                widthFactor: 1.0,
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );

    // Wrap the surface in a SizedBox to enforce height but allow dynamic width
    final Widget constrainedSurface = SizedBox(
      height: widget.height,
      child: surface,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _hasTap ? _onTapDown : null,
      onTapUp: _hasTap ? _onTapUp : null,
      onTapCancel: _hasTap ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: constrainedSurface,
      ),
    );
  }
}
