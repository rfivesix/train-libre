import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/statistics/domain/timeframe_block.dart';

void main() {
  test(
    'rolling periods include exactly the stated number of calendar days',
    () {
      for (final block in [TimeframeBlock.week, TimeframeBlock.month]) {
        final bounds = block.getRollingBounds();
        final start = DateTime.utc(
          bounds.start.year,
          bounds.start.month,
          bounds.start.day,
        );
        final end = DateTime.utc(
          bounds.end.year,
          bounds.end.month,
          bounds.end.day,
        );
        expect(end.difference(start).inDays + 1, block.rollingDurationDays);
      }
    },
  );
}
