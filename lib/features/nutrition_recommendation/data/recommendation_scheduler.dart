class RecommendationScheduler {
  const RecommendationScheduler._();

  static DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime dueWeekStart(
    DateTime now, {
    int checkInWeekday = DateTime.monday,
  }) {
    final day = normalizeDay(now);
    final offset = ((day.weekday - checkInWeekday) % 7 + 7) % 7;
    return day.subtract(Duration(days: offset));
  }

  /// Stable input anchor for recommendation generation inside a due week.
  ///
  /// Uses the completed day prior to check-in day as the rolling-window end.
  static DateTime stableWindowEndDayForDueWeek(
    DateTime now, {
    int checkInWeekday = DateTime.monday,
  }) {
    final dueStart = dueWeekStart(now, checkInWeekday: checkInWeekday);
    return normalizeDay(dueStart.subtract(const Duration(days: 1)));
  }

  static String dueWeekKeyFor(
    DateTime now, {
    int checkInWeekday = DateTime.monday,
  }) {
    final dueStart = dueWeekStart(now, checkInWeekday: checkInWeekday);
    final year = dueStart.year.toString().padLeft(4, '0');
    final month = dueStart.month.toString().padLeft(2, '0');
    final day = dueStart.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static bool shouldGenerateForWeek({
    required String dueWeekKey,
    required String? lastGeneratedDueWeekKey,
  }) {
    return dueWeekKey != lastGeneratedDueWeekKey;
  }

  static bool isDueNow({
    required DateTime now,
    required String? lastGeneratedDueWeekKey,
    int checkInWeekday = DateTime.monday,
  }) {
    return shouldGenerateForWeek(
      dueWeekKey: dueWeekKeyFor(now, checkInWeekday: checkInWeekday),
      lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
    );
  }

  static DateTime nextDueAt({
    required DateTime now,
    required String? lastGeneratedDueWeekKey,
    int checkInWeekday = DateTime.monday,
  }) {
    final dueStart = dueWeekStart(now, checkInWeekday: checkInWeekday);
    final dueNow = isDueNow(
      now: now,
      lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
      checkInWeekday: checkInWeekday,
    );
    if (dueNow) {
      return dueStart;
    }
    return dueStart.add(const Duration(days: 7));
  }
}
