import 'package:flutter/material.dart';

/// A simple pulsing skeleton building block.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.04);
    final highlightColor = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.08);

    _colorAnimation = ColorTween(
      begin: baseColor,
      end: highlightColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

/// A pre-styled skeleton row for text placeholders.
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
