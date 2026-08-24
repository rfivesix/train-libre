// lib/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../services/haptic_feedback_service.dart';

/// State interface for programmatic impulse / ripple triggers on [AiNeuralCloudOrbWidget].
abstract class AiNeuralCloudOrbState {
  void triggerImpulse();
  void triggerRipple();
  void incrementCharge();
}

/// An iconic, organic morphing cloud animation inspired by modern AI voice/thinking clouds.
///
/// Features:
/// * Dynamic multi-harmonic undulating lobes that move like living fluid/smoke.
/// * 100% continuous, smooth rotation without angular jumps or jerky phase shifts.
/// * Seamless liquid dye diffusion: each tap smoothly spreads the vibrant primary green
///   across the unified cloud silhouette without internal circular seam lines.
/// * Theme-adaptive: Automatically adapts between dark mode (white cloud on black) and
///   light mode (black cloud on white), flowing with the theme's primary accent color.
/// * Gentle, soft breathing ripple on status changes and user interaction.
/// * Trailing satellite bubble with responsive elastic physics.
/// * 60/120fps hardware-accelerated vector rendering with soft ambient aura.
class AiNeuralCloudOrbWidget extends StatefulWidget {
  final double size;
  final bool showAmbientGlow;
  final Color? baseColor;
  final Color? accentColor;
  final VoidCallback? onTap;

  const AiNeuralCloudOrbWidget({
    super.key,
    this.size = 280,
    this.showAmbientGlow = true,
    this.baseColor,
    this.accentColor,
    this.onTap,
  });

  @override
  State<AiNeuralCloudOrbWidget> createState() => AiNeuralCloudOrbWidgetState();
}

