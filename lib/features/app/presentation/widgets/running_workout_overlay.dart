import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../services/theme_service.dart';
import '../../../../theme/color_constants.dart';
import '../../../../generated/app_localizations.dart';

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
    final bg = isDark ? summaryCardDarkMode : summaryCardWhiteMode;
    final themeService = context.watch<ThemeService>();

    final Color neutralTint = (isDark ? Colors.white : Colors.white)
        .withValues(alpha: isDark ? 0.1 : 0.10);
    // Smarter liquid glass color: pure white translucent tint without solid gray base.
    final Color effectiveGlass = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.15);

    Widget child = _RunningWorkoutRow(
      timeText: elapsedDuration,
      onContinue: onContinue,
      onDiscard: onDiscard,
      l10n: l10n,
    );

    if (themeService.visualStyle == 1) {
      double radius = 37.0; // Half of height 74.0 for perfect pill
      return Container(
        margin: const EdgeInsets.only(
            bottom: 16.0), // Yields exactly 20px gap above GlassBottomBar
        height: 74.0,
        child: Stack(
          children: [
            // Shadow dimming layer underneath exactly like main_screen.dart
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.16),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            GlassContainer(
              useOwnLayer: true,
              height: 74.0,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              shape: LiquidRoundedSuperellipse(borderRadius: radius),
              quality: GlassQuality.premium,
              settings: LiquidGlassSettings(
                thickness: 30,
                blur: 2.0,
                glassColor: effectiveGlass,
                lightIntensity: isDark ? 0.55 : 0.80,
                saturation: 1.20,
              ),
              child: child,
            ),
          ],
        ),
      );
    }
    double radius = 20;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.toDouble()),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(radius.toDouble()),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.10),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
          child: child,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
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
