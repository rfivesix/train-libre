import 'dart:convert';

import '../../../../data/database_helper.dart';
import '../../../nutrition_recommendation/data/recommendation_input_adapter.dart';
import '../../../nutrition_recommendation/data/recommendation_repository.dart';
import '../../../nutrition_recommendation/data/recommendation_scheduler.dart';
import '../../../nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
import '../../../nutrition_recommendation/domain/recommendation_models.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';
import 'weekly_goal_review_service.dart';

class WeeklyGoalReviewInput {
  final int weightObservationCount;
  final int loggedIntakeDaysCount;
  final double? observedRateKgPerWeek;
  final double? operatingRateKgPerWeek;
  final double? currentSmoothedWeightKg;
  final double? averageLoggedCalories;
  final double? tdeeEstimate;
  final int? currentCalories;
  final NutritionRecommendation? recommendation;

  const WeeklyGoalReviewInput({
    required this.weightObservationCount,
    required this.loggedIntakeDaysCount,
    required this.observedRateKgPerWeek,
    this.operatingRateKgPerWeek,
    this.currentSmoothedWeightKg,
    this.averageLoggedCalories,
    required this.tdeeEstimate,
    required this.currentCalories,
    required this.recommendation,
  });
}

abstract interface class WeeklyGoalReviewInputSource {
  Future<WeeklyGoalReviewInput> load({
    required DateTime windowEnd,
  });
}

class DatabaseWeeklyGoalReviewInputSource
    implements WeeklyGoalReviewInputSource {
  final RecommendationInputAdapter _inputAdapter;
  final RecommendationRepository _recommendationRepository;

  DatabaseWeeklyGoalReviewInputSource({
    DatabaseHelper? databaseHelper,
    RecommendationInputAdapter? inputAdapter,
    RecommendationRepository? recommendationRepository,
  })  : _inputAdapter = inputAdapter ??
            RecommendationInputAdapter(
              databaseHelper: databaseHelper ?? DatabaseHelper.instance,
            ),
        _recommendationRepository =
            recommendationRepository ?? RecommendationRepository();

  @override
  Future<WeeklyGoalReviewInput> load({required DateTime windowEnd}) async {
    final results = await Future.wait<dynamic>([
      _inputAdapter.buildInput(now: windowEnd, rollingWindowDays: 7),
      _inputAdapter.buildInput(now: windowEnd, rollingWindowDays: 21),
      _recommendationRepository.getLatestRecommendationSnapshot(),
    ]);
    final recentInput = results[0] as RecommendationGenerationInput;
    final operatingInput = results[1] as RecommendationGenerationInput;
    final snapshot = results[2] as AdaptiveRecommendationSnapshot?;
    final recommendation = snapshot?.recommendation;

    return WeeklyGoalReviewInput(
      weightObservationCount: recentInput.weightLogCount,
      loggedIntakeDaysCount: recentInput.intakeLoggedDays,
      observedRateKgPerWeek: recentInput.smoothedWeightSlopeKgPerWeek,
      operatingRateKgPerWeek: operatingInput.smoothedWeightSlopeKgPerWeek,
      currentSmoothedWeightKg: recentInput.smoothedCurrentWeightKg,
      averageLoggedCalories: recentInput.avgLoggedCalories,
      tdeeEstimate: snapshot?.maintenanceEstimate.posteriorMaintenanceCalories,
      currentCalories: recentInput.activeTargetCalories,
      recommendation: recommendation,
    );
  }
}

class WeeklyGoalReviewGenerationResult {
  final Goal? goal;
  final GoalReviewRecord? review;
  final bool wasCreated;

  const WeeklyGoalReviewGenerationResult({
    required this.goal,
    required this.review,
    required this.wasCreated,
  });
}

