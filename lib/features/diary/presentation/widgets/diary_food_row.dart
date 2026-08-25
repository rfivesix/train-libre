// lib/features/diary/presentation/widgets/diary_food_row.dart

import 'package:flutter/material.dart';

/// Width of the amount column shared by every diary row.
const double kDiaryAmountColumnWidth = 58;

/// Width of the energy column shared by every diary row.
///
/// Fixed rather than intrinsic on purpose: the point is that all energy values
/// on the screen line up under each other, whether they belong to a meal, one
/// of its ingredients, or a standalone entry.
const double kDiaryEnergyColumnWidth = 78;

/// Width reserved after the energy column.
///
/// Every row keeps this space free even when it has nothing to put there, so
/// the expand chevron on a meal header cannot push its energy value out of the
/// flight the other rows sit in.
const double kDiaryTrailingColumnWidth = 26;

/// One line of the diary: name, amount, energy.
///
/// Used for standalone entries and for the ingredients inside a meal alike.
/// They used to be two different shapes — a two-line `ListTile` and a one-line
/// row with the amount glued to the name — which is why the columns never
/// lined up and long names pushed the numbers around.
class DiaryFoodRow extends StatelessWidget {
  final String name;
  final String amountLabel;
  final String energyLabel;

  /// Ingredients inside a meal are set slightly quieter than the entries that
  /// stand on their own, so the grouping is readable without indentation.
  final bool isNested;

  /// Optional widget in the reserved trailing slot — the expand chevron on a
  /// meal header. Rows without one still reserve the space.
  final Widget? trailing;

  const DiaryFoodRow({
    super.key,
    required this.name,
    required this.amountLabel,
    required this.energyLabel,
    this.isNested = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameStyle = isNested
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.titleMedium;
    final mutedColor = theme.textTheme.bodySmall?.color;
    // The energy value of a standalone entry carries the same weight as the
    // entry's name, so it takes the same full-contrast ink: white on dark,
    // near-black on light. `onSurface` looked washed out in dark mode.
    final energyColor = isDark ? Colors.white : const Color(0xFF12120F);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isNested ? 7 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: nameStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: kDiaryAmountColumnWidth,
            child: Text(
              amountLabel,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              maxLines: 1,
            ),
          ),
          SizedBox(
            width: kDiaryEnergyColumnWidth,
            child: Text(
              energyLabel,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isNested ? FontWeight.w600 : FontWeight.w700,
                // Explicit: `labelLarge` inherits a muted colour in the light
                // theme, which made every energy value look disabled.
                color:
                    isNested ? theme.textTheme.bodyMedium?.color : energyColor,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(
            width: kDiaryTrailingColumnWidth,
            child: trailing == null
                ? null
                : Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
