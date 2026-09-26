import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_buckets.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/value_summary_card.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../domain/models/goal_model.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/services/goal_trajectory_calculator.dart';
import '../data/goal_repository_impl.dart';
import 'widgets/goal_adjustment_sheet.dart';

class WeeklyGoalReviewScreen extends StatefulWidget {
  final Goal goal;
  final GoalReviewRecord? review;
  final IGoalRepository? repository;
  final AdaptiveNutritionRecommendationService? recommendationService;

  const WeeklyGoalReviewScreen({
    super.key,
    required this.goal,
    this.review,
    this.repository,
    this.recommendationService,
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
  bool _showAdjustmentEditor = false;
  double? _currentWeightKg;
  final _adjustmentKey = GlobalKey<GoalAdjustmentSheetState>();

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.weeklyGoalReview));
    _goalRepository = widget.repository ?? GoalRepositoryImpl();
    _recommendationService = widget.recommendationService ??
        AdaptiveNutritionRecommendationService();
    _review = widget.review;
    _initReview();
  }

  Future<void> _initReview() async {
    final progress = await _goalRepository.getGoalProgress(widget.goal);
    _currentWeightKg = progress?.currentValue ?? progress?.baselineValue;
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
        _weightObservationCount = weights
            .where((m) => !m.date.isBefore(start) && !m.date.isAfter(end))
            .length;

        final logs = await db.select(db.nutritionLogs).get();
        final days = logs
            .where((l) =>
                !l.consumedAt.isBefore(start) && !l.consumedAt.isAfter(end))
            .map((l) =>
                '${l.consumedAt.year}-${l.consumedAt.month}-${l.consumedAt.day}')
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

  String _nutritionExplanation(BuildContext context, String? action) {
    final l10n = AppLocalizations.of(context)!;
    return switch (action) {
      'adjust_targets' => l10n.reviewNutritionAdjustTargets,
      'keep_targets_intake_differs' =>
        l10n.reviewNutritionKeepTargetsIntakeDiffers,
      'trajectory_change_needed' => l10n.reviewNutritionTrajectoryChangeNeeded,
      'insufficient_data' => l10n.reviewNutritionInsufficientData,
      _ => l10n.reviewNutritionKeepTargets,
    };
  }

  void _trackReviewCompleted(
    String decision, {
    String calorieDirection = 'none',
    bool hasMacroAdjustments = false,
  }) {
    final rev = _review;
    unawaited(TelemetryService.instance.trackWeeklyGoalReviewCompleted(
      trajectoryStatus: rev?.trajectoryStatus ?? 'calibrating',
      confidenceLevel: rev?.confidenceLevel ?? 'uncalibrated',
      decision: decision,
      weightObservationCountBucket:
          TelemetryBuckets.getObservationCountBucket(_weightObservationCount),
      loggedIntakeDaysBucket:
          TelemetryBuckets.getObservationCountBucket(_loggedIntakeDaysCount),
      calorieAdjustmentDirection: calorieDirection,
      hasMacroAdjustments: hasMacroAdjustments,
    ));
  }

  Future<void> _applyRecommendation() async {
    if (_isApplying) return;
    setState(() => _isApplying = true);

    try {
      final rec = await _recommendationService.recalculateAndApply();
      final review = _review;
      if (rec != null && review != null) {
        await _goalRepository.updateReviewStatus(
          review.id,
          'applied',
          decision: 'apply_recommendation',
        );
        final base = rec.baselineCalories;
        final dir = base == null || rec.recommendedCalories == base
            ? 'maintain'
            : (rec.recommendedCalories > base ? 'increase' : 'decrease');
        _trackReviewCompleted('applied',
            calorieDirection: dir, hasMacroAdjustments: true);
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rec != null
                ? l10n.adaptiveRecommendationAppliedToGoalsSnack
                : l10n.adaptiveRecommendationNotAvailableSnack,
          ),
        ),
      );
      if (rec != null) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewActionError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _dismissReview() async {
    if (_isApplying) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reviewKeepAndApplyTitle),
        content: Text(l10n.reviewKeepAndApplyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.reviewActionKeepCurrent),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isApplying = true);

    try {
      await _recommendationService.recalculateAndApply();
      final review = _review;
      if (review != null) {
        await _goalRepository.updateReviewStatus(
          review.id,
          'dismissed',
          decision: 'keep_goal_and_update_targets',
        );
        _trackReviewCompleted('dismissed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewDismissedSnack)),
      );
      Navigator.of(context).pop(false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewActionError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _onAdjustmentSaved() async {
    if (_isApplying) return;
    setState(() => _isApplying = true);
    try {
      final rec = await _recommendationService.recalculateAndApply();
      final review = _review;
      if (rec != null && review != null) {
        await _goalRepository.updateReviewStatus(
          review.id,
          'applied',
          decision: 'plan_adjusted',
        );
        _trackReviewCompleted('goal_changed', hasMacroAdjustments: true);
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rec != null
                ? l10n.adaptiveRecommendationAppliedToGoalsSnack
                : l10n.adaptiveRecommendationNotAvailableSnack,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewActionError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
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
    final assessment = review?.assessment;
    final primaryStatus = assessment?.overallStatus ?? review?.trajectoryStatus;
    final statusColor = _statusColor(primaryStatus, theme);
    final statusLabel = _statusLabel(context, primaryStatus);
    final recommendedRate = _recommendedRate(assessment);
    final recommendedDate = _recommendedDate(
      assessment: assessment,
      rateKgPerWeek: recommendedRate,
    );
    final hasAdjustmentEditor =
        _currentWeightKg != null && widget.goal.targetValue != null;

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.weeklyReviewScreenTitle,
      ),
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          // Header card with evaluation verdict and date range
          SummaryCard(
            margin: EdgeInsets.zero,
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
                  assessment == null
                      ? l10n.weeklyReviewPendingDefaultExplanation
                      : l10n.reviewOverallSummary(
                          statusLabel,
                          _momentumLabel(
                            context,
                            assessment.recentMomentumStatus,
                          ),
                        ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          if (assessment?.expectedValue != null ||
              assessment?.currentSmoothedValue != null) ...[
            SummaryCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewPlanVsRealityTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _buildValueRow(
                    context,
                    l10n.reviewExpectedByNowLabel,
                    _formatWeight(assessment?.expectedValue, unitService),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  _buildValueRow(
                    context,
                    l10n.reviewSmoothedCurrentLabel,
                    _formatWeight(
                      assessment?.currentSmoothedValue,
                      unitService,
                    ),
                  ),
                  const Divider(height: DesignConstants.spacingL),
                  _buildValueRow(
                    context,
                    l10n.reviewTrajectoryGapLabel,
                    _formatWeight(assessment?.trajectoryGap, unitService,
                        signed: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],

          if (_currentWeightKg != null && widget.goal.targetValue != null) ...[
            SummaryCard(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingM,
                  vertical: DesignConstants.spacingS,
                ),
                leading: Icon(
                  LucideIcons.sliders_horizontal,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  l10n.adjustGoalTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(l10n.adjustGoalDescription),
                trailing: Icon(
                  _showAdjustmentEditor
                      ? LucideIcons.chevron_up
                      : LucideIcons.chevron_down,
                ),
                onTap: () => setState(
                  () => _showAdjustmentEditor = !_showAdjustmentEditor,
                ),
              ),
            ),
            if (_showAdjustmentEditor) ...[
              const SizedBox(height: DesignConstants.spacingM),
              GoalAdjustmentSheet(
                key: _adjustmentKey,
                goal: widget.goal,
                startWeightKg: _currentWeightKg!,
                repository: _goalRepository,
                embedded: true,
                recommendedTargetDate: recommendedDate,
                recommendedWeeklyRateKg: recommendedRate,
                showSaveButton: false,
                onSaved: _onAdjustmentSaved,
              ),
            ],
            const SizedBox(height: DesignConstants.spacingL),
          ],

          // Trajectory Comparison: Observed Rate vs Target Rate
          if (review?.observedRateKgPerWeek != null ||
              widget.goal.desiredWeeklyRateKg != null) ...[
            SummaryCard(
              margin: EdgeInsets.zero,
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
                        child: ValueSummaryCard(
                          label: l10n.reviewObservedRateLabel,
                          value: _formatRate(
                            review?.observedRateKgPerWeek,
                            unitService,
                            l10n,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingS),
                      Expanded(
                        child: ValueSummaryCard(
                          label: l10n.reviewTargetRateLabel,
                          value: _formatRate(
                            assessment?.plannedRateKgPerWeek ??
                                widget.goal.desiredWeeklyRateKg,
                            unitService,
                            l10n,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (assessment?.requiredRemainingRateKgPerWeek != null) ...[
                    const Divider(height: DesignConstants.spacingL),
                    ValueSummaryCard(
                      label: l10n.reviewRequiredRateLabel,
                      value: _formatRate(
                        assessment?.requiredRemainingRateKgPerWeek,
                        unitService,
                        l10n,
                      ),
                    ),
                  ],
                  if (assessment?.projectedTargetDate != null) ...[
                    const SizedBox(height: DesignConstants.spacingS),
                    ValueSummaryCard(
                      label: l10n.reviewProjectedDateLabel,
                      value:
                          dateFormat.format(assessment!.projectedTargetDate!),
                    ),
                  ],
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
            const SizedBox(height: DesignConstants.spacingL),
          ],

          if (assessment != null) ...[
            Text(
              _nutritionExplanation(context, assessment.nutritionAction),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.35,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],

          // Recommended Targets
          if (review?.recommendedCalories != null) ...[
            SummaryCard(
              margin: EdgeInsets.zero,
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
                        Text(l10n.carbs, style: theme.textTheme.bodyMedium),
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
            const SizedBox(height: DesignConstants.spacingXL),
          ],

          // Data basis is deliberately secondary and stays at the bottom.
          SummaryCard(
            margin: EdgeInsets.zero,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const PageStorageKey('weekly_review_data_quality'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.reviewSufficiencyGateTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${l10n.reviewWeighInsCountLabel}: $_weightObservationCount • ${l10n.reviewLoggedDaysCountLabel}: $_loggedIntakeDaysCount',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: DesignConstants.spacingM,
                    ),
                    child: Row(
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Nutrition actions remain separate from trajectory changes.
          if (!_showAdjustmentEditor &&
              review?.recommendedCalories != null) ...[
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label:
                    _isApplying ? '...' : l10n.reviewActionApplyRecommendation,
                tooltip: l10n.reviewActionApplyRecommendation,
                onPressed: _isApplying ? null : _applyRecommendation,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
          ],
          if (!_showAdjustmentEditor)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isApplying ? null : _dismissReview,
                child: _isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.reviewActionKeepCurrent),
              ),
            ),
          const BottomContentSpacer(),
        ],
      ),
      bottomNavigationBar: hasAdjustmentEditor && _showAdjustmentEditor
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                DesignConstants.spacingM,
                DesignConstants.spacingS,
                DesignConstants.spacingM,
                DesignConstants.spacingM,
              ),
              child: AppButton.primary(
                label: _isApplying
                    ? '...'
                    : (recommendedDate != null && recommendedRate != null
                        ? l10n.adjustGoalAcceptRecommendationAndUpdatePlan
                        : l10n.adjustGoalUpdatePlanButton),
                tooltip: l10n.adjustGoalUpdatePlanButton,
                onPressed: _isApplying
                    ? null
                    : () => recommendedDate != null && recommendedRate != null
                        ? _adjustmentKey.currentState
                            ?.acceptRecommendedAndSave()
                        : _adjustmentKey.currentState?.confirmAndSave(),
              ),
            )
          : null,
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

  Widget _buildValueRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: DesignConstants.spacingM),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatWeight(
    double? value,
    UnitService unitService, {
    bool signed = false,
  }) {
    if (value == null) return '--';
    final converted = unitService.convertDisplayValue(
      value,
      UnitDimension.weight,
    );
    final prefix = signed && converted > 0 ? '+' : '';
    return '$prefix${converted.toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}';
  }

  String _formatRate(
    double? value,
    UnitService unitService,
    AppLocalizations l10n,
  ) {
    if (value == null) return '--';
    final converted = unitService.convertDisplayValue(
      value,
      UnitDimension.weight,
    );
    return '${converted >= 0 ? "+" : ""}${converted.toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}';
  }

  double? _recommendedRate(GoalReviewAssessment? assessment) {
    if (assessment == null ||
        (assessment.overallStatus != 'behind' &&
            assessment.overallStatus != 'target_date_needs_review')) {
      return null;
    }
    final planned =
        assessment.plannedRateKgPerWeek ?? widget.goal.desiredWeeklyRateKg;
    final required = assessment.requiredRemainingRateKgPerWeek;
    if (required != null &&
        required != 0 &&
        GoalTrajectoryCalculator.isRateSafe(required)) {
      return required;
    }
    if (planned == null || planned == 0) return null;
    return planned.clamp(
      GoalTrajectoryCalculator.maxSafeLossRateKgPerWeek,
      GoalTrajectoryCalculator.maxSafeGainRateKgPerWeek,
    );
  }

  DateTime? _recommendedDate({
    required GoalReviewAssessment? assessment,
    required double? rateKgPerWeek,
  }) {
    final current = _currentWeightKg;
    final target = widget.goal.targetValue;
    if (assessment == null ||
        current == null ||
        target == null ||
        rateKgPerWeek == null ||
        rateKgPerWeek == 0 ||
        (target - current).sign != rateKgPerWeek.sign) {
      return null;
    }
    final required = assessment.requiredRemainingRateKgPerWeek;
    if (required != null &&
        (required - rateKgPerWeek).abs() < 0.0001 &&
        widget.goal.targetDate != null) {
      return widget.goal.targetDate;
    }
    final now = DateTime.now();
    return GoalTrajectoryCalculator.calculateTargetDate(
      startWeight: current,
      targetWeight: target,
      startDate: DateTime(now.year, now.month, now.day),
      weeklyRateKg: rateKgPerWeek,
    );
  }
}
