class MuscleAnalyticsUtils {
  static DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime weekStart(DateTime date) {
    final day = normalizeDay(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static Map<String, dynamic> buildSummary({
    required List<Map<String, dynamic>> contributions,
    required int daysBack,
    required int weeksBack,
    required DateTime now,
  }) {
    final normalizedNow = normalizeDay(now);
    final totalWeeks = (daysBack / 7).clamp(1, 1e9).toDouble();

    final Map<DateTime, Map<String, double>> dayMuscleSets = {};
    final Map<DateTime, Map<String, double>> weekMuscleSets = {};

    void ensureWeek(DateTime weekStartDate) {
      weekMuscleSets.putIfAbsent(weekStartDate, () => {});
    }

    for (int i = 0; i < weeksBack; i++) {
      final week = weekStart(normalizedNow.subtract(Duration(days: i * 7)));
      ensureWeek(week);
    }

    for (final item in contributions) {
      final date = normalizeDay(item['day'] as DateTime);
      final muscle = (item['muscleGroup'] as String).trim();
      final value = (item['equivalentSets'] as num).toDouble();
      if (muscle.isEmpty || value <= 0) continue;

      final week = weekStart(date);

      final dayMap = dayMuscleSets.putIfAbsent(date, () => {});
      dayMap[muscle] = (dayMap[muscle] ?? 0.0) + value;

      ensureWeek(week);
      final weekMap = weekMuscleSets[week]!;
      weekMap[muscle] = (weekMap[muscle] ?? 0.0) + value;
    }

    final Map<String, double> equivalentByMuscle = {};
    final Map<String, int> trainedDaysByMuscle = {};

    for (final dayEntry in dayMuscleSets.entries) {
      for (final muscleEntry in dayEntry.value.entries) {
        equivalentByMuscle[muscleEntry.key] =
            (equivalentByMuscle[muscleEntry.key] ?? 0.0) + muscleEntry.value;

        if (muscleEntry.value >= 1.0) {
          trainedDaysByMuscle[muscleEntry.key] =
              (trainedDaysByMuscle[muscleEntry.key] ?? 0) + 1;
        }
      }
    }

    final totalEquivalentSets = equivalentByMuscle.values.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );

    final muscles = equivalentByMuscle.entries.map((entry) {
      final trainedDays = trainedDaysByMuscle[entry.key] ?? 0;
      final share =
          totalEquivalentSets > 0 ? (entry.value / totalEquivalentSets) : 0.0;
      return {
        'muscleGroup': entry.key,
        'equivalentSets': entry.value,
        'trainedDays': trainedDays,
        'frequencyPerWeek': trainedDays / totalWeeks,
        'distributionShare': share,
      };
    }).toList()
      ..sort(
        (a, b) => ((b['equivalentSets'] as num).toDouble()).compareTo(
          (a['equivalentSets'] as num).toDouble(),
        ),
      );

    final weekRows = weekMuscleSets.entries.map((entry) {
      final weekStartDate = entry.key;
      final weekLabel = '${weekStartDate.day}.${weekStartDate.month}.';
      final totalWeekSets = entry.value.values.fold<double>(
        0.0,
        (sum, value) => sum + value,
      );
      return {
        'weekStart': weekStartDate,
        'weekLabel': weekLabel,
        'muscles': entry.value,
        'totalEquivalentSets': totalWeekSets,
      };
    }).toList()
      ..sort(
        (a, b) => (a['weekStart'] as DateTime).compareTo(
          b['weekStart'] as DateTime,
        ),
      );

    return {
      'daysBack': daysBack,
      'weeksBack': weeksBack,
      'totalEquivalentSets': totalEquivalentSets,
      'muscles': muscles,
      'weekly': weekRows,
    };
  }
}
