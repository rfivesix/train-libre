import 'package:flutter/material.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A reusable global filter for selecting timeframes.
/// The active timeframe chip dynamically expands to include the date navigation directly inside.
class TimeRangeFilter extends StatefulWidget {
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
    this.showDateNavigation = true,
  });

  final List<String> ranges;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? displayDate;
  final VoidCallback? onTapDateDisplay;
  final bool nextEnabled;
  final bool showDateNavigation;

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
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.ranges.length != widget.ranges.length) {
      if (oldWidget.ranges.length != widget.ranges.length) {
        _updateKeys();
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSelected(force: true));
    }
  }

  void _updateKeys() {
    _keys.clear();
    for (int i = 0; i < widget.ranges.length; i++) {
      _keys.add(GlobalKey());
    }
  }

  void _scrollToSelected({bool force = false}) {
    if (widget.selectedIndex == null || widget.selectedIndex! >= _keys.length) {
      return;
    }
    final key = _keys[widget.selectedIndex!];
    final chipContext = key.currentContext;
    if (chipContext != null && _scrollController.hasClients) {
      final chipBox = chipContext.findRenderObject() as RenderBox?;
      final scrollBox = _scrollController
          .position.context.storageContext
          .findRenderObject() as RenderBox?;
      if (chipBox != null &&
          scrollBox != null &&
          chipBox.attached &&
          scrollBox.attached) {
        final localOffset =
            chipBox.localToGlobal(Offset.zero, ancestor: scrollBox);
        final currentScroll = _scrollController.offset;
        final targetOffset = currentScroll +
            localOffset.dx -
            DesignConstants.cardPaddingInternal;
        final clamped = targetOffset.clamp(
            0.0, _scrollController.position.maxScrollExtent);

        if (force) {
          if ((clamped - currentScroll).abs() > 0.5) {
            _scrollController.animateTo(
              clamped,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        } else {
          _scrollController.jumpTo(clamped);
        }
      }
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
                    borderRadius: BorderRadius.circular(
                        100), // Perfect circular pill edges
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment
                        .stretch, // Ensure inkwells fill the 32px height
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

                      // Animated expansion of inner date navigation
                      if (widget.showDateNavigation)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 1,
                                  height: 16,
                                  color: theme.colorScheme.onPrimary
                                      .withValues(alpha: 0.3),
                                ),
                              ),

                              // Navigation
                              Tooltip(
                                message: MaterialLocalizations.of(context)
                                    .previousPageTooltip,
                                child: InkWell(
                                  key: const Key('time-range-prev'),
                                  onTap: widget.onPrevious != null
                                      ? () {
                                          HapticFeedbackService.instance
                                              .selectionFeedback();
                                          widget.onPrevious!();
                                        }
                                      : null,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.chevron_left,
                                        semanticLabel: MaterialLocalizations.of(
                                                context)
                                            .previousPageTooltip,
                                        size: 16,
                                        color: widget.onPrevious != null
                                            ? theme.colorScheme.onPrimary
                                            : theme.disabledColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (widget.displayDate != null)
                                InkWell(
                                  onTap: widget.onTapDateDisplay != null
                                      ? () {
                                          HapticFeedbackService.instance
                                              .selectionFeedback();
                                          widget.onTapDateDisplay!();
                                        }
                                      : null,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 4),
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

                              Tooltip(
                                message:
                                    MaterialLocalizations.of(context).nextPageTooltip,
                                child: InkWell(
                                  key: const Key('time-range-next'),
                                  onTap: widget.nextEnabled && widget.onNext != null
                                      ? () {
                                          HapticFeedbackService.instance
                                              .selectionFeedback();
                                          widget.onNext!();
                                        }
                                      : null,
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(100)),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 10),
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.chevron_right,
                                        semanticLabel:
                                            MaterialLocalizations.of(context)
                                                .nextPageTooltip,
                                        size: 16,
                                        color: widget.nextEnabled &&
                                                widget.onNext != null
                                            ? theme.colorScheme.onPrimary
                                            : theme.disabledColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                  onSelected: (_) {
                    HapticFeedbackService.instance.selectionFeedback();
                    widget.onSelected(index);
                  },
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
}
