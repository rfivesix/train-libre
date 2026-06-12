import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';

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

    double radius = 37.0; // Half of height 74.0 for perfect pill
    return Container(
      margin: const EdgeInsets.only(
          bottom: 16.0), // Yields exactly 20px gap above GlassBottomBar
      height: 74.0,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: ShadowOuterClipper(borderRadius: radius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: DesignConstants.glassShadow,
                ),
              ),
            ),
          ),
          GlassAdaptiveScope(
            minQuality: GlassQuality.premium,
            maxQuality: GlassQuality.premium,
            child: GlassContainer(
              useOwnLayer: true,
              height: 74.0,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              shape: LiquidRoundedSuperellipse(borderRadius: radius),
              quality: GlassQuality.premium,
              settings: DesignConstants.liquidGlassSettings(isDark),
              child: child,
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
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
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.continue_workout_button),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onDiscard,
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.discard_button),
        ),
      ],
    );
  }
}
