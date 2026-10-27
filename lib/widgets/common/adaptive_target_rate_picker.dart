// lib/widgets/common/adaptive_target_rate_picker.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../features/nutrition_recommendation/domain/goal_models.dart';
import '../../generated/app_localizations.dart';
import '../../services/haptic_feedback_service.dart';
import '../../services/unit_service.dart';
import '../../util/design_constants.dart';
import 'app_button.dart';
import 'platform_adaptive_pickers.dart';

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
      return GlassPickerSheet(
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
      );
    },
  );

  return result;
}
