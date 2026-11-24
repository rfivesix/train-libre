import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/analytics/presentation/statistics_hub_view_model.dart';
import 'package:train_libre/features/analytics/presentation/widgets/body_metrics_section_card.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_engine.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:train_libre/features/statistics/domain/statistics_data_quality_policy.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
  });

  testWidgets(
    'BodyMetricsSectionCard fits sparse data and its legend at XXL text size',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = BodyNutritionAnalyticsEngine.build(
        range: DateTimeRange(
          start: DateTime.utc(2025, 11, 1),
          end: DateTime.utc(2025, 11, 9),
        ),
        weightPoints: const [],
        caloriesByDay: {
          DateTime.utc(2025, 11, 2): 2000,
          DateTime.utc(2025, 11, 6): 2200,
        },
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => UnitService(),
          child: MaterialApp(
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BodyMetricsSectionCard(
                    state: SectionLoadState(data: result),
                    onRetry: () {},
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.map((spot) => spot.x), [
        1,
        5,
      ]);
      expect(find.text('Gesamtgewicht (kg)'), findsOneWidget);
      expect(find.text('Gesamtkalorien (kcal)'), findsOneWidget);
    },
  );

  testWidgets(
    'BodyMetricsSectionCard omits relationship and confidence footer text',
    (tester) async {
      final unitService = UnitService();
      final result = BodyNutritionAnalyticsResult(
        range: DateTimeRange(
          start: DateTime(2026, 10, 24),
          end: DateTime(2026, 11, 22),
        ),
        totalDays: 30,
        currentWeightKg: 78.8,
        weightChangeKg: -1.2,
        avgDailyCalories: 2545,
        weightDays: 20,
        loggedCalorieDays: 25,
        weightDaily: [
          DailyValuePoint(day: DateTime(2026, 10, 24), value: 80.0),
          DailyValuePoint(day: DateTime(2026, 11, 22), value: 78.8),
        ],
        smoothedWeight: const [],
        caloriesDaily: [
          DailyValuePoint(day: DateTime(2026, 10, 24), value: 2500),
          DailyValuePoint(day: DateTime(2026, 11, 22), value: 2590),
        ],
        smoothedCalories: const [],
        weightTrend: const BodyNutritionTrendSnapshot(
          direction: BodyNutritionTrendDirection.falling,
          slopePerWeek: -0.3,
          netChange: -1.2,
          signalToNoise: 1.5,
        ),
        calorieTrend: const BodyNutritionTrendSnapshot(
          direction: BodyNutritionTrendDirection.stable,
          slopePerWeek: 0,
          netChange: 0,
          signalToNoise: 0.5,
        ),
        relationship: BodyNutritionRelationshipType.mixedOrUnclear,
        confidence: BodyNutritionConfidence.high,
        qualitySummary: const BodyNutritionDataQualitySummary(
          spanDays: 30,
          weightDays: 20,
          calorieDays: 25,
          overlapDays: 18,
          weightCoverage: 0.67,
          calorieCoverage: 0.83,
          overlapCoverage: 0.6,
          weightLargestGapDays: 2,
          calorieLargestGapDays: 2,
        ),
        insightType: BodyNutritionInsightType.mixed,
        insightDataQuality: const StatisticsDataQualityAssessment(
          hasSufficientData: true,
          reasonHook: 'quality:body-nutrition:sufficient',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<UnitService>.value(
          value: unitService,
          child: MaterialApp(
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BodyMetricsSectionCard(
                  state: SectionLoadState<BodyNutritionAnalyticsResult>(
                    data: result,
                  ),
                  onRetry: () {},
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Signale sind gemischt'), findsNothing);
      expect(
        find.textContaining('Muster mit höherer Verlässlichkeit'),
        findsNothing,
      );
      expect(find.textContaining('·'), findsNothing);
    },
  );
}
