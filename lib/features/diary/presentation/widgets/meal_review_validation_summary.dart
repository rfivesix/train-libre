import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_meal_validation.dart';
import '../../../../util/ai_validation_localization.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MealReviewValidationSummary extends StatefulWidget {
  const MealReviewValidationSummary({
    super.key,
    required this.validation,
    required this.itemsCount,
  });

  final AiValidationResult validation;
  final int itemsCount;

  @override
  State<MealReviewValidationSummary> createState() =>
      _MealReviewValidationSummaryState();
}

class _MealReviewValidationSummaryState
    extends State<MealReviewValidationSummary> {
  bool _validationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final validation = widget.validation;

    final allActionableIssues = validation.allIssues
        .where((issue) => issue.severity != AiValidationSeverity.info)
        .toList(growable: false);
    final color = validation.passed
        ? Colors.green
        : validation.errors.isNotEmpty
            ? theme.colorScheme.error
            : Colors.orange;

    final shouldAutoExpand = !validation.passed || validation.errors.isNotEmpty;
    final isExpanded = _validationExpanded || shouldAutoExpand;

    final compactTotals = '${validation.totals.kcalRounded} kcal · '
        'P${validation.totals.proteinRounded} · '
        'C${validation.totals.carbsRounded} · '
        'F${validation.totals.fatRounded}';

    return SummaryCard(
      child: InkWell(
        onTap: shouldAutoExpand
            ? null
            : () => setState(
                  () => _validationExpanded = !_validationExpanded,
                ),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    validation.passed
                        ? LucideIcons.badge_check
                        : LucideIcons.triangle_alert,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${validation.score}/100',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      compactTotals,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!shouldAutoExpand)
                    Icon(
                      isExpanded
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                ],
              ),
              // The token cost line was removed: it showed
              // `1200 + itemsCount * 80`, a made-up number presented with a
              // currency icon as if it had been measured. Real usage belongs in
              // the developer inspector, not on the user's review screen.
              if (isExpanded) ...[
                if (validation.repairLimitReached) ...[
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    l10n.aiValidationRepairLimitReachedReview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (allActionableIssues.isNotEmpty) ...[
                  const SizedBox(height: DesignConstants.spacingS),
                  ...allActionableIssues.take(4).map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '\u2022 ${aiValidationIssueText(l10n, issue)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                  if (allActionableIssues.length > 4) ...[
                    const SizedBox(height: DesignConstants.spacingXS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _showAllIssues(allActionableIssues, l10n),
                        child: Text(
                          l10n.showAllWithCount(allActionableIssues.length),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAllIssues(
    List<AiValidationIssue> issues,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aiValidationReviewSuggestedTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignConstants.spacingM),
              ...issues.map(
                (issue) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: DesignConstants.spacingXS),
                  child: Text(
                    '\u2022 ${aiValidationIssueText(l10n, issue)}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
