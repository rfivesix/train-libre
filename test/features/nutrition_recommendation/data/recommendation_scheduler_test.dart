import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_scheduler.dart';

void main() {
  group('RecommendationScheduler', () {
    test('dueWeekKeyFor anchors week to Monday', () {
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 6, 9, 0)),
        '2026-04-06',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 7, 9, 0)),
        '2026-04-06',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 12, 23, 0)),
        '2026-04-06',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(DateTime(2026, 4, 13, 0, 1)),
        '2026-04-13',
      );
    });

    test('shouldGenerateForWeek enforces one recommendation per due week', () {
      expect(
        RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: '2026-04-06',
          lastGeneratedDueWeekKey: null,
        ),
        isTrue,
      );
      expect(
        RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: '2026-04-06',
          lastGeneratedDueWeekKey: '2026-04-06',
        ),
        isFalse,
      );
      expect(
        RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: '2026-04-13',
          lastGeneratedDueWeekKey: '2026-04-06',
        ),
        isTrue,
      );
    });

    test('isDueNow and nextDueAt expose freshness semantics', () {
      final monday = DateTime(2026, 4, 6, 9, 0);
      expect(
        RecommendationScheduler.isDueNow(
          now: monday,
          lastGeneratedDueWeekKey: null,
        ),
        isTrue,
      );
      expect(
        RecommendationScheduler.nextDueAt(
          now: monday,
          lastGeneratedDueWeekKey: null,
        ),
        DateTime(2026, 4, 6),
      );

      expect(
        RecommendationScheduler.isDueNow(
          now: DateTime(2026, 4, 8, 9, 0),
          lastGeneratedDueWeekKey: '2026-04-06',
        ),
        isFalse,
      );
      expect(
        RecommendationScheduler.nextDueAt(
          now: DateTime(2026, 4, 8, 9, 0),
          lastGeneratedDueWeekKey: '2026-04-06',
        ),
        DateTime(2026, 4, 13),
      );
    });

    test('stableWindowEndDayForDueWeek stays fixed within the same due week',
        () {
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 6, 0, 1),
        ),
        DateTime(2026, 4, 5),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 8, 18, 30),
        ),
        DateTime(2026, 4, 5),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 12, 23, 59),
        ),
        DateTime(2026, 4, 5),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          DateTime(2026, 4, 13, 0, 1),
        ),
        DateTime(2026, 4, 12),
      );
    });

    test('supports dynamic checkInWeekday (e.g. Thursday or Sunday)', () {
      // 2026-04-09 is a Thursday
      final thursday = DateTime(2026, 4, 9, 10, 0);
      final saturday = DateTime(2026, 4, 11, 14, 0);
      final nextWednesday = DateTime(2026, 4, 15, 22, 0);
      final nextThursday = DateTime(2026, 4, 16, 9, 0);

      expect(
        RecommendationScheduler.dueWeekKeyFor(
          thursday,
          checkInWeekday: DateTime.thursday,
        ),
        '2026-04-09',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(
          saturday,
          checkInWeekday: DateTime.thursday,
        ),
        '2026-04-09',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(
          nextWednesday,
          checkInWeekday: DateTime.thursday,
        ),
        '2026-04-09',
      );
      expect(
        RecommendationScheduler.dueWeekKeyFor(
          nextThursday,
          checkInWeekday: DateTime.thursday,
        ),
        '2026-04-16',
      );

      // Stable window ends on the completed day before check-in (Wednesday 2026-04-08)
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          thursday,
          checkInWeekday: DateTime.thursday,
        ),
        DateTime(2026, 4, 8),
      );
      expect(
        RecommendationScheduler.stableWindowEndDayForDueWeek(
          saturday,
          checkInWeekday: DateTime.thursday,
        ),
        DateTime(2026, 4, 8),
      );

      // Freshness & next due date
      expect(
        RecommendationScheduler.isDueNow(
          now: saturday,
          lastGeneratedDueWeekKey: '2026-04-09',
          checkInWeekday: DateTime.thursday,
        ),
        isFalse,
      );
      expect(
        RecommendationScheduler.nextDueAt(
          now: saturday,
          lastGeneratedDueWeekKey: '2026-04-09',
          checkInWeekday: DateTime.thursday,
        ),
        DateTime(2026, 4, 16),
      );
    });
  });
}
