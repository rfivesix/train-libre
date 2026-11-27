import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';
import 'package:train_libre/features/analytics/presentation/body_nutrition_correlation_screen.dart';
import 'package:train_libre/features/analytics/presentation/macro_statistics_screen.dart';
import 'package:train_libre/features/analytics/presentation/statistics_hub_view_model.dart';
import 'package:train_libre/features/analytics/presentation/widgets/body_metrics_section_card.dart';
import 'package:train_libre/features/analytics/presentation/widgets/macro_history_stacked_bar_chart.dart';
import 'package:train_libre/features/analytics/presentation/widgets/macro_section_card.dart';
import 'package:train_libre/features/analytics/presentation/widgets/sleep_section_card.dart';
import 'package:train_libre/features/analytics/presentation/widgets/water_section_card.dart';
import 'package:train_libre/features/profile/domain/models/measurement_session.dart';
import 'package:train_libre/features/profile/domain/repositories/profile_repository.dart';
import 'package:train_libre/features/profile/presentation/measurements_screen.dart';
import 'package:train_libre/features/profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:train_libre/features/sleep/data/sleep_hub_summary_repository.dart';
import 'package:train_libre/features/statistics/data/macro_analytics_data_adapter.dart';
import 'package:train_libre/features/statistics/data/water_analytics_data_adapter.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_engine.dart';
import 'package:train_libre/features/statistics/domain/timeframe_block.dart';
import 'package:train_libre/features/steps/domain/steps_models.dart';
import 'package:train_libre/features/steps/presentation/statistics_steps_card.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/empty_states/active_gap_overlay.dart';
import 'package:train_libre/widgets/common/empty_states/card_empty_state_overlay.dart';

class _FakeMacroAdapter extends MacroAnalyticsDataAdapter {
  const _FakeMacroAdapter(this.summary);

  final MacroPeriodSummary summary;

  @override
  Future<MacroPeriodSummary> fetchSummary({
    required DateTimeRange range,
  }) async {
    return summary;
  }
}

class _FakeWaterAdapter extends WaterAnalyticsDataAdapter {
  const _FakeWaterAdapter(this.summary);

  final WaterPeriodSummary summary;

  @override
  Future<WaterPeriodSummary> fetchSummary({
    required DateTimeRange range,
  }) async {
    return summary;
  }
}

class _EmptyProfileRepository implements IProfileRepository {
  @override
  Future<List<MeasurementSession>> getMeasurementSessions() async => const [];

  @override
  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(
    String type,
    DateTimeRange range,
  ) async => const [];

  @override
  Stream<List<ChartDataPoint>> watchChartDataForTypeAndRange(
    String type,
    DateTimeRange range,
  ) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithApp(Widget child, {double textScale = 1.0}) {
  return ChangeNotifierProvider(
    create: (_) => UnitService(),
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
  });

