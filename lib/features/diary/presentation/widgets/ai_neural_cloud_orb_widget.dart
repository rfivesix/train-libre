// lib/features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
/// * Seamless liquid dye diffusion: the vibrant primary green spreads across the
///   unified cloud silhouette without internal circular seam lines.
/// * Theme-adaptive: Automatically adapts between dark mode (white cloud on black) and
///   light mode (black cloud on white), flowing with the theme's primary accent color.
/// * Gentle, soft breathing ripple on status changes and user interaction.
/// * Trailing satellite bubble with responsive elastic physics.
/// * 60/120fps hardware-accelerated vector rendering with soft ambient aura.
///
/// [morph] and [energy] let the same cloud stand in for a microphone: at rest it
/// collapses to a plain circle, and it swells and flows faster with the voice
/// driving it.
class AiNeuralCloudOrbWidget extends StatefulWidget {
  final double size;
  final double rotation;
  final Size? canvasSize;
  final Offset? cloudCenter;

  /// Safe-space bounds for the expanded cloud-frame layout.
  final Rect? frameRect;

  /// Morphs the same orbiting cloud components from the center to four corners
  /// and the connecting frame edges.
  final double frameMorph;

  /// Optional external transition clock for synchronized overlay gestures.
  final Animation<double>? frameMorphAnimation;
  final bool showAmbientGlow;

  /// Whether to draw the detached trailing bubble beside the cloud.
  ///
  /// It is part of the AI-oriented treatment by default, but callers such as
  /// app startup can keep the silhouette purely decorative.
  final bool showDetachedSatellite;
  final Color? baseColor;
  final Color? accentColor;
  final VoidCallback? onTap;

  /// 0 collapses the lobes into a single calm circle, 1 is the full cloud.
  /// Animated internally, so callers can flip it between the two.
  final double morph;

  /// Drives the silhouette directly for compound transitions where another
  /// shape (for example a number made of pixels) must meet this cloud on the
  /// exact same frame. Normal callers should leave this null and use [morph].
  final double? instantaneousMorph;

  /// Live input level, 0 to 1. Swells the silhouette and speeds up the flow.
  /// Smoothed here rather than by the caller, so it decays gently into silence
  /// instead of snapping back between microphone callbacks.
  final double energy;

  /// Multiplier on how fast the cloud flows at rest.
  ///
  /// The analysis screen wants the full pace; a microphone waiting for someone
  /// to speak should be noticeably calmer than that, or the motion reads as
  /// impatience.
  final double flowSpeed;

  /// Whether the cloud should keep its autonomous, continuous motion.
  ///
  /// Set this to false for progress-driven contexts such as app startup. The
  /// cloud can still morph and change colour through [morph] and [tint], but
  /// it consumes no per-frame ticker work while the progress is unchanged.
  final bool animate;

  /// Whether taps may trigger the widget's own ripple and colour response.
  /// Decorative uses can disable this when an ancestor handles interaction.
  final bool enableInteraction;

  /// Drives the base-to-accent dye sweep from outside, 0 to 1.
  ///
  /// The scale is the same five dye steps the tap counter walks through, so
  /// 0.4 is "step 2". Null leaves the colour to the widget's own tap/charge
  /// counter, which is what the analysis screen uses. Anything else takes it
  /// over completely — a tap then only reports back and never changes the
  /// colour by itself.
  final double? tint;

  /// How much further [energy] pushes the dye on top of [tint], 0 to 1.
  ///
  /// Applied per frame from the smoothed energy rather than through the tint
  /// animation: the level arrives many times a second, and restarting a 450 ms
  /// animation on each one would leave it permanently mid-flight and visibly
  /// stuck. Zero by default, so it is inert for callers that do not feed a
  /// level in.
  final double tintEnergyGain;

  const AiNeuralCloudOrbWidget({
    super.key,
    this.size = 280,
    this.rotation = 0,
    this.canvasSize,
    this.cloudCenter,
    this.frameRect,
    this.frameMorph = 0,
    this.frameMorphAnimation,
    this.showAmbientGlow = true,
    this.showDetachedSatellite = true,
    this.baseColor,
    this.accentColor,
    this.onTap,
    this.morph = 1.0,
    this.instantaneousMorph,
    this.energy = 0.0,
    this.flowSpeed = 1.0,
    this.animate = true,
    this.enableInteraction = true,
    this.tint,
    this.tintEnergyGain = 0.0,
  });

  @override
  State<AiNeuralCloudOrbWidget> createState() => AiNeuralCloudOrbWidgetState();
}

