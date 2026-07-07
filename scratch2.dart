enum TimeframeBlock { week, month, threeMonths, sixMonths, year, maxBlock }

class TestShift {
  static DateTime shift(DateTime anchor, TimeframeBlock block, bool backward) {
    int dir = backward ? -1 : 1;
    switch(block) {
      case TimeframeBlock.week: return anchor.add(Duration(days: 7 * dir));
      case TimeframeBlock.month: return DateTime(anchor.year, anchor.month + dir, anchor.day);
      case TimeframeBlock.threeMonths: return DateTime(anchor.year, anchor.month + 3 * dir, anchor.day);
      case TimeframeBlock.sixMonths: return DateTime(anchor.year, anchor.month + 6 * dir, anchor.day);
      case TimeframeBlock.year: return DateTime(anchor.year + dir, anchor.month, anchor.day);
      case TimeframeBlock.maxBlock: return anchor;
    }
  }
}

void main() {
  print(TestShift.shift(DateTime(2026, 7, 7), TimeframeBlock.month, true));
}
