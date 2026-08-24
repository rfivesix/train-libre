// lib/features/diary/presentation/dialogs/delete_meal_entry_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../../util/design_constants.dart';

enum DeleteMealChoice {
  dissolveGroupOnly, // Unlink food items so they stay as individual logs
  deleteAll, // Delete meal entry and all child food logs
}

/// Bottom sheet confirming meal entry deletion with two clear options (Screen D5).
class DeleteMealEntryBottomSheet {
  static Future<DeleteMealChoice?> show(
    BuildContext context, {
    required String mealTitle,
    required int itemCount,
    required int totalKcal,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF222220) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final subtitleColor =
        isDark ? const Color(0xFF8A8A82) : const Color(0xFF5C5C55);
    final destructiveColor = const Color(0xFFB32219);
    final l10n = AppLocalizations.of(context)!;

    return showGlassBottomMenu<DeleteMealChoice>(
      context: context,
      title: mealTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.mealDeleteQuestion,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: subtitleColor,
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),

            // Option 1: Dissolve group only
            InkWell(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              onTap: () =>
                  Navigator.of(ctx).pop(DeleteMealChoice.dissolveGroupOnly),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusL),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mealDeleteUngroupTitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.mealDeleteUngroupBody(itemCount),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        height: 1.4,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),

            // Option 2: Delete meal and all items
            InkWell(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusL),
              onTap: () => Navigator.of(ctx).pop(DeleteMealChoice.deleteAll),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius:
                      BorderRadius.circular(DesignConstants.borderRadiusL),
                  border: Border.all(
                    color: destructiveColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mealDeleteAllTitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: destructiveColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.mealDeleteAllBody(itemCount, totalKcal),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        height: 1.4,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),

            // Cancel Button
            AppButton.secondary(
              onPressed: close,
              label: l10n.cancel,
              tooltip: l10n.cancel,
            ),
          ],
        );
      },
    );
  }
}
