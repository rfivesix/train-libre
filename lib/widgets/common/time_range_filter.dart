import 'package:flutter/material.dart';
import '../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'platform_adaptive_pickers.dart';

/// A reusable global filter for selecting timeframes.
/// The active timeframe chip dynamically expands to include the date navigation directly inside.
class TimeRangeFilter extends StatelessWidget {
  const TimeRangeFilter({
    super.key,
    required this.ranges,
    required this.selectedIndex,
    required this.onSelected,
    this.onPrevious,
    this.onNext,
    this.displayDate,
    this.onTapDateDisplay,
    this.nextEnabled = true,
  });

  final List<String> ranges;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? displayDate;
  final VoidCallback? onTapDateDisplay;
  final bool nextEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.cardPaddingInternal,
        ),
        child: Row(
          children: List.generate(ranges.length, (index) {
            final range = ranges[index];
            final isSelected = selectedIndex == index;
            
            if (isSelected) {
              return Padding(
                padding: const EdgeInsets.only(right: DesignConstants.spacingS),
                child: Container(
                  height: 32, // Strictly match default ChoiceChip height
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary, // App primary color
                    borderRadius: BorderRadius.circular(100), // Perfect circular pill edges
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure inkwells fill the 32px height
                    children: [
                      // Left Side: Block label
                      InkWell(
                        onTap: () async {
                          if (ranges.isEmpty || selectedIndex == null) return;
                          final newIndex = await showAdaptiveBlockTypePicker(
                            context: context,
                            ranges: ranges,
                            initialIndex: selectedIndex!,
                          );
                          if (newIndex != null) {
                            onSelected(newIndex);
                          }
                        },
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(100)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: Text(
                              range,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Center Divider
                      Center(
                        child: Container(
                          width: 1,
                          height: 16,
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      
                      // Navigation
                      InkWell(
                        onTap: onPrevious,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            child: Icon(
                              LucideIcons.chevron_left, 
                              size: 16,
                              color: onPrevious != null ? theme.colorScheme.onPrimary : theme.disabledColor,
                            ),
                          ),
                        ),
                      ),
                      
                      if (displayDate != null)
                        InkWell(
                          onTap: onTapDateDisplay,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Center(
                              child: Text(
                                displayDate!,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                      InkWell(
                        onTap: nextEnabled ? onNext : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(100)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Icon(
                              LucideIcons.chevron_right, 
                              size: 16,
                              color: nextEnabled && onNext != null ? theme.colorScheme.onPrimary : theme.disabledColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Inactive standard ChoiceChip
            return Padding(
              padding: const EdgeInsets.only(right: DesignConstants.spacingS),
              child: ChoiceChip(
                label: Text(range),
                selected: false,
                onSelected: (_) => onSelected(index),
                padding: EdgeInsets.zero,
              ),
            );
          }),
        ),
      ),
    );
  }
}
