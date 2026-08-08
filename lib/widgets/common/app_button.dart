import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';

enum AppButtonVariant { primary, secondary, danger }

enum AppButtonSize { regular, medium, small }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? tooltip;
  final String? semanticsLabel;
  final AppButtonVariant variant;
  final bool isLoading;
  final AppButtonSize size;

  const AppButton.primary({
    super.key,
    required this.label,
    this.tooltip,
    this.semanticsLabel,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = AppButtonSize.regular,
  })  : assert(tooltip != null || semanticsLabel != null,
            'Either tooltip or semanticsLabel must be provided'),
        variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.tooltip,
    this.semanticsLabel,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = AppButtonSize.regular,
  })  : assert(tooltip != null || semanticsLabel != null,
            'Either tooltip or semanticsLabel must be provided'),
        variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.tooltip,
    this.semanticsLabel,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = AppButtonSize.regular,
  })  : assert(tooltip != null || semanticsLabel != null,
            'Either tooltip or semanticsLabel must be provided'),
        variant = AppButtonVariant.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      if (widget.variant == AppButtonVariant.danger) {
        HapticFeedbackService.instance.chartSelectionFeedback();
      } else {
        HapticFeedbackService.instance.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final Color primaryColor = theme.colorScheme.primary;

    // ── Declare variables before switch scope ───────────────────────────────
    Color foregroundColor;
    LiquidGlassSettings glassSettings;
    Color glowColor;

    // ── Build the button configuration ──────────────────────────────────────
    switch (widget.variant) {
      case AppButtonVariant.primary:
        foregroundColor = theme.colorScheme.onPrimary;
        glassSettings = LiquidGlassSettings(
          thickness: 18, // Thinner glass = reduced gray refraction
          blur: 1.5, // Subtle blur for sharper colors
          glassColor: primaryColor.withValues(alpha: 0.35), // Transparent glass base
          lightIntensity: isDark ? 0.85 : 0.95, // High light intensity for clarity
          saturation: 1.60, // Enhanced saturation for vibrant tint
          ambientRim: 0.15,
        );
        glowColor = Colors.white.withValues(alpha: isDark ? 0.15 : 0.10);
        break;
      case AppButtonVariant.danger:
        foregroundColor = Colors.white;
        glassSettings = LiquidGlassSettings(
          thickness: 18,
          blur: 1.5,
          glassColor: DesignConstants.brandRedColor
              .withValues(alpha: 0.40), // Sattes Rot strahlt durch
          lightIntensity: isDark ? 0.80 : 0.90,
          saturation: 1.50,
          ambientRim: 0.10,
        );
        glowColor = Colors.white.withValues(alpha: isDark ? 0.15 : 0.10);
        break;
      case AppButtonVariant.secondary:
        foregroundColor = theme.colorScheme.primary;
        glassSettings = DesignConstants.liquidGlassSettings(isDark).copyWith(
          thickness: 15,
          blur: 1.5,
        );
        glowColor = Colors.white.withValues(alpha: isDark ? 0.10 : 0.05);
        break;
    }

    if (!isEnabled) {
      foregroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);
    }

    // ── Size tokens ─────────────────────────────────────────────────────────
    final double height;
    final EdgeInsets padding;
    final TextStyle? textStyle;
    final double iconSize;
    final double progressSize;
    switch (widget.size) {
      case AppButtonSize.regular:
        height = 48.0;
        padding = const EdgeInsets.symmetric(horizontal: 16.0);
        textStyle = theme.textTheme.labelLarge;
        iconSize = 20.0;
        progressSize = 18.0;
        break;
      case AppButtonSize.medium:
        height = 40.0;
        padding = const EdgeInsets.symmetric(horizontal: 12.0);
        textStyle = theme.textTheme.labelMedium;
        iconSize = 18.0;
        progressSize = 16.0;
        break;
      case AppButtonSize.small:
        height = 32.0;
        padding = const EdgeInsets.symmetric(horizontal: 8.0);
        textStyle = theme.textTheme.labelMedium;
        iconSize = 16.0;
        progressSize = 14.0;
        break;
    }

    const double radius = 14.0;

    // ── Build the button label/icon row ─────────────────────────────────────
    Widget labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: progressSize,
            height: progressSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 8.0),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, color: foregroundColor, size: iconSize),
          const SizedBox(width: 8.0),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: textStyle?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // ── Disabled state — flat container, no GPU cost ─────────────────────────
    Widget buttonContent;
    if (!isEnabled) {
      final disabledBg = widget.variant == AppButtonVariant.secondary
          ? Colors.transparent
          : theme.colorScheme.onSurface.withValues(alpha: 0.12);
      buttonContent = Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: disabledBg,
          borderRadius: BorderRadius.circular(radius),
          border: widget.variant == AppButtonVariant.secondary
              ? Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                )
              : null,
        ),
        child: labelRow,
      );
    } else {
      // ── Your custom Rim Color adaptation ───────────────────────────────────
      final Color rimColor = isDark
          ? Colors.grey.shade700
          : theme.colorScheme.onSurface.withValues(alpha: 0.1);
 
// Inner content container — carries the solid background, rim border, and labels
      final Widget innerContent = Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: widget.variant == AppButtonVariant.primary
              ? primaryColor
              : widget.variant == AppButtonVariant.danger
                  ? DesignConstants.brandRedColor
                  : primaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(radius),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: rimColor, width: 0.5),
        ),
        child: labelRow,
      );

      // ── Clean Glass Stack without any shadow ───────────────────────────────
      //
      // PERFORMANCE: the glass shader itself is cheap, but the `BackdropFilter`
      // it pushes is not. `AdaptiveGlass` runs the Standard renderer here
      // (quality defaults to `GlassQuality.standard`, so the global
      // `DesignConstants.defaultGlassQuality` scope never applies to buttons),
      // and `LightweightLiquidGlass` pushes one `BackdropFilterLayer` per
      // instance whenever `blur > 0`. Every such layer forces the rasterizer to
      // break the render pass and re-read the backdrop — on a tile-based iOS GPU
      // that means a full framebuffer store/load each time. On screens that show
      // several buttons at once (Nutrition Hub: recalculate + apply + goals +
      // one per recipe card) this dominated the raster thread and dropped
      // scrolling below 120 Hz on device, while a Mac's memory bandwidth hid it
      // completely.
      //
      // `InheritedLiquidGlass(isBlurProvidedByAncestor: true)` makes
      // `LightweightLiquidGlass` take its `skipBlur` path, so the shader still
      // paints tint, rim and Fresnel exactly as before but no backdrop layer is
      // pushed. `allowElevation: false` keeps `AdaptiveGlass` off its "elevated"
      // branch, which would otherwise boost lightIntensity/ambientStrength and
      // visibly change the button.
      //
      // This is visually safe because every button in the app sits on a flat,
      // near-neutral surface: a σ=1.5 blur over a flat area is the identity, and
      // the shader's saturation boost is a no-op on neutral pixels. Measured
      // delta versus the previous rendering is a single physical AA pixel on the
      // outer edge (1/3 logical px at 3×). Do NOT drop this optimisation for a
      // button placed over a photo, camera preview or other high-frequency
      // backdrop — there the missing blur would be visible.
      buttonContent = SizedBox(
        height: height,
        child: RepaintBoundary(
          child: InheritedLiquidGlass(
            settings: glassSettings,
            isBlurProvidedByAncestor: true,
            child: AdaptiveGlass(
              settings: glassSettings,
              allowElevation: false,
              shape: LiquidRoundedSuperellipse(borderRadius: radius),
              child: GlassGlow(
                glowColor: glowColor,
                glowRadius: 1.0,
                child: innerContent,
              ),
            ),
          ),
        ),
      );
    }

    // ── Semantics + gesture + animation ─────────────────────────────────────
    final String semanticLabelStr =
        widget.semanticsLabel ?? widget.tooltip ?? widget.label;

    Widget semanticButton = Semantics(
      label: semanticLabelStr,
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: buttonContent,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: semanticButton);
    }
    return semanticButton;
  }
}
