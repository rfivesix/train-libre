import 'dart:math' as math;
import 'dart:ui' show Vertices, VertexMode;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/theme_service.dart';
import '../../../theme/app_color_choice.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';

const _colorFieldCornerRadius = 18.0;

class AppColorSettingsScreen extends StatelessWidget {
  const AppColorSettingsScreen({super.key, this.showSystemColors = false});

  final bool showSystemColors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<ThemeService>();
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final choices = <AppColorChoice>[
      AppColorChoice.trainLibre,
      AppColorChoice.monochrome,
      AppColorChoice.blue,
      AppColorChoice.teal,
      AppColorChoice.purple,
      AppColorChoice.orange,
      AppColorChoice.rose,
      AppColorChoice.custom,
      if (showSystemColors) AppColorChoice.system,
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.settingsAppColorTitle),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          Text(
            l10n.settingsAppColorSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 3 : 2;
              const spacing = 10.0;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final choice in choices)
                    SizedBox(
                      width: tileWidth,
                      height: tileWidth / 1.55,
                      child: _AppColorChoiceCard(
                        choice: choice,
                        selected: service.appColorChoice == choice,
                        customColor: service.customAppColor,
                        onTap: () {
                          if (choice == AppColorChoice.custom) {
                            _showCustomColorPicker(context);
                          } else {
                            context
                                .read<ThemeService>()
                                .setAppColorChoice(choice);
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomColorPicker(BuildContext context) async {
    final service = context.read<ThemeService>();
    final l10n = AppLocalizations.of(context)!;
    final selectedColor = await showGlassBottomMenu<Color>(
      context: context,
      title: l10n.appColorCustomDialogTitle,
      enableDrag: false,
      contentBuilder: (sheetContext, _) => _CustomColorPicker(
        initialColor: service.customAppColor,
        hexLabel: l10n.appColorHexLabel,
        invalidHexLabel: l10n.appColorHexInvalid,
        outOfRangeHexLabel: l10n.appColorHexOutOfRange,
        brightnessLabel: l10n.appColorBrightnessLabel,
        hueSemanticsLabel: l10n.appColorHueLabel,
        cancelLabel: l10n.appColorCancel,
        applyLabel: l10n.appColorApply,
        onCancel: () => Navigator.of(sheetContext).pop(),
        onApply: (color) => Navigator.of(sheetContext).pop(color),
      ),
    );
    if (selectedColor != null) {
      // The glass menu waits until its route has fully unmounted before it
      // returns. Applying the theme after that avoids rebuilding inherited
      // dependents while the color picker route is being removed.
      await service.setCustomAppColor(selectedColor);
    }
  }

  static String _hexString(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  static Color? _parseHex(String input) {
    final hex = input.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _CustomColorPicker extends StatefulWidget {
  const _CustomColorPicker({
    required this.initialColor,
    required this.hexLabel,
    required this.invalidHexLabel,
    required this.outOfRangeHexLabel,
    required this.brightnessLabel,
    required this.hueSemanticsLabel,
    required this.cancelLabel,
    required this.applyLabel,
    required this.onCancel,
    required this.onApply,
  });

  final Color initialColor;
  final String hexLabel;
  final String invalidHexLabel;
  final String outOfRangeHexLabel;
  final String brightnessLabel;
  final String hueSemanticsLabel;
  final String cancelLabel;
  final String applyLabel;
  final VoidCallback onCancel;
  final ValueChanged<Color> onApply;

  @override
  State<_CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<_CustomColorPicker> {
  late final TextEditingController _hexController;
  late Color _color;
  String? _hexError;

  @override
  void initState() {
    super.initState();
    _color = constrainCustomAppColor(Color(widget.initialColor.toARGB32()));
    _hexController = TextEditingController(
      text: AppColorSettingsScreen._hexString(_color),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateColor(Color color) {
    final opaqueColor = constrainCustomAppColor(Color(color.toARGB32()));
    final hex = AppColorSettingsScreen._hexString(opaqueColor);
    _hexController.value = TextEditingValue(
      text: hex,
      selection: TextSelection.collapsed(offset: hex.length),
    );
    setState(() {
      _color = opaqueColor;
      _hexError = null;
    });
  }

  void _updateFromHex(String value) {
    final parsed = AppColorSettingsScreen._parseHex(value);
    setState(() {
      if (parsed == null) {
        _hexError = widget.invalidHexLabel;
      } else if (!isCustomAppColorBrightnessAllowed(parsed)) {
        _hexError = widget.outOfRangeHexLabel;
      } else {
        _hexError = null;
        _color = parsed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hsv = HSVColor.fromColor(_color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.24),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _hexController,
                  maxLength: 7,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: widget.hexLabel,
                    errorText: _hexError,
                    counterText: '',
                    isDense: true,
                  ),
                  onChanged: _updateFromHex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: widget.hueSemanticsLabel,
            child: _ColorWheelPicker(
              hsv: hsv,
              markerColor: _color,
              onChanged: _updateColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.brightnessLabel,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                '${(hsv.value * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: ((hsv.value - customAppColorMinBrightness) /
                    (customAppColorMaxBrightness - customAppColorMinBrightness))
                .clamp(0, 1)
                .toDouble(),
            divisions: 100,
            activeColor: _color,
            onChanged: (value) {
              final brightness = customAppColorMinBrightness +
                  value *
                      (customAppColorMaxBrightness -
                          customAppColorMinBrightness);
              _updateColor(hsv.withValue(brightness).toColor());
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: Text(widget.cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _hexError == null ? () => widget.onApply(_color) : null,
                  child: Text(widget.applyLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorWheelPicker extends StatelessWidget {
  const _ColorWheelPicker({
    required this.hsv,
    required this.markerColor,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color markerColor;
  final ValueChanged<Color> onChanged;

  void _updateFromPosition(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    onChanged(_hsvAtColorFieldPosition(
      position,
      size,
      brightness: hsv.value,
      fallbackHue: hsv.hue,
    ).toColor());
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final markerSize = 32.0;
          final center = Offset(size.width / 2, size.height / 2);
          final hueRadians = hsv.hue * math.pi / 180;
          final directionX = math.cos(hueRadians);
          final directionY = -math.sin(hueRadians);
          final outerRadius = _distanceToColorFieldEdge(
            size,
            directionX,
            directionY,
            inset: markerSize / 2,
          );
          final markerCenter = Offset(
            center.dx + directionX * hsv.saturation * outerRadius,
            center.dy + directionY * hsv.saturation * outerRadius,
          );
          final markerX = markerCenter.dx - markerSize / 2;
          final markerY = markerCenter.dy - markerSize / 2;

          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                _ColorWheelGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                        _ColorWheelGestureRecognizer>(
                  _ColorWheelGestureRecognizer.new,
                  (recognizer) => recognizer
                    ..onPositionChanged =
                        (position) => _updateFromPosition(position, size),
                ),
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ColorWheelPainter(
                        brightness: hsv.value,
                        outlineColor: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerX,
                    top: markerY,
                    child: IgnorePointer(
                      child: Container(
                        width: markerSize,
                        height: markerSize,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter({
    required this.brightness,
    required this.outlineColor,
  });

  final double brightness;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_colorFieldCornerRadius),
    );
    final vertices = _buildColorFieldVertices(size, brightness);
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      Paint()..color = Colors.white,
    );
    canvas.restore();
    vertices.dispose();

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(shape, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.outlineColor != outlineColor;
}

HSVColor _hsvAtColorFieldPosition(
  Offset position,
  Size size, {
  required double brightness,
  required double fallbackHue,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final delta = position - center;
  final distance = delta.distance;
  if (distance < 0.001) {
    return HSVColor.fromAHSV(1, fallbackHue, 0, brightness);
  }

  final directionX = delta.dx / distance;
  final directionY = delta.dy / distance;
  final edgeDistance = _distanceToColorFieldEdge(
    size,
    directionX,
    directionY,
  );
  final saturation = (distance / edgeDistance).clamp(0.0, 1.0);
  final hue = (math.atan2(-delta.dy, delta.dx) * 180 / math.pi + 360) % 360;
  return HSVColor.fromAHSV(1, hue, saturation, brightness);
}

double _distanceToColorFieldEdge(
  Size size,
  double directionX,
  double directionY, {
  double inset = 0,
}) {
  final halfWidth = math.max(0.0, size.width / 2 - inset);
  final halfHeight = math.max(0.0, size.height / 2 - inset);
  final cornerRadius = math.max(
    0.0,
    math.min(
      _colorFieldCornerRadius - inset,
      math.min(halfWidth, halfHeight),
    ),
  );
  final x = directionX.abs();
  final y = directionY.abs();
  if (x < 1e-9) return halfHeight;
  if (y < 1e-9) return halfWidth;

  final toVerticalEdge = halfWidth / x;
  final toHorizontalEdge = halfHeight / y;
  if (toVerticalEdge <= toHorizontalEdge &&
      toVerticalEdge * y <= halfHeight - cornerRadius) {
    return toVerticalEdge;
  }
  if (toHorizontalEdge <= toVerticalEdge &&
      toHorizontalEdge * x <= halfWidth - cornerRadius) {
    return toHorizontalEdge;
  }

  final cornerX = halfWidth - cornerRadius;
  final cornerY = halfHeight - cornerRadius;
  final projection = x * cornerX + y * cornerY;
  final constant =
      cornerX * cornerX + cornerY * cornerY - cornerRadius * cornerRadius;
  return projection +
      math.sqrt(math.max(0, projection * projection - constant));
}

Vertices _buildColorFieldVertices(Size size, double brightness) {
  const segments = 128;
  final rowLength = segments + 1;
  final positions = <Offset>[];
  final colors = <Color>[];
  final indices = <int>[];

  for (var y = 0; y <= segments; y++) {
    final dy = size.height * y / segments;
    for (var x = 0; x <= segments; x++) {
      final position = Offset(size.width * x / segments, dy);
      positions.add(position);
      colors.add(
        _hsvAtColorFieldPosition(
          position,
          size,
          brightness: brightness,
          fallbackHue: 0,
        ).toColor(),
      );
    }
  }

  for (var y = 0; y < segments; y++) {
    for (var x = 0; x < segments; x++) {
      final topLeft = y * rowLength + x;
      final topRight = topLeft + 1;
      final bottomLeft = topLeft + rowLength;
      final bottomRight = bottomLeft + 1;
      indices
        ..add(topLeft)
        ..add(topRight)
        ..add(bottomLeft)
        ..add(topRight)
        ..add(bottomRight)
        ..add(bottomLeft);
    }
  }

  return Vertices(
    VertexMode.triangles,
    positions,
    colors: colors,
    indices: indices,
  );
}

class _ColorWheelGestureRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onPositionChanged;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
    onPositionChanged?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onPositionChanged?.call(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'color wheel drag';
}

class _AppColorChoiceCard extends StatelessWidget {
  const _AppColorChoiceCard({
    required this.choice,
    required this.selected,
    required this.customColor,
    required this.onTap,
  });

  final AppColorChoice choice;
  final bool selected;
  final Color customColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lightColor = choice.primary(
      brightness: Brightness.light,
      customColor: customColor,
      systemColor: theme.colorScheme.primary,
    );
    final darkColor = choice.primary(
      brightness: Brightness.dark,
      customColor: customColor,
      systemColor: theme.colorScheme.primary,
    );
    final label = switch (choice) {
      AppColorChoice.trainLibre => l10n.appColorPresetTrainLibre,
      AppColorChoice.monochrome => l10n.appColorPresetMonochrome,
      AppColorChoice.blue => l10n.appColorPresetBlue,
      AppColorChoice.teal => l10n.appColorPresetTeal,
      AppColorChoice.purple => l10n.appColorPresetPurple,
      AppColorChoice.orange => l10n.appColorPresetOrange,
      AppColorChoice.rose => l10n.appColorPresetRose,
      AppColorChoice.custom => l10n.appColorPresetCustom,
      AppColorChoice.system => l10n.appColorPresetSystem,
    };

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: selected ? 0.8 : 0.48,
      ),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorDot(color: lightColor),
                  const SizedBox(width: 5),
                  _ColorDot(color: darkColor),
                  const Spacer(),
                  if (selected)
                    Icon(
                      LucideIcons.circle_check,
                      size: 19,
                      color: theme.colorScheme.primary,
                    )
                  else if (choice == AppColorChoice.custom)
                    Icon(
                      LucideIcons.palette,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  else if (choice == AppColorChoice.system)
                    Icon(
                      LucideIcons.smartphone,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
