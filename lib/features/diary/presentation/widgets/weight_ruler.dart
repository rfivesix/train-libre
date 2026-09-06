import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../util/design_constants.dart';

/// Dragging changes only the draft. Saving belongs to the enclosing card.
class WeightRuler extends StatefulWidget {
  final double value;
  final bool imperial;
  final bool enabled;
  final String label;
  final String unit;
  final ValueChanged<double> onChanged;

  const WeightRuler({
    super.key,
    required this.value,
    required this.imperial,
    required this.label,
    required this.unit,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<WeightRuler> createState() => _WeightRulerState();
}

class _WeightRulerState extends State<WeightRuler> {
  double _dragValue = 0;
  double get _pixelsPerUnit => widget.imperial ? 35 : 70;

  void _change(double raw) {
    // Keep the painted ruler continuous under the finger. The card formats the
    // visible number to one decimal and rounds only when saving.
    final value = raw.clamp(
      widget.imperial ? 55.0 : 25.0,
      widget.imperial ? 570.0 : 260.0,
    );
    final major = widget.imperial ? 5 : 1;
    if ((value / major).floor() != (widget.value / major).floor()) {
      HapticFeedback.selectionClick();
    }
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat('0.0', locale);
    return Semantics(
      label: widget.label,
      value: '${format.format(widget.value)} ${widget.unit}',
      increasedValue: '${format.format(widget.value + .1)} ${widget.unit}',
      decreasedValue: '${format.format(widget.value - .1)} ${widget.unit}',
      onIncrease: widget.enabled ? () => _change(widget.value + .1) : null,
      onDecrease: widget.enabled ? () => _change(widget.value - .1) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart:
            widget.enabled ? (_) => _dragValue = widget.value : null,
        onHorizontalDragUpdate: widget.enabled
            ? (details) {
                _dragValue -= details.delta.dx / _pixelsPerUnit;
                _change(_dragValue);
              }
            : null,
        child: ClipRect(
          child: CustomPaint(
            size: const Size(double.infinity, 74),
            painter: _RulerPainter(
              value: widget.value,
              imperial: widget.imperial,
              tickColor: cs.onSurface,
              markerColor: cs.primary,
              labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: .64),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              locale: locale,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double value;
  final bool imperial;
  final Color tickColor;
  final Color markerColor;
  final TextStyle labelStyle;
  final String locale;
  final TextScaler textScaler;

  const _RulerPainter({
    required this.value,
    required this.imperial,
    required this.tickColor,
    required this.markerColor,
    required this.labelStyle,
    required this.locale,
    required this.textScaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelsPerUnit = imperial ? 35.0 : 70.0;
    final step = imperial ? .2 : .1;
    final middle = size.width / 2;
    final radius = (middle / 7).ceil() + 2;
    final centerTick = (value / step).round();
    final labelFormat = NumberFormat('0', locale);
    final paint = Paint()..strokeWidth = 1.5;
    for (var i = centerTick - radius; i <= centerTick + radius; i++) {
      final tickValue = i * step;
      final tenths = (tickValue * 10).round();
      final major = tenths % (imperial ? 50 : 10) == 0;
      final mid = tenths % (imperial ? 10 : 5) == 0;
      final x = middle + (tickValue - value) * pixelsPerUnit;
      final fade =
          (math.min(x, size.width - x) / (size.width * .09)).clamp(0.0, 1.0);
      paint.color =
          tickColor.withValues(alpha: fade * (major || mid ? .8 : .4));
      final height = major ? 26.0 : (mid ? 15.0 : 9.0);
      canvas.drawLine(Offset(x, 42 - height), Offset(x, 42), paint);
      // Wider accessibility labels use fewer labels, while all ticks remain.
      final labelStride =
          math.max(1, textScaler.scale(33) / (imperial ? 175 : 70)).ceil();
      if (major && (tenths ~/ (imperial ? 50 : 10)) % labelStride == 0) {
        final text = TextPainter(
          text: TextSpan(
            text: labelFormat.format(tickValue),
            style:
                labelStyle.copyWith(color: tickColor.withValues(alpha: fade)),
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        text.paint(canvas, Offset(x - text.width / 2, 46));
        text.dispose();
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(middle - 1.5, 10, 3, 34),
        const Radius.circular(DesignConstants.spacingXS / 2),
      ),
      Paint()..color = markerColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      value != oldDelegate.value ||
      imperial != oldDelegate.imperial ||
      tickColor != oldDelegate.tickColor ||
      markerColor != oldDelegate.markerColor ||
      labelStyle != oldDelegate.labelStyle ||
      locale != oldDelegate.locale ||
      textScaler != oldDelegate.textScaler;
}
