import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/theme_service.dart';
import '../../../../widgets/common/macro_badge_row.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/platform_adaptive_dropdown.dart';
import '../add_food_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MealItemCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Future<MealCardNutritionTotals> mealTotalsFuture;
  final int ingredientCount;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback? onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MealItemCard({
    super.key,
    required this.meal,
    required this.mealTotalsFuture,
    required this.ingredientCount,
    required this.onAdd,
    required this.onEdit,
    required this.onDuplicate,
    this.onShare,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final themeService = Provider.of<ThemeService>(context);

    return SummaryCard(
      onTap: onTap,
      padding: const EdgeInsets.only(
          left: DesignConstants.spacingL,
          right: DesignConstants.spacingS,
          top: DesignConstants.spacingL,
          bottom: DesignConstants.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meal['name'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXS),
                FutureBuilder<MealCardNutritionTotals>(
                  future: mealTotalsFuture,
                  builder: (_, snap) {
                    final totals = snap.data;
                    final count = totals?.ingredientCount ?? ingredientCount;

                    if (totals == null) {
                      return Text(
                        '${AppLocalizations.of(context)!.mealIngredientsTitle}: $count',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.mealIngredientsTitle}: $count',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: DesignConstants.spacingXS),
                        MacroBadgeRow(
                          kcal: totals.kcal,
                          protein: totals.protein,
                          carbs: totals.carbs,
                          fat: totals.fat,
                          useBadges: themeService.useColorfulMacroBadges,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: AppLocalizations.of(context)!.mealsAddToDiary,
                icon: Icon(LucideIcons.circle_plus, color: color.primary),
                onPressed: onAdd,
              ),
              PlatformAdaptivePopupMenu<String>(
                icon: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(LucideIcons.ellipsis_vertical),
                ),
                items: [
                  if (onShare != null)
                    PlatformAdaptivePopupMenuItem(
                      value: 'share',
                      label: AppLocalizations.of(context)!.share,
                      icon: LucideIcons.link,
                    ),
                  PlatformAdaptivePopupMenuItem(
                    value: 'edit',
                    label: AppLocalizations.of(context)!.mealsEdit,
                    icon: LucideIcons.pencil,
                  ),
                  PlatformAdaptivePopupMenuItem(
                    value: 'duplicate',
                    label: AppLocalizations.of(context)!.mealDuplicate,
                    icon: LucideIcons.copy,
                  ),
                  PlatformAdaptivePopupMenuItem(
                    value: 'delete',
                    label: AppLocalizations.of(context)!.mealsDelete,
                    icon: LucideIcons.trash,
                    isDestructive: true,
                  ),
                ],
                onSelected: (action) {
                  switch (action) {
                    case 'share':
                      onShare?.call();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
