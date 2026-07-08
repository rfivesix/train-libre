import 'package:flutter/material.dart';

enum TimeframeBlock {
  day,
  week,
  month,
  threeMonths,
  sixMonths,
  year,
  maxBlock,
}

extension TimeframeBlockExtension on TimeframeBlock {
  DateTimeRange getBounds(DateTime anchor, DateTime earliest) {
    if (this == TimeframeBlock.maxBlock) {
      final now = DateTime.now();
      return DateTimeRange(
        start: DateTime(earliest.year, earliest.month, earliest.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    }
    
    DateTime start;
    DateTime end;
    
    switch (this) {
      case TimeframeBlock.day:
        start = anchor;
        end = anchor;
        break;
      case TimeframeBlock.week:
        // Assume week starts on Monday
        final weekday = anchor.weekday;
        start = anchor.subtract(Duration(days: weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case TimeframeBlock.month:
        start = DateTime(anchor.year, anchor.month, 1);
        end = DateTime(anchor.year, anchor.month + 1, 0); // Last day of month
        break;
      case TimeframeBlock.threeMonths:
        final quarter = (anchor.month - 1) ~/ 3;
        final startMonth = quarter * 3 + 1;
        start = DateTime(anchor.year, startMonth, 1);
        end = DateTime(anchor.year, startMonth + 3, 0);
        break;
      case TimeframeBlock.sixMonths:
        final half = (anchor.month - 1) ~/ 6;
        final startMonth = half * 6 + 1;
        start = DateTime(anchor.year, startMonth, 1);
        end = DateTime(anchor.year, startMonth + 6, 0);
        break;
      case TimeframeBlock.year:
        start = DateTime(anchor.year, 1, 1);
        end = DateTime(anchor.year, 12, 31);
        break;
      default:
        throw Exception("Unknown block");
    }
    
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  DateTime shift(DateTime anchor, int sign) {
    if (this == TimeframeBlock.maxBlock) return anchor;
    DateTime nextAnchor;
    switch (this) {
      case TimeframeBlock.day:
        nextAnchor = anchor.add(Duration(days: sign));
        break;
      case TimeframeBlock.week:
        nextAnchor = anchor.add(Duration(days: 7 * sign));
        break;
      case TimeframeBlock.month:
        nextAnchor = DateTime(anchor.year, anchor.month + sign, 15);
        break;
      case TimeframeBlock.threeMonths:
        nextAnchor = DateTime(anchor.year, anchor.month + 3 * sign, 15);
        break;
      case TimeframeBlock.sixMonths:
        nextAnchor = DateTime(anchor.year, anchor.month + 6 * sign, 15);
        break;
      case TimeframeBlock.year:
        nextAnchor = DateTime(anchor.year + sign, 6, 15);
        break;
      default:
        nextAnchor = anchor;
    }
    DateTime shiftedStart = getBounds(nextAnchor, DateTime(2020)).start;
    if (shiftedStart.isAfter(DateTime.now())) {
      shiftedStart = DateTime.now();
    }
    return shiftedStart;
  }

  int get rollingDurationDays {
    switch (this) {
      case TimeframeBlock.week:
        return 7;
      case TimeframeBlock.month:
        return 30;
      case TimeframeBlock.threeMonths:
        return 90;
      case TimeframeBlock.sixMonths:
        return 180;
      case TimeframeBlock.year:
        return 365;
      default:
        return 0; // day and maxBlock do not support rolling in the same way
    }
  }

  DateTimeRange getRollingBounds() {
    final now = DateTime.now();
    if (this == TimeframeBlock.maxBlock) {
      return DateTimeRange(
        start: DateTime(2020),
        end: now,
      );
    }
    if (this == TimeframeBlock.day) {
      return getBounds(now, DateTime(2020));
    }
    
    final duration = Duration(days: rollingDurationDays);
    final start = now.subtract(duration);
    
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: now,
    );
  }
}
