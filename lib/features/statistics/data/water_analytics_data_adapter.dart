import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../../features/diary/domain/models/fluid_entry.dart';
import '../domain/timeframe_block.dart';

class WaterDayIntake {
  const WaterDayIntake({
    required this.date,
    required this.milliliters,
    required this.isTracked,
  });

  final DateTime date;
  final int milliliters;
  final bool isTracked;
}

class WaterPeriodSummary {
  const WaterPeriodSummary({
    required this.range,
    required this.dailyIntakes,
    required this.trackedDays,
    required this.averageMilliliters,
    required this.targetMilliliters,
  });

  final DateTimeRange range;
  final List<WaterDayIntake> dailyIntakes;
  final int trackedDays;
  final int averageMilliliters;
  final int targetMilliliters;

  int get totalMilliliters =>
      dailyIntakes.fold(0, (sum, day) => sum + day.milliliters);
}

class WaterAnalyticsDataAdapter {
  const WaterAnalyticsDataAdapter();

  Future<WaterPeriodSummary> fetchSummary({
    required DateTimeRange range,
  }) async {
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final entries = await DatabaseHelper.instance.getFluidEntriesForDateRange(
      start,
      endOfDay,
    );
    final totals = <DateTime, int>{};
    for (final FluidEntry entry in entries) {
      final day = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      totals.update(
        day,
        (value) => value + entry.quantityInMl,
        ifAbsent: () => entry.quantityInMl,
      );
    }

    final days = <WaterDayIntake>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final amount = totals[day];
      days.add(
        WaterDayIntake(
          date: day,
          milliliters: amount ?? 0,
          isTracked: amount != null,
        ),
      );
    }
    final trackedDays = totals.length;
    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    final goals = await DatabaseHelper.instance.getGoalsForDate(end);
    final target = goals?.targetWater ?? 3000;

    return WaterPeriodSummary(
      range: DateTimeRange(start: start, end: end),
      dailyIntakes: List.unmodifiable(days),
      trackedDays: trackedDays,
      averageMilliliters: trackedDays == 0 ? 0 : (total / trackedDays).round(),
      targetMilliliters: target,
    );
  }

  static DateTimeRange rangeFor({
    required TimeframeBlock block,
    required DateTime anchor,
    required bool isRolling,
  }) {
    final bounds = isRolling
        ? block.getRollingBounds()
        : block.getBounds(anchor, DateTime(2020));
    return DateTimeRange(start: bounds.start, end: bounds.end);
  }
}
