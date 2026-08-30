import 'package:flutter/material.dart';

/// A custom painter that draws a glass sheet border that fades out vertically.
///
/// The outline follows the same rounded-superellipse (squircle) geometry the
/// liquid glass shapes use, so the hairline sits exactly on the glass edge
/// instead of cutting across it with a circular arc. It is drawn on the top
/// edge, the top-left/top-right corners and the left/right edges, fading to
/// 0 opacity from top to bottom.
class GlassBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double bottomPadding;

  GlassBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final halfStroke = strokeWidth / 2;

    // The gradient starts at top (0) and fades out at size.height - bottomPadding.
    // If bottomPadding is 0, we can use a default bottom padding (like 40) or just size.height.
    final double fadeEnd = size.height - bottomPadding;
    final double effectiveEnd = fadeEnd > 0 ? fadeEnd : size.height;

    final rect = Rect.fromLTRB(0, 0, size.width, effectiveEnd);
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color,
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    ).createShader(rect);

    // Same shape the glass layer is clipped to (LiquidVerticalRoundedSuperellipse
    // maps onto RoundedSuperellipseBorder), inset by half the stroke so the
    // hairline sits inside the glass edge rather than straddling it.
    final outline = Rect.fromLTRB(
      halfStroke,
      halfStroke,
      size.width - halfStroke,
      size.height,
    );
    final path = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular((radius - halfStroke).clamp(0.0, double.infinity)),
      ),
    ).getOuterPath(outline);

    // The bottom edge of that path is fully transparent through the gradient,
    // so only the top edge, the two squircle corners and the side edges show.
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GlassBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.bottomPadding != bottomPadding;
  }
}
