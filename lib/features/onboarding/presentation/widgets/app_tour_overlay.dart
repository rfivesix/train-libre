import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';

/// Full-screen backdrop-blur spotlight overlay used by the main in-app walkthrough.
/// Everything outside the focused target element is strongly frosted and dimmed,
/// with a silky, soft-feathered gradient transition (no hard cutout edges).
class AppTourOverlay extends StatelessWidget {
  final Rect? targetRect;
  final String title;
  final String description;
  final String progressLabel;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const AppTourOverlay({
    super.key,
    required this.targetRect,
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark
        ? DesignConstants.brandAccentColor
        : DesignConstants.brandAccentColorLightMode;

    final List<RRect> holes = [];
    if (targetRect != null) {
      final rect = targetRect!;
      final isCircular =
          (rect.width - rect.height).abs() <= 6 && rect.width >= 48;
      if (isCircular) {
        final inflated = rect.inflate(6);
        holes.add(
          RRect.fromRectAndRadius(
            inflated,
            Radius.circular(inflated.width / 2),
          ),
        );
      } else if (rect.width > 160) {
        // Navigation bar or large containers
        holes.add(
          RRect.fromRectAndRadius(
            rect.inflate(6),
            const Radius.circular(28),
          ),
        );
      } else {
        // Tabs, chips, and squircle buttons
        holes.add(
          RRect.fromRectAndRadius(
            rect.inflate(6),
            const Radius.circular(22),
          ),
        );
      }
    }

    return Material(
      key: const Key('app_tour_overlay'),
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Frosted-glass blur & dark tint with soft feathered falloff around the focused item
          Positioned.fill(
            child: _FeatheredBackdropLayer(
              holes: holes,
              isDark: isDark,
            ),
          ),

          // 2. Explanatory Card Positioning (smoothly sits above/below active element)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 16.0;
                const spotlightGap = 16.0;
                const topSpacing = 16.0;
                const panelMaxWidth = 520.0;
                const bottomNavClearance = 16.0;

                final mediaQuery = MediaQuery.of(context);
                final safeTop = mediaQuery.padding.top + topSpacing;
                final safeBottom =
                    mediaQuery.padding.bottom + bottomNavClearance;
                final availableWidth =
                    (constraints.maxWidth - horizontalPadding * 2)
                        .clamp(0.0, panelMaxWidth);

                final cardWidget = Card(
                  elevation: 14,
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFFAF9F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: _borderSideOrNull(isDark),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                progressLabel,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? DesignConstants.brandAccentColor
                                      : const Color(0xFF5B6B00),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13.5,
                            height: 1.4,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF333330),
                          ),
                        ),
                        const SizedBox(height: DesignConstants.spacingM),
                        Row(
                          children: [
                            TextButton(
                              onPressed: onSkip,
                              child: Text(
                                skipLabel,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            AppButton.primary(
                              onPressed: onNext,
                              label: nextLabel,
                              tooltip: nextLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

                if (targetRect != null) {
                  final isLowerHalf =
                      targetRect!.center.dy > constraints.maxHeight * 0.45;

                  if (isLowerHalf) {
                    final bottomPos = (constraints.maxHeight -
                            targetRect!.top +
                            spotlightGap)
                        .clamp(
                            safeBottom,
                            (constraints.maxHeight - safeTop - 220)
                                .clamp(safeBottom, double.infinity));
                    return Stack(
                      children: [
                        Positioned(
                          bottom: bottomPos,
                          left: (constraints.maxWidth - availableWidth) / 2,
                          width: availableWidth,
                          child: cardWidget,
                        ),
                      ],
                    );
                  }
                }

                final defaultBottom = safeBottom + 24.0;
                final topPos = (targetRect != null
                        ? targetRect!.bottom + spotlightGap
                        : null);

                return Stack(
                  children: [
                    if (topPos != null)
                      Positioned(
                        top: topPos.clamp(
                            safeTop,
                            (constraints.maxHeight - safeBottom - 220)
                                .clamp(safeTop, double.infinity)),
                        left: (constraints.maxWidth - availableWidth) / 2,
                        width: availableWidth,
                        child: cardWidget,
                      )
                    else
                      Positioned(
                        bottom: defaultBottom,
                        left: (constraints.maxWidth - availableWidth) / 2,
                        width: availableWidth,
                        child: cardWidget,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static BorderSide _borderSideOrNull(bool isDark) {
    return BorderSide(
      color: isDark ? Colors.white12 : Colors.black12,
      width: 1,
    );
  }
}

/// Renders a frosted-glass backdrop filter with soft, silky feathered gradient
/// cutouts for each focused hole using GPU offscreen shader masking.
class _FeatheredBackdropLayer extends StatelessWidget {
  final List<RRect> holes;
  final bool isDark;

  const _FeatheredBackdropLayer({
    required this.holes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (holes.isEmpty) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: Colors.black.withValues(alpha: isDark ? 0.62 : 0.48),
        ),
      );
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder, bounds);

        // 1. Fill entire screen with solid white (opaque = full blur & dim)
        canvas.drawRect(bounds, Paint()..color = Colors.white);

        // 2. Carve out holes with smooth feathered gradient falloff
        for (final hole in holes) {
          // Fully clear center
          final corePaint = Paint()
            ..color = Colors.black
            ..blendMode = BlendMode.dstOut;
          canvas.drawRRect(hole.deflate(6), corePaint);

          // Soft Gaussian feathering around the perimeter (14px smooth transition)
          final featherPaint = Paint()
            ..color = Colors.black
            ..blendMode = BlendMode.dstOut
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
          canvas.drawRRect(hole, featherPaint);
        }

        final picture = recorder.endRecording();
        final img = picture.toImageSync(
          bounds.width.toInt().clamp(1, 4096),
          bounds.height.toInt().clamp(1, 4096),
        );
        return ImageShader(
          img,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
        );
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: Colors.black.withValues(alpha: isDark ? 0.62 : 0.48),
        ),
      ),
    );
  }
}
