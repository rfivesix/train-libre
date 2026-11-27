import 'package:material_ui/material_ui.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import 'rpe_gradient_slider.dart';
import 'rpe_help_sheet.dart';

String formatRpe(num value) =>
    value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

/// A nullable RPE selection. A cleared selection is distinct from RPE 6.
class RpePickerResult {
  final double? value;
  final bool complete;
  const RpePickerResult(this.value, {this.complete = false});
}

Future<RpePickerResult?> showRpePicker(
  BuildContext context, {
  double? value,
  bool allowComplete = false,
}) => showGlassBottomMenu<RpePickerResult>(
  context: context,
  contentBuilder: (context, _) =>
      _RpePicker(value: value, allowComplete: allowComplete),
);

class _RpePicker extends StatefulWidget {
  final double? value;
  final bool allowComplete;
  const _RpePicker({this.value, required this.allowComplete});
  @override
  State<_RpePicker> createState() => _RpePickerState();
}

class _RpePickerState extends State<_RpePicker> {
  late double value = (widget.value ?? 8).clamp(6, 10).toDouble();

  void _change(double next) => setState(() => value = next.clamp(6, 10));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final foreground = theme.colorScheme.onSurface;
    final remaining = 10 - value;
    final description = remaining == 0
        ? l10n.rpeNoReps
        : remaining >= 4
        ? l10n.rpeFourPlus
        : l10n.rpeRepsLeft(
            remaining == remaining.roundToDouble()
                ? formatRpe(remaining)
                : '${remaining.floor()}–${remaining.ceil()}',
          );
    final effort = value == 10
        ? l10n.rpeMaximumEffort
        : value >= 8
        ? l10n.rpeHardEffort
        : l10n.rpeModerateEffort;
    final panelColor = foreground.withValues(alpha: dark ? 0.08 : 0.06);
    final buttonColor = foreground.withValues(alpha: dark ? 0.045 : 0.06);
    // Keep the control stack and the main panel aligned, including when the
    // system text scale makes the explanations taller.
    final panelHeight =
        242.0 +
        (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, 20.0) * 9;

    final buttonSize = (panelHeight - 18) / 4;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              key: const ValueKey('rpe-main-panel'),
              height: panelHeight,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SmallAction(
                        icon: Icons.help_outline,
                        label: l10n.rpeHelpTitle,
                        onTap: () => showRpeHelpSheet(context),
                      ),
                      _SmallAction(
                        icon: Icons.close,
                        label: l10n.rpeClear,
                        onTap: () =>
                            Navigator.pop(context, const RpePickerResult(null)),
                      ),
                    ],
                  ),
                  Text(
                    formatRpe(value),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 56,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    effort,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.62),
                    ),
                  ),
                  const Spacer(),
                  RpeGradientSlider(
                    value: value,
                    onChanged: (next) {
                      if (next == value) return;
                      HapticFeedbackService.instance.selectionFeedback();
                      _change(next);
                    },
                    semanticLabel: l10n.rpeEffortTitle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            key: const ValueKey('rpe-side-controls'),
            width: buttonSize,
            height: panelHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: buttonSize,
                  child: _SideButton(
                    icon: LucideIcons.keyboard_off,
                    label: l10n.rpeSave,
                    color: buttonColor,
                    onTap: () => Navigator.pop(context, RpePickerResult(value)),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: buttonSize,
                  child: _SideButton(
                    icon: Icons.add,
                    label: '${l10n.rpeEffortTitle} +',
                    color: buttonColor,
                    onTap: value < 10 ? () => _change(value + 0.5) : null,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: buttonSize,
                  child: _SideButton(
                    icon: Icons.remove,
                    label: '${l10n.rpeEffortTitle} −',
                    color: buttonColor,
                    onTap: value > 6 ? () => _change(value - 0.5) : null,
                  ),
                ),
                if (widget.allowComplete) ...[
                  const SizedBox(height: 6),
                  Expanded(
                    child: _SideButton(
                      icon: Icons.check,
                      label: l10n.doneButtonLabel,
                      color: theme.colorScheme.primary,
                      foreground: theme.colorScheme.onPrimary,
                      onTap: () => Navigator.pop(
                        context,
                        RpePickerResult(value, complete: true),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    tooltip: label,
    iconSize: 20,
    onPressed: onTap,
    icon: Icon(icon),
  );
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.foreground,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color? foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: (foreground ?? Theme.of(context).colorScheme.onSurface)
                  .withValues(alpha: onTap == null ? 0.3 : 1),
              size: 26,
            ),
          ),
        ),
      ),
    ),
  );
}
