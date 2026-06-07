import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../util/design_constants.dart';
import '../../../../theme/color_constants.dart';
import '../../../../core/performance/glass_performance_manager.dart';

class SpeedDialMenuOverlay extends StatelessWidget {
  final Animation<double> animation;
  final List<Map<String, dynamic>> actions;
  final VoidCallback onClose;
  final Function(String) onActionTap;

  const SpeedDialMenuOverlay({
    super.key,
    required this.animation,
    required this.actions,
    required this.onClose,
    required this.onActionTap,
  });

  double _safe01(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final bool isDarkLocal = Theme.of(context).brightness == Brightness.dark;
    final Color neutralTintLocal = DesignConstants.glassNeutralTint(isDarkLocal);

    // Define liquid animation radius locally here or from a constant.
    const double rLiquid = 99;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = _safe01(animation.value);

        return Offstage(
          offstage: v == 0.0,
          child: IgnorePointer(
            ignoring: v == 0.0,
            child: Stack(
              children: [
                Opacity(
                  opacity: v,
                  child: GestureDetector(
                    onTap: onClose,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 6.0 * v,
                        sigmaY: 6.0 * v,
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4 * v),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100.0,
                  right: 20.0,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: actions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final action = entry.value;
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Interval(
                            (index * 0.12).clamp(0.0, 0.95),
                            1.0,
                            curve: Curves.easeOutBack,
                          ),
                        );
                        final tv = _safe01(curved.value);
                        final offsetY = 90.0 * (index + 1);
                        return Transform.translate(
                          offset: Offset(0, (1 - tv) * offsetY),
                          child: Opacity(
                            opacity: tv,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    action['label'],
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black87
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 74.0,
                                    height: 74.0,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipPath(
                                            clipper: ShadowOuterClipper(
                                              borderRadius: rLiquid,
                                              isOval: true,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(rLiquid),
                                                boxShadow: DesignConstants.glassShadow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ValueListenableBuilder<GlassQuality>(
                                          valueListenable: GlassPerformanceManager().qualityNotifier,
                                          builder: (context, quality, child) {
                                            return GlassButton.custom(
                                              onTap: () {
                                                onActionTap(action['action']);
                                              },
                                              width: 74.0,
                                              height: 74.0,
                                              useOwnLayer: true,
                                              quality: quality,
                                              shape: const LiquidRoundedSuperellipse(
                                                borderRadius: rLiquid,
                                              ),
                                              settings: DesignConstants.liquidGlassSettings(isDarkLocal),
                                              child: child,
                                            );
                                          },
                                          child: Container(
                                            width: 74.0,
                                            height: 74.0,
                                            decoration: BoxDecoration(
                                              color: neutralTintLocal,
                                              borderRadius: BorderRadius.circular(rLiquid),
                                            ),
                                            foregroundDecoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(rLiquid),
                                              border: Border.all(
                                                color: isDarkLocal
                                                    ? Colors.white.withValues(alpha: 0.20)
                                                    : Colors.black.withValues(alpha: 0.08),
                                                width: 1.2,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: action['gradient'] == true
                                                ? ShaderMask(
                                                    blendMode: BlendMode.srcIn,
                                                    shaderCallback: (bounds) =>
                                                        createAiGradientShader(
                                                      bounds,
                                                    ),
                                                    child: Icon(
                                                      action['icon'],
                                                      size: 28,
                                                    ),
                                                  )
                                                : Icon(
                                                    action['icon'],
                                                    size: 28,
                                                    color: isDarkLocal
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