class AiNeuralCloudOrbWidgetState extends State<AiNeuralCloudOrbWidget>
    with TickerProviderStateMixin
    implements AiNeuralCloudOrbState {
  late final AnimationController _continuousController;
  late final AnimationController _rippleController;
  late final Animation<double> _rippleAnimation;

  late final AnimationController _chargeController;
  late Animation<double> _chargeAnimation;

  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    // Continuous time driver (60s loop, seamlessly repeating)
    _continuousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Gentle organic ripple wave controller (750ms soft wave)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOutSine,
    );

    // Color charging animation controller
    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _chargeAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _chargeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _continuousController.dispose();
    _rippleController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  @override
  void triggerImpulse() => triggerRipple();

  @override
  void triggerRipple() {
    if (!mounted) return;
    _rippleController.forward(from: 0.0);
  }

  @override
  void incrementCharge() {
    _handleTap();
  }

  void _handleTap() {
    _tapCount++;
    final double targetCharge = math.min(_tapCount.toDouble(), 5.0);

    _chargeAnimation = Tween<double>(
      begin: _chargeAnimation.value,
      end: targetCharge,
    ).animate(
      CurvedAnimation(parent: _chargeController, curve: Curves.easeOutCubic),
    );

    _chargeController.forward(from: 0.0);
    HapticFeedbackService.instance.selectionFeedback();
    triggerRipple();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBase =
        widget.baseColor ?? (isDark ? Colors.white : Colors.black);
    final effectiveAccent =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _continuousController,
          _rippleAnimation,
          _chargeController,
        ]),
        builder: (context, child) {
          final time = _continuousController.value * 60.0;
          final rippleProgress = _rippleAnimation.value;
          final chargeProgress = _chargeAnimation.value;

          return RepaintBoundary(
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _OrganicLivingCloudPainter(
                time: time,
                ripple: rippleProgress,
                charge: chargeProgress,
                showAmbientGlow: widget.showAmbientGlow,
                baseColor: effectiveBase,
                accentColor: effectiveAccent,
                isDark: isDark,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrganicLivingCloudPainter extends CustomPainter {
  final double time;
  final double ripple;
  final double charge;
  final bool showAmbientGlow;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;

  _OrganicLivingCloudPainter({
    required this.time,
    required this.ripple,
    required this.charge,
    required this.showAmbientGlow,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 280.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Smooth sinusoidal ripple envelope (0 -> 1 -> 0)
    final rippleIntensity = (ripple > 0 && ripple < 1)
        ? math.sin(ripple * math.pi)
        : 0.0;

    // 1. Soft atmospheric background glow with dynamic color tint
    if (showAmbientGlow) {
      final glowBreathe = 0.92 +
          0.08 * math.sin(time * 1.6) +
          0.12 * rippleIntensity;
      final glowRadius = (125.0 + 12.0 * (charge / 5.0)) * scale * glowBreathe;

      if (isDark) {
        final glowPrimaryTint = Color.lerp(
          baseColor.withValues(alpha: 0.15),
          accentColor.withValues(alpha: 0.28),
          (charge / 5.0).clamp(0.0, 1.0),
        )!;

        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              glowPrimaryTint.withValues(alpha: (0.16 + 0.10 * rippleIntensity) * glowBreathe),
              accentColor.withValues(alpha: (0.04 + 0.08 * (charge / 5.0)) * glowBreathe),
              Colors.transparent,
            ],
            stops: const [0.0, 0.52, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: glowRadius))
          ..blendMode = BlendMode.screen;

        canvas.drawCircle(Offset.zero, glowRadius, glowPaint);
      } else {
        // Light mode atmospheric soft shadow/glow
        final glowPrimaryTint = Color.lerp(
          Colors.black.withValues(alpha: 0.06),
          accentColor.withValues(alpha: 0.18),
          (charge / 5.0).clamp(0.0, 1.0),
        )!;

        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              glowPrimaryTint.withValues(alpha: (0.12 + 0.08 * rippleIntensity) * glowBreathe),
              accentColor.withValues(alpha: (0.02 + 0.06 * (charge / 5.0)) * glowBreathe),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: glowRadius))
          ..blendMode = BlendMode.srcOver;

        canvas.drawCircle(Offset.zero, glowRadius, glowPaint);
      }
    }

    // 2. Continuous Liquid Dye Diffusion Shader
    final normalizedCharge = (charge / 5.0).clamp(0.0, 1.0);

    // Wave travels across the diagonal from bottom-left to top-right
    final gradientStart = Offset(-85.0 * scale, 85.0 * scale);
    final gradientEnd = Offset(85.0 * scale, -85.0 * scale);

    final waveCenter = -0.15 + 1.30 * normalizedCharge;
    const feather = 0.26;

    final stop1 = (waveCenter - feather).clamp(0.0, 1.0);
    final stop2 = (waveCenter + feather).clamp(0.0, 1.0);

    final Paint cloudPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    if (normalizedCharge <= 0.001) {
      cloudPaint.color = baseColor;
    } else if (normalizedCharge >= 0.999) {
      cloudPaint.color = accentColor;
    } else {
      cloudPaint.shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          accentColor,
          accentColor,
          baseColor,
          baseColor,
        ],
        stops: [
          0.0,
          stop1,
          stop2,
          1.0,
        ],
      ).createShader(Rect.fromPoints(gradientStart, gradientEnd));
    }

    // 3. Global constant, seamless rotation (16s cycle, zero phase jumps)
    final globalRotation = (time * (2 * math.pi / 16.0)) % (2 * math.pi);

    canvas.save();
    canvas.rotate(globalRotation);

    // Core center with alternating respiration
    final coreRespiration = 0.06 * math.sin(time * 2.0) +
        0.03 * math.cos(time * 3.6) +
        0.10 * rippleIntensity;
    final coreRadius = 49.0 * scale * (1.0 + coreRespiration);
    canvas.drawCircle(Offset.zero, coreRadius, cloudPaint);

    // 6 surrounding undulating lobes with multi-harmonic ripples
    const lobeCount = 6;
    const topLeftAngle = -0.75 * math.pi; // -135 deg in screen space

    for (int i = 0; i < lobeCount; i++) {
      final baseLobeAngle = i * (2 * math.pi / lobeCount);

      // Multi-frequency harmonic angle oscillation
      final primaryAngleWobble = 0.12 * math.sin(time * 1.7 + i * 1.5);
      final secondaryAngleWobble = 0.05 * math.cos(time * 3.3 + i * 2.3);
      final currentAngle = baseLobeAngle + primaryAngleWobble + secondaryAngleWobble;

      // Multi-frequency radial distance undulation
      final primaryDist = 6.0 * math.sin(time * 2.3 + i * 1.9);
      final secondaryDist = 3.0 * math.cos(time * 4.1 + i * 1.1);
      final distance = (35.0 + primaryDist + secondaryDist) * scale;

      final lobePos = Offset(
        distance * math.cos(currentAngle),
        distance * math.sin(currentAngle),
      );

      // Position-based scale: swells towards top-left (-135 deg in screen coordinates)
      final effectiveAngle = (currentAngle + globalRotation) % (2 * math.pi);
      final angleDiff = effectiveAngle - topLeftAngle;
      final posScale = 1.0 + 0.22 * math.cos(angleDiff); // 0.78 -> 1.22

      // Multi-harmonic lobe breathing & smooth additive ripple surge
      final primaryBreathe = 0.10 * math.cos(time * 2.5 + i * 1.7);
      final secondaryBreathe = 0.05 * math.sin(time * 5.0 + i * 2.8);
      final lobeRippleSurge = rippleIntensity * 0.14 * math.sin(ripple * math.pi + i * (math.pi / 3));

      final totalLobeScale = posScale * (1.0 + primaryBreathe + secondaryBreathe + lobeRippleSurge);
      final lobeRadius = 37.0 * scale * totalLobeScale;

      canvas.drawCircle(lobePos, lobeRadius, cloudPaint);
    }

    canvas.restore(); // Undo main rotation for the satellite bubble

    // 4. Detached trailing satellite bubble
    // Satellite turns green on the first tap (charge 0.0 -> 1.0)
    final satProgress = charge.clamp(0.0, 1.0);
    final satColor = Color.lerp(baseColor, accentColor, satProgress)!;

    final satPaint = Paint()
      ..color = satColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final satBreathe = 1.0 +
        0.12 * math.sin(time * 2.4) +
        0.05 * math.cos(time * 4.2) +
        0.12 * rippleIntensity;
    final satDistWobble = 4.0 * math.sin(time * 1.8);
    final satDist = (98.0 + satDistWobble) * scale;

    final satAngleDrift = 0.06 * math.cos(time * 1.4);
    const satBaseAngle = 0.72 * math.pi; // ~130 deg (bottom-left quadrant)
    final satAngle = satBaseAngle + satAngleDrift;

    final satPos = Offset(
      satDist * math.cos(satAngle),
      satDist * math.sin(satAngle),
    );
    final satRadius = 13.0 * scale * satBreathe;
    canvas.drawCircle(satPos, satRadius, satPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrganicLivingCloudPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.ripple != ripple ||
        oldDelegate.charge != charge ||
        oldDelegate.showAmbientGlow != showAmbientGlow ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
