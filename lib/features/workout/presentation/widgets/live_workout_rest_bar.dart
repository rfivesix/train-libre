import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';

class LiveWorkoutRestBar extends StatefulWidget {
  const LiveWorkoutRestBar({
    super.key,
    required this.isRunning,
    required this.isDoneBanner,
    required this.remainingRestSeconds,
    required this.onAdjustRestTime,
    required this.onCancelRest,
  });

  final bool isRunning;
  final bool isDoneBanner;
  final int remainingRestSeconds;
  final void Function(int seconds) onAdjustRestTime;
  final VoidCallback onCancelRest;

  @override
  State<LiveWorkoutRestBar> createState() => _LiveWorkoutRestBarState();
}

class _LiveWorkoutRestBarState extends State<LiveWorkoutRestBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: widget.isDoneBanner ? 1.0 : 0.0,
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant LiveWorkoutRestBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDoneBanner && !oldWidget.isDoneBanner) {
      _morphController.forward(from: 0.0);
    } else if (!widget.isDoneBanner && oldWidget.isDoneBanner) {
      _morphController.reverse();
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final double r = DesignConstants.workoutOverlayHeight / 2;

    final defaultGlass = DesignConstants.liquidGlassSettings(isDark);
    final doneGlassColor = isDark
        ? const Color(0xFF1B5E20).withValues(alpha: 0.75)
        : const Color(0xFF81C784).withValues(alpha: 0.70);

    final doneGlass = LiquidGlassSettings(
      thickness: 25,
      blur: 3.5,
      glassColor: doneGlassColor,
      lightIntensity: isDark ? 0.70 : 0.85,
      saturation: 1.2,
      ambientRim: 0.15,
    );

    final Color doneTextColor = isDark ? Colors.white : Colors.black;
    final Color doneIconColor =
        isDark ? const Color(0xFF69F0AE) : const Color(0xFF2E7D32);

    final restSeconds = widget.remainingRestSeconds;
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    final timerStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: DesignConstants.workoutOverlayHeight,
        child: Stack(
          children: [
            // Drop shadow base
            Positioned.fill(
              child: ClipPath(
                clipper: ShadowOuterClipper(borderRadius: r),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    boxShadow: DesignConstants.glassShadow(isDark),
                  ),
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _morphAnimation,
              builder: (context, _) {
                final t = _morphAnimation.value;

                return Stack(
                  children: [
                    // Layer 1: Dark Glass Timer Pill
                    if (t < 1.0)
                      Positioned.fill(
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 1.0 - (0.04 * t),
                            child: IgnorePointer(
                              ignoring: t > 0.5,
                              child: GlassAdaptiveScope(
                                maxQuality: DesignConstants.defaultGlassQuality,
                                minQuality: DesignConstants.minGlassQuality,
                                child: GlassContainer(
                                  useOwnLayer: true,
                                  height: DesignConstants.workoutOverlayHeight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 12.0),
                                  shape: LiquidRoundedSuperellipse(
                                      borderRadius: r),
                                  quality: DesignConstants.defaultGlassQuality,
                                  settings: defaultGlass,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // -15 Button
                                      SizedBox(
                                        height: 38,
                                        width: 48,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            backgroundColor: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.black
                                                    .withValues(alpha: 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.1)
                                                    : Colors.black.withValues(
                                                        alpha: 0.05),
                                              ),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () =>
                                              widget.onAdjustRestTime(-15),
                                          child: Text(
                                            "-15",
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Timer Text
                                      Container(
                                        height: 38,
                                        alignment: Alignment.center,
                                        child: Text(
                                          timerStr,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // +15 Button
                                      SizedBox(
                                        height: 38,
                                        width: 48,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            backgroundColor: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.black
                                                    .withValues(alpha: 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.1)
                                                    : Colors.black.withValues(
                                                        alpha: 0.05),
                                              ),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () =>
                                              widget.onAdjustRestTime(15),
                                          child: Text(
                                            "+15",
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Skip Button
                                      SizedBox(
                                        height: 38,
                                        child: AppButton.primary(
                                          onPressed: widget.onCancelRest,
                                          label: l10n.skipButton,
                                          tooltip: l10n.skipButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Layer 2: Completed "Pause is over" Pill
                    if (t > 0.0)
                      Positioned.fill(
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.95 + (0.05 * t),
                            child: IgnorePointer(
                              ignoring: t <= 0.5,
                              child: GlassAdaptiveScope(
                                maxQuality: DesignConstants.defaultGlassQuality,
                                minQuality: DesignConstants.minGlassQuality,
                                child: GlassContainer(
                                  useOwnLayer: true,
                                  height: DesignConstants.workoutOverlayHeight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 12.0),
                                  shape: LiquidRoundedSuperellipse(
                                      borderRadius: r),
                                  quality: DesignConstants.defaultGlassQuality,
                                  settings: doneGlass,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.circle_check,
                                              color: doneIconColor),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.restOverLabel,
                                            style: TextStyle(
                                              color: doneTextColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 38,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            foregroundColor: doneTextColor,
                                            backgroundColor: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.15)
                                                : Colors.black
                                                    .withValues(alpha: 0.08),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.20)
                                                    : Colors.black.withValues(
                                                        alpha: 0.08),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                          ),
                                          onPressed: widget.onCancelRest,
                                          child: Text(
                                            l10n.snackbar_button_ok,
                                            style: TextStyle(
                                              color: doneTextColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
