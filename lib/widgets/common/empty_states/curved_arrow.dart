import 'dart:math';
import 'package:flutter/material.dart';

class CurvedArrow extends StatelessWidget {
  final Color? color;
  final double strokeWidth;
  final bool targetCenter;
  final double? customEndXOffset;
  final double? customTargetYOffset;

  const CurvedArrow({
    super.key,
    this.color,
    this.strokeWidth = 2.0,
    this.targetCenter = false,
    this.customEndXOffset,
    this.customTargetYOffset,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CurvedArrowPainter(
        color: color ?? Theme.of(context).colorScheme.primary,
        strokeWidth: strokeWidth,
        bottomSafeArea: MediaQuery.of(context).padding.bottom,
        targetCenter: targetCenter,
        customEndXOffset: customEndXOffset,
        customTargetYOffset: customTargetYOffset,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double bottomSafeArea;
  final bool targetCenter;
  final double? customEndXOffset;
  final double? customTargetYOffset;

  _CurvedArrowPainter({
    required this.color,
    required this.strokeWidth,
    required this.bottomSafeArea,
    required this.targetCenter,
    this.customEndXOffset,
    this.customTargetYOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Start under the text (top center)
    final startX = size.width * 0.5;
    final startY = 0.0;

    // End at the center of the FAB or Center Bottom Button
    final endX = targetCenter 
        ? size.width * 0.5 
        : size.width - (customEndXOffset ?? 48.0);
    
    // The top of the FAB is exactly 96px from the bottom of the screen (12 bottom offset + 20 vertical padding + 64 height).
    // If targetCenter is true, assume a bottom dock height of 86px.
    final targetY = customTargetYOffset != null 
        ? size.height - customTargetYOffset!
        : (targetCenter ? size.height - 96.0 : size.height - 126.0);

    final availableHeight = targetY - startY;
    if (availableHeight < 40) {
      // Very short space, draw straight line down
      path.moveTo(startX, startY);
      path.lineTo(startX, targetY - 10);
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, paint, startX, targetY);
      return;
    } else if (targetCenter) {
      // If targeting center, just draw a slightly wavy or straight line down
      path.moveTo(startX, startY);
      path.lineTo(startX, targetY - 10);
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, paint, startX, targetY);
      return;
    }

    // Straight lines with rounded corners
    double R = 32.0;
    final availableWidth = endX - startX;
    
    // Scale down radius if space is tight
    R = min(R, availableHeight / 3);
    R = min(R, availableWidth / 2);

    // The Y coordinate where we turn horizontal
    // We want a very long first vertical line, turning horizontal near the bottom.
    // Ensure we don't go past the targetY.
    final turnY = max(startY + R, targetY - R - 30.0);

    path.moveTo(startX, startY);
    
    // 1. Straight down
    path.lineTo(startX, turnY - R);
    
    // 2. Rounded corner right
    path.quadraticBezierTo(startX, turnY, startX + R, turnY);
    
    // 3. Straight right
    path.lineTo(endX - R, turnY);
    
    // 4. Rounded corner down
    path.quadraticBezierTo(endX, turnY, endX, turnY + R);
    
    // 5. Straight down to target
    path.lineTo(endX, targetY - 10);

    canvas.drawPath(path, paint);
    _drawArrowHead(canvas, paint, endX, targetY);
  }

  void _drawArrowHead(Canvas canvas, Paint paint, double x, double y) {
    final arrowLength = 14.0;
    final arrowWidth = 10.0;
    
    final arrowPath = Path()
      ..moveTo(x, y)
      ..lineTo(x - arrowWidth, y - arrowLength)
      ..moveTo(x, y)
      ..lineTo(x + arrowWidth, y - arrowLength);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.bottomSafeArea != bottomSafeArea;
  }
}
