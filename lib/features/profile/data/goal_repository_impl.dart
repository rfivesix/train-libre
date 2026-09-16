// lib/features/profile/data/goal_repository_impl.dart

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/models/goal_model.dart';
import '../domain/models/goal_progress.dart';
import '../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements IGoalRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  GoalRepositoryImpl({db.AppDatabase? database})
      : _db = database ?? DatabaseHelper.instance.dbInstance;

  Goal _mapRowToGoal(db.UserGoal row) {
    return Goal(
      id: row.id,
      userId: row.userId,
      area: row.area,
      preset: GoalPreset.fromString(row.preset),
      title: row.title,
      reason: row.reason,
      status: GoalStatus.fromString(row.status),
      startDate: row.startDate,
      trackingMode: GoalTrackingMode.fromString(row.trackingMode),
      baselineMeasurementId: row.baselineMeasurementId,
      baselineValueKg: row.baselineValueKg,
      baselineDate: row.baselineDate,
      targetDate: row.targetDate,
      targetMetric: row.targetMetric,
      targetValue: row.targetValue,
      targetUnit: row.targetUnit,
      desiredWeeklyRateKg: row.desiredWeeklyRateKg,
      isNutritionDriver: row.isNutritionDriver,
      predecessorGoalId: row.predecessorGoalId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      retiredAt: row.retiredAt,
    );
  }

  GoalEvent _mapRowToEvent(db.GoalEvent row) {
    return GoalEvent(
      id: row.id,
      goalId: row.goalId,
      eventType: row.eventType,
      actor: row.actor,
      recommendationId: row.recommendationId,
      reason: row.reason,
      algorithmVersion: row.algorithmVersion,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
    );
  }

  GoalReviewRecord _mapRowToReview(db.GoalReview row) {
    return GoalReviewRecord(
      id: row.id,
      goalId: row.goalId,
      windowStart: row.windowStart,
      windowEnd: row.windowEnd,
      status: row.status,
      trajectoryStatus: row.trajectoryStatus,
      observedRateKgPerWeek: row.observedRateKgPerWeek,
      confidenceLevel: row.confidenceLevel,
      tdeeEstimate: row.tdeeEstimate,
      recommendedCalories: row.recommendedCalories,
      recommendedProtein: row.recommendedProtein,
      recommendedCarbs: row.recommendedCarbs,
      recommendedFat: row.recommendedFat,
      decision: row.decision,
      algorithmVersion: row.algorithmVersion,
      explanation: row.explanation,
      assessment: GoalReviewAssessment.tryParse(row.assessmentJson),
      createdAt: row.createdAt,
    );
  }

  @override
  Future<({String id, double valueKg, DateTime date})?>
      findLatestWeightAtOrBefore(DateTime date) async {
    final query = _db.select(_db.measurements)
      ..where((row) =>
          row.type.equals('weight') & row.date.isSmallerOrEqualValue(date))
      ..orderBy([(row) => drift.OrderingTerm.desc(row.date)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (id: row.id, valueKg: row.value, date: row.date);
  }

  @override
  Future<Goal> captureMissingBaseline(String goalId) async {
    return _db.transaction(() async {
      final current = await getGoalById(goalId);
      if (current == null) throw StateError('Goal not found');
      if (current.baselineValueKg != null && current.baselineDate != null) {
        return current;
      }

      final query = _db.select(_db.measurements)
        ..where((row) => row.type.equals('weight'))
        ..orderBy([(row) => drift.OrderingTerm.desc(row.date)])
        ..limit(1);
      final measurement = await query.getSingleOrNull();
      if (measurement == null || measurement.value <= 0) return current;

      final now = DateTime.now();
      await (_db.update(_db.userGoals)..where((row) => row.id.equals(goalId)))
          .write(db.UserGoalsCompanion(
        baselineMeasurementId: drift.Value(measurement.id),
        baselineValueKg: drift.Value(measurement.value),
        baselineDate: drift.Value(measurement.date),
        updatedAt: drift.Value(now),
      ));
      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: goalId,
            eventType: 'baseline_recorded',
            actor: const drift.Value('user'),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));
      return (await getGoalById(goalId))!;
    });
  }

  @override
  Future<Goal?> getActiveGoal() async {
    return getActiveNutritionGoal();
  }

  @override
  Future<Goal?> getActiveNutritionGoal() async {
    final query = _db.select(_db.userGoals)
      ..where(
          (t) => t.status.equals('active') & t.area.equals('body_composition'))
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRowToGoal(row);
  }

  @override
  Future<List<Goal>> getRetiredGoals() async {
    final query = _db.select(_db.userGoals)
      ..where(
          (t) => t.status.isNotValue('active') & t.status.isNotValue('draft'))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapRowToGoal).toList();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final query = _db.select(_db.userGoals)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRowToGoal(row);
  }

  @override
  Future<GoalProgress?> getGoalProgress(Goal goal) async {
    final metric = goal.targetMetric ?? 'weight';

    // 2. Latest observation overall
    final latestQuery = _db.select(_db.measurements)
      ..where((t) => t.type.equals(metric))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.date)])
      ..limit(1);
    final latestRow = await latestQuery.getSingleOrNull();

    return GoalProgress.calculate(
      goal: goal,
      baselineValue: goal.baselineValueKg,
      baselineDate: goal.baselineDate,
      currentValue: latestRow?.value,
      currentDate: latestRow?.date,
      trendRateKgPerWeek: goal.desiredWeeklyRateKg,
    );
  }

  @override
  Future<Goal> createGoal({
    required GoalPreset preset,
    required String title,
    String? reason,
    required DateTime startDate,
    GoalTrackingMode trackingMode = GoalTrackingMode.weeklyRate,
    String? baselineMeasurementId,
    double? baselineValueKg,
    DateTime? baselineDate,
    DateTime? targetDate,
    String? targetMetric,
    double? targetValue,
    String? targetUnit,
    double? desiredWeeklyRateKg,
    bool isNutritionDriver = true,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      if (baselineValueKg == null ||
          !baselineValueKg.isFinite ||
          baselineValueKg <= 0) {
        throw ArgumentError('A real baseline weight is required');
      }
      final effectiveBaselineDate = baselineDate ?? startDate;
      var effectiveMeasurementId = baselineMeasurementId;
      if (effectiveMeasurementId == null) {
        effectiveMeasurementId = _uuid.v4();
        await _db.into(_db.measurements).insert(
              db.MeasurementsCompanion.insert(
                id: drift.Value(effectiveMeasurementId),
                type: 'weight',
                value: baselineValueKg,
                unit: 'kg',
                date: effectiveBaselineDate,
                legacySessionId: drift.Value(
                  effectiveBaselineDate.millisecondsSinceEpoch,
                ),
              ),
            );
      }

      // Exactly one active goal per area; future workout goals are independent.
      final existingActive = await (_db.select(_db.userGoals)
            ..where((t) =>
                t.status.equals('active') & t.area.equals('body_composition')))
          .get();

      for (final existing in existingActive) {
        await (_db.update(_db.userGoals)
              ..where((t) => t.id.equals(existing.id)))
            .write(db.UserGoalsCompanion(
          status: const drift.Value('superseded'),
          retiredAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ));
        await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
              id: drift.Value(_uuid.v4()),
              goalId: existing.id,
              eventType: 'superseded',
              actor: const drift.Value('user'),
              reason: const drift.Value('Replaced by newly created goal'),
              occurredAt: drift.Value(now),
              createdAt: drift.Value(now),
            ));
        await _closePendingReviewsInTransaction(existing.id, now);
      }

      final newGoalId = _uuid.v4();
      await _db.into(_db.userGoals).insert(db.UserGoalsCompanion.insert(
            id: drift.Value(newGoalId),
            preset: preset.key,
            title: title,
            reason: drift.Value(reason),
            status: const drift.Value('active'),
            startDate: startDate,
            trackingMode: drift.Value(trackingMode.name),
            baselineMeasurementId: drift.Value(effectiveMeasurementId),
            baselineValueKg: drift.Value(baselineValueKg),
            baselineDate: drift.Value(effectiveBaselineDate),
            targetDate: drift.Value(targetDate),
            targetMetric: drift.Value(targetMetric),
            targetValue: drift.Value(targetValue),
            targetUnit: drift.Value(targetUnit),
            desiredWeeklyRateKg: drift.Value(desiredWeeklyRateKg),
            isNutritionDriver: drift.Value(isNutritionDriver),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ));

      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: newGoalId,
            eventType: 'created',
            actor: const drift.Value('user'),
            reason: drift.Value(reason),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));
      final created = await getGoalById(newGoalId);
      return created!;
    });
  }

  @override
  Future<Goal> supersedeGoal({
    required Goal currentGoal,
    required double? targetValue,
    required DateTime? targetDate,
    required double? desiredWeeklyRateKg,
    String? reason,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      final successorStartDate = DateTime(now.year, now.month, now.day);

      // 1. Mark old goal as superseded
      await (_db.update(_db.userGoals)
            ..where((t) => t.id.equals(currentGoal.id)))
          .write(db.UserGoalsCompanion(
        status: const drift.Value('superseded'),
        retiredAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ));

      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: currentGoal.id,
            eventType: 'superseded',
            actor: const drift.Value('user'),
            reason:
                drift.Value(reason ?? 'Superseded by trajectory adjustment'),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));
      await _closePendingReviewsInTransaction(currentGoal.id, now);

      // 2. Create successor goal linked to currentGoal.id
      final successorId = _uuid.v4();
      await _db.into(_db.userGoals).insert(db.UserGoalsCompanion.insert(
            id: drift.Value(successorId),
            preset: currentGoal.preset.key,
            title: currentGoal.title,
            reason: drift.Value(reason ?? currentGoal.reason),
            status: const drift.Value('active'),
            startDate: successorStartDate,
            trackingMode: drift.Value(currentGoal.trackingMode.name),
            baselineMeasurementId:
                drift.Value(currentGoal.baselineMeasurementId),
            baselineValueKg: drift.Value(currentGoal.baselineValueKg),
            baselineDate: drift.Value(currentGoal.baselineDate),
            targetDate: drift.Value(targetDate),
            targetMetric: drift.Value(currentGoal.targetMetric),
            targetValue: drift.Value(targetValue),
            targetUnit: drift.Value(currentGoal.targetUnit),
            desiredWeeklyRateKg: drift.Value(desiredWeeklyRateKg),
            isNutritionDriver: drift.Value(currentGoal.isNutritionDriver),
            predecessorGoalId: drift.Value(currentGoal.id),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ));

      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: successorId,
            eventType: 'created',
            actor: const drift.Value('user'),
            reason: const drift.Value(
                'Created as successor from trajectory adjustment'),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));

      final created = await getGoalById(successorId);
      return created!;
    });
  }

  @override
  Future<Goal> reviseGoal({
    required Goal currentGoal,
    GoalTrackingMode? trackingMode,
    required double? targetValue,
    required DateTime? targetDate,
    required double? desiredWeeklyRateKg,
    double? anchorValue,
    String? reason,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      final revision = jsonEncode({
        'reason': reason,
        'effectiveAt': now.toIso8601String(),
        'anchorValue': anchorValue,
        'before': {
          'targetValue': currentGoal.targetValue,
          'targetDate': currentGoal.targetDate?.toIso8601String(),
          'desiredWeeklyRateKg': currentGoal.desiredWeeklyRateKg,
        },
        'after': {
          'trackingMode': (trackingMode ?? currentGoal.trackingMode).name,
          'targetValue': targetValue,
          'targetDate': targetDate?.toIso8601String(),
          'desiredWeeklyRateKg': desiredWeeklyRateKg,
        },
      });

      await (_db.update(_db.userGoals)
            ..where((table) => table.id.equals(currentGoal.id)))
          .write(db.UserGoalsCompanion(
        targetValue: drift.Value(targetValue),
        targetDate: drift.Value(targetDate),
        desiredWeeklyRateKg: drift.Value(desiredWeeklyRateKg),
        trackingMode:
            drift.Value((trackingMode ?? currentGoal.trackingMode).name),
        updatedAt: drift.Value(now),
      ));
      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: currentGoal.id,
            eventType: 'plan_revised',
            actor: const drift.Value('user'),
            reason: drift.Value(revision),
            algorithmVersion: const drift.Value('goal_plan_revision_1_0'),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));
      await _closePendingReviewsInTransaction(currentGoal.id, now);
      return (await getGoalById(currentGoal.id))!;
    });
  }

  @override
  Future<void> retireGoal(String goalId, {String? reason}) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.userGoals)..where((t) => t.id.equals(goalId)))
          .write(db.UserGoalsCompanion(
        status: const drift.Value('retired'),
        retiredAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ));

      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: goalId,
            eventType: 'retired',
            actor: const drift.Value('user'),
            reason: drift.Value(reason),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));
      await _closePendingReviewsInTransaction(goalId, now);
    });
  }

  @override
  Future<Goal> resumeGoal(String goalId) async {
    return _db.transaction(() async {
      final now = DateTime.now();

      // Ensure no other goal remains active
      final activeGoals = await (_db.select(_db.userGoals)
            ..where((t) =>
                t.status.equals('active') & t.area.equals('body_composition')))
          .get();
      for (final g in activeGoals) {
        if (g.id != goalId) {
          await (_db.update(_db.userGoals)..where((t) => t.id.equals(g.id)))
              .write(db.UserGoalsCompanion(
            status: const drift.Value('retired'),
            retiredAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ));
          await _closePendingReviewsInTransaction(g.id, now);
        }
      }

      await (_db.update(_db.userGoals)..where((t) => t.id.equals(goalId)))
          .write(db.UserGoalsCompanion(
        status: const drift.Value('active'),
        retiredAt: const drift.Value(null),
        updatedAt: drift.Value(now),
      ));

      await _db.into(_db.goalEvents).insert(db.GoalEventsCompanion.insert(
            id: drift.Value(_uuid.v4()),
            goalId: goalId,
            eventType: 'resumed',
            actor: const drift.Value('user'),
            occurredAt: drift.Value(now),
            createdAt: drift.Value(now),
          ));

      final resumed = await getGoalById(goalId);
      return resumed!;
    });
  }

  @override
  Future<void> deleteDraftGoal(String goalId) async {
    await (_db.delete(_db.userGoals)..where((t) => t.id.equals(goalId))).go();
  }

  @override
  Future<GoalReviewRecord?> getPendingReview(String goalId) async {
    final query = _db.select(_db.goalReviews)
      ..where((t) => t.goalId.equals(goalId) & t.status.equals('pending'))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRowToReview(row);
  }

  @override
  Future<GoalReviewRecord?> getReviewById(String reviewId) async {
    final query = _db.select(_db.goalReviews)
      ..where((t) => t.id.equals(reviewId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRowToReview(row);
  }

  @override
  Future<GoalReviewRecord?> getReviewForWindow(
    String goalId,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final query = _db.select(_db.goalReviews)
      ..where((t) =>
          t.goalId.equals(goalId) &
          t.windowStart.equals(windowStart) &
          t.windowEnd.equals(windowEnd))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRowToReview(row);
  }

  @override
  Future<void> saveReview(GoalReviewRecord review) async {
    await _db.into(_db.goalReviews).insertOnConflictUpdate(
          db.GoalReviewsCompanion.insert(
            id: drift.Value(review.id),
            goalId: review.goalId,
            windowStart: review.windowStart,
            windowEnd: review.windowEnd,
            status: drift.Value(review.status),
            trajectoryStatus: drift.Value(review.trajectoryStatus),
            observedRateKgPerWeek: drift.Value(review.observedRateKgPerWeek),
            confidenceLevel: drift.Value(review.confidenceLevel),
            tdeeEstimate: drift.Value(review.tdeeEstimate),
            recommendedCalories: drift.Value(review.recommendedCalories),
            recommendedProtein: drift.Value(review.recommendedProtein),
            recommendedCarbs: drift.Value(review.recommendedCarbs),
            recommendedFat: drift.Value(review.recommendedFat),
            decision: drift.Value(review.decision),
            algorithmVersion: review.algorithmVersion,
            explanation: drift.Value(review.explanation),
            assessmentJson: drift.Value(
              review.assessment == null
                  ? null
                  : jsonEncode(review.assessment!.toMap()),
            ),
            createdAt: drift.Value(review.createdAt),
          ),
        );
  }

  @override
  Future<void> updateReviewStatus(
    String reviewId,
    String status, {
    String? decision,
  }) async {
    await (_db.update(_db.goalReviews)..where((t) => t.id.equals(reviewId)))
        .write(db.GoalReviewsCompanion(
      status: drift.Value(status),
      decision: drift.Value(decision),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  Future<void> _closePendingReviewsInTransaction(
    String goalId,
    DateTime now,
  ) async {
    await (_db.update(_db.goalReviews)
          ..where((t) => t.goalId.equals(goalId) & t.status.equals('pending')))
        .write(db.GoalReviewsCompanion(
      status: const drift.Value('goal_changed'),
      decision: const drift.Value('goal_changed'),
      updatedAt: drift.Value(now),
    ));
  }

  @override
  Future<void> closePendingReviews(String goalId) {
    return _closePendingReviewsInTransaction(goalId, DateTime.now());
  }

  @override
  Future<void> updateGoalWeeklyRate(String goalId, double weeklyRateKg) async {
    final now = DateTime.now();
    await (_db.update(_db.userGoals)..where((t) => t.id.equals(goalId)))
        .write(db.UserGoalsCompanion(
      desiredWeeklyRateKg: drift.Value(weeklyRateKg),
      updatedAt: drift.Value(now),
    ));
  }

  @override
  Future<List<GoalEvent>> getGoalEvents(String goalId) async {
    final query = _db.select(_db.goalEvents)
      ..where((t) => t.goalId.equals(goalId))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapRowToEvent).toList();
  }
}
