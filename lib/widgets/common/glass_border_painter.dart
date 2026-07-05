import 'package:flutter/material.dart';

/// A custom painter that draws a glass sheet border that fades out vertically.
///
/// The border is drawn on the top edge, top-left/top-right rounded corners,
/// and left/right edges, fading to 0 opacity from top to bottom.
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

    final path = Path();
    // Start at bottom left (inset by halfStroke from the left edge)
    path.moveTo(halfStroke, size.height);
    // Line up to top-left corner start
    path.lineTo(halfStroke, radius + halfStroke);
    // Arc to top-left corner end (inset from top by halfStroke)
    path.arcToPoint(
      Offset(radius + halfStroke, halfStroke),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // Line across the top to top-right corner start
    path.lineTo(size.width - radius - halfStroke, halfStroke);
    // Arc to top-right corner end (inset from right by halfStroke)
    path.arcToPoint(
      Offset(size.width - halfStroke, radius + halfStroke),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // Line down to bottom right
    path.lineTo(size.width - halfStroke, size.height);

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
