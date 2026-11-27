import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/analytics/presentation/pr_dashboard_screen.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_metrics.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/empty_states/active_gap_overlay.dart';
import 'package:train_libre/widgets/common/summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
  });

  Widget buildApp({
    required PeriodRecordsLoader loader,
    Locale locale = const Locale('de'),
  }) {
    return ChangeNotifierProvider<UnitService>(
      create: (_) => UnitService(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PRDashboardScreen(loadPeriodRecords: loader),
      ),
    );
  }

  testWidgets(
    'renders record-type dropdown, individual 3-line cards, updated hint, and omits old overview',
    (tester) async {
      final now = DateTime(2026, 11, 20);
      final sampleResult = PeriodPersonalRecordsResult(
        hasAnyCompletedWorkouts: true,
        recordsByMetric: {
          ExerciseMetric.est1rm: [
            PeriodPersonalRecord(
              metric: ExerciseMetric.est1rm,
              exerciseName: 'Standing Calf Raises',
              previousValue: 100.8,
              newValue: 118.8,
              deltaValue: 18.0,
              improvementPct: 17.9,
              achievedAt: now.subtract(const Duration(days: 1)),
              weightKg: 100.0,
              reps: 6,
            ),
            PeriodPersonalRecord(
              metric: ExerciseMetric.est1rm,
              exerciseName: 'Chest Press',
              previousValue: 108.6,
              newValue: 121.0,
              deltaValue: 12.4,
              improvementPct: 11.4,
              achievedAt: now,
              weightKg: 105.0,
              reps: 5,
            ),
          ],
          ExerciseMetric.maxWeight: [
            PeriodPersonalRecord(
              metric: ExerciseMetric.maxWeight,
              exerciseName: 'Squats',
              previousValue: 120.0,
              newValue: 130.0,
              deltaValue: 10.0,
              improvementPct: 8.3,
              achievedAt: now,
              weightKg: 130.0,
              reps: 3,
            ),
          ],
          ExerciseMetric.volume: const [],
          ExerciseMetric.distance: [
            PeriodPersonalRecord(
              metric: ExerciseMetric.distance,
              exerciseName: 'Running',
              previousValue: 5.0,
              newValue: 10.0,
              deltaValue: 5.0,
              improvementPct: 100.0,
              achievedAt: now,
              distanceKm: 10.0,
              durationSeconds: 3000,
            ),
          ],
          ExerciseMetric.duration: const [],
          ExerciseMetric.pace: const [],
        },
      );

      await tester.pumpWidget(
        buildApp(loader: (_, _) async => sampleResult),
      );
      await tester.pumpAndSettle();

      // Subtitle hint removed
      expect(
        find.text('Steigerung ggü. bisheriger Bestleistung'),
        findsNothing,
      );
      expect(find.textContaining('Vorzeitraum'), findsNothing);

      // Redundant bottom overview removed
      expect(find.text('REKORDÜBERSICHT'), findsNothing);
      expect(find.text('Rekordübersicht'), findsNothing);

      // Default metric is Max. Gewicht
      expect(find.text('Max. Gewicht'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('+10 kg'), findsOneWidget);
      expect(find.text('130 kg × 3'), findsOneWidget);
      expect(find.textContaining('+10 kg ·'), findsOneWidget);

      // Record type dropdown opens and switches to Schätz. 1RM
      await tester.tap(
        find.byKey(const ValueKey('pr_dashboard_record_type_menu')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Schätz. 1RM'), findsOneWidget);
      expect(find.text('Volumen'), findsOneWidget);
      expect(find.text('Distanz'), findsOneWidget);
      expect(find.text('Dauer'), findsOneWidget);
      expect(find.text('Tempo'), findsOneWidget);

      await tester.tap(find.text('Schätz. 1RM').last);
      await tester.pumpAndSettle();

      // KPI cards: 2 records, +18 kg Standing Calf Raises
      expect(find.text('2'), findsOneWidget);
      expect(find.text('+18 kg'), findsOneWidget);
      expect(find.text('Standing Calf Raises'), findsAtLeastNWidgets(2));

      // Individual SummaryCards (2 KPI cards + 2 record cards = 4 SummaryCards)
      expect(find.byType(SummaryCard), findsNWidgets(4));

      // 3-line layout values with absolute deltas
      expect(find.text('Chest Press'), findsOneWidget);
      expect(find.text('121 kg · 105 kg × 5'), findsOneWidget);
      expect(find.textContaining('+12.4 kg ·'), findsOneWidget);
      expect(find.textContaining('+18 kg ·'), findsOneWidget);
    },
  );

  testWidgets(
    'shows zero KPI and empty period card without ActiveGapOverlay when user has workout history',
    (tester) async {
      final resultWithEmptyMetrics = PeriodPersonalRecordsResult(
        hasAnyCompletedWorkouts: true,
        recordsByMetric: {
          for (final metric in ExerciseMetric.values) metric: const [],
        },
      );

      await tester.pumpWidget(
        buildApp(loader: (_, _) async => resultWithEmptyMetrics),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActiveGapOverlay), findsNothing);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('–'), findsOneWidget);
      expect(
        find.text('Keine Bestleistungen in diesem Zeitraum'),
        findsOneWidget,
      );
    },
  );
}
