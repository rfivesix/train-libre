// lib/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// State interface for programmatic impulse triggers on [AiNeuralCloudOrbWidget].
abstract class AiNeuralCloudOrbState {
  void triggerImpulse();
}

/// An iconic, organic morphing cloud animation inspired by modern AI voice/thinking clouds.
///
/// Features:
/// * Clean, solid morphing cloud silhouette composed of interconnected undulating lobes.
/// * Continuous, fluid rotation and harmonic breathing (scale swells at top-left).
/// * Detached trailing satellite bubble at the bottom-left.
/// * Pure 60/120fps hardware-accelerated vector rendering with optional ambient aura.
class AiNeuralCloudOrbWidget extends StatefulWidget {
  final double size;
  final bool showAmbientGlow;
  final Color cloudColor;
  final VoidCallback? onTap;

  const AiNeuralCloudOrbWidget({
    super.key,
    this.size = 280,
    this.showAmbientGlow = true,
    this.cloudColor = Colors.white,
    this.onTap,
  });

  @override
  State<AiNeuralCloudOrbWidget> createState() => AiNeuralCloudOrbWidgetState();
}

class AiNeuralCloudOrbWidgetState extends State<AiNeuralCloudOrbWidget>
    with SingleTickerProviderStateMixin
    implements AiNeuralCloudOrbState {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void triggerImpulse() {
    // Continuous smooth animation
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final time = _controller.value * 60.0;

          return RepaintBoundary(
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _OrganicCloudPainter(
                time: time,
                showAmbientGlow: widget.showAmbientGlow,
                cloudColor: widget.cloudColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrganicCloudPainter extends CustomPainter {
  final double time;
  final bool showAmbientGlow;
  final Color cloudColor;

  _OrganicCloudPainter({
    required this.time,
    required this.showAmbientGlow,
    required this.cloudColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 280.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 1. Subtle ambient background glow behind the cloud
    if (showAmbientGlow) {
      final breathe = 0.92 + 0.08 * math.sin(time * 1.8);
      final glowRadius = 120.0 * scale * breathe;
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            cloudColor.withValues(alpha: 0.15 * breathe),
            const Color(0xFFDDFF00).withValues(alpha: 0.04 * breathe),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: glowRadius))
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset.zero, glowRadius, glowPaint);
    }

    final cloudPaint = Paint()
      ..color = cloudColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // 2. Global gentle cluster rotation (16s cycle)
    final globalRotation = (time * (2 * math.pi / 16.0)) % (2 * math.pi);
    canvas.save();
    canvas.rotate(globalRotation);

    // Core center base
    final coreRadius = 48.0 * scale * (1.0 + 0.05 * math.sin(time * 2.0));
    canvas.drawCircle(Offset.zero, coreRadius, cloudPaint);

    // 6 surrounding organic cloud lobes
    const lobeCount = 6;
    const topLeftAngle = -0.75 * math.pi; // -135 deg in screen space

    for (int i = 0; i < lobeCount; i++) {
      final baseAngle = i * (2 * math.pi / lobeCount);
      // Individual lobe subtle harmonic oscillation
      final angleWobble = 0.12 * math.sin(time * 1.5 + i * 1.8);
      final currentAngle = baseAngle + angleWobble;

      // Distance from center
      final distWobble = 6.0 * math.sin(time * 2.2 + i * 2.0);
      final distance = (34.0 + distWobble) * scale;

      final lobePos = Offset(
        distance * math.cos(currentAngle),
        distance * math.sin(currentAngle),
      );

      // Position-based scale: swells towards top-left (-135 deg relative to global rotation)
      final effectiveAngle = (currentAngle + globalRotation) % (2 * math.pi);
      final angleDiff = effectiveAngle - topLeftAngle;
      final posScale = 1.0 + 0.22 * math.cos(angleDiff); // 0.78 -> 1.22

      // Organic lobe breathing
      final lobeBreathe = 1.0 + 0.10 * math.cos(time * 2.5 + i * 1.5);
      final lobeRadius = 36.0 * scale * posScale * lobeBreathe;

      canvas.drawCircle(lobePos, lobeRadius, cloudPaint);
    }

    canvas.restore(); // Undo rotation for satellite bubble

    // 3. Detached satellite bubble (bottom-left)
    final satBreathe = 1.0 + 0.12 * math.sin(time * 2.4);
    final satDist = (82.0 + 4.0 * math.cos(time * 1.8)) * scale;
    const satAngle = 0.72 * math.pi; // ~130 deg (bottom-left quadrant)
    final satPos = Offset(
      satDist * math.cos(satAngle),
      satDist * math.sin(satAngle),
    );
    final satRadius = 12.5 * scale * satBreathe;
    canvas.drawCircle(satPos, satRadius, cloudPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrganicCloudPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.showAmbientGlow != showAmbientGlow ||
        oldDelegate.cloudColor != cloudColor;
  }
}
