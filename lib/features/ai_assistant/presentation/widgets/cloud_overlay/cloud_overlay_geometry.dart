import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../../util/design_constants.dart';

/// The four corners of the adjustable safe area rectangle.
enum SafeSpaceCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Material's standard easing for smooth, deliberate UI transitions.
const Curve overlayMorphCurve = Cubic(0.2, 0.0, 0.0, 1.0);

/// Clips the expanded overlay controls to the animated reveal boundary.
class CloudControlsClipper extends CustomClipper<Rect> {
  const CloudControlsClipper(this.revealBounds);

  final Rect revealBounds;

  @override
  Rect getClip(Size size) => revealBounds.intersect(Offset.zero & size);

  @override
  bool shouldReclip(covariant CloudControlsClipper oldClipper) =>
      oldClipper.revealBounds != revealBounds;
}

/// Computes the visual appearance progress of the overlay during morphing.
double openingAppearanceProgress(double progress) {
  const transitionRange = 0.5;
  final transitionProgress =
      (progress / transitionRange).clamp(0.0, 1.0).toDouble();
  return overlayMorphCurve.transform(transitionProgress);
}

/// Computes the overlay surface background color based on theme and progress.
Color overlaySurfaceColor(ThemeData theme, double appearanceProgress) {
  final appIsDark = theme.brightness == Brightness.dark;
  final cloudSurface = appIsDark ? Colors.white : Colors.black;
  return Color.lerp(
    cloudSurface,
    theme.scaffoldBackgroundColor,
    appearanceProgress,
  )!;
}

/// Computes the overlay foreground text/icon color based on theme and progress.
Color overlayForegroundColor(ThemeData theme, double appearanceProgress) {
  final appIsDark = theme.brightness == Brightness.dark;
  final cloudForeground = appIsDark ? Colors.black : Colors.white;
  return Color.lerp(
    cloudForeground,
    theme.colorScheme.onSurface,
    appearanceProgress,
  )!;
}

/// Computes the overlay control button fill color based on theme and progress.
Color overlayControlFill(ThemeData theme, double appearanceProgress) {
  final appIsDark = theme.brightness == Brightness.dark;
  final cloudFill = appIsDark
      ? DesignConstants.glassNeutralTint(true)
      : Colors.black.withValues(alpha: 0.04);
  final appFill = appIsDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.04);
  return Color.lerp(cloudFill, appFill, appearanceProgress)!;
}

/// Interactive resize handle positioned at a corner of the safe space rectangle.
class CloudResizeHandle extends StatelessWidget {
  const CloudResizeHandle({
    super.key,
    required this.corner,
    required this.position,
    required this.panelSize,
    required this.onPanUpdate,
    required this.isExpanded,
    required this.morphAnimation,
  });

  final SafeSpaceCorner corner;
  final Offset position;
  final Size panelSize;
  final GestureDragUpdateCallback onPanUpdate;
  final bool isExpanded;
  final Animation<double> morphAnimation;

  @override
  Widget build(BuildContext context) {
    const hitTargetSize = 40.0;
    final theme = Theme.of(context);
    final handleColor = theme.colorScheme.primary;

    return Positioned(
      left: position.dx - hitTargetSize / 2,
      top: position.dy - hitTargetSize / 2,
      width: hitTargetSize,
      height: hitTargetSize,
      child: IgnorePointer(
        ignoring: !isExpanded,
        child: FadeTransition(
          opacity: morphAnimation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            onPanUpdate: onPanUpdate,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: handleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.maximize_2,
                  size: 10,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
