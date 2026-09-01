import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../util/design_constants.dart';

/// A reusable, high-performance container transform route that morphs an
/// originating UI element (card, tile, FAB) into a destination screen and
/// collapses back on pop.
///
/// Follows the architecture and performance invariants of `WorkoutMorphRoute`:
/// 1. The container grows from [sourceRect] to the full screen, flattening
///    its corner radii smoothly.
/// 2. The destination screen is laid out full-screen once and scaled uniformly
///    via [Transform] without per-frame relayouts.
/// 3. The destination page cross-fades *over* the source element inside a
///    bounded [ClipRRect], ensuring any `saveLayer` is confined and liquid glass
///    in the source never loses refraction under an `Opacity` layer.
///
///    Which of the two does the fading is not a free choice. A source may be
///    liquid glass, and glass is a [BackdropFilterLayer]: it can only refract
///    what was painted into the save layer enclosing it. An `Opacity` is
///    exactly such a save layer, and an empty one, so a fading source has
///    nothing to refract and renders flat until its opacity reaches 1.0, at
///    which point Flutter stops pushing the layer and the glass snaps in from
///    nothing. Hence the source copy is always drawn at full opacity,
///    *underneath* the page, and the page is what fades — in both directions.
/// 4. Background dims with a subtle scrim.
/// 5. Handover at both ends is overlap-safe (no 1-frame blank).
/// 6. Supports interactive iOS edge-swipe back gesture to collapse on drag.
class CardMorphRoute<T> extends PageRoute<T> {
  CardMorphRoute({
    required this.builder,
    this.sourceRect,
    this.sourceContext,
    this.sourceBorderRadius = DesignConstants.borderRadiusL,
    this.sourceBuilder,
    this.morphOnPop = true,
    this.onSourceVisibilityChanged,
    super.settings,
    Duration expandDuration = const Duration(milliseconds: 420),
    Duration collapseDuration = const Duration(milliseconds: 360),
    bool maintainState = true,
    bool fullscreenDialog = false,
  })  : _expandDuration = expandDuration,
        _collapseDuration = collapseDuration,
        _maintainState = maintainState,
        _fullscreenDialog = fullscreenDialog;

  final WidgetBuilder builder;

  /// Whether the route should morph back into [sourceRect] on pop.
  /// When false (e.g. for LiveWorkoutScreen), it morphs open from the card on push,
  /// but slides down into the bottom progress bar on pop.
  final bool morphOnPop;

  /// Fixed bounding rect of the source widget in global coordinates.
  final Rect? sourceRect;

  /// Optional context used to dynamically measure the source widget's global
  /// bounds at the moment of navigation.
  final BuildContext? sourceContext;

  /// Corner radius of the originating element.
  final double sourceBorderRadius;

  /// Optional builder that draws a copy of the source element during flight.
  final WidgetBuilder? sourceBuilder;

  /// Callback to hide the original source widget on screen during flight and
  /// restore it once the collapse lands.
  final void Function(bool hidden)? onSourceVisibilityChanged;

  final Duration _expandDuration;
  final Duration _collapseDuration;
  final bool _maintainState;

  @override
  bool get maintainState => _maintainState;

  final bool _fullscreenDialog;

  @override
  bool get fullscreenDialog => _fullscreenDialog;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => _expandDuration;

  @override
  Duration get reverseTransitionDuration => _collapseDuration;

  void handleDragStart() {
    controller?.stop();
  }

  void handleDragUpdate(double deltaFraction) {
    if (controller != null) {
      controller!.value = (controller!.value - deltaFraction).clamp(0.0, 1.0);
    }
  }

