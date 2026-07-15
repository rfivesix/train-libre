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
    final Color neutralTintLocal =
        DesignConstants.glassNeutralTint(isDarkLocal);

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
                  bottom: 116.0,
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
                            163.0 + (actionCount - 1 - index) * 94.0;
                        final double yFab = 69.0;
                        final double offsetY = yFinal - yFab;
                        final double offsetX =
                            0.0; // Perfectly aligned with FAB

                        // Staggered label fade & slide
                        final double labelTv =
                            ((tv - 0.65) / 0.35).clamp(0.0, 1.0);
                        final double labelOpacity = labelTv;
                        final double labelOffsetX = (1.0 - labelTv) * -16.0;

                        // Liquid stretch parameters
                        final double stretch = _getStretch(tv);
                        final double btnWidth = 74.0 * (1.0 - stretch * 0.3);
                        final double btnHeight = 74.0 * (1.0 + stretch);

                        return Transform.translate(
                          offset:
                              Offset((1 - tv) * offsetX, (1 - tv) * offsetY),
                          child: Opacity(
                            opacity: tv,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
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
                                    width: 74.0,
                                    height: 74.0,
                                    child: Center(
                                      child: SizedBox(
                                        width: btnWidth,
                                        height: btnHeight,
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
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            rLiquid),
                                                    boxShadow: DesignConstants
                                                        .glassShadow,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GlassButton.custom(
                                              onTap: () {
                                                onActionTap(action['action']);
                                              },
                                              width: btnWidth,
                                              height: btnHeight,
                                              useOwnLayer: true,
                                              quality: GlassQuality.minimal,
                                              shape:
                                                  const LiquidRoundedSuperellipse(
                                                borderRadius: rLiquid,
                                              ),
                                              settings: DesignConstants
                                                  .liquidGlassSettings(
                                                      isDarkLocal),
                                              child: Container(
                                                width: btnWidth,
                                                height: btnHeight,
                                                decoration: BoxDecoration(
                                                  color: neutralTintLocal,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          rLiquid),
                                                ),
                                                foregroundDecoration:
                                                    BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          rLiquid),
                                                  border: Border.all(
                                                    color: isDarkLocal
                                                        ? Colors.white
                                                            .withValues(
                                                                alpha: 0.20)
                                                        : Colors.black
                                                            .withValues(
                                                                alpha: 0.08),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child:
                                                    action['gradient'] == true
                                                        ? ShaderMask(
                                                            blendMode:
                                                                BlendMode.srcIn,
                                                            shaderCallback: (bounds) =>
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
                                                                ? Colors.white
                                                                : Colors.black,
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
                  bottom: 32.0,
                  right: 16.0,
                  child: IgnorePointer(
                    ignoring: v == 0.0,
                    child: Opacity(
                      opacity: v,
                      child: Stack(
                        children: [
                          ClipPath(
                            clipper: ShadowOuterClipper(
                                borderRadius: 37, isOval: true),
                            child: Container(
                              width: 74.0,
                              height: 74.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(37),
                                boxShadow: DesignConstants.glassShadow,
                              ),
                            ),
                          ),
                          GlassAdaptiveScope(
                            minQuality: GlassQuality.premium,
                            maxQuality: GlassQuality.premium,
                            child: AdaptiveGlass(
                              shape: const LiquidOval(),
                              settings: DesignConstants.liquidGlassSettings(
                                  isDarkLocal),
                              quality: GlassQuality.premium,
                              useOwnLayer: true,
                              isInteractive:
                                  false, // Force background blur during animations
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onClose,
                                  child: SizedBox(
                                    width: 74.0,
                                    height: 74.0,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
