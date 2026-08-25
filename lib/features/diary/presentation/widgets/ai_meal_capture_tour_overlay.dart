import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';

/// Full-screen backdrop-blur spotlight overlay for the interactive AI Meal Capture tour.
/// Everything outside the focused target elements is strongly frosted and dimmed,
/// keeping the active controls and previews crisp and sharp.
class AiMealCaptureTourOverlay extends StatelessWidget {
  final List<Rect> targetRects;
  final String title;
  final String description;
  final String progressLabel;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  AiMealCaptureTourOverlay({
    super.key,
    Rect? targetRect,
    List<Rect>? targetRects,
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  }) : targetRects = targetRects ?? (targetRect != null ? [targetRect] : const []);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark
        ? DesignConstants.brandAccentColor
        : DesignConstants.brandAccentColorLightMode;

    final holes = targetRects.map((rect) {
      final isShutterCircle =
          (rect.width - rect.height).abs() <= 6 && rect.width >= 58;
      if (isShutterCircle) {
        final inflated = rect.inflate(4);
        return RRect.fromRectAndRadius(
          inflated,
          Radius.circular(inflated.width / 2),
        );
      }
      final isBanner = rect.width > 120;
      if (isBanner) {
        // Generous padding for banner horizontally and on top, without bleeding downwards into buttons
        final adjustedRect = Rect.fromLTRB(
          rect.left - 4,
          rect.top - 4,
          rect.right + 4,
          rect.bottom + 1,
        );
        return RRect.fromRectAndRadius(adjustedRect, const Radius.circular(22));
      }
      // Squircle secondary buttons (48x48 rounded rectangles with 16px radius)
      final inflated = rect.inflate(4.5);
      return RRect.fromRectAndRadius(inflated, const Radius.circular(19));
    }).toList();

    // 10-stage concentric progressive blur ramp for an ultra-soft, feathered falloff
    const int blurTiers = 10;
    const double stepDistance = 3.0;
    const double tierSigma = 1.8;
    final double tierAlpha = isDark ? 0.065 : 0.045;

    return Material(
      key: const Key('ai_meal_capture_tour_overlay'),
      color: Colors.transparent,
      child: Stack(
        children: [
          // Multi-tier progressive feathered blur & dimming layers
          if (holes.isEmpty)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.58 : 0.42),
                ),
              ),
            )
          else
            for (int i = 0; i < blurTiers; i++)
              Positioned.fill(
                child: ClipPath(
                  clipper: _InvertedHolesClipper(
                    holes: holes
                        .map((h) => _inflateRRect(h, (blurTiers - 1 - i) * stepDistance))
                        .toList(),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: tierSigma,
                      sigmaY: tierSigma,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: tierAlpha),
                    ),
                  ),
                ),
              ),

          // 2. Explanatory Card Positioning (smoothly sits above active elements)
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

                if (targetRects.isNotEmpty) {
                  final topmostTargetTop =
                      targetRects.map((r) => r.top).reduce(min);
                  final isLowerHalf =
                      topmostTargetTop > constraints.maxHeight * 0.35;

                  if (isLowerHalf) {
                    final bottomPos = (constraints.maxHeight -
                            topmostTargetTop +
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

                final defaultTop = (constraints.maxHeight * 0.18).clamp(
                    safeTop,
                    (constraints.maxHeight - safeBottom - 220)
                        .clamp(safeTop, double.infinity));
                final lowestTargetBottom = targetRects.isNotEmpty
                    ? targetRects.map((r) => r.bottom).reduce(max)
                    : null;
                final topPos = (lowestTargetBottom != null
                        ? lowestTargetBottom + spotlightGap
                        : defaultTop)
                    .clamp(
                        safeTop,
                        (constraints.maxHeight - safeBottom - 220)
                            .clamp(safeTop, double.infinity));

                return Stack(
                  children: [
                    Positioned(
                      top: topPos,
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

  static RRect _inflateRRect(RRect rrect, double amount) {
    if (amount == 0) return rrect;
    final rect = rrect.outerRect.inflate(amount);
    final radius = Radius.circular(
      (rrect.tlRadiusX + amount).clamp(0.0, rect.shortestSide / 2),
    );
    return RRect.fromRectAndRadius(rect, radius);
  }

  static BorderSide _borderSideOrNull(bool isDark) {
    return BorderSide(
      color: isDark ? Colors.white12 : Colors.black12,
      width: 1,
    );
  }
}

class _InvertedHolesClipper extends CustomClipper<Path> {
  final List<RRect> holes;

  _InvertedHolesClipper({required this.holes});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Offset.zero & size);
    for (final hole in holes) {
      path.addRRect(hole);
    }
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant _InvertedHolesClipper oldClipper) {
    if (oldClipper.holes.length != holes.length) return true;
    for (int i = 0; i < holes.length; i++) {
      if (oldClipper.holes[i] != holes[i]) return true;
    }
    return false;
  }
}