/// Creates exactly one review for the latest completed scheduler-aligned week.
/// Persistence and the deterministic ID make concurrent foreground and
/// background checks safe and idempotent. A backdated goal never creates
/// historical reviews for periods that were not actually reviewed.
class WeeklyGoalReviewOrchestrator {
  static const String algorithmVersion = 'weekly_goal_review_2_0';

  final IGoalRepository _goalRepository;
  final WeeklyGoalReviewInputSource _inputSource;

  WeeklyGoalReviewOrchestrator({
    required IGoalRepository goalRepository,
    WeeklyGoalReviewInputSource? inputSource,
  })  : _goalRepository = goalRepository,
        _inputSource = inputSource ?? DatabaseWeeklyGoalReviewInputSource();

  Future<WeeklyGoalReviewGenerationResult> generateIfDue({
    DateTime? now,
  }) async {
    final goal = await _goalRepository.getActiveGoal();
    if (goal == null) {
      return const WeeklyGoalReviewGenerationResult(
        goal: null,
        review: null,
        wasCreated: false,
      );
    }

    final createdAt = now ?? DateTime.now();
    final effectiveNow = _day(createdAt);
    final windowEndDay =
        RecommendationScheduler.stableWindowEndDayForDueWeek(
      effectiveNow,
      checkInWeekday: goal.startDate.weekday,
    );
    final windowStart = windowEndDay.subtract(const Duration(days: 6));
    final windowEnd = DateTime(
      windowEndDay.year,
      windowEndDay.month,
      windowEndDay.day,
      23,
      59,
      59,
      999,
    );

    if (_day(goal.startDate).isAfter(windowEndDay)) {
      return WeeklyGoalReviewGenerationResult(
        goal: goal,
        review: null,
        wasCreated: false,
      );
    }

    final events = await _goalRepository.getGoalEvents(goal.id);
    final lastResume = events
        .where((event) => event.eventType == 'resumed')
        .map((event) => event.occurredAt ?? event.createdAt)
        .fold<DateTime?>(
            null,
            (latest, value) =>
                latest == null || value.isAfter(latest) ? value : latest);
    if (lastResume != null && _day(lastResume).isAfter(windowStart)) {
      return WeeklyGoalReviewGenerationResult(
        goal: goal,
        review: null,
        wasCreated: false,
      );
    }

    final existing = await _goalRepository.getReviewForWindow(
      goal.id,
      windowStart,
      windowEnd,
    );
    if (existing?.algorithmVersion == algorithmVersion &&
        existing?.assessment != null) {
      return WeeklyGoalReviewGenerationResult(
        goal: goal,
        review: existing,
        wasCreated: false,
      );
    }

    final results = await Future.wait<dynamic>([
      _inputSource.load(windowEnd: windowEnd),
      _goalRepository.getGoalProgress(goal),
    ]);
    final input = results[0] as WeeklyGoalReviewInput;
    final progress = results[1];
    final recommendation = input.recommendation;
    final recentEvaluation = WeeklyGoalReviewService.evaluate(
      goal: goal,
      weightObservationCount: input.weightObservationCount,
      loggedIntakeDaysCount: input.loggedIntakeDaysCount,
      observedRateKgPerWeek: input.observedRateKgPerWeek,
      expectedRateKgPerWeek: goal.desiredWeeklyRateKg,
      tdeeEstimate: input.tdeeEstimate,
      currentCalories: input.currentCalories,
      engineRecommendedCalories: recommendation?.recommendedCalories,
      engineRecommendedProtein: recommendation?.recommendedProteinGrams,
      engineRecommendedCarbs: recommendation?.recommendedCarbsGrams,
      engineRecommendedFat: recommendation?.recommendedFatGrams,
    );

    GoalReviewAssessment assessment;
    if (progress?.baselineValue == null || progress?.baselineDate == null) {
      assessment = GoalReviewAssessment(
        overallStatus: 'calibrating',
        recentMomentumStatus: 'unclear',
        currentSmoothedValue: input.currentSmoothedWeightKg,
        recentRateKgPerWeek: input.observedRateKgPerWeek,
        weightObservationCount: input.weightObservationCount,
        nutritionLoggedDays: input.loggedIntakeDaysCount,
        averageLoggedCalories: input.averageLoggedCalories,
        dataQuality: 'insufficient',
        nutritionAction: 'insufficient_data',
      );
    } else {
      final revisionAnchor = _latestRevisionAnchor(events);
      assessment = WeeklyGoalTrajectoryAssessmentService.evaluate(
        goal: goal,
        baselineDate: revisionAnchor?.date ?? _day(goal.startDate),
        baselineValue: revisionAnchor?.value ?? progress.baselineValue!,
        reviewDate: windowEndDay,
        currentSmoothedValue: input.currentSmoothedWeightKg,
        recentRateKgPerWeek: input.observedRateKgPerWeek,
        operatingRateKgPerWeek: input.operatingRateKgPerWeek,
        weightObservationCount: input.weightObservationCount,
        nutritionLoggedDays: input.loggedIntakeDaysCount,
        averageLoggedCalories: input.averageLoggedCalories,
        currentCalories: input.currentCalories,
      );
    }

    final canAdjustNutrition = assessment.nutritionAction == 'adjust_targets';
    final previousPending = await _goalRepository.getPendingReview(goal.id);
    if (previousPending != null && previousPending.id != existing?.id) {
      await _goalRepository.updateReviewStatus(
        previousPending.id,
        'deferred',
        decision: 'superseded_by_new_review',
      );
    }
    final review = GoalReviewRecord(
      id: 'weekly-${goal.id}-${windowStart.millisecondsSinceEpoch}',
      goalId: goal.id,
      windowStart: windowStart,
      windowEnd: windowEnd,
      status: 'pending',
      trajectoryStatus: _legacyTrajectoryStatus(assessment.overallStatus),
      observedRateKgPerWeek: input.observedRateKgPerWeek,
      confidenceLevel: recentEvaluation.confidenceLevel,
      tdeeEstimate: input.tdeeEstimate,
      recommendedCalories:
          canAdjustNutrition ? recentEvaluation.recommendedCalories : null,
      recommendedProtein:
          canAdjustNutrition ? recentEvaluation.recommendedProtein : null,
      recommendedCarbs:
          canAdjustNutrition ? recentEvaluation.recommendedCarbs : null,
      recommendedFat:
          canAdjustNutrition ? recentEvaluation.recommendedFat : null,
      algorithmVersion: algorithmVersion,
      assessment: assessment,
      createdAt: createdAt,
    );
    await _goalRepository.saveReview(review);
    final persisted = await _goalRepository.getReviewForWindow(
          goal.id,
          windowStart,
          windowEnd,
        ) ??
        review;
    return WeeklyGoalReviewGenerationResult(
      goal: goal,
      review: persisted,
      wasCreated: true,
    );
  }

  static String _legacyTrajectoryStatus(String overallStatus) {
    return switch (overallStatus) {
      'behind' || 'target_date_needs_review' => 'slower',
      'ahead' => 'faster',
      'on_trajectory' || 'target_reached' => 'on_track',
      _ => 'calibrating',
    };
  }

  static _TrajectoryAnchor? _latestRevisionAnchor(List<GoalEvent> events) {
    for (final event in events) {
      if (event.eventType != 'plan_revised' || event.reason == null) continue;
      try {
        final payload = jsonDecode(event.reason!);
        if (payload is! Map<String, dynamic>) continue;
        final value = (payload['anchorValue'] as num?)?.toDouble();
        final date = DateTime.tryParse(payload['effectiveAt'] as String? ?? '');
        if (value != null && date != null) {
          return _TrajectoryAnchor(date: _day(date), value: value);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _TrajectoryAnchor {
  final DateTime date;
  final double value;

  const _TrajectoryAnchor({required this.date, required this.value});
}
