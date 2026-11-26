import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../util/glass_preferences.dart';
import '../../../../util/time_util.dart';
import '../../../../widgets/common/app_button.dart';

class LiveWorkoutRestBar extends StatelessWidget {
  const LiveWorkoutRestBar({
    super.key,
    required this.isRunning,
    required this.isDoneBanner,
    required this.remainingRestSeconds,
    required this.onAdjustRestTime,
    required this.onCancelRest,
    this.actionLabel,
    this.actionIcon,
    this.formatAsStopwatch = false,
  });

  final bool isRunning;
  final bool isDoneBanner;
  final int remainingRestSeconds;
  final void Function(int seconds) onAdjustRestTime;
  final VoidCallback onCancelRest;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool formatAsStopwatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final radius = DesignConstants.workoutOverlayHeight / 2;
    final minutes = remainingRestSeconds ~/ 60;
    final seconds = remainingRestSeconds % 60;
    final timer = formatAsStopwatch
        ? formatDuration(Duration(seconds: remainingRestSeconds))
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Widget adjustment(String text, int delta) => SizedBox(
      width: 48,
      height: 38,
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
        onPressed: () => onAdjustRestTime(delta),
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: DesignConstants.workoutOverlayHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: ShadowOuterClipper(borderRadius: radius),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: DesignConstants.glassShadow(isDark),
                  ),
                ),
              ),
            ),
            GlassAdaptiveScope(
              maxQuality: DesignConstants.defaultGlassQuality,
              minQuality: DesignConstants.minGlassQuality,
              child: GlassContainer(
                useOwnLayer: true,
                height: DesignConstants.workoutOverlayHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: LiquidRoundedSuperellipse(borderRadius: radius),
                quality: DesignConstants.defaultGlassQuality,
                settings: GlassPreferences.of(context).apply(
                  DesignConstants.liquidGlassSettings(isDark),
                  premium: true,
                ),
                child: Row(
                  children: [
                    adjustment('-15', -15),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isDoneBanner ? l10n.restOverLabel : timer,
                            key: ValueKey(isDoneBanner),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: isDoneBanner ? 21 : 27,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    adjustment('+15', 15),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 38,
                      child: AppButton.primary(
                        onPressed: onCancelRest,
                        icon: actionIcon,
                        label: actionIcon != null
                            ? ''
                            : actionLabel ??
                                  (isDoneBanner
                                      ? l10n.snackbar_button_ok
                                      : l10n.skipButton),
                        tooltip:
                            actionLabel ??
                            (isDoneBanner
                                ? l10n.snackbar_button_ok
                                : l10n.skipButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
