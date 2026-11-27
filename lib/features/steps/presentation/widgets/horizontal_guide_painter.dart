import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class HorizontalGuidePainter extends CustomPainter {
  HorizontalGuidePainter({
    required this.lineColor,
    required this.goalColor,
    this.goalRatio,
  });

  final Color lineColor;
  final Color goalColor;
  final double? goalRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (final ratio in const [0.0, 0.5, 1.0]) {
      final y = size.height * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final goal = goalRatio;
    if (goal == null) return;
    final goalPaint = Paint()
      ..color = goalColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.2;
    final y = size.height * (1 - goal);
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 5, size.width), y),
        goalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalGuidePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.goalColor != goalColor ||
      oldDelegate.goalRatio != goalRatio;
}
