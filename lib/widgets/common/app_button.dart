import 'package:flutter/material.dart';
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
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.primary;
        borderSide = BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        );
        break;
      case AppButtonVariant.danger:
        backgroundColor = DesignConstants.brandRedColor;
        foregroundColor = Colors.white;
        break;
    }

    if (!isEnabled) {
      backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);
      foregroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);
      if (widget.variant == AppButtonVariant.secondary) {
        backgroundColor = Colors.transparent;
        borderSide = BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        );
      }
    }

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

    Widget buttonContent = Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: borderSide.style != BorderStyle.none
            ? Border.fromBorderSide(borderSide)
            : null,
      ),
      padding: padding,
      child: Row(
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
      ),
    );

    final semanticLabelStr =
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
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: child,
              ),
            );
          },
          child: buttonContent,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: semanticButton,
      );
    }
    return semanticButton;
  }
}
