// lib/features/profile/presentation/widgets/adaptive_review_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/models/goal_model.dart';
import '../weekly_goal_review_screen.dart';

class AdaptiveReviewCard extends StatelessWidget {
  final Goal? activeGoal;
  final GoalReviewRecord? pendingReview;
  final bool isRecommendationDue;
  final DateTime? nextDueAt;
  final VoidCallback? onApply;
  final VoidCallback? onRefresh;

  const AdaptiveReviewCard({
    super.key,
    required this.activeGoal,
    this.pendingReview,
    this.isRecommendationDue = false,
    this.nextDueAt,
    this.onApply,
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
    final primaryStatus = assessment?.overallStatus ?? review?.trajectoryStatus;
    final statusColor = _statusColor(primaryStatus, theme);
    final statusLabel = _statusLabel(context, primaryStatus);

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(DesignConstants.borderRadiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.weeklyReviewCardHeaderBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Text(
              assessment == null
                  ? review?.explanation ??
                      l10n.weeklyReviewPendingDefaultExplanation
                  : l10n.reviewOverallSummary(
                      statusLabel,
                      _momentumLabel(
                        context,
                        assessment.recentMomentumStatus,
                      ),
                    ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: l10n.reviewOpenDetailsButton,
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WeeklyGoalReviewScreen(
                            goal: activeGoal!,
                            review: review,
                          ),
                        ),
                      );
                      onRefresh?.call();
                    },
                  ),
                ),
                if (review?.recommendedCalories != null && onApply != null) ...[
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: AppButton.primary(
                      label: l10n.applyRecommendationButton,
                      onPressed: onApply,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
