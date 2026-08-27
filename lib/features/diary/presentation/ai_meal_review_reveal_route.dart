// lib/features/diary/presentation/ai_meal_review_reveal_route.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Slow-motion debugging switch:
/// Set to 10.0 for 10x slow-motion. Set back to 1.0 for normal speed.
const double kAiMealReviewRevealDebugSlowdown = 1.0;

/// Custom PageRoute that:
/// 1. Takes the solid, hard contracted circle at t=0, bursts it into 12 organic
///    vapor puffs that start crisp, quickly soften into blurry mist, swell, and
///    evaporate as they scatter outward away from the center.
/// 2. Smoothly uncovers [AiMealReviewScreen] as the center immediately clears out.
/// 3. Pops cleanly with a standard soft fade (never reversing into a cloud on save/cancel).
class AiMealReviewRevealRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Offset? originCenter;
  final Duration _duration;

  AiMealReviewRevealRoute({
    required this.builder,
    this.originCenter,
    super.settings,
    Duration? duration,
  }) : _duration = duration ??
            Duration(
              milliseconds: (500 * kAiMealReviewRevealDebugSlowdown).round(),
            );

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // When popping / saving / dismissing: clean standard soft fade out!
    if (animation.status == AnimationStatus.reverse) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    }

    final Size screen = MediaQuery.sizeOf(context);
    final Offset center =
        originCenter ?? Offset(screen.width / 2, screen.height * 0.40);

    return _CloudVaporRevealTransition(
      animation: animation,
      center: center,
      child: child,
    );
  }
}

class _CloudVaporRevealTransition extends StatelessWidget {
  final Animation<double> animation;
  final Offset center;
  final Widget child;

