import 'dart:math';
import 'package:flutter/material.dart';

class CurvedArrow extends StatelessWidget {
  final Color? color;
  final double strokeWidth;

  const CurvedArrow({
    super.key,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CurvedArrowPainter(
        color: color ?? Theme.of(context).colorScheme.primary,
        strokeWidth: strokeWidth,
        bottomSafeArea: MediaQuery.of(context).padding.bottom,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double bottomSafeArea;

  _CurvedArrowPainter({
    required this.color,
    required this.strokeWidth,
    required this.bottomSafeArea,
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

    // End at the center of the FAB
    // Assume FAB center is ~48px from the right edge.
    // The FAB size is 64px, margin right is 16px. So center is 16 + 32 = 48px from right edge.
    final endX = size.width - 48.0;
    
    // The top of the FAB is exactly 96px from the bottom of the screen (12 bottom offset + 20 vertical padding + 64 height).
    // We want the arrow to stop 10px above the FAB, so it stops 106px from the bottom.
    final targetY = size.height - 106.0;

    final availableHeight = targetY - startY;
    if (availableHeight < 40) {
      // Not enough space to draw the complex arrow, just draw a simple line
      path.moveTo(startX, startY);
      path.lineTo(startX, size.height);
      canvas.drawPath(path, paint);
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
    path.lineTo(endX, targetY);
    
    canvas.drawPath(path, paint);

    // Draw arrowhead pointing down
    final arrowLength = 14.0;
    final arrowWidth = 10.0;
    
    final arrowPath = Path()
      ..moveTo(endX, targetY)
      ..lineTo(endX - arrowWidth, targetY - arrowLength)
      ..moveTo(endX, targetY)
      ..lineTo(endX + arrowWidth, targetY - arrowLength);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.bottomSafeArea != bottomSafeArea;
  }
}
