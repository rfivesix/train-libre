import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../util/design_constants.dart';
import '../../../../util/glass_preferences.dart';

const _thumbDiameter = 52.0;

/// A compact, discrete gradient scale with its labels inside the track.
///
/// [value] must be between [min] and [max]. Touch and accessibility actions
/// snap to [step], including the two endpoints.
class GradientStepSlider extends StatefulWidget {
  const GradientStepSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.step,
    required this.labels,
    required this.colors,
    this.semanticLabel,
  }) : assert(max > min),
       assert(step > 0),
       assert(colors.length >= 2);

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final Map<double, String> labels;
  final List<Color> colors;
  final String? semanticLabel;

  @override
  State<GradientStepSlider> createState() => _GradientStepSliderState();
}

class _GradientStepSliderState extends State<GradientStepSlider> {
  double? _dragValue;
  double get min => widget.min;
  double get max => widget.max;
  double get step => widget.step;
  double get value => widget.value;
  ValueChanged<double> get onChanged => widget.onChanged;
  Map<double, String> get labels => widget.labels;
  List<Color> get colors => widget.colors;
  String? get semanticLabel => widget.semanticLabel;

  double _snap(double v) =>
      (min + ((v - min) / step).round() * step).clamp(min, max).toDouble();

  String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final current = value.clamp(min, max).toDouble();
    final visual = (_dragValue ?? current).clamp(min, max).toDouble();
    void adjust(double amount) => onChanged(_snap(current + amount));

    return Semantics(
      label: semanticLabel,
      value: _format(current),
      increasedValue: _format(_snap(current + step)),
      decreasedValue: _format(_snap(current - step)),
      onIncrease: current < max ? () => adjust(step) : null,
      onDecrease: current > min ? () => adjust(-step) : null,
      slider: true,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.arrowUp) {
            adjust(step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            adjust(-step);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            void setPosition(Offset point) {
              // The thumb is centered at either end of the track.
              const inset = _thumbDiameter / 2;
              final usable = math.max(1.0, width - inset * 2);
              final fraction = ((point.dx - inset) / usable).clamp(0.0, 1.0);
              final next = min + fraction * (max - min);
              setState(() => _dragValue = next);
              final snapped = _snap(next);
              if (snapped != current) onChanged(snapped);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => setPosition(details.localPosition),
              onTapUp: (_) => setState(() => _dragValue = null),
              onTapCancel: () {
                if (_dragValue != null) setState(() => _dragValue = null);
              },
              onHorizontalDragEnd: (_) => setState(() => _dragValue = null),
              onHorizontalDragCancel: () => setState(() => _dragValue = null),
              onHorizontalDragStart: (details) =>
                  setPosition(details.localPosition),
              onHorizontalDragUpdate: (details) =>
                  setPosition(details.localPosition),
              child: SizedBox(
                height: _thumbDiameter,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (visual - min) / (max - min)),
                  duration: _dragValue == null
                      ? const Duration(milliseconds: 160)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  builder: (context, fraction, _) {
                    final colorPosition = fraction * (colors.length - 1);
                    final colorIndex = math.min(
                      colorPosition.floor(),
                      colors.length - 2,
                    );
                    final base = Color.lerp(
                      colors[colorIndex],
                      colors[colorIndex + 1],
                      colorPosition - colorIndex,
                    )!;
                    final vivid = HSVColor.fromColor(base)
                        .withSaturation(1)
                        .toColor();
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GradientStepPainter(
                              fraction: fraction,
                              isDark:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                              min: min,
                              max: max,
                              labels: labels,
                              colors: colors,
                              textStyle: Theme.of(context).textTheme.labelSmall!
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: width < 275 ? 10 : 12,
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                        left: (width - _thumbDiameter) * fraction,
                        top: 0,
                          child: IgnorePointer(
                            child: GlassAdaptiveScope(
                              maxQuality: DesignConstants.defaultGlassQuality,
                              minQuality: DesignConstants.minGlassQuality,
                              child: RepaintBoundary(
                                child: GlassContainer(
                                  useOwnLayer: true,
                                width: _thumbDiameter,
                                height: _thumbDiameter,
                                  shape: const LiquidOval(),
                                  quality: DesignConstants.defaultGlassQuality,
                                  settings: GlassPreferences.of(context)
                                      .apply(
                                        DesignConstants.liquidGlassSettings(
                                          Theme.of(context).brightness ==
                                              Brightness.dark,
                                        ),
                                        premium: true,
                                      )
                                      .copyWith(blur: 12, saturation: 2.8),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.lerp(
                                            vivid,
                                            Colors.white,
                                            0.22,
                                          )!,
                                          vivid,
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// RPE scale matching the effort colours used in the explanation.
class RpeGradientSlider extends StatelessWidget {
  const RpeGradientSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => GradientStepSlider(
    value: value,
    onChanged: onChanged,
    min: 6,
    max: 10,
    step: 0.5,
    semanticLabel: semanticLabel,
    colors: const [
      Color(0xff25c75b),
      Color(0xffd4d50b),
      Color(0xffff9100),
      Color(0xffed2323),
    ],
    labels: {
      6: '6',
      6.5: '6.5',
      7: '7',
      7.5: '7.5',
      8: '8',
      8.5: '8.5',
      9: '9',
      9.5: '9.5',
      10: '10',
    },
  );
}

class _GradientStepPainter extends CustomPainter {
  const _GradientStepPainter({
    required this.fraction,
    required this.isDark,
    required this.min,
    required this.max,
    required this.labels,
    required this.colors,
    required this.textStyle,
  });

  final double fraction;
  final bool isDark;
  final double min;
  final double max;
  final Map<double, String> labels;
  final List<Color> colors;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 21.0;
    const left = _thumbDiameter / 2;
    final right = math.max(left + 1, size.width - left);
    final centerY = size.height / 2;
    final track = Rect.fromLTRB(
      0,
      centerY - radius,
      size.width,
      centerY + radius,
    );
    final rounded = RRect.fromRectAndRadius(
      track,
      const Radius.circular(radius),
    );
    final gradient = LinearGradient(colors: colors);
    final gradientPaint = Paint()..shader = gradient.createShader(track);
    canvas.drawRRect(rounded, gradientPaint);
    final thumbX = left + (right - left) * fraction;
    canvas.save();
    canvas.clipRRect(rounded);
    canvas.drawRect(
      track,
      Paint()..color = Colors.black.withValues(alpha: isDark ? 0.72 : 0.42),
    );
    final activeRight = thumbX + radius;
    final active = RRect.fromRectAndRadius(
      Rect.fromLTRB(track.left, track.top, activeRight, track.bottom),
      const Radius.circular(radius),
    );
    canvas.drawRRect(active, gradientPaint);
    for (final entry in labels.entries) {
      final x = left + (right - left) * ((entry.key - min) / (max - min));
      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: textStyle.copyWith(color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final textX = (x - painter.width / 2)
          .clamp(track.left + 4, track.right - painter.width - 4)
          .toDouble();
      painter.paint(canvas, Offset(textX, centerY - painter.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GradientStepPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.isDark != isDark ||
      oldDelegate.min != min ||
      oldDelegate.max != max ||
      oldDelegate.labels != labels ||
      oldDelegate.colors != colors ||
      oldDelegate.textStyle != textStyle;
}