  void handleDragEnd({required bool shouldPop}) {
    if (controller == null) return;
    if (shouldPop) {
      controller!.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
        if (isActive) {
          navigator?.pop();
        }
      });
    } else {
      controller!.animateTo(1.0, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  /// Helper to measure the global rect of a given [BuildContext].
  static Rect? measureRect(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      return null;
    }
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  Rect? _resolvedSourceRect;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _resolvedSourceRect ??= sourceRect ?? measureRect(sourceContext);
    final measured = _resolvedSourceRect;

    // Fallback if no source bounds could be resolved: soft fade
    if (measured == null) {
      return FadeTransition(opacity: animation, child: child);
    }

    return _CardMorphTransition(
      route: this,
      animation: animation,
      sourceRect: measured,
      sourceBorderRadius: sourceBorderRadius,
      sourceBuilder: sourceBuilder,
      morphOnPop: morphOnPop,
      child: child,
    );
  }

  bool _sourceHidden = false;
  double _lastAnimationValue = 0.0;

  @override
  Animation<double> createAnimation() {
    final anim = super.createAnimation();
    if (onSourceVisibilityChanged != null) {
      anim.addStatusListener(_handleAnimationStatus);
      anim.addListener(_handleAnimationValue);
    }
    return anim;
  }

  @override
  TickerFuture didPush() {
    if (onSourceVisibilityChanged != null) {
      // Deliberately one frame late: a route's content is not in the tree
      // until the frame after the push, so hiding the real card any earlier
      // leaves a frame with no card at all.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (isActive) _setSourceHidden(true);
      });
    }
    return super.didPush();
  }

  /// Hands the card back to the screen *before* the route is dismissed.
  ///
  /// At [_kSourceHandoverAt] the container is all but back on the card and the
  /// copy is still drawn there — same position, same size, full opacity — so
  /// the two overlap indistinguishably for the last few frames. Restoring on
  /// [AnimationStatus.dismissed] instead put the original back on the very
  /// last frame, at full density, with nothing having faded it in.
  ///
  /// Direction is read from the value rather than from the status: the
  /// interactive back-swipe collapses via `animateTo(0.0)`, which reports
  /// [AnimationStatus.forward] the whole way down.
  void _handleAnimationValue() {
    final double value = animation?.value ?? 0.0;
    final bool receding = value < _lastAnimationValue;
    _lastAnimationValue = value;
    if (value > _kSourceHandoverAt) {
      _setSourceHidden(true);
    } else if (receding || animation?.status == AnimationStatus.dismissed) {
      _setSourceHidden(false);
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _setSourceHidden(false);
    }
  }

  /// The copy and the original must never both be absent. Routes tick and are
  /// disposed from inside a frame, where flipping state the screen depends on
  /// would rebuild a widget that has already been built.
  void _setSourceHidden(bool hidden) {
    final void Function(bool hidden)? callback = onSourceVisibilityChanged;
    if (callback == null || _sourceHidden == hidden) return;
    _sourceHidden = hidden;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => callback(hidden));
    } else {
      callback(hidden);
    }
  }

  @override
  void dispose() {
    if (onSourceVisibilityChanged != null) {
      animation?.removeStatusListener(_handleAnimationStatus);
      animation?.removeListener(_handleAnimationValue);
      // Safety net for the paths that never run the collapse at all, such as
      // a route that is replaced outright.
      _setSourceHidden(false);
    }
    super.dispose();
  }
}

const Curve _kExpandCurve = Curves.fastOutSlowIn;
const Curve _kCollapseCurve = FlippedCurve(_kExpandCurve);
const double _kRadiusLead = 1.35;
const double _kScrimOpacity = 0.45;

/// How far the container has to have grown for the page to be fully opaque —
/// which is also when it has finished covering the source copy underneath, so
/// this is the length of the hand-over between the two.
///
/// Tied to the container's progress rather than to elapsed time on purpose:
/// the expand and collapse curves spend their time very differently, so a
/// time-based window would leave the page still a third opaque while the
/// container has long stopped moving, and the hand-over would read as a flash.
///
/// A touch wider than the workout bar's 0.30, because a card covers far more
/// area than a pill and a large surface needs longer to read as a dissolve
/// rather than as an appearance.
const double _kHandoverBand = 0.32;

/// Raw animation value at or below which the screen takes its real card back.
///
/// The copy is still drawn there, at the card's exact position, size and full
/// opacity, so the two overlap indistinguishably for the last few frames.
const double _kSourceHandoverAt = 0.06;

class _CardMorphTransition extends StatefulWidget {
  final CardMorphRoute route;
  final Animation<double> animation;
  final Rect sourceRect;
  final double sourceBorderRadius;
  final WidgetBuilder? sourceBuilder;
  final bool morphOnPop;
  final Widget child;

  const _CardMorphTransition({
    required this.route,
    required this.animation,
    required this.sourceRect,
    required this.sourceBorderRadius,
    required this.sourceBuilder,
    required this.morphOnPop,
    required this.child,
  });

  @override
  State<_CardMorphTransition> createState() => _CardMorphTransitionState();
}

class _CardMorphTransitionState extends State<_CardMorphTransition> {
  bool _isDragging = false;

  /// The copy of the source, built exactly once.
  ///
  /// A [CardMorphRoute.sourceBuilder] closes over the screen it came from, and
  /// that screen is free to rebuild while the morph is still in flight — or to
  /// replace its whole subtree with a spinner, which is what a screen holding
  /// its content in a `FutureBuilder` does when it reloads. Several reload on
  /// the push future, and that future completes the moment the pop starts, not
  /// the moment the collapse lands: the source's elements are then deactivated
  /// for the rest of the collapse, and calling the builder again would look up
  /// a deactivated widget's ancestor on every frame.
  ///
  /// The widget the builder returned the first time is an immutable
  /// description and stays valid however the screen below changes, so it is
  /// built once — on the frame after the push, while the source is
  /// unquestionably alive — and reused for the whole flight. That is also what
  /// the copy should be: the card as it looked when it was left, not as the
  /// screen underneath has since rebuilt it.
  Widget? _sourceCopy;
  bool _sourceCopyBuilt = false;

  void _handleDragStart(DragStartDetails details) {
    if (details.globalPosition.dx <= 40.0 && widget.animation.isCompleted) {
      _isDragging = true;
      widget.route.handleDragStart();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isDragging) return;
    final double delta = details.primaryDelta ?? 0.0;
    widget.route.handleDragUpdate(delta / screenWidth);
  }

