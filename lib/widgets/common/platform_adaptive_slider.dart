import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/haptic_feedback_service.dart';

/// A Material 3 slider on Android and a liquid-glass slider on iOS.
class PlatformAdaptiveSlider extends StatelessWidget {
  const PlatformAdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.semanticValue,
    this.semanticFormatter,
    this.activeColor,
    this.inactiveColor,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
  }) : assert(max > min),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);

  final double value;
  final ValueChanged<double>? onChanged;
  final String semanticLabel;
  final String? semanticValue;
  final String Function(double)? semanticFormatter;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.platform != TargetPlatform.iOS) {
      final slider = Slider(
        value: value,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        showValueIndicator: label == null ? null : ShowValueIndicator.onDrag,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        focusNode: focusNode,
        autofocus: autofocus,
        semanticFormatterCallback: semanticFormatter,
        // material_ui still defaults to the older 2023 slider design.
        // ignore: deprecated_member_use
        year2023: false,
      );
      return Semantics(
        label: semanticLabel,
        child: divisions != null && divisions! > 20
            ? SliderTheme(
                data: SliderTheme.of(context)
                    .copyWith(tickMarkShape: SliderTickMarkShape.noTickMark),
                child: slider,
              )
            : slider,
      );
    }

    final step = (max - min) / (divisions ?? 10);
    String formatValue(double next) =>
        semanticFormatter?.call(next) ??
        '${((next - min) / (max - min) * 100).round()}%';
    final valueText = semanticValue ?? formatValue(value);
    final usePackageSteps =
        HapticFeedbackService.instance.isEnabled &&
        (divisions == null || divisions! <= 50);
    return LayoutBuilder(
      builder: (context, constraints) {
        void tap(TapUpDetails details) {
          if (onChanged == null) return;
          // GlassSlider's thumb radius is 15; its own track has this inset.
          final width = constraints.maxWidth - 30;
          if (width <= 0) return;
          var position = ((details.localPosition.dx - 15) / width).clamp(
            0.0,
            1.0,
          );
          if (Directionality.of(context) == TextDirection.rtl) {
            position = 1 - position;
          }
          var next = min + position * (max - min);
          if (divisions != null) {
            next = min + ((next - min) / step).round() * step;
          }
          next = next.clamp(min, max);
          onChangeStart?.call(value);
          onChanged!(next);
          onChangeEnd?.call(next);
        }

        return Semantics(
          label: semanticLabel,
          value: valueText,
          increasedValue: onChanged == null
              ? null
              : formatValue((value + step).clamp(min, max)),
          decreasedValue: onChanged == null
              ? null
              : formatValue((value - step).clamp(min, max)),
          slider: true,
          enabled: onChanged != null,
          onIncrease: onChanged == null
              ? null
              : () => onChanged!((value + step).clamp(min, max)),
          onDecrease: onChanged == null
              ? null
              : () => onChanged!((value - step).clamp(min, max)),
          child: ExcludeSemantics(
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) {
                if (onChanged == null ||
                    (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
                  return KeyEventResult.ignored;
                }
                final key = event.logicalKey;
                final rtl = Directionality.of(context) == TextDirection.rtl;
                final increase =
                    key == LogicalKeyboardKey.arrowUp ||
                    key ==
                        (rtl
                            ? LogicalKeyboardKey.arrowLeft
                            : LogicalKeyboardKey.arrowRight);
                final decrease =
                    key == LogicalKeyboardKey.arrowDown ||
                    key ==
                        (rtl
                            ? LogicalKeyboardKey.arrowRight
                            : LogicalKeyboardKey.arrowLeft);
                if (!increase && !decrease) return KeyEventResult.ignored;
                onChanged!((value + (increase ? step : -step)).clamp(min, max));
                return KeyEventResult.handled;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: onChanged == null ? null : tap,
                child: IgnorePointer(
                  ignoring: onChanged == null,
                  child: GlassSlider(
                    value: value,
                    onChanged: onChanged == null
                        ? null
                        : !usePackageSteps && divisions != null
                        ? (next) => onChanged!(
                            (min + ((next - min) / step).round() * step).clamp(
                              min,
                              max,
                            ),
                          )
                        : onChanged,
                    onChangeStart: onChangeStart,
                    onChangeEnd: onChangeEnd,
                    min: min,
                    max: max,
                    // The package emits haptics for discrete steps itself, so
                    // snap externally when the app's haptic setting is off.
                    divisions: usePackageSteps ? divisions : null,
                    activeColor: activeColor ?? theme.colorScheme.primary,
                    inactiveColor: inactiveColor,
                    label: semanticLabel,
                    focusNode: focusNode,
                    autofocus: autofocus,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