class AiNeuralCloudOrbWidgetState extends State<AiNeuralCloudOrbWidget>
    with TickerProviderStateMixin
    implements AiNeuralCloudOrbState {
  /// Accumulated flow time in seconds, advanced by the ticker at a rate that
  /// rises with [AiNeuralCloudOrbWidget.energy].
  ///
  /// A repeating controller cannot do this: its value wraps, and because the
  /// harmonics are not whole multiples of the loop the shape jumped every time
  /// it did. Integrating the delta keeps the motion continuous *and* lets the
  /// speed change mid-flight.
  final ValueNotifier<double> _flow = ValueNotifier<double>(0);
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// Smoothed [AiNeuralCloudOrbWidget.energy].
  double _energy = 0;

  late final AnimationController _rippleController;
  late final Animation<double> _rippleAnimation;

  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;

  late final AnimationController _chargeController;
  late Animation<double> _chargeAnimation;

  int _tapCount = 0;

  bool get _externallyTinted => widget.tint != null;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
    if (widget.animate) _ticker.start();

    // Gentle organic ripple wave controller (750ms soft wave)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOutSine,
    );

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      value: widget.morph.clamp(0.0, 1.0),
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Color charging animation controller
    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    final initialCharge = (widget.tint ?? 0) * 5.0;
    _chargeAnimation = Tween<double>(
      begin: initialCharge,
      end: initialCharge,
    ).animate(
      CurvedAnimation(parent: _chargeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(AiNeuralCloudOrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.instantaneousMorph == null && oldWidget.morph != widget.morph) {
      _morphController.animateTo(widget.morph.clamp(0.0, 1.0));
    }

    final tint = widget.tint;
    if (tint != null && tint != oldWidget.tint) {
      _animateChargeTo(tint.clamp(0.0, 1.0) * 5.0);
    }

    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _lastTick = Duration.zero;
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  void _onTick(Duration elapsed) {
    // Capped: the ticker is muted while the route is not current, and without
    // a cap the first frame after coming back would jump the flow forward by
    // however long the sheet sat in the background.
    final dt = _lastTick == Duration.zero
        ? 1 / 60
        : math.min(
            (elapsed - _lastTick).inMicroseconds / 1000000.0,
            1 / 20,
          );
    _lastTick = elapsed;
    if (dt <= 0) return;

    // Exponential approach: loud syllables arrive as spikes, and following them
    // literally makes the cloud stutter rather than breathe.
    final target = widget.energy.clamp(0.0, 1.0);
    _energy += (target - _energy) * math.min(1.0, dt * 7.0);

    _flow.value += dt * widget.flowSpeed * (1.0 + 2.4 * _energy);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _flow.dispose();
    _rippleController.dispose();
    _morphController.dispose();
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
    if (_externallyTinted) return;
    _tapCount++;
    _animateChargeTo(math.min(_tapCount.toDouble(), 5.0));
  }

  void _animateChargeTo(double target) {
    _chargeAnimation = Tween<double>(
      begin: _chargeAnimation.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _chargeController, curve: Curves.easeOutCubic),
    );
    _chargeController.forward(from: 0.0);
  }

  void _handleTap() {
    if (!widget.enableInteraction) return;
    // The colour is the caller's business when it hands one in; charging on tap
    // as well would fight whatever it is trying to say.
    if (!_externallyTinted) {
      _tapCount++;
      _animateChargeTo(math.min(_tapCount.toDouble(), 5.0));
    }
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
      onTap: widget.enableInteraction ? _handleTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _flow,
          _rippleAnimation,
          _morphAnimation,
          _chargeController,
          if (widget.frameMorphAnimation != null) widget.frameMorphAnimation!,
        ]),
        builder: (context, child) {
          return RepaintBoundary(
            child: CustomPaint(
              size: widget.canvasSize ?? Size(widget.size, widget.size),
              painter: _OrganicLivingCloudPainter(
                cloudSize: widget.size,
                rotation: widget.rotation,
                cloudCenter: widget.cloudCenter,
                frameRect: widget.frameRect,
                frameMorph:
                    (widget.frameMorphAnimation?.value ?? widget.frameMorph)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                time: _flow.value,
                ripple: _rippleAnimation.value,
                charge: (_chargeAnimation.value +
                        widget.tintEnergyGain * _energy * 5.0)
                    .clamp(0.0, 5.0),
                morph: (widget.instantaneousMorph ?? _morphAnimation.value)
                    .clamp(0.0, 1.0),
                energy: _energy,
                showAmbientGlow: widget.showAmbientGlow,
                showDetachedSatellite: widget.showDetachedSatellite,
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
  final double cloudSize;
  final double rotation;
  final Offset? cloudCenter;
  final Rect? frameRect;
  final double frameMorph;
  final double time;
  final double ripple;
  final double charge;

  /// 0 draws a single calm circle, 1 the full lobed cloud.
  final double morph;

  /// Smoothed input level, 0 to 1.
  final double energy;

  final bool showAmbientGlow;
  final bool showDetachedSatellite;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;

  _OrganicLivingCloudPainter({
    required this.cloudSize,
    required this.rotation,
    required this.cloudCenter,
    required this.frameRect,
    required this.frameMorph,
    required this.time,
    required this.ripple,
    required this.charge,
    required this.morph,
    required this.energy,
    required this.showAmbientGlow,
    required this.showDetachedSatellite,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = cloudCenter ?? Offset(size.width / 2, size.height / 2);
    final scale = cloudSize / 280.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Smooth sinusoidal ripple envelope (0 -> 1 -> 0)
    final rippleIntensity =
        (ripple > 0 && ripple < 1) ? math.sin(ripple * math.pi) : 0.0;

    // Every undulation is scaled by how far into the cloud we are: at rest the
    // circle must be genuinely still, or it reads as a loading spinner rather
    // than as something waiting to be tapped.
    final motion = morph;

    // 1. Soft atmospheric background glow with dynamic color tint
    if (showAmbientGlow && morph > 0.01 && frameMorph < 0.999) {
      final glowBreathe = (0.92 +
              0.08 * math.sin(time * 1.6) * motion +
              0.12 * rippleIntensity +
              0.18 * energy) *
          morph.clamp(0.0, 1.0) *
          (1.0 - frameMorph).clamp(0.0, 1.0);
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
              glowPrimaryTint.withValues(
                  alpha: (0.16 + 0.10 * rippleIntensity + 0.14 * energy) *
                      glowBreathe),
              accentColor.withValues(
                  alpha: (0.04 + 0.08 * (charge / 5.0)) * glowBreathe),
              Colors.transparent,
            ],
            stops: const [0.0, 0.52, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: glowRadius))
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
              glowPrimaryTint.withValues(
                  alpha: (0.12 + 0.08 * rippleIntensity + 0.10 * energy) *
                      glowBreathe),
              accentColor.withValues(
                  alpha: (0.02 + 0.06 * (charge / 5.0)) * glowBreathe),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: glowRadius))
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
    final safeRect = frameRect?.shift(Offset(-center.dx, -center.dy));
    if (safeRect != null && frameMorph > 0.001) {
      final spread = Curves.easeInOutCubic.transform(
        frameMorph.clamp(0.0, 1.0).toDouble(),
      );
      // The inner fill tracks the same four moving corner centers as the cloud.
      final fillBounds = Rect.lerp(Rect.zero, safeRect.inflate(24), spread)!;
      canvas.drawRect(fillBounds, cloudPaint);
    }

    if (safeRect == null || frameMorph <= 0.001) {
      _drawOrganicCloudCluster(
        canvas: canvas,
        paint: cloudPaint,
        center: Offset.zero,
        scale: scale,
        sizeFactor: 1,
        time: time,
        phaseOffset: 0,
        motion: motion,
        energy: energy,
        rippleIntensity: rippleIntensity,
        ripple: ripple,
        morph: morph,
        rotation: globalRotation + rotation,
      );
    } else {
      _drawMorphingCloudFrame(
        canvas: canvas,
        paint: cloudPaint,
        sourceCenter: Offset.zero,
        safeRect: safeRect,
        frameMorph: frameMorph,
        scale: scale,
        time: time,
        motion: motion,
        energy: energy,
        rippleIntensity: rippleIntensity,
        ripple: ripple,
        morph: morph,
        rotation: globalRotation + rotation,
      );
    }

    // 4. Detached trailing satellite bubble — only once there is a cloud for it
    // to have detached from.
    if (showDetachedSatellite && morph > 0.02 && frameMorph <= 0.001) {
      final satProgress = charge.clamp(0.0, 1.0);
      final satColor = Color.lerp(baseColor, accentColor, satProgress)!;

      final satPaint = Paint()
        ..color = satColor.withValues(alpha: satColor.a * morph)
        ..isAntiAlias = true
        ..style = PaintingStyle.fill;

      final satBreathe = 1.0 +
          (0.12 * math.sin(time * 2.4) + 0.05 * math.cos(time * 4.2)) * motion +
          0.12 * rippleIntensity +
          0.22 * energy;
      final satDistWobble = 4.0 * math.sin(time * 1.8) * motion;
      final satDist = (98.0 + satDistWobble) * scale * morph;

      final satAngleDrift = 0.06 * math.cos(time * 1.4) * motion;
      const satBaseAngle = 0.72 * math.pi; // ~130 deg (bottom-left quadrant)
      final satAngle = satBaseAngle + satAngleDrift;

      final satPos = Offset(
        satDist * math.cos(satAngle),
        satDist * math.sin(satAngle),
      );
      final satRadius = 13.0 * scale * satBreathe * morph;
      canvas.drawCircle(satPos, satRadius, satPaint);
    }

    canvas.restore();
  }

  void _drawMorphingCloudFrame({
    required Canvas canvas,
    required Paint paint,
    required Offset sourceCenter,
    required Rect safeRect,
    required double frameMorph,
    required double scale,
    required double time,
    required double motion,
    required double energy,
    required double rippleIntensity,
    required double ripple,
    required double morph,
    required double rotation,
  }) {
    final spread = Curves.easeInOutCubic.transform(
      frameMorph.clamp(0.0, 1.0).toDouble(),
    );
    final frameBounds = safeRect.inflate(24);
    final sourceSize = (1.0 - spread).clamp(0.0, 1.0).toDouble();

    // The original orb recedes as its individual cloud lobes travel out to
    // form the expanded perimeter.
    _drawOrganicCloudCluster(
      canvas: canvas,
      paint: paint,
      center: sourceCenter,
      scale: scale,
      sizeFactor: sourceSize,
      time: time,
      phaseOffset: 0,
      motion: motion,
      energy: energy,
      rippleIntensity: rippleIntensity,
      ripple: ripple,
      morph: morph,
      rotation: rotation,
    );

    final corners = <Offset>[
      frameBounds.topLeft,
      frameBounds.topRight,
      frameBounds.bottomRight,
      frameBounds.bottomLeft,
    ];
    for (var index = 0; index < corners.length; index++) {
      final sizeVariation = 1.08 + 0.09 * math.sin(index * 1.8 + 0.4);
      _drawOrganicCloudPuff(
        canvas: canvas,
        paint: paint,
        sourceCenter: sourceCenter,
        targetCenter: corners[index],
        frameCenter: frameBounds.center,
        scale: scale,
        spread: spread,
        time: time,
        phase: index * 0.83,
        sizeVariation: sizeVariation,
        motion: motion,
        energy: energy,
        rippleIntensity: rippleIntensity,
        ripple: ripple,
        morph: morph,
      );
    }

    // Larger individual lobes follow the sides of the rectangle: four across
    // the shorter edges and six down each side.
    const horizontalIntervals = 4;
    const verticalIntervals = 7;
    for (var index = 1; index < horizontalIntervals; index++) {
      final along = index / horizontalIntervals;
      final sizeVariation = 0.98 +
          0.12 * math.sin(index * 2.1 + 0.5) +
          0.06 * math.cos(index * 1.3);
      for (final y in [frameBounds.top, frameBounds.bottom]) {
        _drawOrganicCloudPuff(
          canvas: canvas,
          paint: paint,
          sourceCenter: sourceCenter,
          targetCenter: Offset.lerp(
            Offset(frameBounds.left, y),
            Offset(frameBounds.right, y),
            along,
          )!,
          frameCenter: frameBounds.center,
          scale: scale,
          spread: spread,
          time: time,
          phase: (y == frameBounds.top ? 0.2 : 2.4) + index * 0.91,
          sizeVariation: sizeVariation,
          motion: motion,
          energy: energy,
          rippleIntensity: rippleIntensity,
          ripple: ripple,
          morph: morph,
        );
      }
    }

    for (var index = 1; index < verticalIntervals; index++) {
      final along = index / verticalIntervals;
      final sizeVariation = 1.0 +
          0.11 * math.sin(index * 1.71 + 0.3) +
          0.06 * math.cos(index * 2.23);
      for (final x in [frameBounds.left, frameBounds.right]) {
        _drawOrganicCloudPuff(
          canvas: canvas,
          paint: paint,
          sourceCenter: sourceCenter,
          targetCenter: Offset.lerp(
            Offset(x, frameBounds.top),
            Offset(x, frameBounds.bottom),
            along,
          )!,
          frameCenter: frameBounds.center,
          scale: scale,
          spread: spread,
          time: time,
          phase: (x == frameBounds.left ? 1.1 : 3.6) + index * 0.73,
          sizeVariation: sizeVariation,
          motion: motion,
          energy: energy,
          rippleIntensity: rippleIntensity,
          ripple: ripple,
          morph: morph,
        );
      }
    }
  }

  void _drawOrganicCloudPuff({
    required Canvas canvas,
    required Paint paint,
    required Offset sourceCenter,
    required Offset targetCenter,
    required Offset frameCenter,
    required double scale,
    required double spread,
    required double time,
    required double phase,
    required double sizeVariation,
    required double motion,
    required double energy,
    required double rippleIntensity,
    required double ripple,
    required double morph,
  }) {
    final localTime = time + phase;
    final radial = targetCenter - frameCenter;
    final radialLength = radial.distance;
    final normal = radialLength > 0 ? radial / radialLength : Offset.zero;
    final orbit = normal *
        (3.2 * math.sin(localTime * 1.7) + 1.4 * math.cos(localTime * 2.6)) *
        spread;
    final center = Offset.lerp(sourceCenter, targetCenter, spread)! + orbit;
    final primaryBreathe = 0.10 * math.cos(localTime * 2.5) * motion;
    final secondaryBreathe = 0.05 * math.sin(localTime * 5.0) * motion;
    final rippleSurge =
        rippleIntensity * 0.12 * math.sin(ripple * math.pi + phase);
    final energySwell = 1.0 + 0.85 * energy;
    final lobeBase = 10.0 + (37.0 - 10.0) * morph;
    final radius = lobeBase *
        scale *
        3.0 *
        sizeVariation *
        spread *
        (1 + primaryBreathe + secondaryBreathe + rippleSurge) *
        energySwell;
    if (radius > 0.01) canvas.drawCircle(center, radius, paint);
  }

  void _drawOrganicCloudCluster({
    required Canvas canvas,
    required Paint paint,
    required Offset center,
    required double scale,
    required double sizeFactor,
    required double time,
    required double phaseOffset,
    required double motion,
    required double energy,
    required double rippleIntensity,
    required double ripple,
    required double morph,
    required double rotation,
  }) {
    if (sizeFactor <= 0.001) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final localTime = time + phaseOffset;
    final coreRespiration =
        (0.06 * math.sin(localTime * 2.0) + 0.03 * math.cos(localTime * 3.6)) *
                motion +
            0.10 * rippleIntensity +
            0.09 * energy;
    final coreBase = 62.0 + (49.0 - 62.0) * morph;
    final coreRadius = coreBase * scale * sizeFactor * (1.0 + coreRespiration);
    canvas.drawCircle(Offset.zero, coreRadius, paint);

    const lobeCount = 6;
    const topLeftAngle = -0.75 * math.pi;
    final swell = 1.0 + 0.85 * energy;
    for (var index = 0; index < lobeCount; index++) {
      final baseAngle = index * (2 * math.pi / lobeCount);
      final angle = baseAngle +
          0.12 * math.sin(localTime * 1.7 + index * 1.5) * motion +
          0.05 * math.cos(localTime * 3.3 + index * 2.3) * motion;
      final distance = (35.0 * morph +
              13.0 * energy * morph +
              6.0 * math.sin(localTime * 2.3 + index * 1.9) * motion +
              3.0 * math.cos(localTime * 4.1 + index * 1.1) * motion) *
          scale *
          sizeFactor;
      final lobePosition = Offset(
        distance * math.cos(angle),
        distance * math.sin(angle),
      );
      final effectiveAngle = (angle + rotation) % (2 * math.pi);
      final angleDiff = effectiveAngle - topLeftAngle;
      final positionalScale = 1.0 + 0.22 * math.cos(angleDiff) * motion;
      final primaryBreathe =
          0.10 * math.cos(localTime * 2.5 + index * 1.7) * motion;
      final secondaryBreathe =
          0.05 * math.sin(localTime * 5.0 + index * 2.8) * motion;
      final rippleSurge = rippleIntensity *
          0.14 *
          math.sin(ripple * math.pi + index * (math.pi / 3));
      final lobeScale = positionalScale *
          (1.0 + primaryBreathe + secondaryBreathe + rippleSurge);
      final lobeBase = 10.0 + (37.0 - 10.0) * morph;
      final lobeRadius = lobeBase * scale * sizeFactor * lobeScale * swell;
      canvas.drawCircle(lobePosition, lobeRadius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrganicLivingCloudPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.cloudSize != cloudSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.cloudCenter != cloudCenter ||
        oldDelegate.frameRect != frameRect ||
        oldDelegate.frameMorph != frameMorph ||
        oldDelegate.ripple != ripple ||
        oldDelegate.charge != charge ||
        oldDelegate.morph != morph ||
        oldDelegate.energy != energy ||
        oldDelegate.showAmbientGlow != showAmbientGlow ||
        oldDelegate.showDetachedSatellite != showDetachedSatellite ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
