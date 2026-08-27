import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../util/design_constants.dart';

/// ---------------------------------------------------------------------------
/// SLOW MOTION — debug knob
///
/// Set this to e.g. `50` to play the morph fifty times slower and watch it
/// frame by frame, then set it back to `1`. It multiplies both durations and
/// nothing else, so the shape of the motion is exactly what ships.
///
/// Ignored in release builds, so forgetting to reset it cannot reach users.
/// ---------------------------------------------------------------------------
const double kWorkoutMorphTimeScale = 1.0;

/// Change these to retime the morph — [kWorkoutMorphTimeScale] is only for
/// looking at it.
const Duration _kExpandDuration = Duration(milliseconds: 700);
const Duration _kCollapseDuration = Duration(milliseconds: 600);

double get _timeScale => kDebugMode ? kWorkoutMorphTimeScale : 1.0;

/// True while a morph that draws its own copy of the running workout bar is in
/// flight. The real bar hides itself then, so the copy can move and fade
/// without the original sitting motionless underneath it.
final ValueNotifier<bool> workoutMorphSourceHidden = ValueNotifier<bool>(false);

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
/// 3. The two representations cross-fade: the page dissolves in over the bar
///    and back out of it, so it never reads as "a hole punched into the
///    workout screen".
/// 4. What is left behind dims, which is what gives the whole thing depth.
///
/// Which of the two does the fading is not a free choice. The bar is liquid
/// glass, and glass is a [BackdropFilterLayer] — it can only refract what was
/// painted into the save layer enclosing it. An `Opacity` *is* such a save
/// layer, and an empty one, so a fading bar has nothing to refract and renders
/// flat until its opacity reaches exactly 1.0, at which point Flutter stops
/// pushing the layer and the glass snaps in from nothing. Hence: the bar is
/// always drawn at full opacity and the page fades over it.
///
/// The page is always laid out full screen and only ever transformed, faded
/// and clipped, so nothing relayouts per frame. The fade is the only layer
/// pushed, it exists solely during the cross-fade window, and it sits *inside*
/// the clip — so its `saveLayer` is bounded by the pill rather than by the
/// screen.
class WorkoutMorphRoute<T> extends PageRouteBuilder<T> {
  WorkoutMorphRoute({
    required WidgetBuilder builder,
    this.sourceBuilder,
    super.settings,
  }) : super(
          transitionDuration: _kExpandDuration * _timeScale,
          reverseTransitionDuration: _kCollapseDuration * _timeScale,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        );

  /// Builds the widget the morph starts from — the running workout bar itself.
  ///
  /// Pass the *same* widget the screen renders behind this route, not a
  /// look-alike: the copy replaces the original for the length of the flight,
  /// so anything that differs shows up as a jump at one end or the other.
  ///
  /// Without it the page simply fades in over whatever is behind, which is all
  /// that can be done when the morph did not start from the bar — a deep link
  /// out of the Live Activity, say.
  final WidgetBuilder? sourceBuilder;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _WorkoutMorphTransition(
      animation: animation,
      sourceBuilder: sourceBuilder,
      child: child,
    );
  }

  @override
  void install() {
    super.install();
    if (sourceBuilder == null) return;
    // Deliberately one frame late: a route's content is not in the tree until
    // the frame after the push, so hiding the real bar any earlier leaves a
    // frame with no bar at all — a flicker right at the start of the morph.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isActive) _setSourceHidden(true);
    });
    animation?.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    // Hand back to the real bar the moment the collapse lands, not when the
    // route is eventually torn down. At this point the copy is still on
    // screen — at exactly the bar's position, size and opacity — so the two
    // overlap indistinguishably for a frame. Waiting for [dispose] instead
    // leaves a frame in which the copy is gone and the real bar has not been
    // rebuilt yet, and the bar blinks out just as it arrives.
    if (status == AnimationStatus.dismissed) _setSourceHidden(false);
  }

  @override
  void dispose() {
    if (sourceBuilder != null) {
      animation?.removeStatusListener(_handleAnimationStatus);
      // Safety net for the paths that never run the collapse at all, such as
      // finishing a workout, which replaces this route outright.
      _setSourceHidden(false);
    }
    super.dispose();
  }

  /// The copy and the original must never both be absent, nor both present.
  /// Routes are disposed from inside a frame, where flipping a listenable the
  /// screen depends on would rebuild a widget that has already been built.
  static void _setSourceHidden(bool value) {
    if (workoutMorphSourceHidden.value == value) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => workoutMorphSourceHidden.value = value,
      );
    } else {
      workoutMorphSourceHidden.value = value;
    }
  }
}