  void _handleDragEnd(DragEndDetails details, double screenWidth) {
    if (!_isDragging) return;
    _isDragging = false;
    final double velocity = details.primaryVelocity ?? 0.0;
    final double progress = widget.animation.value;
    final bool shouldPop =
        velocity > 300.0 || (progress < 0.7 && velocity > -100.0);
    widget.route.handleDragEnd(shouldPop: shouldPop);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (!_sourceCopyBuilt) {
      _sourceCopyBuilt = true;
      final WidgetBuilder? builder = widget.sourceBuilder;
      _sourceCopy = builder == null
          ? null
          : Material(
              type: MaterialType.transparency,
              child: builder(context),
            );
    }
    final Widget? source = _sourceCopy;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: (d) =>
          _handleDragUpdate(d, MediaQuery.sizeOf(context).width),
      onHorizontalDragEnd: (d) =>
          _handleDragEnd(d, MediaQuery.sizeOf(context).width),
      child: AnimatedBuilder(
        animation: widget.animation,
        child: widget.child,
        builder: (context, page) {
          final double raw = widget.animation.value.clamp(0.0, 1.0);
          if (raw >= 1.0) return page!;

          final Size screen = MediaQuery.sizeOf(context);
          final Rect fullRect = Offset.zero & screen;
          final double screenRadius =
              MediaQuery.viewPaddingOf(context).bottom > 0 ? 44.0 : 0.0;

          // If morphOnPop is false and we are popping (e.g. LiveWorkoutScreen minimizing to bottom bar),
          // slide down off screen smoothly towards the bottom progress bar:
          if (!widget.morphOnPop &&
              widget.animation.status == AnimationStatus.reverse) {
            final double popProgress = (1.0 - raw);
            final double slideY =
                Curves.easeInCubic.transform(popProgress) * screen.height;
            final double scrimAlpha = raw * _kScrimOpacity;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.black.withValues(alpha: scrimAlpha)),
                Transform.translate(
                  offset: Offset(0.0, slideY),
                  child: page,
                ),
              ],
            );
          }

          final Curve curve = widget.animation.status == AnimationStatus.reverse
              ? _kCollapseCurve
              : _kExpandCurve;
          final double t = curve.transform(raw);

          final Rect rect = Rect.lerp(widget.sourceRect, fullRect, t)!;
          final double radius = lerpDouble(
            widget.sourceBorderRadius,
            screenRadius,
            (t * _kRadiusLead).clamp(0.0, 1.0),
          )!;

          final double scale = rect.width / screen.width;
          final double sourceScale = rect.width / widget.sourceRect.width;

          // Content fade: the destination page and its background dissolve
          // across the hand-over band. On the way back that is what reveals
          // the source copy underneath — gradually, instead of switching it on
          // at full density once the container has shrunk far enough.
          final double pageOpacity = (t / _kHandoverBand).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background scrim
              ColoredBox(
                color: Colors.black.withValues(alpha: t * _kScrimOpacity),
              ),
              // The expanding card body
              ClipRRect(
                clipper: _CardMorphClipper(rect: rect, radius: radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Full scaffold background fading in sync with the page
                    if (pageOpacity > 0.0)
                      Positioned.fromRect(
                        rect: rect,
                        child: ColoredBox(
                          color: theme.scaffoldBackgroundColor
                              .withValues(alpha: pageOpacity),
                        ),
                      ),

                    // Source element (e.g. GlassFab or card copy), pinned to
                    // the same corner of the container and scaled by the same
                    // rule as the page. Both occupy the same box and sweep
                    // together, so what the eye sees is one turning into the
                    // other rather than one being swapped for the other.
                    //
                    // Never wrapped in anything that pushes a save layer — see
                    // the note on [CardMorphRoute]. It is drawn at full
                    // opacity for the whole hand-over band and simply stops
                    // being built once the page has finished covering it.
                    if (source != null && pageOpacity < 1.0)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translateByDouble(rect.left, rect.top, 0.0, 1.0)
                            ..scaleByDouble(sourceScale, sourceScale, 1.0, 1.0),
                          child: SizedBox(
                            width: widget.sourceRect.width,
                            height: widget.sourceRect.height,
                            child: Material(
                              type: MaterialType.transparency,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    widget.sourceBorderRadius),
                                child: OverflowBox(
                                  alignment: Alignment.topLeft,
                                  minWidth: widget.sourceRect.width,
                                  maxWidth: widget.sourceRect.width,
                                  minHeight: widget.sourceRect.height,
                                  maxHeight: widget.sourceRect.height,
                                  child: source,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Destination page, dissolving in over the source copy on
                    // the way out and back off it on the way in. The only
                    // layer this transition pushes, and it sits *inside* the
                    // clip, so its `saveLayer` is bounded by the card rather
                    // than by the screen.
                    if (pageOpacity > 0.0)
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
      ),
    );
  }
}

class _CardMorphClipper extends CustomClipper<RRect> {
  final Rect rect;
  final double radius;

  const _CardMorphClipper({required this.rect, required this.radius});

  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  bool shouldReclip(_CardMorphClipper oldClipper) =>
      oldClipper.rect != rect || oldClipper.radius != radius;
}
