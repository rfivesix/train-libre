import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class MealIngredientSummaryItem {
  final String name;
  final int grams;
  final int kcal;

  const MealIngredientSummaryItem({
    required this.name,
    required this.grams,
    required this.kcal,
  });
}

/// The deliberately quiet default between a meal's nutrition summary and its
/// full ingredient editor. Both an AI result and an already saved meal use it,
/// so opening either surface has the same visual contract: inspect first,
/// edit deliberately.
class MealIngredientsSummary extends StatelessWidget {
  final List<MealIngredientSummaryItem> ingredients;
  final VoidCallback onEdit;
  final ValueChanged<int>? onIngredientTap;

  const MealIngredientsSummary({
    super.key,
    required this.ingredients,
    required this.onEdit,
    this.onIngredientTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visibleIngredients = ingredients
        .where((ingredient) => ingredient.name.trim().isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mealIngredientCount(visibleIngredients.length),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        ...visibleIngredients.asMap().entries.map(
              (entry) => Padding(
                padding:
                    const EdgeInsets.only(bottom: DesignConstants.spacingS),
                child: SummaryCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: onIngredientTap == null
                        ? null
                        : () => onIngredientTap!(entry.key),
                    borderRadius: BorderRadius.circular(
                      DesignConstants.borderRadiusL,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(DesignConstants.spacingM),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value.name.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignConstants.spacingM),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${entry.value.kcal} kcal',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${entry.value.grams} g',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        if (visibleIngredients.isEmpty) ...[
          const SizedBox(height: DesignConstants.spacingXS),
          Text(
            l10n.aiReviewNoMatch,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: DesignConstants.spacingS),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(LucideIcons.pencil, size: 18),
            label: Text(l10n.edit),
          ),
        ),
      ],
    );
  }
}
