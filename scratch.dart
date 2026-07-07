enum TimeframeBlock { week, month, threeMonths, sixMonths, year, maxBlock }

class DateUtils {
  static DateTimeRange getBlockBounds(TimeframeBlock block, DateTime anchor, DateTime earliest) {
    if (block == TimeframeBlock.maxBlock) {
      return DateTimeRange(start: earliest, end: DateTime.now());
    }
    
    switch (block) {
      case TimeframeBlock.week:
        // Assume week starts on Monday
        final weekday = anchor.weekday;
        final start = anchor.subtract(Duration(days: weekday - 1));
        final end = start.add(Duration(days: 6));
        return DateTimeRange(start: start, end: end);
      case TimeframeBlock.month:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 0); // Last day of month
        return DateTimeRange(start: start, end: end);
      case TimeframeBlock.threeMonths:
        final quarter = (anchor.month - 1) ~/ 3;
        final startMonth = quarter * 3 + 1;
        final start = DateTime(anchor.year, startMonth, 1);
        final end = DateTime(anchor.year, startMonth + 3, 0);
        return DateTimeRange(start: start, end: end);
      case TimeframeBlock.sixMonths:
        final half = (anchor.month - 1) ~/ 6;
        final startMonth = half * 6 + 1;
        final start = DateTime(anchor.year, startMonth, 1);
        final end = DateTime(anchor.year, startMonth + 6, 0);
        return DateTimeRange(start: start, end: end);
      case TimeframeBlock.year:
        final start = DateTime(anchor.year, 1, 1);
        final end = DateTime(anchor.year, 12, 31);
        return DateTimeRange(start: start, end: end);
      default:
        throw Exception("Unknown block");
    }
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange({required this.start, required this.end});
  @override String toString() => '${start.toString().split(' ')[0]} - ${end.toString().split(' ')[0]}';
}

void main() {
  final anchor = DateTime(2026, 7, 7);
  final earliest = DateTime(2020, 1, 1);
  for (final block in TimeframeBlock.values) {
    print('$block: ${DateUtils.getBlockBounds(block, anchor, earliest)}');
  }
}
