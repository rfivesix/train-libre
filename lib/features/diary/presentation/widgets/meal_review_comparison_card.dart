import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_meal_validation.dart';
import '../../../../util/ai_validation_localization.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import 'package:provider/provider.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/base_food_language_service.dart';
import '../../domain/models/food_item.dart';
import 'meal_review_macros_bar.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A card representing an AI suggested meal item compared against database matches.
class MealReviewComparisonCard extends StatelessWidget {
  final Key dismissibleKey;
  final String name;
  final int estimatedGrams;
  final double confidence;

  /// Optional badge shown before the name — the numbered pin that matches the
  /// marker on the meal photo.
  final Widget? leading;
  final FoodItem? matchedFood;
  final List<AiValidationIssue> issues;
  final AiNutritionTotals nutrition;
  final VoidCallback onDismissed;
  final VoidCallback onTap;
  final VoidCallback onReplace;
  final VoidCallback onEditQuantity;
  final ValueChanged<int>? onQuickAdjustQuantity;

  const MealReviewComparisonCard({
    required this.dismissibleKey,
    required this.name,
    required this.estimatedGrams,
    required this.confidence,
    this.leading,
    required this.matchedFood,
    required this.issues,
    required this.nutrition,
    required this.onDismissed,
    required this.onTap,
    required this.onReplace,
    required this.onEditQuantity,
    this.onQuickAdjustQuantity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMatch = matchedFood != null;

    final Color confidenceColor;
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
    } else if (confidence >= 0.5) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Theme.of(context).colorScheme.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
      child: Dismissible(
        key: dismissibleKey,
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
          ),
          child: const Icon(LucideIcons.trash, color: Colors.white),
        ),
        onDismissed: (_) => onDismissed(),
        child: SummaryCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
            child: Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 2, right: DesignConstants.spacingM),
                      child: leading!,
                    ),
                  ],
                  // Left: food info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: DesignConstants.spacingXS),
                        if (hasMatch)
                          Builder(
                            builder: (context) {
                              final themeService =
                                  Provider.of<ThemeService>(context);
                              final baseFoodLang =
                                  BaseFoodLanguageService.resolveLanguageCode(
                                choice: themeService.baseFoodLanguage,
                                context: context,
                              );
                              final matchName =
                                  matchedFood!.source == FoodItemSource.base
                                      ? matchedFood!.getLocalizedName(context,
                                          languageCode: baseFoodLang)
                                      : matchedFood!.getLocalizedName(context);
                              // Only name the database entry when it differs —
                              // printing the same word twice tells the user
                              // nothing and makes the card look cluttered.
                              final differs = matchName.trim().toLowerCase() !=
                                  name.trim().toLowerCase();
                              return Text(
                                differs
                                    ? '$matchName • ${matchedFood!.calories} kcal/100g'
                                    : '${matchedFood!.calories} kcal/100g',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          )
                        else
                          Text(
                            l10n.aiReviewNoMatch,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        // Macro badges row
                        const SizedBox(height: 6),
                        MealReviewMacrosBar(nutrition: nutrition),
                        // Confidence is only worth showing when it is low
                        // enough to be worth a second look. A green "95%" on
                        // every row is one more colour competing for attention
                        // and nothing the user can act on.
                        if (confidence < 0.7) ...[
                          const SizedBox(height: DesignConstants.spacingXS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: confidenceColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  DesignConstants.borderRadiusM),
                            ),
                            child: Text(
                              l10n.aiReviewUncertain(
                                  (confidence * 100).round()),
                              style: TextStyle(
                                color: confidenceColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (issues
                            .where(
                              (issue) =>
                                  issue.severity != AiValidationSeverity.info,
                            )
                            .isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...issues
                              .where(
                                (issue) =>
                                    issue.severity != AiValidationSeverity.info,
                              )
                              .take(2)
                              .map(
                                (issue) => Text(
                                  aiValidationIssueText(l10n, issue),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: issue.severity ==
                                            AiValidationSeverity.error
                                        ? theme.colorScheme.error
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: DesignConstants.spacingS),

                  // Right: Stacked action buttons (Replace/Delete above Stepper)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              LucideIcons.arrow_left_right,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            tooltip: l10n.aiReviewReplaceItem,
                            onPressed: onReplace,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            icon: Icon(
                              LucideIcons.trash,
                              size: 16,
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.8),
                            ),
                            tooltip: l10n.delete,
                            onPressed: onDismissed,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                              DesignConstants.borderRadiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onQuickAdjustQuantity != null)
                              InkWell(
                                onTap: () => onQuickAdjustQuantity!(-25),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(
                                      DesignConstants.borderRadiusS),
                                  bottomLeft: Radius.circular(
                                      DesignConstants.borderRadiusS),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  child: Icon(LucideIcons.minus, size: 14),
                                ),
                              ),
                            GestureDetector(
                              onTap: onEditQuantity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.spacingS,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${estimatedGrams}g',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (onQuickAdjustQuantity != null)
                              InkWell(
                                onTap: () => onQuickAdjustQuantity!(25),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(
                                      DesignConstants.borderRadiusS),
                                  bottomRight: Radius.circular(
                                      DesignConstants.borderRadiusS),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  child: Icon(LucideIcons.plus, size: 14),
                                ),
                              ),
                          ],
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
    );
  }
}
