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
      final isCircular = (rect.width - rect.height).abs() <= 6;
      final radius = isCircular
          ? Radius.circular(rect.width / 2)
          : (rect.width > 120 ? const Radius.circular(16) : const Radius.circular(18));
      return RRect.fromRectAndRadius(rect.inflate(4), radius);
    }).toList();

    return Material(
      key: const Key('ai_meal_capture_tour_overlay'),
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Strong frosted-glass blur & darkened backdrop with cutouts for focused items
          Positioned.fill(
            child: ClipPath(
              clipper: _InvertedHolesClipper(holes: holes),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.62 : 0.48),
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
