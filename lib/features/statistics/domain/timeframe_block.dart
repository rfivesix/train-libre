import 'package:flutter/material.dart';

enum TimeframeBlock {
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
}
