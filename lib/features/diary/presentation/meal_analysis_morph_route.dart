// lib/features/diary/presentation/meal_analysis_morph_route.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Slow-motion debugging switch:
/// Set to 10.0 for 10x slow-motion. Set back to 1.0 for normal speed.
const double kMealAnalysisMorphDebugSlowdown = 1.0;

/// A custom container morph route that transitions the "Analyze" button:
/// 1. Contracts into a compact circle as it glides up to the center.
/// 2. Warps/blooms from the circle into the living neural cloud orb.
class MealAnalysisMorphRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Rect? sourceRect;
  final BuildContext? sourceContext;
  final Duration _duration;

  MealAnalysisMorphRoute({
    required this.builder,
    this.sourceRect,
    this.sourceContext,
    super.settings,
    Duration? duration,
  }) : _duration = duration ??
            Duration(
              milliseconds: (480 * kMealAnalysisMorphDebugSlowdown).round(),
            );

  @override
  bool get opaque => true;

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

  Rect? _cachedSourceRect;

  static Rect? measureRect(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      return null;
    }
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

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
    if (animation.status == AnimationStatus.reverse) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    }

    _cachedSourceRect ??= sourceRect ?? measureRect(sourceContext);
    final Size screen = MediaQuery.sizeOf(context);

    final Rect startRect = _cachedSourceRect ??
        Rect.fromLTWH(
          16,
          screen.height - 70,
          screen.width - 32,
          46,
        );

    return _MealAnalysisMorphTransition(
      animation: animation,
      sourceRect: startRect,
      child: child,
    );
  }
}

class _MealAnalysisMorphTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect sourceRect;
  final Widget child;

  const _MealAnalysisMorphTransition({
    required this.animation,
    required this.sourceRect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Size screen = MediaQuery.sizeOf(context);

    final double orbSize = (screen.width * 0.78).clamp(260.0, 360.0);
    final Offset cloudCenter = Offset(screen.width / 2, screen.height * 0.40);
    final double circleDiameter = 124.0 * (orbSize / 280.0);

    final Color accentColor = theme.colorScheme.primary;
    final Color circleColor = isDark ? Colors.white : const Color(0xFF09090B);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final double raw = animation.value.clamp(0.0, 1.0);
        // Only reveal the actual destination page when the flight reaches 1.0
        // This guarantees strictly ONE circle is visible during the entire flight.
        if (raw >= 1.0) return page!;

        final double t = Curves.easeInOutCubic.transform(raw);

        // Position: glides smoothly from sourceRect.center to cloudCenter
        final Offset currentCenter = Offset.lerp(
          sourceRect.center,
          cloudCenter,
          t,
        )!;

        // Size: contracts smoothly from button bounds to exact circleDiameter
        final double currentWidth = lerpDouble(
          sourceRect.width,
          circleDiameter,
          Curves.easeOutCubic.transform(t),
        )!;

        final double currentHeight = lerpDouble(
          sourceRect.height,
          circleDiameter,
          Curves.easeOutCubic.transform(t),
        )!;

        final double currentRadius = math.min(currentWidth, currentHeight) / 2;

        // Button text / icon fades out early in flight
        final double buttonContentOpacity = (1.0 - (t / 0.25)).clamp(0.0, 1.0);

        // Color transition from button accent to circle color
        final Color currentColor = Color.lerp(
          accentColor,
          circleColor,
          t,
        )!;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Atmosphere backdrop fading in
            Opacity(
              opacity: t,
              child: ColoredBox(
                color:
                    isDark ? const Color(0xFF07090E) : const Color(0xFFF8FAFC),
              ),
            ),

            // 2. The ONLY morphing button-to-circle shape gliding from bottom to center
            Positioned(
              left: currentCenter.dx - (currentWidth / 2),
              top: currentCenter.dy - (currentHeight / 2),
              width: currentWidth,
              height: currentHeight,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Base circle / pill
                  Container(
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(currentRadius),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha: (1.0 - t) * 0.35,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  // Button Text & Icon (fades out as it contracts into circle)
                  if (buttonContentOpacity > 0.0)
                    Opacity(
                      opacity: buttonContentOpacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 18,
                            color:
                                isDark ? const Color(0xFF12120F) : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Analysieren',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark
                                  ? const Color(0xFF12120F)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
