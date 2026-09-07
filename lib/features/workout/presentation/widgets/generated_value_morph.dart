import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';

// Mirrors the calm core in AiNeuralCloudOrbWidget's painter: 62 logical
// units in a 280-unit canvas. Keeping this shared conversion explicit makes
// the pixel circle and the cloud's collapsed circle the same physical shape.
const _cloudSize = 48.0;
const _cloudRestingRadius = 62.0 / 280.0 * _cloudSize;

// TextPainter's glyph box and InputDecorator's editable baseline differ by a
// single logical pixel in the live workout row. Align the moving glyph to the
// real field, not merely to its enclosing Stack, so the final hand-off has no
// down-right jump.
const _inputGlyphAlignmentOffset = Offset(-1, -1);

/// Turns an old generated number into an AI cloud and back into the new value.
///
/// This intentionally does not use blur, fade-outs, or two overlapping text
/// widgets. It rasterises visible glyph pixels, moves those exact pixels into
/// a compact white circle, lets the existing cloud grow from that circle, and
/// reverses the same route for the incoming value.
class GeneratedValueMorph extends StatefulWidget {
  final String? suggestionKey;
  final String value;
  final Color accentColor;
  final Color restingColor;
  final TextStyle morphTextStyle;
  final Widget Function(Color textColor) childBuilder;

  const GeneratedValueMorph({
    super.key,
    required this.suggestionKey,
    required this.value,
    required this.accentColor,
    required this.restingColor,
    required this.morphTextStyle,
    required this.childBuilder,
  });

  @override
  State<GeneratedValueMorph> createState() => _GeneratedValueMorphState();
}

class _GeneratedValueMorphState extends State<GeneratedValueMorph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _PixelField? _outgoingPixels;
  _PixelField? _incomingPixels;
  var _captureGeneration = 0;

  bool get _isGenerated => widget.suggestionKey != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    if (_isGenerated) {
      // A first render has no old number, only a cloud resolving into the new
      // generated value.
      _capturePixelFields(outgoing: '', incoming: widget.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(GeneratedValueMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isGenerated && oldWidget.suggestionKey != widget.suggestionKey) {
      // [oldWidget.value] is frozen from the previous build, before the
      // TextEditingController received the new suggestion.
      _capturePixelFields(
        outgoing: oldWidget.value,
        incoming: widget.value,
      );
      _controller.forward(from: 0);
    } else if (!_isGenerated) {
      _controller.value = 1;
    }
  }

  void _capturePixelFields({
    required String outgoing,
    required String incoming,
  }) {
    final generation = ++_captureGeneration;
    final fields = [
      _PixelField.fromText(
        outgoing,
        widget.morphTextStyle,
        widget.accentColor,
      ),
      _PixelField.fromText(
        incoming,
        widget.morphTextStyle,
        widget.restingColor,
      ),
    ];
    // Picture rasterisation can complete in the middle of layout. Defer the
    // state swap to the next frame; changing a semantics-bearing subtree while
    // its parent data is being calculated corrupts the workout screen's render
    // pass on iOS.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _captureGeneration) {
        for (final field in fields) {
          field?.dispose();
        }
        return;
      }

      setState(() {
        _outgoingPixels?.dispose();
        _incomingPixels?.dispose();
        _outgoingPixels = fields[0];
        _incomingPixels = fields[1];
      });
    });
  }

  @override
  void dispose() {
    _captureGeneration++;
    _outgoingPixels?.dispose();
    _incomingPixels?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGenerated) return widget.childBuilder(widget.restingColor);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final timeline = _controller.value;
        // Number -> white circle, circle -> cloud, cloud -> circle, circle
        // -> number. The circle windows overlap so every transition has a
        // real shared shape rather than an opacity cut.
        final outgoingProgress =
            Curves.easeInOutCubic.transform((timeline / 0.30).clamp(0.0, 1.0));
        final incomingProgress = Curves.easeInOutCubic
            .transform(((timeline - 0.70) / 0.30).clamp(0.0, 1.0));
        final cloudMorph = timeline < 0.44
            ? Curves.easeInOutCubic
                .transform(((timeline - 0.28) / 0.16).clamp(0.0, 1.0))
            : timeline > 0.56
                ? 1 -
                    Curves.easeInOutCubic
                        .transform(((timeline - 0.56) / 0.16).clamp(0.0, 1.0))
                : 1.0;
        final cloudVisible = timeline >= 0.28 && timeline <= 0.72;
        final textColor = _incomingColor(incomingProgress);

        return Stack(
          alignment: Alignment.center,
          children: [
            // This non-positioned child owns the row's finite height. The
            // surrounding workout list gives rows a loose vertical constraint,
            // so the visual layers below must never make the Stack expand.
            Opacity(
              // This is deliberately a binary visibility switch, not a fade:
              // the static field appears only once its moving pixel twin has
              // already formed the exact same number.
              opacity: incomingProgress >= 1 ? 1 : 0,
              child: widget.childBuilder(textColor),
            ),
            if (_outgoingPixels case final outgoingPixels?
                when timeline <= 0.30)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('generated-value-morph-outgoing'),
                    painter: _PixelCirclePainter(
                      field: outgoingPixels,
                      progress: outgoingProgress,
                      towardCircle: true,
                      fromColor: widget.accentColor,
                      toColor: Colors.white,
                    ),
                  ),
                ),
              ),
            if (cloudVisible)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AiNeuralCloudOrbWidget(
                      size: _cloudSize,
                      showAmbientGlow: true,
                      baseColor: Colors.white,
                      accentColor: widget.accentColor,
                      // Bypasses the cloud's own easing so its circle meets
                      // the circle made by the number pixels on this frame.
                      morph: 0,
                      instantaneousMorph: cloudMorph,
                      tint: 0.4,
                      energy: 0.35,
                      flowSpeed: 2.2,
                    ),
                  ),
                ),
              ),
            if (_incomingPixels case final incomingPixels?
                when timeline >= 0.70 && timeline < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('generated-value-morph-incoming'),
                    painter: _PixelCirclePainter(
                      field: incomingPixels,
                      progress: incomingProgress,
                      towardCircle: false,
                      fromColor: Colors.white,
                      toColor: widget.restingColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _incomingColor(double progress) {
    // The new number first inherits the AI accent, then settles into the
    // ordinary input colour without a separate fade-in stage.
    final accentPhase = (progress / 0.42).clamp(0.0, 1.0);
    if (accentPhase < 1) {
      return Color.lerp(Colors.white, widget.accentColor, accentPhase) ??
          widget.accentColor;
    }
    return Color.lerp(
          widget.accentColor,
          widget.restingColor,
          ((progress - 0.42) / 0.58).clamp(0.0, 1.0),
        ) ??
        widget.restingColor;
  }
}

class _PixelField {
  static const _circleRadius = _cloudRestingRadius;
  static const _goldenAngle = 2.399963229728653;

  final TextPainter textPainter;
  final Size size;
  final List<_GlyphPixel> pixels;

  const _PixelField({
    required this.textPainter,
    required this.size,
    required this.pixels,
  });

  static _PixelField? fromText(
    String text,
    TextStyle style,
    Color color,
  ) {
    if (text.isEmpty) return null;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = math.max(1, textPainter.width.ceil() + 2);
    final height = math.max(1, textPainter.height.ceil() + 2);
    // Moving every cell is safe: empty cells remain empty, while the visible
    // glyph pixels travel with their own clipped 1×1 source cells.
    final sources = <Rect>[
      for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
    ];
    final pixels = <_GlyphPixel>[];
    for (var index = 0; index < sources.length; index++) {
      final fraction = (index + 0.5) / sources.length;
      final radius = math.sqrt(fraction) * _circleRadius;
      final angle = index * _goldenAngle;
      pixels.add(
        _GlyphPixel(
          source: sources[index],
          circlePoint: Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          ),
        ),
      );
    }
    return _PixelField(
      textPainter: textPainter,
      size: Size(width.toDouble(), height.toDouble()),
      pixels: pixels,
    );
  }

  void dispose() => textPainter.dispose();
}

