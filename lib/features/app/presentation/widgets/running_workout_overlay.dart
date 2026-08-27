import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';

/// Status dot colors. Green while the workout runs, blue while a pause counts
/// down — the same two signals the live workout screen uses.
const Color _kRunningDotColor = Color(0xFF30D158);
const Color _kRestColor = Color(0xFF4C8EFF);

/// The minimized running workout bar shown above the bottom navigation.
///
/// Three zones: an expand affordance on the left, status and context in the
/// middle, and the discard action on the right. Everything but the discard
/// button opens the live workout screen.
class RunningWorkoutOverlay extends StatelessWidget {
  /// Formatted workout duration (`MM:SS` / `HH:MM:SS`) — shown while no pause
  /// is running.
  final String elapsedDuration;

  /// Formatted remaining pause time (`MM:SS`) — shown while [isResting].
  final String restDuration;

  /// Whether a pause timer is currently counting down.
  final bool isResting;

  /// The exercise named on the second row. Null or empty leaves that row out
  /// entirely rather than showing a placeholder.
  final String? exerciseName;

  /// Opens the live workout screen.
  final VoidCallback onExpand;

  /// Discards the workout — asks for confirmation first.
  final VoidCallback onDiscard;

  const RunningWorkoutOverlay({
    super.key,
    required this.elapsedDuration,
    required this.restDuration,
    required this.isResting,
    required this.exerciseName,
    required this.onExpand,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: DesignConstants.workoutOverlayHeight,
      child: GlassAdaptiveScope(
        maxQuality: DesignConstants.defaultGlassQuality,
        minQuality: DesignConstants.minGlassQuality,
        child: RepaintBoundary(
          child: GlassContainer(
            useOwnLayer: true,
            height: DesignConstants.workoutOverlayHeight,
            padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.floatingBarPillInset),
            alignment: Alignment.center,
            shape: const LiquidRoundedSuperellipse(
              borderRadius: DesignConstants.workoutOverlayRadius,
            ),
            quality: DesignConstants.defaultGlassQuality,
            settings: DesignConstants.liquidGlassSettings(isDark),
            child: _RunningWorkoutRow(
              elapsedDuration: elapsedDuration,
              restDuration: restDuration,
              isResting: isResting,
              exerciseName: exerciseName,
              onExpand: onExpand,
              onDiscard: onDiscard,
              l10n: l10n,
            ),
          ),
        ),
      ),
    );
  }
}

class _RunningWorkoutRow extends StatelessWidget {
  final String elapsedDuration;
  final String restDuration;
  final bool isResting;
  final String? exerciseName;
  final VoidCallback onExpand;
  final VoidCallback onDiscard;
  final AppLocalizations l10n;

  const _RunningWorkoutRow({
    required this.elapsedDuration,
    required this.restDuration,
    required this.isResting,
    required this.exerciseName,
    required this.onExpand,
    required this.onDiscard,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final Color onSurface = isDark ? Colors.white : Colors.black;
    final Color pillColor = DesignConstants.floatingBarPillColor(isDark);

    final Color accent = isResting ? _kRestColor : colorScheme.primary;
    final String statusLabel = isResting ? l10n.restTimerLabel : l10n.workout;
    final String timeText = isResting ? restDuration : elapsedDuration;
    final String? subtitle = (exerciseName != null && exerciseName!.isNotEmpty)
        ? exerciseName
        : null;

    return Row(
      children: [
        // Expand affordance + status. One tap target — the whole bar opens the
        // workout, only the discard button on the right opts out of it.
        Expanded(
          child: Semantics(
            button: true,
            label: l10n.continue_workout_button,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExpand,
              child: Row(
                children: [
                  _CircleAffordance(
                    icon: LucideIcons.chevron_up,
                    iconColor: onSurface,
                    backgroundColor: pillColor,
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isResting ? _kRestColor : _kRunningDotColor,
                              ),
                            ),
                            const SizedBox(
                                width: DesignConstants.spacingXS + 2),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: '$statusLabel  '),
                                    TextSpan(
                                      text: timeText,
                                      style: TextStyle(
                                        color: accent,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DesignConstants.floatingBarStatusStyle
                                    .copyWith(
                                  color: onSurface,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                DesignConstants.floatingBarLabelStyle.copyWith(
                              fontWeight: FontWeight.w500,
                              color: onSurface.withValues(alpha: 0.55),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Semantics(
          button: true,
          label: l10n.discard_button,
          child: Tooltip(
            message: l10n.discard_button,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDiscard,
              child: _CircleAffordance(
                icon: LucideIcons.trash_2,
                iconColor: colorScheme.error,
                backgroundColor: pillColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The two circular buttons flanking the bar. Same size, shape and fill as the
/// selected-tab pill in the bottom navigation, so both floating bars read as
/// one system — on the discard button the red icon carries the meaning rather
/// than a tint of its own.
class _CircleAffordance extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _CircleAffordance({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DesignConstants.floatingBarPillSize,
      height: DesignConstants.floatingBarPillSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Icon(icon, size: DesignConstants.iconSizeL, color: iconColor),
    );
  }
}
