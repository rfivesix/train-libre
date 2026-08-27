import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../util/design_constants.dart';

/// Route that grows the live workout screen out of the minimized running
/// workout bar and, on pop, shrinks it back into it.
///
/// The page itself is always laid out full screen; only its painting is
/// clipped to a rounded rect that expands from the bar's pill to the whole
/// screen. That keeps the transition free of relayouts — and free of a
/// full-screen `Opacity` layer, which would cost a `saveLayer` on every frame
/// of the animation.
class WorkoutMorphRoute<T> extends PageRouteBuilder<T> {
  WorkoutMorphRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _WorkoutMorphTransition(animation: animation, child: child),
        );
}

/// The design's easing (`cubic-bezier(.32,.72,0,1)`). Applied unchanged in
/// both directions so an interrupted transition never jumps.
const Curve _morphCurve = Cubic(0.32, 0.72, 0.0, 1.0);

class _WorkoutMorphTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _WorkoutMorphTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final Rect barRect = DesignConstants.workoutOverlayRect(screen);
    final Rect fullRect = Offset.zero & screen;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final double t = _morphCurve.transform(
          animation.value.clamp(0.0, 1.0),
        );
        if (t >= 1.0) return page!;
        return ClipRRect(
          clipper: _MorphClipper(
            rect: Rect.lerp(barRect, fullRect, t)!,
            radius: lerpDouble(DesignConstants.workoutOverlayRadius, 0.0, t)!,
          ),
          child: page,
        );
      },
    );
  }
}

class _MorphClipper extends CustomClipper<RRect> {
  final Rect rect;
  final double radius;

  const _MorphClipper({required this.rect, required this.radius});

  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  bool shouldReclip(_MorphClipper oldClipper) =>
      oldClipper.rect != rect || oldClipper.radius != radius;
}
