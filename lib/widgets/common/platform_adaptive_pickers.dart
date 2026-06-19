// lib/widgets/common/platform_adaptive_pickers.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';

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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    _getSelectDateTitle(ctx),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  left: 16.0,
                  right: 16.0,
                  top: 4.0,
                  bottom: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                        ),
                        onPressed: () => Navigator.pop(ctx, tempDate),
                        child: Text(l10n?.snackbarButtonOK ?? 'OK'),
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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    _getSelectTimeTitle(ctx),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  left: 16.0,
                  right: 16.0,
                  top: 4.0,
                  bottom: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                        ),
                        onPressed: () => Navigator.pop(ctx, tempDateTime),
                        child: Text(l10n?.snackbarButtonOK ?? 'OK'),
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
        ? theme.colorScheme.surface.withValues(alpha: 0.88)
        : theme.colorScheme.surface.withValues(alpha: 0.94);
    final Color effectiveGlass = DesignConstants.glassColor(isDark);

    const double r = 24;
    const EdgeInsets outerMargin = EdgeInsets.fromLTRB(16, 0, 16, 16);

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
                      borderRadius: BorderRadius.circular(r),
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
                      thickness: 30,
                      blur: 8,
                      glassColor: effectiveGlass,
                      lightIntensity: isDark ? 0.55 : 0.80,
                      saturation: 1.20,
                    ),
                    shape: const LiquidRoundedSuperellipse(borderRadius: r),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: neutralTint,
                              borderRadius: BorderRadius.circular(r),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.20)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: bottomInset),
                          child: child,
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
