// lib/features/diary/presentation/widgets/meal_reanalysis_comparison_dialog.dart

import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/tracked_food_item.dart';

class ReanalysisItemDiff {
  final String name;
  final int grams;
  final bool isNew;
  final bool isChanged;
  final String? diffBadge;

  const ReanalysisItemDiff({
    required this.name,
    required this.grams,
    this.isNew = false,
    this.isChanged = false,
    this.diffBadge,
  });
}

/// Dialog comparing previously saved meal items vs re-analyzed new AI items (Screen D4).
class MealReanalysisComparisonDialog extends StatelessWidget {
  final String mealTitle;
  final List<TrackedFoodItem> previousItems;
  final List<ReanalysisItemDiff> newItems;
  final VoidCallback onKeepPrevious;
  final VoidCallback onApplyNew;

  const MealReanalysisComparisonDialog({
    super.key,
    required this.mealTitle,
    required this.previousItems,
    required this.newItems,
    required this.onKeepPrevious,
    required this.onApplyNew,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String mealTitle,
    required List<TrackedFoodItem> previousItems,
    required List<ReanalysisItemDiff> newItems,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MealReanalysisComparisonDialog(
        mealTitle: mealTitle,
        previousItems: previousItems,
        newItems: newItems,
        onKeepPrevious: () => Navigator.of(ctx).pop(false),
        onApplyNew: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161616) : const Color(0xFFF7F7F4);
    final cardBg = isDark ? const Color(0xFF222220) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF12120F);
    final subtitleColor =
        isDark ? const Color(0xFF8A8A82) : const Color(0xFF5C5C55);
    final lime = const Color(0xFFC9EF00);

    int prevKcal = 0;
    for (final it in previousItems) {
      final factor = it.entry.quantityInGrams / 100.0;
      prevKcal += (it.item.calories * factor).round();
    }

    // Estimate new kcal (or estimate proportional)
    int newKcal = prevKcal;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF33332E)
                      : const Color(0xFFD6D6CC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Text(
              l10n.reanalysisTitle,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 21,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reanalysisSubtitle,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 16),

            // Side-by-Side Comparison Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BISHER Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reanalysisPrevious,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$prevKcal kcal',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: titleColor,
                          ),
                        ),
                        const Divider(height: 16),
                        ...previousItems.map(
                          (it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.item.name,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: titleColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${it.entry.quantityInGrams} g',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: subtitleColor,
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
                const SizedBox(width: 10),

                // NEU Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: lime, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reanalysisNew,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            color: const Color(0xFF5B6B00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$newKcal kcal',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ...newItems.map(
                          (it) {
                            final isHighlighted = it.isNew || it.isChanged;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: isHighlighted
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3)
                                  : EdgeInsets.zero,
                              decoration: isHighlighted
                                  ? BoxDecoration(
                                      color: lime.withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.name,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: titleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${it.grams} g${it.diffBadge != null ? " · ${it.diffBadge}" : ""}',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: isHighlighted
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 12,
                                      color: isHighlighted
                                          ? const Color(0xFF4A5800)
                                          : subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legend Info
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.reanalysisDiffHint,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom CTA Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardBg,
                      foregroundColor: titleColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                      elevation: 1,
                    ),
                    onPressed: onKeepPrevious,
                    child: Text(
                      l10n.reanalysisKeepPrevious,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: const Color(0xFF12120F),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onApplyNew,
                    child: Text(
                      l10n.reanalysisApplyNew,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
