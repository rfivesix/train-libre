import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../../../features/diary/presentation/widgets/ai_neural_cloud_orb_widget.dart';
import '../../../../features/workout/domain/models/prescription_enums.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/telemetry/telemetry_service.dart';
import '../../../../services/training_autonomy_service.dart';
import '../../../../util/design_constants.dart';

/// Glass accessory controls shown above the keyboard on workout screens.
class WorkoutKeyboardAccessoryBar extends StatefulWidget {
  const WorkoutKeyboardAccessoryBar(
      {super.key, this.showProgressionToggle = false});

  final bool showProgressionToggle;

  @override
  State<WorkoutKeyboardAccessoryBar> createState() =>
      _WorkoutKeyboardAccessoryBarState();
}

class _WorkoutKeyboardAccessoryBarState
    extends State<WorkoutKeyboardAccessoryBar> with WidgetsBindingObserver {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocusChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateKeyboardHeight());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() => _updateKeyboardHeight();

  void _updateKeyboardHeight() {
    if (!mounted) return;
    final view = View.of(context);
    final height = view.viewInsets.bottom / view.devicePixelRatio;
    if (height != _keyboardHeight) setState(() => _keyboardHeight = height);
  }

  void _insertHyphen() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final editable =
        focusContext?.findAncestorWidgetOfExactType<EditableText>();
    if (editable == null ||
        editable.keyboardType.index != TextInputType.number.index) {
      return;
    }

    final controller = editable.controller;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start;
    final end = selection.end;
    final text = value.text.replaceRange(start, end, '-');
    controller.value = value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: start + 1),
      composing: TextRange.empty,
    );
  }

  bool _hasNextFocus() {
    final current = FocusManager.instance.primaryFocus;
    final currentContext = current?.context;
    final scope = current?.nearestScope;
    if (current == null ||
        currentContext == null ||
        !currentContext.mounted ||
        scope == null) {
      return false;
    }

    final ordered = scope.traversalDescendants.toList(growable: false);
    final currentIndex = ordered.indexOf(current);
    return currentIndex >= 0 && currentIndex < ordered.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_keyboardHeight <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final autonomyService = widget.showProgressionToggle
        ? Provider.of<TrainingAutonomyService?>(context)
        : null;
    final progressionEnabled = autonomyService?.isSuggestEnabled ?? false;
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.showProgressionToggle && autonomyService != null) ...[
              _KeyboardGlassButton(
                label: '',
                neuralCloud: true,
                semanticLabel: progressionEnabled
                    ? l10n.progressionToggleEnabled
                    : l10n.progressionToggleDisabled,
                tooltip: progressionEnabled
                    ? l10n.progressionToggleEnabled
                    : l10n.progressionToggleDisabled,
                iconColor: progressionEnabled
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                iconSlashed: !progressionEnabled,
                onPressed: () {
                  final next = progressionEnabled
                      ? AutonomyLevel.off
                      : AutonomyLevel.suggest;
                  autonomyService.setLevel(next);
                  TelemetryService.instance.trackSettingToggled(
                    settingKey: 'training_autonomy_level',
                    value: next.name,
                  );
                },
                circular: true,
              ),
              const SizedBox(width: 8),
            ],
            _KeyboardGlassButton(
              label: '-',
              semanticLabel: l10n.workoutKeyboardInsertHyphen,
              tooltip: l10n.workoutKeyboardInsertHyphen,
              onPressed: _insertHyphen,
              circular: true,
            ),
            const SizedBox(width: 8),
            if (_hasNextFocus()) ...[
              _KeyboardGlassButton(
                label: '',
                icon: LucideIcons.chevron_right,
                semanticLabel: l10n.appTourNext,
                tooltip: l10n.workoutKeyboardNextField,
                onPressed: () =>
                    FocusManager.instance.primaryFocus?.nextFocus(),
                circular: true,
              ),
              const SizedBox(width: 8),
            ],
            _KeyboardGlassButton(
              label: l10n.doneButtonLabel,
              semanticLabel: l10n.workoutKeyboardClose,
              tooltip: l10n.workoutKeyboardClose,
              onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardGlassButton extends StatelessWidget {
  const _KeyboardGlassButton({
    required this.label,
    required this.onPressed,
    this.circular = false,
    this.icon,
    this.neuralCloud = false,
    this.semanticLabel,
    this.tooltip,
    this.iconColor,
    this.iconSlashed = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool circular;
  final IconData? icon;
  final bool neuralCloud;
  final String? semanticLabel;
  final String? tooltip;
  final Color? iconColor;
  final bool iconSlashed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : Colors.black;
    final content = circular
        ? SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: neuralCloud
                  ? _buildIcon(foreground)
                  : icon == null
                      ? Text(
                          label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : _buildIcon(foreground),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 36,
              child: Center(
                child: neuralCloud
                    ? _buildIcon(foreground)
                    : icon == null
                        ? Text(
                            label,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : _buildIcon(foreground),
              ),
            ),
          );

    return Tooltip(
      message: tooltip ?? semanticLabel ?? label,
      child: Semantics(
        button: true,
        label: semanticLabel ?? (circular ? 'Insert hyphen' : label),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedbackService.instance.lightImpact();
            onPressed();
          },
          child: GlassAdaptiveScope(
            maxQuality: DesignConstants.defaultGlassQuality,
            minQuality: DesignConstants.minGlassQuality,
            child: RepaintBoundary(
              child: GlassContainer(
                useOwnLayer: true,
                height: 36,
                width: circular ? 36 : null,
                shape: circular
                    ? const LiquidOval()
                    : const LiquidRoundedSuperellipse(borderRadius: 18),
                quality: DesignConstants.defaultGlassQuality,
                settings: DesignConstants.liquidGlassSettings(isDark),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color foreground) {
    final iconWidget = neuralCloud
        ? AiNeuralCloudOrbWidget(
            size: 36,
            animate: false,
            showAmbientGlow: false,
            showDetachedSatellite: false,
            enableInteraction: false,
            baseColor: iconColor,
            accentColor: iconColor,
          )
        : Icon(icon, color: iconColor ?? foreground, size: 18);
    if (!iconSlashed) return iconWidget;
    return SizedBox(
      width: neuralCloud ? 36 : 20,
      height: neuralCloud ? 36 : 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          iconWidget,
          Transform.rotate(
            angle: -0.785398,
            child: Container(
              width: 23,
              height: 1.6,
              decoration: BoxDecoration(
                color: foreground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
