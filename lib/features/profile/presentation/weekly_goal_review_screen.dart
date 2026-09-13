// lib/features/profile/presentation/weekly_goal_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../domain/models/goal_model.dart';
import '../domain/repositories/goal_repository.dart';
import '../data/goal_repository_impl.dart';
import 'widgets/goal_adjustment_sheet.dart';

class WeeklyGoalReviewScreen extends StatefulWidget {
  final Goal goal;
  final GoalReviewRecord? review;
  final IGoalRepository? repository;

  const WeeklyGoalReviewScreen({
    super.key,
    required this.goal,
    this.review,
    this.repository,
  });

  @override
  State<WeeklyGoalReviewScreen> createState() => _WeeklyGoalReviewScreenState();
}

class _WeeklyGoalReviewScreenState extends State<WeeklyGoalReviewScreen> {
  late final IGoalRepository _goalRepository;
  late final AdaptiveNutritionRecommendationService _recommendationService;
  GoalReviewRecord? _review;
  int _weightObservationCount = 0;
  int _loggedIntakeDaysCount = 0;
  bool _isLoading = true;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.repository ?? GoalRepositoryImpl();
    _recommendationService = AdaptiveNutritionRecommendationService();
    _review = widget.review;
    _initReview();
  }

  Future<void> _initReview() async {
    if (_review == null) {
      final pending = await _goalRepository.getPendingReview(widget.goal.id);
      _review = pending;
    }

    final rev = _review;
    if (rev != null) {
      try {
        final db = DatabaseHelper.instance.dbInstance;
        final start = rev.windowStart;
        final end = rev.windowEnd;

        final weights = await (db.select(db.measurements)
              ..where((t) => t.type.equals('weight')))
            .get();
        _weightObservationCount = weights.where((m) =>
            !m.date.isBefore(start) && !m.date.isAfter(end)).length;

        final logs = await db.select(db.nutritionLogs).get();
        final days = logs
            .where((l) => !l.consumedAt.isBefore(start) && !l.consumedAt.isAfter(end))
            .map((l) => '${l.consumedAt.year}-${l.consumedAt.month}-${l.consumedAt.day}')
            .toSet();
        _loggedIntakeDaysCount = days.length;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status, ThemeData theme) {
    switch (status) {
      case 'on_track':
        return Colors.green;
      case 'slower':
        return Colors.orange;
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

  Future<void> _applyRecommendation() async {
    if (_isApplying) return;
    setState(() => _isApplying = true);

    final applied =
        await _recommendationService.applyLatestRecommendationToActiveTargets();
    if (!mounted) return;
    setState(() => _isApplying = false);

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied
              ? l10n.adaptiveRecommendationAppliedToGoalsSnack
              : l10n.adaptiveRecommendationNotAvailableSnack,
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _dismissReview() async {
    final review = _review;
    if (review != null) {
      await _goalRepository.updateReviewStatus(
        review.id,
        'dismissed',
        decision: 'keep_current',
      );
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reviewDismissedSnack)),
    );
    Navigator.of(context).pop(false);
  }

  Future<void> _openGoalAdjustment() async {
    final progress = await _goalRepository.getGoalProgress(widget.goal);
    final startWeight =
        progress?.currentValue ?? progress?.baselineValue ?? 75.0;

    if (!mounted) return;
    final adjusted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalAdjustmentSheet(
        goal: widget.goal,
        startWeightKg: startWeight,
        repository: _goalRepository,
      ),
    );

    if (adjusted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    if (_isLoading) {
      return Scaffold(
        appBar: GlobalAppBar(title: l10n.weeklyReviewScreenTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final review = _review;
    final statusColor = _statusColor(review?.trajectoryStatus, theme);
    final statusLabel = _statusLabel(context, review?.trajectoryStatus);

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.weeklyReviewScreenTitle,
      ),
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          // Header card with evaluation verdict and date range
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            DesignConstants.borderRadiusS,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (review != null)
                        Text(
                          '${dateFormat.format(review.windowStart)} – ${dateFormat.format(review.windowEnd)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  Text(
                    review?.explanation ??
                        l10n.weeklyReviewPendingDefaultExplanation,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Sufficiency Gate Status
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewSufficiencyGateTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGateMetric(
                          context,
                          label: l10n.reviewWeighInsCountLabel,
                          value: '$_weightObservationCount / 3',
                          isMet: _weightObservationCount >= 3,
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingM),
                      Expanded(
                        child: _buildGateMetric(
                          context,
                          label: l10n.reviewLoggedDaysCountLabel,
                          value: '$_loggedIntakeDaysCount / 4',
                          isMet: _loggedIntakeDaysCount >= 4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Trajectory Comparison: Observed Rate vs Target Rate
          if (review?.observedRateKgPerWeek != null ||
              widget.goal.desiredWeeklyRateKg != null) ...[
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reviewTrajectoryComparisonTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.reviewObservedRateLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                review?.observedRateKgPerWeek != null
                                    ? '${review!.observedRateKgPerWeek! >= 0 ? "+" : ""}${unitService.convertDisplayValue(review.observedRateKgPerWeek!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}'
                                    : '--',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.reviewTargetRateLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.goal.desiredWeeklyRateKg != null
                                    ? '${widget.goal.desiredWeeklyRateKg! >= 0 ? "+" : ""}${unitService.convertDisplayValue(widget.goal.desiredWeeklyRateKg!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}'
                                    : '--',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (review?.tdeeEstimate != null) ...[
                      const Divider(height: DesignConstants.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.reviewEstimatedTDEELabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${review!.tdeeEstimate!.round()} kcal',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],

          // Recommended Targets
          if (review?.recommendedCalories != null) ...[
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reviewRecommendationTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.calories,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${review!.recommendedCalories} kcal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (review.recommendedProtein != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.protein, style: theme.textTheme.bodyMedium),
                          Text(
                            '${review.recommendedProtein} g',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (review.recommendedCarbs != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.carbs,
                              style: theme.textTheme.bodyMedium),
                          Text(
                            '${review.recommendedCarbs} g',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (review.recommendedFat != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.fat, style: theme.textTheme.bodyMedium),
                          Text(
                            '${review.recommendedFat} g',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
          ],

          // The 3 Explicit Actions
          if (review?.recommendedCalories != null) ...[
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: _isApplying
                    ? '...'
                    : l10n.reviewActionApplyRecommendation,
                tooltip: l10n.reviewActionApplyRecommendation,
                onPressed: _isApplying ? null : _applyRecommendation,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
          ],
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              label: l10n.reviewActionAdjustTrajectory,
              tooltip: l10n.reviewActionAdjustTrajectory,
              onPressed: _openGoalAdjustment,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _dismissReview,
              child: Text(l10n.reviewActionKeepCurrent),
            ),
          ),
          const BottomContentSpacer(),
        ],
      ),
    );
  }

  Widget _buildGateMetric(
    BuildContext context, {
    required String label,
    required String value,
    required bool isMet,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingM),
      decoration: BoxDecoration(
        color: isMet
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
      ),
      child: Row(
        children: [
          Icon(
            isMet ? LucideIcons.circle_check : LucideIcons.circle_alert,
            color: isMet ? Colors.green : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
