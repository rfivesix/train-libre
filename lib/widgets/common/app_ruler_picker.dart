import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../util/design_constants.dart';

/// A reusable horizontal ruler picker component for tactile, precision values
/// such as weight, target pace, or measurements.
///
/// Features horizontal scrolling with continuous ticks, edge fading, center accent marker,
/// localized number formatting, and haptic feedback on every tick interval.
class AppRulerPicker extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double step;
  final double pixelsPerUnit;
  final double majorInterval;
  final double minorInterval;
  final int fractionDigits;
  final String label;
  final String unit;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const AppRulerPicker({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.pixelsPerUnit,
    required this.majorInterval,
    required this.minorInterval,
    required this.fractionDigits,
    required this.label,
    required this.unit,
    required this.onChanged,
    this.enabled = true,
  });

  /// Factory for body weight picker (kg / lbs).
  factory AppRulerPicker.weight({
    Key? key,
    required double value,
    required bool imperial,
    required ValueChanged<double> onChanged,
    bool enabled = true,
    String? label,
  }) {
    return AppRulerPicker(
      key: key,
      value: value,
      minValue: imperial ? 55.0 : 25.0,
      maxValue: imperial ? 570.0 : 260.0,
      step: imperial ? 0.2 : 0.1,
      pixelsPerUnit: imperial ? 35.0 : 70.0,
      majorInterval: imperial ? 5.0 : 1.0,
      minorInterval: imperial ? 1.0 : 0.5,
      fractionDigits: 1,
      label: label ?? (imperial ? 'Weight (lbs)' : 'Weight (kg)'),
      unit: imperial ? 'lbs' : 'kg',
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  /// Factory for weekly rate / pace picker (kg/week / lbs/week).
  factory AppRulerPicker.rate({
    Key? key,
    required double value,
    required bool imperial,
    required ValueChanged<double> onChanged,
    bool enabled = true,
    String? label,
    String? unit,
  }) {
    return AppRulerPicker(
      key: key,
      value: value,
      minValue: 0.05,
      maxValue: imperial ? 4.50 : 2.00,
      step: imperial ? 0.10 : 0.05,
      pixelsPerUnit: imperial ? 140.0 : 260.0,
      majorInterval: imperial ? 0.50 : 0.25,
      minorInterval: imperial ? 0.10 : 0.05,
      fractionDigits: 2,
      label: label ?? (imperial ? 'Rate (lbs/week)' : 'Rate (kg/week)'),
      unit: unit ?? (imperial ? 'lbs/wk' : 'kg/Wo.'),
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  @override
  State<AppRulerPicker> createState() => _AppRulerPickerState();
}

class _AppRulerPickerState extends State<AppRulerPicker> {
  double _dragValue = 0;
  int? _lastHapticTick;

  void _change(double raw) {
    final clamped = raw.clamp(widget.minValue, widget.maxValue);
    final tick = (clamped / widget.step).round();
    final snapped = tick * widget.step;

    if (tick != _lastHapticTick) {
      HapticFeedback.selectionClick();
      _lastHapticTick = tick;
    }
    widget.onChanged(snapped);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatStr = widget.fractionDigits == 1 ? '0.0' : '0.00';
    final format = NumberFormat(formatStr, locale);

    return Semantics(
      label: widget.label,
      value: '${format.format(widget.value)} ${widget.unit}',
      increasedValue:
          '${format.format(widget.value + widget.step)} ${widget.unit}',
      decreasedValue:
          '${format.format(widget.value - widget.step)} ${widget.unit}',
      onIncrease:
          widget.enabled ? () => _change(widget.value + widget.step) : null,
      onDecrease:
          widget.enabled ? () => _change(widget.value - widget.step) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: widget.enabled
            ? (_) {
                _dragValue = widget.value;
                _lastHapticTick = (widget.value / widget.step).round();
              }
            : null,
        onHorizontalDragUpdate: widget.enabled
            ? (details) {
                _dragValue -= details.delta.dx / widget.pixelsPerUnit;
                _change(_dragValue);
              }
            : null,
        child: ClipRect(
          child: CustomPaint(
            size: const Size(double.infinity, 74),
            painter: _RulerPainter(
              value: widget.value,
              minValue: widget.minValue,
              maxValue: widget.maxValue,
              step: widget.step,
              pixelsPerUnit: widget.pixelsPerUnit,
              majorInterval: widget.majorInterval,
              minorInterval: widget.minorInterval,
              fractionDigits: widget.fractionDigits,
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
  final double minValue;
  final double maxValue;
  final double step;
  final double pixelsPerUnit;
  final double majorInterval;
  final double minorInterval;
  final int fractionDigits;
  final Color tickColor;
  final Color markerColor;
  final TextStyle labelStyle;
  final String locale;
  final TextScaler textScaler;

  const _RulerPainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.pixelsPerUnit,
    required this.majorInterval,
    required this.minorInterval,
    required this.fractionDigits,
    required this.tickColor,
    required this.markerColor,
    required this.labelStyle,
    required this.locale,
    required this.textScaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.width / 2;
    final tickDistance = pixelsPerUnit * step;
    final radius = (middle / tickDistance).ceil() + 2;
    final centerTick = (value / step).round();
    final labelFormat =
        NumberFormat(fractionDigits == 2 ? '0.00' : '0', locale);
    final paint = Paint()..strokeWidth = 1.5;

    final epsilon = step / 4;

    for (var i = centerTick - radius; i <= centerTick + radius; i++) {
      final tickValue = (i * step * 1000).round() / 1000.0;
      if (tickValue < minValue - epsilon || tickValue > maxValue + epsilon) {
        continue;
      }

      final remMajor = (tickValue % majorInterval).abs();
      final isMajor =
          remMajor < epsilon || (majorInterval - remMajor).abs() < epsilon;

      final remMinor = (tickValue % minorInterval).abs();
      final isMid =
          remMinor < epsilon || (minorInterval - remMinor).abs() < epsilon;

      final x = middle + (tickValue - value) * pixelsPerUnit;
      final fade =
          (math.min(x, size.width - x) / (size.width * .09)).clamp(0.0, 1.0);
      paint.color =
          tickColor.withValues(alpha: fade * (isMajor || isMid ? .8 : .4));
      final height = isMajor ? 26.0 : (isMid ? 15.0 : 9.0);
      canvas.drawLine(Offset(x, 42 - height), Offset(x, 42), paint);

      if (isMajor) {
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

    // Center accent indicator
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
      minValue != oldDelegate.minValue ||
      maxValue != oldDelegate.maxValue ||
      step != oldDelegate.step ||
      pixelsPerUnit != oldDelegate.pixelsPerUnit ||
      majorInterval != oldDelegate.majorInterval ||
      minorInterval != oldDelegate.minorInterval ||
      tickColor != oldDelegate.tickColor ||
      markerColor != oldDelegate.markerColor ||
      labelStyle != oldDelegate.labelStyle ||
      locale != oldDelegate.locale ||
      textScaler != oldDelegate.textScaler;
}