  const _CloudVaporRevealTransition({
    required this.animation,
    required this.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Size screen = MediaQuery.sizeOf(context);
    final double orbSize = (screen.width * 0.78).clamp(260.0, 360.0);
    final double coreRadius = (124.0 * (orbSize / 280.0)) / 2;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final double raw = animation.value.clamp(0.0, 1.0);
        if (raw >= 1.0) return page!;

        final double t = Curves.easeOutCubic.transform(raw);

        // Review screen materialization
        final double pageOpacity = Curves.easeInCubic.transform(t);
        final double pageScale = 0.96 + (0.04 * t);
        final double pageSlideY = (1.0 - t) * 10.0;

        // Global vapor opacity (dissipates to 0)
        final double vaporOpacity =
            (1.0 - math.pow(raw, 0.75)).clamp(0.0, 1.0).toDouble();

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Destination Review Page emerging cleanly from beneath the dispersing vapor
            Opacity(
              opacity: pageOpacity,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translateByDouble(0.0, pageSlideY, 0.0, 1.0)
                  ..scaleByDouble(pageScale, pageScale, 1.0, 1.0),
                child: page,
              ),
            ),

            // 2. Dynamic Organic Vapor Puffs dispersing outward and evaporating
            if (vaporOpacity > 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _OrganicVaporDispersePainter(
                      center: center,
                      t: t,
                      opacity: vaporOpacity,
                      coreRadius: coreRadius,
                      primaryColor: theme.colorScheme.primary,
                      baseColor:
                          isDark ? Colors.white : const Color(0xFF09090B),
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VaporPuffSpec {
  final double angle;
  final double speed;
  final double baseRadiusFraction;
  final double growthPeak;
  final double accentBlend;

  const _VaporPuffSpec({
    required this.angle,
    required this.speed,
    required this.baseRadiusFraction,
    required this.growthPeak,
    required this.accentBlend,
  });
}

class _OrganicVaporDispersePainter extends CustomPainter {
  final Offset center;
  final double t;
  final double opacity;
  final double coreRadius;
  final Color primaryColor;
  final Color baseColor;
  final bool isDark;

  // 12 deterministic organic puff trajectories with unique angles, speeds and dynamics
  static final List<_VaporPuffSpec> _specs = [
    const _VaporPuffSpec(
        angle: 0.05,
        speed: 1.15,
        baseRadiusFraction: 0.85,
        growthPeak: 1.45,
        accentBlend: 0.20),
    const _VaporPuffSpec(
        angle: 0.58,
        speed: 0.90,
        baseRadiusFraction: 0.70,
        growthPeak: 1.30,
        accentBlend: 0.45),
    const _VaporPuffSpec(
        angle: 1.12,
        speed: 1.30,
        baseRadiusFraction: 0.95,
        growthPeak: 1.50,
        accentBlend: 0.15),
    const _VaporPuffSpec(
        angle: 1.65,
        speed: 0.85,
        baseRadiusFraction: 0.75,
        growthPeak: 1.35,
        accentBlend: 0.35),
    const _VaporPuffSpec(
        angle: 2.18,
        speed: 1.20,
        baseRadiusFraction: 0.90,
        growthPeak: 1.40,
        accentBlend: 0.25),
    const _VaporPuffSpec(
        angle: 2.72,
        speed: 1.05,
        baseRadiusFraction: 0.80,
        growthPeak: 1.38,
        accentBlend: 0.40),
    const _VaporPuffSpec(
        angle: 3.25,
        speed: 1.25,
        baseRadiusFraction: 0.88,
        growthPeak: 1.48,
        accentBlend: 0.18),
    const _VaporPuffSpec(
        angle: 3.78,
        speed: 0.95,
        baseRadiusFraction: 0.72,
        growthPeak: 1.32,
        accentBlend: 0.50),
    const _VaporPuffSpec(
        angle: 4.31,
        speed: 1.35,
        baseRadiusFraction: 0.92,
        growthPeak: 1.55,
        accentBlend: 0.12),
    const _VaporPuffSpec(
        angle: 4.84,
        speed: 0.88,
        baseRadiusFraction: 0.78,
        growthPeak: 1.36,
        accentBlend: 0.38),
    const _VaporPuffSpec(
        angle: 5.37,
        speed: 1.18,
        baseRadiusFraction: 0.86,
        growthPeak: 1.42,
        accentBlend: 0.22),
    const _VaporPuffSpec(
        angle: 5.90,
        speed: 1.02,
        baseRadiusFraction: 0.82,
        growthPeak: 1.39,
        accentBlend: 0.30),
  ];

  const _OrganicVaporDispersePainter({
    required this.center,
    required this.t,
    required this.opacity,
    required this.coreRadius,
    required this.primaryColor,
    required this.baseColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;

    final maxDistance = size.width * 0.50;

    // Blur starts strictly at 0.0 (crisp, hard, solid edge on first frame) and softens rapidly
    final double blurSigma =
        t <= 0.001 ? 0.0 : (26.0 * math.pow(t, 0.45)).clamp(0.0, 36.0);

    // 12 dispersing organic vapor puffs that start at center as a solid circle and scatter outward
    for (final spec in _specs) {
      final distance = spec.speed * maxDistance * t;
      final puffCenter = Offset(
        center.dx + math.cos(spec.angle) * distance,
        center.dy + math.sin(spec.angle) * distance,
      );

      // Dynamics: swells up initially (0.0 -> 0.35), then thins and shrinks away (0.35 -> 1.0)
      final double sizeFactor;
      if (t < 0.35) {
        final localT = t / 0.35;
        sizeFactor = 1.0 +
            (spec.growthPeak - 1.0) * Curves.easeOutQuad.transform(localT);
      } else {
        final localT = (t - 0.35) / 0.65;
        sizeFactor = spec.growthPeak *
            (1.0 - 0.80 * Curves.easeInQuad.transform(localT));
      }

      final puffRadius = coreRadius * spec.baseRadiusFraction * sizeFactor;
      final puffColor = Color.lerp(baseColor, primaryColor, spec.accentBlend)!;
      final puffAlpha = (opacity * (1.0 - 0.55 * t)).clamp(0.0, 1.0);

      final puffPaint = Paint()
        ..color =
            puffColor.withValues(alpha: puffAlpha * (isDark ? 0.90 : 0.85));

      if (blurSigma > 0.5) {
        puffPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      }

      canvas.drawCircle(puffCenter, puffRadius, puffPaint);
    }
  }

  @override
  bool shouldRepaint(_OrganicVaporDispersePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.opacity != opacity ||
      oldDelegate.center != center;
}
