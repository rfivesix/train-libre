import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';

/// A reusable Apple HIG iOS-style Segmented Control component.
///
/// Displays a horizontal strip of segments with a smooth animated sliding
/// indicator pill (`#2C2C2E` in Dark Mode, `#FFFFFF` in Light Mode) and
/// triggers settings-aware haptic feedback on tab changes.
class AppSegmentedControl<T> extends StatelessWidget {
  /// Map of value to widget/label for each segment.
  final Map<T, String> children;

  /// Currently selected value.
  final T groupValue;

  /// Callback fired when user selects a segment.
  final ValueChanged<T> onValueChanged;

  /// Optional height for the segmented control container.
  final double height;

  const AppSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
    this.height = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keys = children.keys.toList();
    final selectedIndex = keys.indexOf(groupValue);

    final containerBg = isDark
        ? const Color(0xFF171719)
        : const Color(0xFFE3E3E8);

    final indicatorBg = isDark
        ? DesignConstants.summaryCardSecondaryDarkMode // #2C2C2E
        : Colors.white;

    final squircleRadius = SmoothBorderRadius(
      cornerRadius: DesignConstants.borderRadiusM,
      cornerSmoothing: 0.6,
    );
    final squircle = SmoothRectangleBorder(borderRadius: squircleRadius);

    return Container(
      height: height,
      padding: const EdgeInsets.all(2.0),
      decoration: ShapeDecoration(
        color: containerBg,
        shape: squircle,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalSegments = keys.length;
          if (totalSegments == 0) return const SizedBox.shrink();

          final segmentWidth = (constraints.maxWidth - 4.0) / totalSegments;
          final validIndex = selectedIndex >= 0 ? selectedIndex : 0;

          return Stack(
            children: [
              // Animated sliding indicator pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: validIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: ShapeDecoration(
                    color: indicatorBg,
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: DesignConstants.borderRadiusM - 2,
                        cornerSmoothing: 0.6,
                      ),
                    ),
                    shadows: isDark
                        ? const []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                ),
              ),

              // Interactive Segment Labels Row
              Row(
                children: keys.map((key) {
                  final isSelected = key == groupValue;
                  final label = children[key]!;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedbackService.instance.selectionFeedback();
                          onValueChanged(key);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.60),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
