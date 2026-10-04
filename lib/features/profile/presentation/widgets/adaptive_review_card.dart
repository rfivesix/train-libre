// lib/features/profile/presentation/widgets/adaptive_review_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/models/goal_model.dart';
import '../weekly_goal_review_screen.dart';

class AdaptiveReviewCard extends StatelessWidget {
  final Goal? activeGoal;
  final GoalReviewRecord? pendingReview;
  final bool isRecommendationDue;
  final DateTime? nextDueAt;
  final VoidCallback? onOpenReview;
  final VoidCallback? onRefresh;

  const AdaptiveReviewCard({
    super.key,
    required this.activeGoal,
    this.pendingReview,
    this.isRecommendationDue = false,
    this.nextDueAt,
    this.onOpenReview,
    this.onRefresh,
  });

  Color _statusColor(String? status, ThemeData theme) {
    switch (status) {
      case 'on_trajectory':
      case 'target_reached':
      case 'on_track':
        return Colors.green;
      case 'behind':
      case 'target_date_needs_review':
      case 'slower':
        return Colors.orange;
      case 'ahead':
      case 'faster':
        return Colors.blue;
      case 'calibrating':
      default:
        return theme.colorScheme.primary;
    }
  }

  String _statusLabel(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'behind':
        return l10n.reviewStatusBehind;
      case 'ahead':
        return l10n.reviewStatusAhead;
      case 'target_reached':
        return l10n.reviewStatusTargetReached;
      case 'target_date_needs_review':
        return l10n.reviewStatusTargetDateNeedsReview;
      case 'on_trajectory':
      case 'on_track':
        return l10n.reviewStatusOnTrack;
      case 'slower':
        return l10n.reviewStatusSlower;
      case 'faster':
        return l10n.reviewStatusFaster;
      case 'calibrating':
      default:
        return l10n.reviewStatusCalibrating;
    }
  }

  String _momentumLabel(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      'matching_plan' => l10n.reviewMomentumMatchingPlan,
      'catching_up' => l10n.reviewMomentumCatchingUp,
      'falling_further_behind' => l10n.reviewMomentumFallingBehind,
      'moving_faster' => l10n.reviewMomentumMovingFaster,
      'moving_slower' => l10n.reviewMomentumMovingSlower,
      _ => l10n.reviewMomentumUnclear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (activeGoal == null) {
      return const SizedBox.shrink();
    }

    final review = pendingReview;
    final hasActiveReview = review != null || isRecommendationDue;

    if (!hasActiveReview) {
      // Quiet informational card when no review is due
      if (nextDueAt == null) return const SizedBox.shrink();
      final dateStr = DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).format(nextDueAt!);

      return SummaryCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingL,
            vertical: DesignConstants.spacingM,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: Text(
                  l10n.reviewNextAnalysisScheduled(dateStr),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final assessment = review?.assessment;
    final hasInsufficientData =
        assessment?.nutritionAction == 'insufficient_data';
    final primaryStatus = hasInsufficientData
        ? 'calibrating'
        : assessment?.overallStatus ?? review?.trajectoryStatus;
    final statusColor = _statusColor(primaryStatus, theme);
    final statusLabel = _statusLabel(context, primaryStatus);
    final recommendedCalories =
        hasInsufficientData ? null : review?.recommendedCalories;
    final currentCalories = assessment?.currentCalories;
    final hasCalories = currentCalories != null || recommendedCalories != null;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final signedDelta = currentCalories == null || recommendedCalories == null
        ? null
        : recommendedCalories - currentCalories;

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.weeklyReviewCardHeaderBadge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingS),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignConstants.spacingS,
                        vertical: DesignConstants.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          DesignConstants.borderRadiusS,
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
            if (hasCalories)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.weeklyReviewCaloriesCurrent,
                        value: currentCalories == null
                            ? '—'
                            : '${numberFormat.format(currentCalories)} kcal',
                        useSecondarySurface: true,
                        disableShadow: true,
                        mainAxisAlignment: MainAxisAlignment.start,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Expanded(
                      child: ValueSummaryCard(
                        label: l10n.weeklyReviewCaloriesRecommended,
                        value: recommendedCalories == null
                            ? '—'
                            : '${numberFormat.format(recommendedCalories)} kcal',
                        subtitle: signedDelta == null
                            ? null
                            : l10n.weeklyReviewCaloriesChange(
                                '${signedDelta > 0 ? '+' : ''}${numberFormat.format(signedDelta)}',
                              ),
                        valueColor: theme.colorScheme.primary,
                        borderColor: theme.colorScheme.primary,
                        useSecondarySurface: true,
                        disableShadow: true,
                        mainAxisAlignment: MainAxisAlignment.start,
                      ),
                    ),
                  ],
                ),
              )
            else
              _ReviewFactRow(
                label: l10n.weeklyReviewCardRecentLabel,
                value: assessment == null
                    ? l10n.reviewMomentumUnclear
                    : _momentumLabel(
                        context,
                        assessment.recentMomentumStatus,
                      ),
              ),
            if (assessment == null && review?.explanation != null) ...[
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                review!.explanation!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: l10n.reviewOpenDetailsButton,
                onPressed: () async {
                  final openReview = onOpenReview;
                  if (openReview != null) {
                    openReview();
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WeeklyGoalReviewScreen(
                          goal: activeGoal!,
                          review: review,
                        ),
                      ),
                    );
                    onRefresh?.call();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFactRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewFactRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
