import re

# 1. Update TimeRangeFilter to be a StatefulWidget with auto-scrolling
file_tr = "lib/widgets/common/time_range_filter.dart"
with open(file_tr, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace TimeRangeFilter declaration and build method
new_tr_code = """class TimeRangeFilter extends StatefulWidget {
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
  State<TimeRangeFilter> createState() => _TimeRangeFilterState();
}

class _TimeRangeFilterState extends State<TimeRangeFilter> {
  late final ScrollController _scrollController;
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _updateKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(TimeRangeFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex || oldWidget.ranges.length != widget.ranges.length) {
      _updateKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _updateKeys() {
    _keys.clear();
    for (int i = 0; i < widget.ranges.length; i++) {
      _keys.add(GlobalKey());
    }
  }

  void _scrollToSelected() {
    if (widget.selectedIndex == null || widget.selectedIndex! >= _keys.length) return;
    final key = _keys[widget.selectedIndex!];
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.cardPaddingInternal,
        ),
        child: Row(
          children: List.generate(widget.ranges.length, (index) {
            final range = widget.ranges[index];
            final isSelected = widget.selectedIndex == index;
            
            Widget chip;
            if (isSelected) {
              chip = Padding(
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
                      Padding(
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
                        onTap: widget.onPrevious,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            child: Icon(
                              LucideIcons.chevron_left, 
                              size: 16,
                              color: widget.onPrevious != null ? theme.colorScheme.onPrimary : theme.disabledColor,
                            ),
                          ),
                        ),
                      ),
                      
                      if (widget.displayDate != null)
                        InkWell(
                          onTap: widget.onTapDateDisplay,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Center(
                              child: Text(
                                widget.displayDate!,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                      InkWell(
                        onTap: widget.nextEnabled ? widget.onNext : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(100)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Icon(
                              LucideIcons.chevron_right, 
                              size: 16,
                              color: widget.nextEnabled && widget.onNext != null ? theme.colorScheme.onPrimary : theme.disabledColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Inactive standard ChoiceChip
              chip = Padding(
                padding: const EdgeInsets.only(right: DesignConstants.spacingS),
                child: ChoiceChip(
                  label: Text(range),
                  selected: false,
                  onSelected: (_) => widget.onSelected(index),
                  padding: EdgeInsets.zero,
                ),
              );
            }

            return Container(
              key: _keys[index],
              child: chip,
            );
          }),
        ),
      ),
    );
  }
}"""

# Find class TimeRangeFilter ... and replace until the end of file
start_idx = content.find("class TimeRangeFilter")
if start_idx != -1:
    content = content[:start_idx] + new_tr_code

with open(file_tr, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated TimeRangeFilter")

