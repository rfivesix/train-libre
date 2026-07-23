// lib/widgets/common/platform_adaptive_pickers.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../features/statistics/domain/timeframe_block.dart';
import 'package:intl/intl.dart';
import 'glass_border_painter.dart';
import '../../services/haptic_feedback_service.dart';
import 'app_button.dart';
import '../../features/nutrition_recommendation/domain/goal_models.dart';
import '../../services/unit_service.dart';

/// Helper to get the localized date picker title.
String _getSelectDateTitle(BuildContext context) {
  return AppLocalizations.of(context)?.selectDateTitle ?? 'Select Date';
}

/// Helper to get the localized time picker title.
String _getSelectTimeTitle(BuildContext context) {
  return AppLocalizations.of(context)?.selectTimeTitle ?? 'Select Time';
}

/// A platform-adaptive Date Picker.
///
/// On Android, displays a themed Material 3 Date Picker dialog.
/// On iOS, displays a custom [GlassModalSheet] wrapping a [CupertinoDatePicker]
/// spinner with transparent background and glass controls.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  Locale? locale,
}) async {
  return _showGlassDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

/// A platform-adaptive Time Picker.
///
/// On all platforms, displays a custom glass picker wrapping a [CupertinoDatePicker]
/// time spinner with transparent background and glass controls.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  return _showGlassTimePicker(
    context: context,
    initialTime: initialTime,
  );
}

/// Internal iOS Liquid Glass Date Picker sheet
Future<DateTime?> _showGlassDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  DateTime tempDate = initialDate;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  final selected = await showModalBottomSheet<DateTime>(
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
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title at the top
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignConstants.spacingL,
                  right: DesignConstants.spacingL,
                  top: DesignConstants.spacingL,
                  bottom: DesignConstants.spacingS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      _getSelectDateTitle(ctx),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            HapticFeedbackService.instance.selectionFeedback();
                            Navigator.pop(ctx, DateTime.now());
                          },
                          child: Text(
                            l10n?.today ?? 'Today',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Date Picker Wheel
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    initialDateTime: initialDate,
                    minimumDate: firstDate,
                    maximumDate: lastDate,
                    mode: CupertinoDatePickerMode.date,
                    use24hFormat: MediaQuery.alwaysUse24HourFormatOf(ctx) ||
                        Localizations.localeOf(ctx).languageCode == 'de',
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ),
              // Action Buttons
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
                        onPressed: () => Navigator.pop(ctx, tempDate),
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

/// Internal iOS Liquid Glass Time Picker sheet
Future<TimeOfDay?> _showGlassTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  final now = DateTime.now();
  DateTime tempDateTime = DateTime(
    now.year,
    now.month,
    now.day,
    initialTime.hour,
    initialTime.minute,
  );
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  final selected = await showModalBottomSheet<DateTime>(
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
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title at the top
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignConstants.spacingL,
                  right: DesignConstants.spacingL,
                  top: DesignConstants.spacingL,
                  bottom: DesignConstants.spacingS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      _getSelectTimeTitle(ctx),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            HapticFeedbackService.instance.selectionFeedback();
                            final now = DateTime.now();
                            Navigator.pop(ctx, now);
                          },
                          child: Text(
                            l10n?.nowLabel ?? 'Now',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Time Picker Wheel
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    initialDateTime: tempDateTime,
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: MediaQuery.alwaysUse24HourFormatOf(ctx) ||
                        Localizations.localeOf(ctx).languageCode == 'de',
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempDateTime = newDateTime;
                    },
                  ),
                ),
              ),
              // Action Buttons
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
                        onPressed: () => Navigator.pop(ctx, tempDateTime),
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

  if (selected != null) {
    return TimeOfDay(hour: selected.hour, minute: selected.minute);
  }
  return null;
}

/// Reusable Glass Picker Sheet container that replicates the styling of [showGlassBottomMenu].
class _GlassPickerSheet extends StatelessWidget {
  final Widget child;

  const _GlassPickerSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = media.viewPadding.bottom;

