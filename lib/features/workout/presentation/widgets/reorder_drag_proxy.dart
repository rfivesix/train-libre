// lib/features/workout/presentation/widgets/reorder_drag_proxy.dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Corner radius the workout cards clip themselves to (see [WorkoutCard]).
const double kReorderDragProxyRadius = 20.0;

/// Decorates the row that a reorderable list lifts into the drag overlay.
///
/// [child] is the very widget the list row renders. It is *decorated*, never
/// rebuilt: a proxy that is built from scratch inevitably ends up with
/// different metrics than the row it was dragged out of, which makes it drift
/// away from the finger.
///
/// The workout cards are deliberately transparent — inside the list the
/// scaffold background shines through them. In the drag overlay there is
/// nothing behind them, so an undecorated proxy looks empty (and any glass
/// blur would sample the void). The [Material] added here gives the proxy an
/// opaque surface taken from the theme and animates the lift.
Widget buildReorderDragProxy(
  BuildContext context,
  Widget child,
  Animation<double> animation, {
  double borderRadius = kReorderDragProxyRadius,
}) {
  final ThemeData theme = Theme.of(context);
  final Color surface = reorderDragProxySurfaceColor(theme);
  final BorderRadius radius = BorderRadius.circular(borderRadius);

  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final double t = Curves.easeInOut.transform(animation.value);
      return Material(
        elevation: lerpDouble(0.0, 6.0, t)!,
        color: surface,
        shadowColor: theme.shadowColor,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    },
    child: child,
  );
}

/// The opaque surface the drag proxy paints on.
///
/// Uses the app's own card surface ([AppSurfaces.summaryCard], white in light
/// mode and `#1C1C1E` on the OLED-black dark theme) and falls back to
/// [ThemeData.cardColor]. The result is composited onto the scaffold
/// background so a translucent card colour can never leave the proxy
/// see-through in the overlay.
Color reorderDragProxySurfaceColor(ThemeData theme) {
  final Color base =
      theme.extension<AppSurfaces>()?.summaryCard ?? theme.cardColor;
  return Color.alphaBlend(
    base,
    theme.scaffoldBackgroundColor.withValues(alpha: 1.0),
  );
}
