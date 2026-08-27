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
class CardMorphRoute<T> extends PageRouteBuilder<T> {
  CardMorphRoute({
    required WidgetBuilder builder,
    this.sourceRect,
    this.sourceContext,
    this.sourceBorderRadius = DesignConstants.borderRadiusL,
    this.sourceBuilder,
    this.onSourceVisibilityChanged,
    super.settings,
    Duration expandDuration = const Duration(milliseconds: 400),
    Duration collapseDuration = const Duration(milliseconds: 350),
  }) : super(
          transitionDuration: expandDuration,
          reverseTransitionDuration: collapseDuration,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        );

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

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final measured = sourceRect ?? measureRect(sourceContext);

    // Fallback if no source bounds could be resolved: soft fade
    if (measured == null) {
      return FadeTransition(opacity: animation, child: child);
    }

    return _CardMorphTransition(
      animation: animation,
      sourceRect: measured,
      sourceBorderRadius: sourceBorderRadius,
      sourceBuilder: sourceBuilder,
      child: child,
    );
  }

  @override
  void install() {
    super.install();
    if (onSourceVisibilityChanged == null) return;
    // Deliberately 1 frame late: the route content is not in the tree until the
    // frame after the push, so hiding any earlier leaves a 1-frame gap.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isActive) onSourceVisibilityChanged?.call(true);
    });
    animation?.addStatusListener(_handleAnimationStatus);
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
const double _kPageFadeInAt = 0.30;
const double _kScrimOpacity = 0.40;

class _CardMorphTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect sourceRect;
  final double sourceBorderRadius;
  final WidgetBuilder? sourceBuilder;
  final Widget child;

  const _CardMorphTransition({
    required this.animation,
    required this.sourceRect,
    required this.sourceBorderRadius,
    required this.sourceBuilder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size screen = MediaQuery.sizeOf(context);
    final Widget? source = sourceBuilder?.call(context);
    final Rect fullRect = Offset.zero & screen;

    final double screenRadius =
        MediaQuery.viewPaddingOf(context).bottom > 0 ? 44.0 : 0.0;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final double raw = animation.value.clamp(0.0, 1.0);
        if (raw >= 1.0) return page!;

        final Curve curve = animation.status == AnimationStatus.reverse
            ? _kCollapseCurve
            : _kExpandCurve;
        final double t = curve.transform(raw);

        final Rect rect = Rect.lerp(sourceRect, fullRect, t)!;
        final double radius = lerpDouble(
          sourceBorderRadius,
          screenRadius,
          (t * _kRadiusLead).clamp(0.0, 1.0),
        )!;

        final double scale = rect.width / screen.width;
        final double sourceScale = rect.width / sourceRect.width;
        final double pageOpacity = (t / _kPageFadeInAt).clamp(0.0, 1.0);
        final double stripHeight = sourceRect.height * sourceScale;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black.withValues(alpha: t * _kScrimOpacity),
            ),
            ClipRRect(
              clipper: _CardMorphClipper(rect: rect, radius: radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                  if (source != null && pageOpacity < 1.0)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translateByDouble(rect.left, rect.top, 0.0, 1.0)
                          ..scaleByDouble(sourceScale, sourceScale, 1.0, 1.0),
                        child: SizedBox(
                          width: sourceRect.width,
                          height: sourceRect.height,
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
