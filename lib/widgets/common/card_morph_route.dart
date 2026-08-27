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

  @override
  Animation<double> createAnimation() {
    final anim = super.createAnimation();
    if (onSourceVisibilityChanged != null) {
      anim.addStatusListener(_handleAnimationStatus);
    }
    return anim;
  }

  @override
  TickerFuture didPush() {
    if (onSourceVisibilityChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (isActive) onSourceVisibilityChanged?.call(true);
      });
    }
    return super.didPush();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      onSourceVisibilityChanged?.call(false);
    }
  }

  @override
  void dispose() {
    if (onSourceVisibilityChanged != null) {
      animation?.removeStatusListener(_handleAnimationStatus);
      onSourceVisibilityChanged?.call(false);
    }
    super.dispose();
  }
}

const Curve _kExpandCurve = Curves.fastOutSlowIn;
const Curve _kCollapseCurve = FlippedCurve(_kExpandCurve);
const double _kRadiusLead = 1.35;
const double _kScrimOpacity = 0.45;

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
    final bool shouldPop = velocity > 300.0 || (progress < 0.7 && velocity > -100.0);
    widget.route.handleDragEnd(shouldPop: shouldPop);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget? source = widget.sourceBuilder != null
        ? Material(
            type: MaterialType.transparency,
            child: widget.sourceBuilder!(context),
          )
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: (d) => _handleDragUpdate(d, MediaQuery.sizeOf(context).width),
      onHorizontalDragEnd: (d) => _handleDragEnd(d, MediaQuery.sizeOf(context).width),
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

          // Content fade: destination page and its background fade smoothly
          // across the lower range (0.0 to 0.25) so it dissolves gently into the source FAB/card.
          const double kFadeThreshold = 0.25;
          final double pageOpacity = (t / kFadeThreshold).clamp(0.0, 1.0);

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

                    // Destination page (fades in/out smoothly as it expands/collapses)
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

                    // Source element (e.g. GlassFab or card copy) sits smoothly over the page
                    // during flight so its liquid glass blur refracts the page underneath
                    if (source != null && t < 0.45)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translateByDouble(
                                rect.left, rect.top, 0.0, 1.0)
                            ..scaleByDouble(
                                sourceScale, sourceScale, 1.0, 1.0),
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
