// lib/widgets/common/adaptive_timeframe_picker.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/statistics/domain/timeframe_block.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import 'app_button.dart';
import 'platform_adaptive_pickers.dart';

class TimeframeSelection {
  final DateTime anchorDate;
  final bool isRolling;

  TimeframeSelection(this.anchorDate, {this.isRolling = false});
}

Future<TimeframeSelection?> showAdaptiveTimeframePicker({
  required BuildContext context,
  required TimeframeBlock activeBlock,
  required DateTime initialAnchor,
  required DateTime earliestAvailableDay,
  DateTime? latestAvailableDay,
  bool initialIsRolling = false,
  bool supportRolling = true,
}) async {
  if (activeBlock == TimeframeBlock.maxBlock) return null;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  final now = DateTime.now();
  final latest = latestAvailableDay ?? now;

  // Generate selectable calendar blocks inside the caller's real data range.
  final List<DateTime> options = [];
  DateTime current =
      activeBlock.getBounds(earliestAvailableDay, earliestAvailableDay).start;

  while (current.isBefore(latest) ||
      current.isAtSameMomentAs(latest) ||
      current.year == latest.year && current.month == latest.month) {
    if (activeBlock
        .getBounds(current, earliestAvailableDay)
        .start
        .isAfter(latest)) {
      break;
    }
    options.add(current);

    // Increment to next block
    switch (activeBlock) {
      case TimeframeBlock.day:
        current = DateTime(current.year, current.month, current.day + 1);
        break;
      case TimeframeBlock.week:
        current = DateTime(current.year, current.month, current.day + 7);
        break;
      case TimeframeBlock.month:
        current = DateTime(current.year, current.month + 1, 15);
        break;
      case TimeframeBlock.threeMonths:
        current = DateTime(current.year, current.month + 3, 15);
        break;
      case TimeframeBlock.sixMonths:
        current = DateTime(current.year, current.month + 6, 15);
        break;
      case TimeframeBlock.year:
        current = DateTime(current.year + 1, 6, 15);
        break;
      case TimeframeBlock.maxBlock:
        break;
    }
    // Snap current back to bounds start for safety in iteration
    if (activeBlock != TimeframeBlock.maxBlock) {
      current = activeBlock.getBounds(current, earliestAvailableDay).start;
    } else {
      break;
    }
  }

  // Fallback if empty
  if (options.isEmpty) {
    options.add(earliestAvailableDay);
  }

  // Insert rolling option
  final DateTime rollingFlag = DateTime(9999);
  if (supportRolling &&
      activeBlock != TimeframeBlock.day &&
      activeBlock != TimeframeBlock.maxBlock) {
    // Insert before the last element (which is the current calendar block)
    if (options.isNotEmpty) {
      options.insert(options.length - 1, rollingFlag);
    } else {
      options.add(rollingFlag);
    }
  }

  // Find initial index
  int initialIndex;
  if (initialIsRolling && options.contains(rollingFlag)) {
    initialIndex = options.indexOf(rollingFlag);
  } else {
    initialIndex = options.indexWhere((d) {
      if (d == rollingFlag) return false;
      final b1 = activeBlock.getBounds(d, earliestAvailableDay);
      final b2 = activeBlock.getBounds(initialAnchor, earliestAvailableDay);
      return b1.start.year == b2.start.year &&
          b1.start.month == b2.start.month &&
          b1.start.day == b2.start.day;
    });
    if (initialIndex < 0) initialIndex = options.length - 1;
  }

  int selectedIndex = initialIndex;

  final locale = Localizations.localeOf(context).toString();
  String formatOption(DateTime date) {
    if (date == rollingFlag) {
      return l10n?.rollingDaysLabel(activeBlock.rollingDurationDays) ??
          "Letzte ${activeBlock.rollingDurationDays} Tage (rollierend)";
    }
    final b = activeBlock.getBounds(date, earliestAvailableDay);
    switch (activeBlock) {
      case TimeframeBlock.day:
        return DateFormat('dd. MMM yyyy', locale).format(b.start);
      case TimeframeBlock.week:
        return "${DateFormat('dd. MMM', locale).format(b.start)} - ${DateFormat('dd. MMM yyyy', locale).format(b.end)}";
      case TimeframeBlock.month:
        return DateFormat('MMMM yyyy', locale).format(b.start);
      case TimeframeBlock.threeMonths:
        return "${DateFormat('MMM', locale).format(b.start)} - ${DateFormat('MMM yyyy', locale).format(b.end)}";
      case TimeframeBlock.sixMonths:
        return "${DateFormat('MMM', locale).format(b.start)} - ${DateFormat('MMM yyyy', locale).format(b.end)}";
      case TimeframeBlock.year:
        return DateFormat('yyyy', locale).format(b.start);
      default:
        return "";
    }
  }

  final selected = await showModalBottomSheet<TimeframeSelection>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    builder: (ctx) {
      final kb = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: kb),
        child: GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.spacingL),
                child: Center(
                  child: Text(
                    AppLocalizations.of(ctx)?.selectDateTitle ?? 'Select Date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: initialIndex),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      selectedIndex = index;
                    },
                    children: options
                        .map((date) => Center(child: Text(formatOption(date))))
                        .toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignConstants.spacingL,
                  right: DesignConstants.spacingL,
                  top: DesignConstants.spacingXS,
                  bottom: DesignConstants.spacingM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        onPressed: () => Navigator.pop(ctx),
                        label: l10n?.cancel ?? 'Cancel',
                        tooltip: l10n?.cancel ?? 'Cancel',
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: AppButton.primary(
                        onPressed: () {
                          final selectedDate = options[selectedIndex];
                          final isRolling = selectedDate.year == 9999;
                          final anchor =
                              isRolling ? DateTime.now() : selectedDate;
                          Navigator.pop(ctx,
                              TimeframeSelection(anchor, isRolling: isRolling));
                        },
                        label: l10n?.snackbarButtonOK ?? 'OK',
                        tooltip: l10n?.snackbarButtonOK ?? 'OK',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return selected;
}