class _GlyphPixel {
  final Rect source;
  final Offset circlePoint;

  const _GlyphPixel({required this.source, required this.circlePoint});
}

class _PixelCirclePainter extends CustomPainter {
  final _PixelField field;
  final double progress;
  final bool towardCircle;
  final Color fromColor;
  final Color toColor;

  const _PixelCirclePainter({
    required this.field,
    required this.progress,
    required this.towardCircle,
    required this.fromColor,
    required this.toColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2);
    final sourceOrigin = Offset(field.size.width / 2, field.size.height / 2);
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = ColorFilter.mode(
          Color.lerp(fromColor, toColor, progress) ?? toColor,
          BlendMode.srcIn,
        ),
    );

    for (final pixel in field.pixels) {
      final sourceCenter =
          pixel.source.center - sourceOrigin + _inputGlyphAlignmentOffset;
      final localCenter = towardCircle
          ? Offset.lerp(sourceCenter, pixel.circlePoint, progress) ??
              pixel.circlePoint
          : Offset.lerp(pixel.circlePoint, sourceCenter, progress) ??
              sourceCenter;
      // Source and destination use the same hard pixel size. The pixels are
      // genuinely re-positioned into the cloud's circle; they do not inflate
      // into a different, larger circle while travelling there.
      const pixelSize = 1.0;
      final destination = Rect.fromCenter(
        center: origin + localCenter,
        width: pixelSize,
        height: pixelSize,
      );
      canvas.save();
      canvas.clipRect(destination, doAntiAlias: false);
      // Translate the original glyph so the selected source cell lands in the
      // destination cell. The glyph is never blurred, scaled or redrawn as a
      // different shape; its existing pixels physically travel across canvas.
      canvas.translate(
        destination.left - pixel.source.left,
        destination.top - pixel.source.top,
      );
      field.textPainter.paint(canvas, const Offset(1, 1));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PixelCirclePainter oldDelegate) =>
      oldDelegate.field != field ||
      oldDelegate.progress != progress ||
      oldDelegate.towardCircle != towardCircle ||
      oldDelegate.fromColor != fromColor ||
      oldDelegate.toColor != toColor;
}
