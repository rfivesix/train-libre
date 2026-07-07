import 'package:flutter/material.dart';

import 'recovery_domain_service.dart';
import 'timeframe_block.dart';

enum StatisticsRangeSemantics { selected, fixed, capped, dynamicAll }

enum StatisticsMetricId {
  bodyNutritionTrend,
  muscleAnalytics,
  hubMuscleAnalytics,
  hubNotablePrImprovements,
  prNotableImprovements,
  consistencyWeeklyMetrics,
  consistencyCalendar,
  hubWeeklyVolume,
  hubWorkoutsPerWeek,
  hubConsistencyMetrics,
  hubRecoveryReadiness,
  bodyNutritionInsightKpi,
}

class StatisticsMetricRangeMetadata {
  final StatisticsMetricId metricId;
  final StatisticsRangeSemantics semantics;
  final int? fixedDays;
  final int? fixedWeeks;
  final int? capDays;
  final String disclosureHook;

  const StatisticsMetricRangeMetadata({
    required this.metricId,
    required this.semantics,
    required this.disclosureHook,
    this.fixedDays,
    this.fixedWeeks,
    this.capDays,
  });
}

class StatisticsResolvedRange {
  final StatisticsRangeSemantics semantics;
  final int? effectiveDays;
  final int? effectiveWeeks;
  final DateTimeRange? dateRange;
  final TimeframeBlock? block;
  final String disclosureHook;

  const StatisticsResolvedRange({
    required this.semantics,
    required this.disclosureHook,
    this.effectiveDays,
    this.effectiveWeeks,
    this.dateRange,
    this.block,
  });
}

class StatisticsRangePolicyService {
  const StatisticsRangePolicyService._();

  static const StatisticsRangePolicyService instance =
      StatisticsRangePolicyService._();

  static const Map<StatisticsMetricId, StatisticsMetricRangeMetadata> metadata =
      {
    StatisticsMetricId.bodyNutritionTrend: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      semantics: StatisticsRangeSemantics.dynamicAll,
      disclosureHook: 'range:dynamic-all',
    ),
    StatisticsMetricId.muscleAnalytics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.muscleAnalytics,
      semantics: StatisticsRangeSemantics.selected,
      disclosureHook: 'range:selected',
    ),
    StatisticsMetricId.hubMuscleAnalytics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubMuscleAnalytics,
      semantics: StatisticsRangeSemantics.selected,
      fixedWeeks: 8,
      disclosureHook: 'range:selected+fixed-weeks',
    ),
    StatisticsMetricId.hubNotablePrImprovements: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubNotablePrImprovements,
      semantics: StatisticsRangeSemantics.capped,
      capDays: 90,
      disclosureHook: 'range:capped-90d',
    ),
    StatisticsMetricId.prNotableImprovements: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.prNotableImprovements,
      semantics: StatisticsRangeSemantics.selected,
      disclosureHook: 'range:selected',
    ),
    StatisticsMetricId.consistencyWeeklyMetrics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.consistencyWeeklyMetrics,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 12,
      disclosureHook: 'range:fixed-12w',
    ),
    StatisticsMetricId.consistencyCalendar: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.consistencyCalendar,
      semantics: StatisticsRangeSemantics.fixed,
      fixedDays: 120,
      disclosureHook: 'range:fixed-120d',
    ),
    StatisticsMetricId.hubWeeklyVolume: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubWeeklyVolume,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 6,
      disclosureHook: 'range:fixed-6w',
    ),
    StatisticsMetricId.hubWorkoutsPerWeek: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubWorkoutsPerWeek,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 6,
      disclosureHook: 'range:fixed-6w',
    ),
    StatisticsMetricId.hubConsistencyMetrics: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubConsistencyMetrics,
      semantics: StatisticsRangeSemantics.fixed,
      fixedWeeks: 6,
      disclosureHook: 'range:fixed-6w',
    ),
    StatisticsMetricId.hubRecoveryReadiness: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.hubRecoveryReadiness,
      semantics: StatisticsRangeSemantics.fixed,
      fixedDays: RecoveryDomainService.recoveryLookbackDays,
      disclosureHook: 'range:fixed-current-recovery-14d',
    ),
    StatisticsMetricId.bodyNutritionInsightKpi: StatisticsMetricRangeMetadata(
      metricId: StatisticsMetricId.bodyNutritionInsightKpi,
      semantics: StatisticsRangeSemantics.dynamicAll,
      disclosureHook: 'range:dynamic-all',
    ),
  };

  StatisticsResolvedRange resolve({
    required StatisticsMetricId metricId,
    TimeframeBlock? selectedBlockType,
    DateTime? now,
    DateTime? earliestAvailableDay,
    int? effectiveWeeks,
  }) {
    final policy = metadata[metricId]!;
    final anchor = _normalizeDay(now ?? DateTime.now());

    int? days = policy.fixedDays;
    DateTimeRange? dateRange;

    switch (policy.semantics) {
      case StatisticsRangeSemantics.selected:
      case StatisticsRangeSemantics.capped:
      case StatisticsRangeSemantics.dynamicAll:
        if (selectedBlockType != null) {
          dateRange = selectedBlockType.getBounds(
            anchor,
            earliestAvailableDay ?? DateTime(2020),
          );
          days = dateRange.end.difference(dateRange.start).inDays + 1;
        } else {
          days = 30;
          dateRange = DateTimeRange(
            start: anchor.subtract(Duration(days: days - 1)),
            end: _endOfDay(anchor),
          );
        }
        
        if (policy.semantics == StatisticsRangeSemantics.capped && policy.capDays != null) {
          if (days > policy.capDays!) {
            days = policy.capDays;
            dateRange = DateTimeRange(
              start: anchor.subtract(Duration(days: days! - 1)),
              end: _endOfDay(anchor),
            );
          }
        }
        break;
      case StatisticsRangeSemantics.fixed:
        days = policy.fixedDays;
        if (days != null && days > 0) {
          dateRange = DateTimeRange(
            start: anchor.subtract(Duration(days: days - 1)),
            end: _endOfDay(anchor),
          );
        }
        break;
    }

    return StatisticsResolvedRange(
      semantics: policy.semantics,
      disclosureHook: policy.disclosureHook,
      effectiveDays: days,
      effectiveWeeks: effectiveWeeks ?? policy.fixedWeeks,
      dateRange: dateRange,
      block: selectedBlockType,
    );
  }

  int resolveWeeksBack({
    required StatisticsMetricId metricId,
    int? effectiveDays,
  }) {
    final policy = metadata[metricId]!;
    if (policy.fixedWeeks != null) {
      return policy.fixedWeeks!;
    }

    if (metricId == StatisticsMetricId.muscleAnalytics &&
        effectiveDays != null) {
      final derived = (effectiveDays / 7).ceil();
      return derived.clamp(4, 16);
    }

    return 1;
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);
}