    final Color neutralTint = isDark
        ? DesignConstants.summaryCardDarkMode.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.82);
    final Color effectiveGlass = DesignConstants.glassColor(isDark);

    const double r = 24;
    const EdgeInsets outerMargin = EdgeInsets.zero;

    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: outerMargin,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(r)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: AdaptiveGlass(
                    settings: LiquidGlassSettings(
                      thickness: 0,
                      blur: 8,
                      glassColor: effectiveGlass,
                      lightIntensity: 0,
                      saturation: 1.20,
                    ),
                    shape: const LiquidVerticalRoundedSuperellipse(
                      topRadius: r,
                      bottomRadius: 0,
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: neutralTint,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(r)),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GlassBorderPainter(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.08),
                              radius: r,
                              strokeWidth: 1.5,
                              bottomPadding: bottomInset,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: bottomInset),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: DesignConstants.spacingS),
                              Center(
                                child: Container(
                                  width: 44,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                              child,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  // Generate the list of allowed anchor dates from earliestAvailableDay to now
  final List<DateTime> options = [];
  DateTime current =
      activeBlock.getBounds(earliestAvailableDay, earliestAvailableDay).start;

  while (current.isBefore(now) ||
      current.isAtSameMomentAs(now) ||
      current.year == now.year && current.month == now.month) {
    if (activeBlock
        .getBounds(current, earliestAvailableDay)
        .start
        .isAfter(now)) {
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
    options.add(now);
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
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.spacingL),
                child: Center(
                  child: Text(
                    _getSelectDateTitle(ctx),
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

Future<int?> showAdaptiveBlockTypePicker({
  required BuildContext context,
  required List<String> ranges,
  required int initialIndex,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  int selectedIndex = initialIndex;

  final selected = await showModalBottomSheet<int>(
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
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.spacingL),
                child: Center(
                  child: Text(
                    'Timeframe',
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
                    children:
                        ranges.map((r) => Center(child: Text(r))).toList(),
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
                        onPressed: () => Navigator.pop(ctx, selectedIndex),
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

Future<Duration?> showAdaptiveDurationPicker({
  required BuildContext context,
  required Duration initialDuration,
  String? title,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  Duration selectedDuration = initialDuration;

  final selected = await showModalBottomSheet<Duration>(
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
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: DesignConstants.spacingL),
                  child: Center(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: DesignConstants.spacingL),
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
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: initialDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      selectedDuration = newDuration;
                    },
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
                        onPressed: () => Navigator.pop(ctx, selectedDuration),
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

/// A platform-adaptive target rate picker sheet with a Cupertino wheel spinner.
///
/// Allows setting a custom target rate (e.g. 0.37 kg/week or 370 g/week).
Future<double?> showAdaptiveTargetRatePicker({
  required BuildContext context,
  required BodyweightGoal goal,
  required double initialKgPerWeek,
  required UnitService unitService,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final isMetric = unitService.isMetric;

  final Color barrierColor = isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.3);

  // Generate options list
  // Metric: 0.05 kg to 1.50 kg in 0.01 kg (10 g) steps (50g to 1500g)
  // Imperial: 0.10 lbs to 3.00 lbs in 0.02 lbs steps
  final List<double> rateValues = [];
  if (isMetric) {
    for (int step = 5; step <= 150; step++) {
      rateValues.add(step / 100.0); // 0.05, 0.06, ..., 1.50 kg/week
    }
  } else {
    for (int step = 10; step <= 300; step += 2) {
      rateValues.add(
        unitService.convertToMetric(step / 100.0, UnitDimension.weight),
      );
    }
  }

  final absInitial = initialKgPerWeek.abs();
  int initialIndex = 0;
  double minDiff = double.infinity;
  for (int i = 0; i < rateValues.length; i++) {
    final diff = (rateValues[i] - absInitial).abs();
    if (diff < minDiff) {
      minDiff = diff;
      initialIndex = i;
    }
  }

  int selectedIndex = initialIndex;
  double selectedValue = rateValues[selectedIndex];

  String formatRate(double rawKgPerWeek) {
    final sign = goal == BodyweightGoal.loseWeight ? '-' : '+';
    if (isMetric) {
      final grams = (rawKgPerWeek * 1000).round();
      final displayVal = rawKgPerWeek
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      if (grams < 1000 && grams % 100 != 0) {
        return '$sign$grams g/Woche ($sign$displayVal kg)';
      }
      return '$sign$displayVal kg/Woche ($sign$grams g)';
    } else {
      final displayLbs = unitService.convertDisplayValue(
        rawKgPerWeek,
        UnitDimension.weight,
      );
      final valStr = displayLbs
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      final suffix = unitService.suffixFor(UnitDimension.weight);
      return '$sign$valStr $suffix/week';
    }
  }

  final result = await showModalBottomSheet<double>(
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
        child: _GlassPickerSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignConstants.spacingL,
                ),
                child: Center(
                  child: Text(
                    l10n?.customTargetRateDialogTitle ??
                        'Eigene Zielrate festlegen',
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
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    itemExtent: 42,
                    onSelectedItemChanged: (int index) {
                      selectedIndex = index;
                      selectedValue = rateValues[index];
                      HapticFeedbackService.instance.selectionFeedback();
                    },
                    children: rateValues
                        .map((val) => Center(child: Text(formatRate(val))))
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
                          final finalSigned = goal == BodyweightGoal.loseWeight
                              ? -selectedValue
                              : selectedValue;
                          Navigator.pop(ctx, finalSigned);
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

  return result;
}