  testWidgets(
    'BodyMetricsSectionCard shows skeleton chart with existing empty message and stays tappable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapped = false;
      final emptyResult = BodyNutritionAnalyticsEngine.build(
        range: DateTimeRange(
          start: DateTime.utc(2026, 10, 25),
          end: DateTime.utc(2026, 11, 24),
        ),
        weightPoints: const [],
        caloriesByDay: const {},
      );

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: SingleChildScrollView(
              child: BodyMetricsSectionCard(
                state: SectionLoadState(data: emptyResult),
                rangeLabel: 'Letzte 30 Tage',
                onRetry: () {},
                onTap: () => tapped = true,
              ),
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Körper & Ernährung'), findsOneWidget);
      expect(find.text('Letzte 30 Tage'), findsOneWidget);
      expect(
        find.text('Erfasse Gewicht oder Ernährung, um deine Trends zu sehen.'),
        findsOneWidget,
      );
      expect(find.byType(CardEmptyStateOverlay), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsOneWidget);

      await tester.tap(find.byType(BodyMetricsSectionCard));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'BodyNutritionCorrelationScreen shows skeleton trend chart with ActiveGapOverlay when period has no data',
    (tester) async {
      final range = DateTimeRange(
        start: DateTime.utc(2026, 10, 25),
        end: DateTime.utc(2026, 11, 24),
      );
      final emptyResult = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: const [],
        caloriesByDay: const {},
      );

      await tester.pumpWidget(
        _wrapWithApp(
          BodyNutritionCorrelationScreen(
            initialBlock: TimeframeBlock.month,
            analyticsLoader: ({
              required TimeframeBlock selectedBlockType,
              required DateTime anchorDate,
              bool isRolling = false,
            }) async => emptyResult,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveGapOverlay), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(
        find.text('Keine Daten für diesen Zeitraum verfügbar'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BodyNutritionCorrelationScreen renders real chart without overlay when period has data',
    (tester) async {
      final range = DateTimeRange(
        start: DateTime.utc(2026, 10, 25),
        end: DateTime.utc(2026, 11, 24),
      );
      final populatedResult = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: const [],
        caloriesByDay: {DateTime.utc(2026, 11, 10): 2300},
      );

      await tester.pumpWidget(
        _wrapWithApp(
          BodyNutritionCorrelationScreen(
            initialBlock: TimeframeBlock.month,
            analyticsLoader: ({
              required TimeframeBlock selectedBlockType,
              required DateTime anchorDate,
              bool isRolling = false,
            }) async => populatedResult,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActiveGapOverlay), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsNothing,
      );
      expect(find.byType(LineChart), findsOneWidget);
    },
  );

  testWidgets(
    'MacroSectionCard shows skeleton bars with existing empty message and stays tappable',
    (tester) async {
      var tapped = false;
      final range = DateTimeRange(
        start: DateTime(2026, 11, 18),
        end: DateTime(2026, 11, 24),
      );
      final emptySummary = MacroPeriodSummary(
        range: range,
        dailyIntakes: List.generate(
          7,
          (i) => DailyMacroIntake(
            date: DateTime(2026, 11, 18 + i),
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
          ),
        ),
        avgCalories: 0,
        avgProtein: 0,
        avgCarbs: 0,
        avgFat: 0,
        totalDays: 7,
        trackedDays: 0,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: SingleChildScrollView(
              child: MacroSectionCard(
                adapter: _FakeMacroAdapter(emptySummary),
                rangeLabel: 'Letzte 7 Tage',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('Makronährstoffe'), findsOneWidget);
      expect(
        find.text('Keine Ernährung in den letzten 7 Tagen erfasst.'),
        findsOneWidget,
      );
      expect(find.byType(CardEmptyStateOverlay), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsOneWidget,
      );

      await tester.tap(find.byType(MacroSectionCard));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'MacroStatisticsScreen shows skeleton chart with ActiveGapOverlay only when current window has zero tracked days',
    (tester) async {
      final range = DateTimeRange(
        start: DateTime(2026, 11, 18),
        end: DateTime(2026, 11, 24),
      );
      final emptySummary = MacroPeriodSummary(
        range: range,
        dailyIntakes: List.generate(
          7,
          (i) => DailyMacroIntake(
            date: DateTime(2026, 11, 18 + i),
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
          ),
        ),
        avgCalories: 0,
        avgProtein: 0,
        avgCarbs: 0,
        avgFat: 0,
        totalDays: 7,
        trackedDays: 0,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          MacroStatisticsScreen(
            initialBlock: TimeframeBlock.week,
            adapter: _FakeMacroAdapter(emptySummary),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveGapOverlay), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsOneWidget,
      );
      expect(find.byType(MacroHistoryStackedBarChart), findsOneWidget);
      expect(
        find.text('Keine Daten für diesen Zeitraum verfügbar'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'MacroStatisticsScreen shows real chart without overlay when at least one day is tracked',
    (tester) async {
      final range = DateTimeRange(
        start: DateTime(2026, 11, 18),
        end: DateTime(2026, 11, 24),
      );
      final partialSummary = MacroPeriodSummary(
        range: range,
        dailyIntakes: [
          for (int i = 0; i < 6; i++)
            DailyMacroIntake(
              date: DateTime(2026, 11, 18 + i),
              calories: 0,
              proteinGrams: 0,
              carbsGrams: 0,
              fatGrams: 0,
            ),
          DailyMacroIntake(
            date: DateTime(2026, 11, 24),
            calories: 2150,
            proteinGrams: 150,
            carbsGrams: 220,
            fatGrams: 70,
          ),
        ],
        avgCalories: 2150,
        avgProtein: 150,
        avgCarbs: 220,
        avgFat: 70,
        totalDays: 7,
        trackedDays: 1,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          MacroStatisticsScreen(
            initialBlock: TimeframeBlock.week,
            adapter: _FakeMacroAdapter(partialSummary),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActiveGapOverlay), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsNothing,
      );
      expect(find.byType(MacroHistoryStackedBarChart), findsOneWidget);
    },
  );

  testWidgets(
    'Graphical hub cards (Steps, Sleep, Water) render skeleton previews with empty messages',
    (tester) async {
      final range = DateTimeRange(
        start: DateTime(2026, 11, 18),
        end: DateTime(2026, 11, 24),
      );
      final emptyWater = WaterPeriodSummary(
        range: range,
        dailyIntakes: List.generate(
          7,
          (i) => WaterDayIntake(
            date: DateTime(2026, 11, 18 + i),
            milliliters: 0,
            isTracked: false,
          ),
        ),
        trackedDays: 0,
        averageMilliliters: 0,
        targetMilliliters: 3000,
      );
      final mockSteps = List.generate(
        7,
        (i) => StepsBucket(
          start: DateTime(2026, 11, 18 + i),
          steps: 7000 + i * 400,
        ),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  StatisticsStepsCard(
                    title: 'Schritte',
                    chipText: 'Letzte 7 Tage',
                    currentSteps: 7840,
                    currentStepsSubtitle: 'Heute',
                    dailyTotals: mockSteps,
                    dailyGoal: 10000,
                    emptyStateMessage:
                        'Keine Schritte in den letzten 7 Tagen erfasst.',
                  ),
                  SleepSectionCard(
                    state: const SectionLoadState(data: SleepHubSummary()),
                    rangeLabel: 'Letzte 7 Tage',
                    onRetry: () {},
                    onTap: () {},
                  ),
                  WaterSectionCard(
                    block: TimeframeBlock.week,
                    anchor: DateTime(2026, 11, 24),
                    isRolling: true,
                    adapter: _FakeWaterAdapter(emptyWater),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(CardEmptyStateOverlay), findsNWidgets(3));
      expect(
        find.text('Keine Schritte in den letzten 7 Tagen erfasst.'),
        findsOneWidget,
      );
      expect(
        find.text('Kein Schlaf in den letzten 7 Tagen erfasst.'),
        findsOneWidget,
      );
      expect(find.text('Noch keine Getränke protokolliert'), findsOneWidget);
    },
  );

  testWidgets(
    'MeasurementsScreen wraps mock chart and list together inside Skeletonizer and ActiveGapOverlay when empty',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          MeasurementsScreen(
            repository: _EmptyProfileRepository(),
            initialBlock: TimeframeBlock.threeMonths,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveGapOverlay), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ActiveGapOverlay),
          matching: find.byType(MeasurementChartWidget),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
          matching: find.byType(MeasurementChartWidget),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Keine Daten für diesen Zeitraum verfügbar'),
        findsOneWidget,
      );
    },
  );
}
