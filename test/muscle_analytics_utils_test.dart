import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/util/muscle_analytics_utils.dart';

void main() {
  group('MuscleAnalyticsUtils', () {
    test('summarizes direct working-set counts and training-day frequency', () {
      final now = DateTime(2026, 3, 9);
      final data = MuscleAnalyticsUtils.buildSummary(
        now: now,
        daysBack: 30,
        weeksBack: 8,
        contributions: [
          {
            'day': DateTime(2026, 3, 1, 10),
            'muscleGroup': 'Chest',
            'equivalentSets': 1.0,
          },
          {
            'day': DateTime(2026, 3, 1, 10),
            'muscleGroup': 'Triceps',
            'equivalentSets': 1.0,
          },
          {
            'day': DateTime(2026, 3, 3, 11),
            'muscleGroup': 'Triceps',
            'equivalentSets': 1.0,
          },
          {
            'day': DateTime(2026, 3, 3, 11),
            'muscleGroup': 'Triceps',
            'equivalentSets': 1.0,
          },
        ],
      );

      final muscles =
          (data['muscles'] as List<dynamic>).cast<Map<String, dynamic>>();
      final chest = muscles.firstWhere((m) => m['muscleGroup'] == 'Chest');
      final triceps = muscles.firstWhere((m) => m['muscleGroup'] == 'Triceps');

      expect((chest['equivalentSets'] as num).toDouble(), 1.0);
      expect((triceps['equivalentSets'] as num).toDouble(), 3.0);

      expect(chest['trainedDays'], 1);
      expect(triceps['trainedDays'], 2);
    });
  });
}
