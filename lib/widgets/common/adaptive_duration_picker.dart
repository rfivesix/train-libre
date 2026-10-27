// lib/widgets/common/adaptive_duration_picker.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../../services/haptic_feedback_service.dart';
import '../../util/design_constants.dart';
import 'app_button.dart';
import 'platform_adaptive_pickers.dart';

Future<Duration?> showAdaptiveDurationPicker({
  required BuildContext context,
  required Duration initialDuration,
  String? title,
  bool allowClear = false,
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
      return GlassPickerSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  const SizedBox(width: 80),
                  Expanded(
                    child: Text(
                      title ?? l10n?.restTimerLabel ?? 'Timer',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: allowClear
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                HapticFeedbackService.instance
                                    .selectionFeedback();
                                Navigator.pop(ctx, Duration.zero);
                              },
                              child: Text(
                                l10n?.clearDuration ?? 'Clear duration',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
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
      );
    },
  );

  return selected;
}
