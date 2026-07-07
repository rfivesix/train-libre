import 'package:flutter/material.dart';
import '../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';


/// A reusable global filter for selecting timeframes, supporting navigation and custom dates.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (displayDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.cardPaddingInternal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevron_left),
                  onPressed: onPrevious,
                  color: onPrevious != null ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: onTapDateDisplay,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            displayDate!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevron_right),
                  onPressed: nextEnabled ? onNext : null,
                  color: nextEnabled && onNext != null ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
                ),
              ],
            ),
          ),
        if (displayDate != null)
          const SizedBox(height: DesignConstants.spacingXS),
        SizedBox(
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
                return Padding(
                  padding: const EdgeInsets.only(right: DesignConstants.spacingS),
                  child: ChoiceChip(
                    label: Text(range),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onSelected(index);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
