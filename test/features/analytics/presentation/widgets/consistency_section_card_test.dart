import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/analytics/presentation/statistics_hub_view_model.dart';
import 'package:train_libre/features/analytics/presentation/widgets/consistency_section_card.dart';
import 'package:train_libre/features/analytics/presentation/widgets/training_heatmap.dart';
import 'package:train_libre/features/statistics/domain/consistency_payload_models.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders compact TrainingHeatmap on the Statistics hub consistency card and keeps tap navigation',
    (tester) async {
      var tapped = false;
      final today = DateTime.now();
      final normToday = DateTime(today.year, today.month, today.day);

      final state = SectionLoadState<ConsistencySectionData>(
        data: ConsistencySectionData(
          workoutsPerWeek: const [],
          weeklyConsistencyMetrics: const [],
          recentWorkoutCount: 17,
          trainingStats: const TrainingStatsPayload(
            totalWorkouts: 51,
            thisWeekCount: 3,
            avgPerWeek: 2.8,
            streakWeeks: 7,
          ),
          workoutDayCounts: {
            normToday: 2,
            normToday.subtract(const Duration(days: 3)): 1,
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ConsistencySectionCard(
              state: state,
              onRetry: () {},
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('17 Workouts'), findsOneWidget);
      expect(find.text('Serie: 7 Wochen'), findsOneWidget);
      expect(find.byType(TrainingHeatmap), findsOneWidget);
      // Compact preview omits axis labels
      expect(find.text('Mo'), findsNothing);

      // Tapping on the heatmap area still opens the card destination
      await tester.tapAt(tester.getCenter(find.byType(TrainingHeatmap)));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );
}
