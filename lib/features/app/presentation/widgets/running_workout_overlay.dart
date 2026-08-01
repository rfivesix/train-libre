import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';

class RunningWorkoutOverlay extends StatelessWidget {
  final String elapsedDuration;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const RunningWorkoutOverlay({
    super.key,
    required this.elapsedDuration,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child = _RunningWorkoutRow(
      timeText: elapsedDuration,
      onContinue: onContinue,
      onDiscard: onDiscard,
      l10n: l10n,
    );

    final double radius = DesignConstants.workoutOverlayHeight / 2; // Half of height for perfect pill
    return SizedBox(
      height: DesignConstants.workoutOverlayHeight,
      child: GlassAdaptiveScope(
            maxQuality: DesignConstants.defaultGlassQuality,
            child: RepaintBoundary(
              child: GlassContainer(
                useOwnLayer: true,
                height: DesignConstants.workoutOverlayHeight,
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingXL),
                alignment: Alignment.center,
                shape: LiquidRoundedSuperellipse(borderRadius: radius),
                quality: DesignConstants.defaultGlassQuality,
                settings: DesignConstants.liquidGlassSettings(isDark),
                child: child,
              ),
            ),
          ),
    );
  }
}

class _RunningWorkoutRow extends StatelessWidget {
  final String timeText;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;
  final AppLocalizations l10n;

  const _RunningWorkoutRow({
    required this.timeText,
    required this.onContinue,
    required this.onDiscard,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    //final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(LucideIcons.clock, size: 20),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  decoration: TextDecoration.none,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        AppButton.primary(
          onPressed: onContinue,
          label: l10n.continue_workout_button,
          tooltip: l10n.continue_workout_button,
          size: AppButtonSize.small,
        ),
        const SizedBox(width: DesignConstants.spacingS),
        AppButton.danger(
          onPressed: onDiscard,
          label: l10n.discard_button,
          tooltip: l10n.discard_button,
          size: AppButtonSize.small,
        ),
      ],
    );
  }
}
