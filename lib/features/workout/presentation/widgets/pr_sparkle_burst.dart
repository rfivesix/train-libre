import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Small, paint-only burst; it never intercepts taps or affects layout.
class PrSparkleBurst extends StatelessWidget {
  const PrSparkleBurst({
    super.key,
    required this.progress,
    required this.color,
    this.accentColor,
  });
  final double progress;
  final Color color;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _PrSparklePainter(
        progress: progress,
        color: color,
        accentColor: accentColor ?? color,
      ),
    ),
  );
}

class _PrSparklePainter extends CustomPainter {
  const _PrSparklePainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });
  final double progress;
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final distance = 8 + 22 * Curves.easeOut.transform(t);
    final opacity = (1 - t) * 0.85;
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (var i = 0; i < 8; i++) {
      paint.color = (i.isEven ? color : accentColor).withValues(alpha: opacity);
      final angle = i * math.pi / 4 - math.pi / 2;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        position,
        (i.isEven ? 2.3 : 1.4) * (1 - t * 0.4),
        paint,
      );
    }
    canvas.drawCircle(
      center,
      8 + 18 * t,
      Paint()
        ..color = color.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _PrSparklePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.accentColor != accentColor;
}
