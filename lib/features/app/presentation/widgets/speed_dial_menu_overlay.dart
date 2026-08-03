import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../util/design_constants.dart';

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

  double _getStretch(double tv) {
    if (tv < 0.7) {
      // Stretch phase: peak stretch at tv = 0.35
      final double t = tv / 0.7;
      return 0.40 * math.sin(t * math.pi);
    } else {
      // Wobble/settle phase: squash slightly, then settle
      final double t = (tv - 0.7) / 0.3; // 0.0 to 1.0
      // 1 full cycle of wobble (compress, expand, settle)
      return -0.15 * math.sin(t * 2 * math.pi) * (1.0 - t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkLocal = Theme.of(context).brightness == Brightness.dark;


    // Define liquid animation radius locally here or from a constant.
    const double rLiquid = 100.0; // Large radius ensures perfect-circle glass appearance

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
                    child: RepaintBoundary(
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
                ),
                Positioned(
                  bottom: 86.0,
                  right: 16.0,
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

                        // Sprout coordinate system calculations
                        final int actionCount = actions.length;
                        final double yFinal =
                            140.0 + (actionCount - 1 - index) * 76.0;
                        final double yFab = 64.0;
                        final double offsetY = yFinal - yFab;
                        final double offsetX =
                            0.0; // Perfectly aligned with FAB

                        // Staggered label fade & slide
                        final double labelTv =
                            ((tv - 0.65) / 0.35).clamp(0.0, 1.0);
                        final double labelOpacity = labelTv;
                        final double labelOffsetX = (1.0 - labelTv) * -16.0;

                        // Liquid stretch parameters — scale from fabSize to match FAB appearance
                        final double stretch = _getStretch(tv);
                        final double btnWidth =
                            DesignConstants.fabSize * (1.0 - stretch * 0.3);
                        final double btnHeight =
                            DesignConstants.fabSize * (1.0 + stretch);

                        return Transform.translate(
                          offset:
                              Offset((1 - tv) * offsetX, (1 - tv) * offsetY),
                          child: Opacity(
                            opacity: tv,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Opacity(
                                    opacity: labelOpacity,
                                    child: Transform.translate(
                                      offset: Offset(labelOffsetX, 0.0),
                                      child: Text(
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
                                    ),
                                  ),
                                  const SizedBox(
                                      width: DesignConstants.spacingL),
                                  SizedBox(
                                    // Fixed container prevents layout jumps during stretch animation
                                    width: DesignConstants.fabSize,
                                    height: DesignConstants.fabSize,
                                    child: Center(
                                      child: SizedBox(
                                        width: btnWidth,
                                        height: btnHeight,
                                        child: Stack(
                                          children: [
                                            // Shadow layer — identical to FAB shadow
                                            Positioned.fill(
                                              child: ClipPath(
                                                clipper: ShadowOuterClipper(
                                                  borderRadius: rLiquid,
                                                  isOval: true,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            rLiquid),
                                                    boxShadow: DesignConstants
                                                        .glassShadow,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Premium glass layer — identical pattern to the FAB
                                            GlassAdaptiveScope(
                                              maxQuality: DesignConstants.defaultGlassQuality,
                                              child: AdaptiveGlass(
                                                shape: const LiquidOval(),
                                                settings: DesignConstants
                                                    .liquidGlassSettings(
                                                        isDarkLocal),
                                                quality: DesignConstants.defaultGlassQuality,
                                                useOwnLayer: true,
                                                isInteractive: false,
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    customBorder:
                                                        const CircleBorder(),
                                                    onTap: () {
                                                      onActionTap(
                                                          action['action']);
                                                    },
                                                    child: SizedBox(
                                                      width: btnWidth,
                                                      height: btnHeight,
                                                      child: Center(
                                                        child: action[
                                                                    'gradient'] ==
                                                                true
                                                            ? ShaderMask(
                                                                blendMode:
                                                                    BlendMode
                                                                        .srcIn,
                                                                shaderCallback:
                                                                    (bounds) =>
                                                                        DesignConstants
                                                                            .createAiGradientShader(
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
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                // Active Rotating FAB on top of the blur filter
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: IgnorePointer(
                    ignoring: v == 0.0,
                    child: Stack(
                        children: [
                          ClipPath(
                            clipper: ShadowOuterClipper(
                                borderRadius: DesignConstants.fabSize / 2,
                                isOval: true),
                            child: Container(
                              width: DesignConstants.fabSize,
                              height: DesignConstants.fabSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    DesignConstants.fabSize / 2),
                                boxShadow: DesignConstants.glassShadow,
                              ),
                            ),
                          ),
                          GlassAdaptiveScope(
                            maxQuality: DesignConstants.defaultGlassQuality,
                            child: AdaptiveGlass(
                              shape: const LiquidOval(),
                              settings: DesignConstants.liquidGlassSettings(
                                  isDarkLocal),
                              quality: DesignConstants.defaultGlassQuality,
                              useOwnLayer: true,
                              isInteractive:
                                  false, // Force background blur during animations
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onClose,
                                  child: SizedBox(
                                    width: DesignConstants.fabSize,
                                    height: DesignConstants.fabSize,
                                    child: Center(
                                      child: RotationTransition(
                                        turns: Tween<double>(
                                                begin: 0.0, end: 0.375)
                                            .animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.plus,
                                          color: isDarkLocal
                                              ? Colors.white
                                              : Colors.black,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
      },
    );
  }
}