/// Opening. Eases in *and* out: 3% of the distance in the first tenth of the
/// duration, so there is no jump from a standstill, and the bulk of the move
/// spread across the middle where the eye can follow it.
///
/// A spring — even critically damped, even with its dead tail trimmed — is the
/// wrong shape here. Measured, it puts 45% of the distance into the first 20%
/// of the duration, which leaves nothing to watch afterwards and collapses the
/// hand-over between the bar and the page into a blink. Springs earn their
/// keep on gestural, interruptible motion; this is neither.
const Curve _kExpandCurve = Curves.fastOutSlowIn;

/// Closing is the mirror, not the rewind: the page detaches gently, covers
/// most of the distance in the middle and settles into the bar. Played
/// backwards it would instead hang and then slam home.
const Curve _kCollapseCurve = FlippedCurve(_kExpandCurve);

/// The corners are done flattening once the growth is this far along.
const double _kRadiusLead = 1.35;

/// How far the container has to have grown for the page to be fully opaque,
/// and for the bar it grew out of to be fully gone.
///
/// Tied to the container's progress rather than to elapsed time on purpose:
/// the two curves spend their time very differently — the collapse has the
/// container all but back at the pill by mid-duration — so a time-based window
/// would leave the page still a third opaque while the container has long
/// stopped moving, and the handoff to the bar would read as a flash.
///
/// How far the container has to have grown for the page to be fully opaque —
/// which is also when it has finished covering the bar underneath, so this is
/// the length of the hand-over between the two.
const double _kPageFadeInAt = 0.30;

/// How dark the screen left behind gets at full expansion.
const double _kScrimOpacity = 0.45;

class _WorkoutMorphTransition extends StatelessWidget {
  final Animation<double> animation;
  final WidgetBuilder? sourceBuilder;
  final Widget child;

  const _WorkoutMorphTransition({
    required this.animation,
    required this.sourceBuilder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size screen = MediaQuery.sizeOf(context);
    // Built once per rebuild, not once per frame: the per-frame builder below
    // reuses this instance, so its subtree — glass and all — is never rebuilt
    // by the animation. It still refreshes whenever the bar's own data
    // changes, so the timer keeps ticking through the flight instead of
    // freezing on the value it had when the morph started.
    final Widget? source = sourceBuilder?.call(context);
    final Rect barRect = DesignConstants.workoutOverlayRect(screen);
    final Rect fullRect = Offset.zero & screen;

    // Devices with a home indicator have rounded displays. Ending the morph on
    // square corners there makes the last frames snap into a rectangle, which
    // is the single most obvious tell that this is not a system transition.
    final double screenRadius =
        MediaQuery.viewPaddingOf(context).bottom > 0 ? 44.0 : 0.0;

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

        // The bar grows by the same rule, measured against its own width — the
        // other half of the container transform.
        final double sourceScale = rect.width / barRect.width;

        // The page fades against the *real* running workout bar, which sits
        // untouched behind this route at exactly [barRect] the whole time.
        // Painting an approximation of the bar's glass here instead — as this
        // did at first — cannot help but land on a slightly different tone,
        // and the handoff at the end of the collapse then shows as a jump.
        // Fading to nothing hands over to the genuine article.
        final double pageOpacity = (t / _kPageFadeInAt).clamp(0.0, 1.0);
        final double stripHeight = barRect.height * sourceScale;

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
                  // Everything below the bar's own strip, filled in the page's
                  // own background colour. Without it the screen behind would
                  // wash through the container while the page is still fading;
                  // because it is literally the page's background, there is no
                  // tone to match and nothing to see when the page arrives.
                  if (rect.height > stripHeight)
                    Positioned.fromRect(
                      rect: Rect.fromLTRB(
                        rect.left,
                        rect.top + stripHeight,
                        rect.right,
                        rect.bottom,
                      ),
                      child: ColoredBox(color: theme.scaffoldBackgroundColor),
                    ),
                  // The bar itself, pinned to the same corner of the container
                  // and scaled by the same rule as the page. Both occupy the
                  // same strip and sweep together, so what the eye sees is one
                  // turning into the other rather than one fading out
                  // somewhere while the other fades in.
                  //
                  // Never wrapped in anything that pushes a save layer — see
                  // the note on [WorkoutMorphRoute]. It simply stops being
                  // built once the page has finished covering it.
                  if (source != null && pageOpacity < 1.0)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translateByDouble(rect.left, rect.top, 0.0, 1.0)
                          ..scaleByDouble(sourceScale, sourceScale, 1.0, 1.0),
                        child: SizedBox(
                          width: barRect.width,
                          height: barRect.height,
                          child: source,
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: pageOpacity,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(rect.left, rect.top, 0.0, 1.0)
                        ..scaleByDouble(scale, scale, 1.0, 1.0),
                      child: page,
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
