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
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/macro_badge_row.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/value_summary_card.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../domain/models/goal_model.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/services/goal_notification_orchestrator.dart';
import '../domain/services/goal_trajectory_calculator.dart';
import '../data/goal_repository_impl.dart';
import 'widgets/goal_adjustment_sheet.dart';

class WeeklyGoalReviewScreen extends StatefulWidget {
  final Goal goal;
  final GoalReviewRecord? review;
  final IGoalRepository? repository;
  final AdaptiveNutritionRecommendationService? recommendationService;
  final bool previewOnly;

  const WeeklyGoalReviewScreen({
    super.key,
    required this.goal,
    this.review,
    this.repository,
    this.recommendationService,
    this.previewOnly = false,
  });

  @override
  State<WeeklyGoalReviewScreen> createState() => _WeeklyGoalReviewScreenState();
}

class _WeeklyGoalReviewScreenState extends State<WeeklyGoalReviewScreen> {
  IGoalRepository? _goalRepository;
  AdaptiveNutritionRecommendationService? _recommendationService;
  GoalReviewRecord? _review;
  int _weightObservationCount = 0;
  int _loggedIntakeDaysCount = 0;
  bool _isLoading = true;
  bool _isApplying = false;
  bool _showReviewDetails = false;
  double? _currentWeightKg;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.weeklyGoalReview));
    if (!widget.previewOnly) {
      _goalRepository = widget.repository ?? GoalRepositoryImpl();
      _recommendationService = widget.recommendationService ??
          AdaptiveNutritionRecommendationService();
    }
    _review = widget.review;
    _initReview();
  }

  @override
  void didUpdateWidget(WeeklyGoalReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewOnly &&
        (oldWidget.goal != widget.goal || oldWidget.review != widget.review)) {
      _review = widget.review;
      _syncPreviewState();
    }
  }

  Future<void> _initReview() async {
    if (widget.previewOnly) {
      _syncPreviewState();
      return;
    }

    final progress = await _goalRepository!.getGoalProgress(widget.goal);
    _currentWeightKg = progress?.currentValue ??
        progress?.baselineValue ??
        widget.review?.assessment?.currentSmoothedValue ??
        widget.goal.baselineValueKg;
    if (_review == null) {
      final pending = await _goalRepository!.getPendingReview(widget.goal.id);
      _review = pending;
    }
    _currentWeightKg ??= _review?.assessment?.currentSmoothedValue;

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

  void _syncPreviewState() {
    final assessment = _review?.assessment;
    _currentWeightKg = assessment?.currentSmoothedValue;
    _weightObservationCount = assessment?.weightObservationCount ?? 0;
    _loggedIntakeDaysCount = assessment?.nutritionLoggedDays ?? 0;
    _isLoading = false;
  }

  void _showPreviewFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context)!.weeklyReviewPreviewNoChanges),
      ),
    );
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
    if (widget.previewOnly) {
      _showPreviewFeedback();
      return;
    }
    if (_isApplying) return;

    final review = _review;
    final assessment = review?.assessment;
    final currentWeight = _currentWeightKg;
    final targetWeight = widget.goal.targetValue;
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    double? targetRate;
    DateTime? targetDate;
    bool shouldReviseGoal = false;
    bool targetDateNeedsExtension = false;

    if (review != null &&
        _goalRepository != null &&
        currentWeight != null &&
        targetWeight != null &&
        widget.goal.preset != GoalPreset.maintainWeight &&
        widget.goal.preset != GoalPreset.recomposition &&
        (assessment?.overallStatus == 'behind' ||
            assessment?.overallStatus == 'target_date_needs_review')) {
      final recRate = _recommendedRate(assessment);
      final recDate = _recommendedDate(
        assessment: assessment,
        rateKgPerWeek: recRate,
      );

      if (recRate != null && recDate != null) {
        final currentRate = widget.goal.desiredWeeklyRateKg;
        final currentDate = widget.goal.targetDate;

        final rateChanged = currentRate == null ||
            (currentRate - recRate).abs() >= 0.001;
        final dateChanged = currentDate == null ||
            !DateUtils.isSameDay(currentDate, recDate);

        if (rateChanged || dateChanged) {
          shouldReviseGoal = true;
          targetRate = recRate;
          targetDate = recDate;
          targetDateNeedsExtension = dateChanged;
        }
      }
    }

    if (targetDateNeedsExtension && targetDate != null && targetRate != null) {
      final formattedRate = _formatRate(targetRate, unitService, l10n);
      final formattedDate = dateFormat.format(targetDate);
      final confirmed = await showGlassConfirmation(
        context: context,
        title: l10n.weeklyReviewDateExtensionTitle,
        content: l10n.weeklyReviewDateExtensionContent(
          formattedRate,
          formattedDate,
        ),
        confirmLabel: l10n.weeklyReviewApplyTargetsAction,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _isApplying = true);

    try {
      if (shouldReviseGoal && targetRate != null && targetDate != null) {
        await _goalRepository!.reviseGoal(
          currentGoal: widget.goal,
          trackingMode: widget.goal.trackingMode,
          targetValue: widget.goal.targetValue,
          targetDate: targetDate,
          desiredWeeklyRateKg: targetRate,
          anchorValue: currentWeight,
          reason: 'Weekly review: auto-adjusted pace and target date',
        );
        final notifications =
            GoalNotificationOrchestrator(goalRepository: _goalRepository!);
        await notifications.synchronize();
      }

      final rec = await _recommendationService!.recalculateAndApply();
      if (rec != null && review != null) {
        await _goalRepository!.updateReviewStatus(
          review.id,
          'applied',
          decision: shouldReviseGoal ? 'plan_adjusted' : 'apply_recommendation',
        );
        final base = rec.baselineCalories;
        final dir = base == null || rec.recommendedCalories == base
            ? 'maintain'
            : (rec.recommendedCalories > base ? 'increase' : 'decrease');
        _trackReviewCompleted(
          shouldReviseGoal ? 'goal_changed' : 'applied',
          calorieDirection: dir,
          hasMacroAdjustments: true,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldReviseGoal
                ? l10n.weeklyReviewPlanUpdatedSnack
                : (rec != null
                    ? l10n.adaptiveRecommendationAppliedToGoalsSnack
                    : l10n.adaptiveRecommendationNotAvailableSnack),
          ),
        ),
      );
      if (rec != null || shouldReviseGoal) Navigator.of(context).pop(true);
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

  Future<void> _dismissReview() async {
    if (widget.previewOnly) {
      _showPreviewFeedback();
      return;
    }
    if (_isApplying) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassConfirmation(
      context: context,
      title: l10n.reviewKeepAndApplyTitle,
      content: l10n.reviewKeepAndApplyBody,
      confirmLabel: l10n.reviewActionKeepCurrent,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isApplying = true);

    try {
      await _recommendationService!.recalculateAndApply();
      final review = _review;
      if (review != null) {
        await _goalRepository!.updateReviewStatus(
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
    if (widget.previewOnly) {
      _showPreviewFeedback();
      return;
    }
    if (_isApplying) return;
    setState(() => _isApplying = true);
    try {
      final rec = await _recommendationService!.recalculateAndApply();
      final review = _review;
      if (rec != null && review != null) {
        await _goalRepository!.updateReviewStatus(
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

  Future<void> _deferReviewForMoreData() async {
    if (widget.previewOnly) {
      _showPreviewFeedback();
      return;
    }
    if (_isApplying) return;

    final review = _review;
    if (review == null) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isApplying = true);
    try {
      await _goalRepository!.updateReviewStatus(
        review.id,
        'deferred',
        decision: 'insufficient_data_continue_logging',
      );
      if (mounted) Navigator.of(context).pop(false);
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

  Future<void> _openGoalAdjustment(GoalTrackingMode mode) async {
    if (widget.previewOnly) {
      _showPreviewFeedback();
      return;
    }
    if (_isApplying || _currentWeightKg == null || _goalRepository == null) {
      return;
    }

    final saved = await GoalAdjustmentSheet.show(
      context,
      goal: widget.goal,
      startWeightKg: _currentWeightKg!,
      repository: _goalRepository!,
      initialTrackingMode: mode,
      recommendedTargetDate: _recommendedDate(
        assessment: _review?.assessment,
        rateKgPerWeek: _recommendedRate(_review?.assessment),
      ),
      recommendedWeeklyRateKg: _recommendedRate(_review?.assessment),
    );
    if (saved == true && mounted) await _onAdjustmentSaved();
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
    final needsMoreData = assessment?.nutritionAction == 'insufficient_data';
    final primaryStatus = needsMoreData
        ? 'calibrating'
        : assessment?.overallStatus ?? review?.trajectoryStatus;
    final statusColor = _statusColor(primaryStatus, theme);
    final statusLabel = _statusLabel(context, primaryStatus);
    final canAdjustGoal = _currentWeightKg != null &&
        widget.goal.targetValue != null &&
        (widget.previewOnly || _goalRepository != null);
    final canAdjustRate = canAdjustGoal &&
        widget.goal.preset != GoalPreset.maintainWeight &&
        widget.goal.preset != GoalPreset.recomposition;
    final canAdjustDate =
        canAdjustGoal && widget.goal.preset != GoalPreset.recomposition;
    final needsTrajectoryChange =
        assessment?.nutritionAction == 'trajectory_change_needed';
    final dateRange = review == null
        ? null
        : '${dateFormat.format(review.windowStart)} – ${dateFormat.format(review.windowEnd)}';
    return Scaffold(
      appBar: GlobalAppBar(title: l10n.weeklyReviewScreenTitle),
      bottomNavigationBar: _buildReviewActionsBar(
        context: context,
        review: review,
        needsMoreData: needsMoreData,
        needsTrajectoryChange: needsTrajectoryChange,
      ),
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          if (review != null)
            _buildReviewOverview(
              context: context,
              review: review,
              assessment: assessment,
              statusColor: statusColor,
              statusLabel: statusLabel,
              dateRange: dateRange,
            ),
          if (canAdjustRate || canAdjustDate) ...[
            const SizedBox(height: DesignConstants.spacingM),
            _buildGoalAdjustmentOptions(
              context: context,
              canAdjustRate: canAdjustRate,
              canAdjustDate: canAdjustDate,
            ),
          ],
          const SizedBox(height: DesignConstants.spacingM),
          _buildDetailsSection(
            context: context,
            review: review,
            assessment: assessment,
            unitService: unitService,
            dateFormat: dateFormat,
          ),
          if (!widget.previewOnly) const BottomContentSpacer(),
        ],
      ),
    );
  }

  Widget _buildReviewOverview({
    required BuildContext context,
    required GoalReviewRecord review,
    required GoalReviewAssessment? assessment,
    required Color statusColor,
    required String statusLabel,
    required String? dateRange,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final currentCalories = assessment?.currentCalories;
    final recommendedCalories =
        assessment?.nutritionAction == 'insufficient_data'
            ? null
            : (review.recommendedCalories ?? currentCalories);
    final currentTrend = assessment?.currentSmoothedValue ?? _currentWeightKg;
    final expectedTrend = assessment?.expectedValue;
    final unitService = context.read<UnitService>();
    final explanation = assessment == null
        ? (review.explanation ?? l10n.weeklyReviewPendingDefaultExplanation)
        : _nutritionExplanation(context, assessment.nutritionAction);
    final theme = Theme.of(context);
    final isCalorieChanged = currentCalories != null &&
        recommendedCalories != null &&
        recommendedCalories != currentCalories;
    final signedDelta = isCalorieChanged
        ? recommendedCalories - currentCalories
        : null;

    final isNonMaintenance = widget.goal.preset != GoalPreset.maintainWeight &&
        widget.goal.preset != GoalPreset.recomposition;
    final currentRate = widget.goal.desiredWeeklyRateKg;
    final currentDate = widget.goal.targetDate;

    double? candidateRate;
    DateTime? candidateDate;
    if (isNonMaintenance &&
        (assessment?.overallStatus == 'behind' ||
            assessment?.overallStatus == 'target_date_needs_review')) {
      candidateRate = _recommendedRate(assessment);
      candidateDate = _recommendedDate(
        assessment: assessment,
        rateKgPerWeek: candidateRate,
      );
    }

    final isRateChanged = currentRate != null &&
        candidateRate != null &&
        (currentRate - candidateRate).abs() >= 0.001;
    final effectiveRecRate = isRateChanged ? candidateRate : currentRate;
    final currentRateText =
        currentRate != null ? _formatRate(currentRate, unitService, l10n) : '—';
    final recommendedRateText = effectiveRecRate != null
        ? _formatRate(effectiveRecRate, unitService, l10n)
        : '—';
    final rateDeltaSubtitle = isRateChanged
        ? _formatRate(candidateRate - currentRate, unitService, l10n)
        : null;

    final dateFormat = DateFormat.yMMMd(locale);
    final isDateChanged = currentDate != null &&
        candidateDate != null &&
        !DateUtils.isSameDay(currentDate, candidateDate);
    final effectiveRecDate = isDateChanged ? candidateDate : currentDate;
    final currentDateText =
        currentDate != null ? dateFormat.format(currentDate) : '—';
    final recommendedDateText = effectiveRecDate != null
        ? dateFormat.format(effectiveRecDate)
        : '—';
    final dateDeltaSubtitle = isDateChanged
        ? l10n.weeklyReviewDateDaysChange(
            '${candidateDate.difference(currentDate).inDays > 0 ? '+' : ''}${candidateDate.difference(currentDate).inDays}',
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.weeklyReviewWeightProgressTitle,
          isFirst: true,
          action: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingS,
              vertical: DesignConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusS),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ValueSummaryCard(
                label: l10n.weeklyReviewWeightPlannedLabel,
                value: _formatWeight(expectedTrend, unitService),
              ),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: ValueSummaryCard(
                label: l10n.weeklyReviewWeightTrendLabel,
                value: _formatWeight(currentTrend, unitService),
              ),
            ),
          ],
        ),
        if (dateRange != null) ...[
          const SizedBox(height: DesignConstants.spacingXS),
          Text(
            dateRange,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
        const SizedBox(height: DesignConstants.spacingL),
        AppSectionHeader(title: l10n.weeklyReviewCaloriesTitle),
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
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: ValueSummaryCard(
                  label: l10n.weeklyReviewCaloriesRecommended,
                  value: recommendedCalories == null
                      ? '—'
                      : '${numberFormat.format(recommendedCalories)} kcal',
                  subtitle: isCalorieChanged
                      ? l10n.weeklyReviewCaloriesChange(
                          '${signedDelta! > 0 ? '+' : ''}${numberFormat.format(signedDelta)}',
                        )
                      : (recommendedCalories != null
                          ? l10n.weeklyReviewRateNoChange
                          : null),
                  valueColor:
                      isCalorieChanged ? theme.colorScheme.primary : null,
                  borderColor:
                      isCalorieChanged ? theme.colorScheme.primary : null,
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          explanation,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            height: 1.35,
          ),
        ),
        if (isNonMaintenance) ...[
          const SizedBox(height: DesignConstants.spacingL),
          AppSectionHeader(title: l10n.weeklyReviewRateTitle),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ValueSummaryCard(
                    label: l10n.weeklyReviewCaloriesCurrent,
                    value: currentRateText,
                    mainAxisAlignment: MainAxisAlignment.start,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: ValueSummaryCard(
                    label: l10n.weeklyReviewCaloriesRecommended,
                    value: recommendedRateText,
                    subtitle: isRateChanged
                        ? rateDeltaSubtitle
                        : l10n.weeklyReviewRateNoChange,
                    valueColor:
                        isRateChanged ? theme.colorScheme.primary : null,
                    borderColor:
                        isRateChanged ? theme.colorScheme.primary : null,
                    mainAxisAlignment: MainAxisAlignment.start,
                  ),
                ),
              ],
            ),
          ),
          if (currentDate != null) ...[
            const SizedBox(height: DesignConstants.spacingL),
            AppSectionHeader(title: l10n.weeklyReviewDateTitle),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.weeklyReviewCaloriesCurrent,
                      value: currentDateText,
                      mainAxisAlignment: MainAxisAlignment.start,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.weeklyReviewCaloriesRecommended,
                      value: recommendedDateText,
                      subtitle: isDateChanged
                          ? dateDeltaSubtitle
                          : l10n.weeklyReviewDateOnTrack,
                      valueColor:
                          isDateChanged ? theme.colorScheme.primary : null,
                      borderColor:
                          isDateChanged ? theme.colorScheme.primary : null,
                      mainAxisAlignment: MainAxisAlignment.start,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget? _buildReviewActionsBar({
    required BuildContext context,
    required GoalReviewRecord? review,
    required bool needsMoreData,
    required bool needsTrajectoryChange,
  }) {
    if (review?.status != 'pending') return null;
    final l10n = AppLocalizations.of(context)!;

    if (needsMoreData) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignConstants.spacingM,
            DesignConstants.spacingS,
            DesignConstants.spacingM,
            DesignConstants.spacingM,
          ),
          child: SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              label: l10n.weeklyReviewContinueLogging,
              onPressed: _isApplying ? null : _deferReviewForMoreData,
            ),
          ),
        ),
      );
    }

    if (needsTrajectoryChange) return null;
    final canApply = review?.recommendedCalories != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignConstants.spacingM,
          DesignConstants.spacingS,
          DesignConstants.spacingM,
          DesignConstants.spacingM,
        ),
        child: Row(
          children: [
            if (canApply) ...[
              Expanded(
                child: AppButton.primary(
                  label: l10n.weeklyReviewApplyTargetsAction,
                  tooltip: l10n.reviewActionApplyRecommendation,
                  semanticsLabel: l10n.reviewActionApplyRecommendation,
                  onPressed: _isApplying ? null : _applyRecommendation,
                  isLoading: _isApplying,
                  size: AppButtonSize.medium,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
            ],
            Expanded(
              child: AppButton.secondary(
                label: l10n.weeklyReviewKeepGoalAction,
                tooltip: l10n.reviewActionKeepCurrent,
                semanticsLabel: l10n.reviewActionKeepCurrent,
                onPressed: _isApplying ? null : _dismissReview,
                size: AppButtonSize.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalAdjustmentOptions({
    required BuildContext context,
    required bool canAdjustRate,
    required bool canAdjustDate,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.weeklyReviewAdjustPlanTitle),
        SummaryCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (canAdjustRate)
                ListTile(
                  leading: Icon(
                    LucideIcons.activity,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.weeklyReviewAdjustRate),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: _isApplying
                      ? null
                      : () => _openGoalAdjustment(GoalTrackingMode.weeklyRate),
                ),
              if (canAdjustRate && canAdjustDate)
                const Divider(height: 1, indent: 56),
              if (canAdjustDate)
                ListTile(
                  leading: Icon(
                    LucideIcons.calendar_days,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.weeklyReviewAdjustDate),
                  trailing: const Icon(LucideIcons.chevron_right),
                  onTap: _isApplying
                      ? null
                      : () =>
                          _openGoalAdjustment(GoalTrackingMode.targetWeight),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection({
    required BuildContext context,
    required GoalReviewRecord? review,
    required GoalReviewAssessment? assessment,
    required UnitService unitService,
    required DateFormat dateFormat,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showReviewDetails = !_showReviewDetails),
          child: AppSectionHeader(
            title: l10n.weeklyReviewDetailsTitle,
            action: Icon(
              _showReviewDetails
                  ? LucideIcons.chevron_up
                  : LucideIcons.chevron_down,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_showReviewDetails) ...[
          const SizedBox(height: DesignConstants.spacingS),
          if (review?.recommendedProtein != null ||
              review?.recommendedCarbs != null ||
              review?.recommendedFat != null) ...[
            _buildDetailHeading(context, l10n.reviewRecommendationTitle),
            MacroBadgeRow(
              useBadges: true,
              protein: review?.recommendedProtein?.toDouble(),
              carbs: review?.recommendedCarbs?.toDouble(),
              fat: review?.recommendedFat?.toDouble(),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],
          if (assessment?.expectedValue != null ||
              assessment?.currentSmoothedValue != null) ...[
            _buildDetailHeading(context, l10n.reviewPlanVsRealityTitle),
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
                  assessment?.currentSmoothedValue, unitService),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            _buildValueRow(
              context,
              l10n.reviewTrajectoryGapLabel,
              _formatWeight(
                assessment?.trajectoryGap,
                unitService,
                signed: true,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],
          if (review?.observedRateKgPerWeek != null ||
              widget.goal.desiredWeeklyRateKg != null) ...[
            _buildDetailHeading(
                context, l10n.reviewTrajectoryComparisonTitle),
            _buildValueRow(
              context,
              l10n.reviewObservedRateLabel,
              _formatRate(
                  review?.observedRateKgPerWeek, unitService, l10n),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            _buildValueRow(
              context,
              l10n.reviewTargetRateLabel,
              _formatRate(
                assessment?.plannedRateKgPerWeek ??
                    widget.goal.desiredWeeklyRateKg,
                unitService,
                l10n,
              ),
            ),
            if (assessment?.requiredRemainingRateKgPerWeek != null) ...[
              const SizedBox(height: DesignConstants.spacingS),
              _buildValueRow(
                context,
                l10n.reviewRequiredRateLabel,
                _formatRate(
                  assessment?.requiredRemainingRateKgPerWeek,
                  unitService,
                  l10n,
                ),
              ),
            ],
            if (assessment?.projectedTargetDate != null) ...[
              const SizedBox(height: DesignConstants.spacingS),
              _buildValueRow(
                context,
                l10n.reviewProjectedDateLabel,
                dateFormat.format(assessment!.projectedTargetDate!),
              ),
            ],
            if (review?.tdeeEstimate != null) ...[
              const SizedBox(height: DesignConstants.spacingS),
              _buildValueRow(
                context,
                l10n.reviewEstimatedTDEELabel,
                '${review!.tdeeEstimate!.round()} kcal',
              ),
            ],
            const SizedBox(height: DesignConstants.spacingL),
          ],
          _buildDetailHeading(context, l10n.reviewSufficiencyGateTitle),
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
      ],
    );
  }

  Widget _buildDetailHeading(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingM,
        vertical: DesignConstants.spacingS,
      ),
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
            size: 16,
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
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    return '$prefix${number.format(converted)} ${unitService.unitString(UnitDimension.weight)}';
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
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return '${converted >= 0 ? "+" : ""}${number.format(converted)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}';
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
