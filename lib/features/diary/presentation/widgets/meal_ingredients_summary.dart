import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';

class MealIngredientSummaryItem {
  final String? key;
  final String name;
  final int? grams;
  final String? amountLabel;
  final int kcal;

  const MealIngredientSummaryItem({
    this.key,
    required this.name,
    required this.grams,
    this.amountLabel,
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
  final ValueChanged<int>? onIngredientLongPress;
  final ValueChanged<int>? onIngredientDismissed;
  final bool showEditButton;

  const MealIngredientsSummary({
    super.key,
    required this.ingredients,
    required this.onEdit,
    this.onIngredientTap,
    this.onIngredientLongPress,
    this.onIngredientDismissed,
    this.showEditButton = true,
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
        ...visibleIngredients.asMap().entries.map((entry) {
          final card = Padding(
            padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
            child: SummaryCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: onIngredientTap == null
                    ? null
                    : () => onIngredientTap!(entry.key),
                onLongPress: onIngredientLongPress == null
                    ? null
                    : () => onIngredientLongPress!(entry.key),
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
                          if (entry.value.amountLabel != null ||
                              entry.value.grams != null)
                            Text(
                              entry.value.amountLabel ??
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
          );
          if (onIngredientDismissed == null) return card;
          return Dismissible(
            key: ValueKey(
              entry.value.key ?? '${entry.value.name}-${entry.key}',
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onIngredientDismissed!(entry.key),
            background: Container(
              alignment: AlignmentDirectional.centerEnd,
              margin: const EdgeInsets.only(bottom: DesignConstants.spacingS),
              padding: const EdgeInsetsDirectional.only(end: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(
                  DesignConstants.borderRadiusL,
                ),
              ),
              child: Icon(LucideIcons.trash, color: theme.colorScheme.onError),
            ),
            child: card,
          );
        }),
        if (visibleIngredients.isEmpty) ...[
          const SizedBox(height: DesignConstants.spacingXS),
          Text(
            l10n.aiReviewNoMatch,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (showEditButton) ...[
          const SizedBox(height: DesignConstants.spacingS),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: onEdit,
              icon: LucideIcons.pencil,
              label: l10n.edit,
              tooltip: l10n.edit,
            ),
          ),
        ],
      ],
    );
  }
}
