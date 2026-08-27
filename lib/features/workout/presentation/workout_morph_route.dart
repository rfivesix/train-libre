import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../util/design_constants.dart';

/// Route that grows the live workout screen out of the minimized running
/// workout bar and, on pop, shrinks it back into it.
///
/// Modelled on the way iOS opens an app from its icon, which is four things
/// happening at once rather than one:
///
/// 1. The container grows from the pill to the screen, its corners flattening
///    a little ahead of the growth.
/// 2. The content *scales* into place instead of standing still behind a
///    widening window — a static slice of the page showing through a pill is
///    what makes a container transform look cheap.
/// 3. The two representations cross-fade: the pill starts opaque in the bar's
///    own tone and the page dissolves in over the first frames, so it never
///    reads as "a hole punched into the workout screen".
/// 4. What is left behind dims, which is what gives the whole thing depth.
///
/// The page is always laid out full screen and only ever transformed and
/// clipped, so nothing relayouts per frame, and the cross-fade is a plain
/// colour draw rather than an `Opacity` layer — a full-screen `saveLayer` on
/// every frame is exactly the kind of raster cost this app cannot afford.
class WorkoutMorphRoute<T> extends PageRouteBuilder<T> {
  WorkoutMorphRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _WorkoutMorphTransition(animation: animation, child: child),
        );
}

/// Opening: the design's own easing (`cubic-bezier(.32,.72,0,1)`). Covers half
/// the distance in the first sixth of the duration and then glides, which is
/// the shape every iOS presentation has.
const Curve _kExpandCurve = Cubic(0.32, 0.72, 0.0, 1.0);

/// Closing is the mirror, not the rewind: the page detaches at once and settles
/// gently into the bar. Playing [_kExpandCurve] backwards would slam it home.
const Curve _kCollapseCurve = FlippedCurve(_kExpandCurve);

/// The corners are done flattening once the growth is this far along.
const double _kRadiusLead = 1.35;

/// Fraction of the transition the cross-fade between bar tone and page takes.
const double _kCrossFade = 0.28;

/// How dark the screen left behind gets at full expansion.
const double _kScrimOpacity = 0.45;

class _WorkoutMorphTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _WorkoutMorphTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size screen = MediaQuery.sizeOf(context);
    final Rect barRect = DesignConstants.workoutOverlayRect(screen);
    final Rect fullRect = Offset.zero & screen;

    // Devices with a home indicator have rounded displays. Ending the morph on
    // square corners there makes the last frames snap into a rectangle, which
    // is the single most obvious tell that this is not a system transition.
    final double screenRadius =
        MediaQuery.viewPaddingOf(context).bottom > 0 ? 44.0 : 0.0;

    // What the glass bar renders as over the app background. Only ever seen
    // for the ~140ms of the cross-fade, at pill size, so a close approximation
    // is enough — it just has to not be a hole.
    final bool isDark = theme.brightness == Brightness.dark;
    final Color barTone = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
      theme.scaffoldBackgroundColor,
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final double raw = animation.value.clamp(0.0, 1.0);
        if (raw >= 1.0) return page!;

        // Safe to pick by direction: this route has no back-swipe, so the only
        // reversal starts from a settled state, where both curves agree.
        final Curve curve = animation.status == AnimationStatus.reverse
            ? _kCollapseCurve
            : _kExpandCurve;
        final double t = curve.transform(raw);

        final Rect rect = Rect.lerp(barRect, fullRect, t)!;
        final double radius = lerpDouble(
          DesignConstants.workoutOverlayRadius,
          screenRadius,
          (t * _kRadiusLead).clamp(0.0, 1.0),
        )!;

        // Container transform proper: the page is scaled by the container's
        // own width ratio and pinned to its top-left corner, so it fills the
        // pill exactly and grows with it. At the pill end that means the bar
        // shows the *top* of the workout screen — its header, right where the
        // bar's own chevron sits — instead of an arbitrary slice of the set
        // list, which was the real reason the old version read as a hole
        // punched into the page rather than a morph.
        //
        // Uniform scale keeps the aspect ratio; the overflow past the pill's
        // bottom edge is simply clipped. Coverage is therefore exact at every
        // frame, with no need to ease the scale ahead of the container.
        final double scale = rect.width / screen.width;

        final double fill = 1.0 - (raw / _kCrossFade).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black.withValues(alpha: t * _kScrimOpacity),
            ),
            ClipRRect(
              clipper: _MorphClipper(rect: rect, radius: radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(rect.left, rect.top, 0.0, 1.0)
                      ..scaleByDouble(scale, scale, 1.0, 1.0),
                    child: page,
                  ),
                  if (fill > 0.001)
                    ColoredBox(color: barTone.withValues(alpha: fill)),
                ],
              ),
            ),
          ],
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
