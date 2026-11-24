import 'dart:ui' show PointerDeviceKind;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:train_libre/features/statistics/presentation/widgets/body_nutrition_normalized_trend_chart.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  final start = DateTime.utc(2025, 11, 1);
  DateTime day(int offset) => start.add(Duration(days: offset));
  DailyValuePoint point(int offset, double value) =>
      DailyValuePoint(day: day(offset), value: value);
  LineChartData chartData(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data;

  setUp(() {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
  });

  Future<void> pumpChart(
    WidgetTester tester, {
    required List<DailyValuePoint> weight,
    required List<DailyValuePoint> calories,
    Set<DateTime> incompleteDays = const {},
    int startOffset = 0,
    int endOffset = 8,
    bool compact = false,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UnitService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: compact ? 76 : 250,
              child: BodyNutritionNormalizedTrendChart(
                compact: compact,
                edgeToEdge: !compact,
                range: DateTimeRange(
                  start: day(startOffset),
                  end: day(endOffset),
                ),
                weightSeries: weight,
                calorieSeries: calories,
                incompleteNutritionDays: incompleteDays,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final compact in [true, false]) {
    testWidgets(
      'connects recorded calorie points across gaps (compact: $compact)',
      (tester) async {
        await pumpChart(
          tester,
          compact: compact,
          weight: [for (var x = 0; x <= 8; x++) point(x, 80)],
          calories: [
            point(1, 2000),
            point(2, 2200),
            point(3, 0),
            point(4, 2400),
            point(5, 100),
            point(7, 2200),
          ],
          incompleteDays: {DateTime(2025, 11, 6, 13)},
        );

        final bars = chartData(tester).lineBarsData;
        expect(
          bars.first.spots.map((spot) => spot.x),
          List.generate(9, (x) => x),
        );
        final calories = bars.last;
        expect(calories.spots, [
          const FlSpot(1, 0),
          const FlSpot(2, 0.5),
          const FlSpot(4, 1),
          const FlSpot(7, 0.5),
        ]);
        expect(
          calories.dotData.checkToShowDot(calories.spots.last, calories),
          isTrue,
        );
      },
    );
  }

  testWidgets('renders either series on its own', (tester) async {
    await pumpChart(tester, weight: [point(4, 80)], calories: [point(4, 0)]);
    expect(
      tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .single
          .spots,
      [const FlSpot(4, 0.5)],
    );
    expect(find.textContaining('kcal'), findsNothing);

    await pumpChart(tester, weight: [], calories: [point(3, 2200)]);
    expect(
      tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .single
          .spots,
      [const FlSpot(3, 0.5)],
    );
    expect(find.textContaining('kg'), findsNothing);
  });

  testWidgets('shows the empty state when all points are invalid or excluded', (
    tester,
  ) async {
    await pumpChart(
      tester,
      weight: [point(-1, 80), point(1, double.nan), point(2, 0), point(9, 81)],
      calories: [
        point(0, 0),
        point(1, double.infinity),
        point(2, -200),
        point(3, 1500),
        point(9, 2000),
      ],
      incompleteDays: {day(3)},
    );

    expect(find.byType(LineChart), findsNothing);
    expect(find.textContaining('Not enough consistent data'), findsOneWidget);
  });

  testWidgets(
    'a one-day range includes both series and excludes adjacent days',
    (tester) async {
      await pumpChart(
        tester,
        startOffset: 2,
        endOffset: 2,
        weight: [point(1, 200), point(2, 80), point(3, 100)],
        calories: [point(1, 5000), point(2, 2100), point(3, 6000)],
      );

      final data = chartData(tester);
      expect(data.maxX, greaterThan(data.minX));
      expect(find.text('03.11'), findsOneWidget);
      expect(find.text('04.11'), findsNothing);
      expect(data.lineBarsData, hasLength(2));
      for (final bar in data.lineBarsData) {
        expect(bar.spots, [const FlSpot(0, 0.5)]);
        expect(bar.dotData.checkToShowDot(bar.spots.single, bar), isTrue);
      }
    },
  );

  testWidgets('preserves calendar distance across months of missing data', (
    tester,
  ) async {
    await pumpChart(
      tester,
      weight: [point(1, 80), point(350, 76)],
      calories: [point(361, 2300), point(10, 2100)],
      endOffset: 365,
    );

    final data = chartData(tester);
    expect(data.maxX, 365);
    expect(data.lineBarsData.first.spots.map((spot) => spot.x), [1, 350]);
    expect(data.lineBarsData.last.spots.map((spot) => spot.x), [10, 361]);

    final center = tester.getCenter(find.byType(LineChart));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await mouse.moveTo(center);
    await tester.pumpAndSettle();
    expect(find.textContaining('Calories (kcal):'), findsNothing);
    expect(find.textContaining('Weight (kg):'), findsNothing);
    await mouse.removePointer();
  });

  testWidgets(
    'rebuilds after an incomplete day is toggled and the range changes',
    (tester) async {
      final calories = [point(2, 2000), point(4, 2200), point(6, 2400)];
      await pumpChart(tester, weight: [], calories: calories);
      final center = tester.getCenter(find.byType(LineChart));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: center);
      await mouse.moveTo(center);
      await tester.pumpAndSettle();
      expect(find.text('Calories (kcal): 2,200 kcal'), findsOneWidget);

      await pumpChart(
        tester,
        weight: [],
        calories: calories,
        incompleteDays: {day(4)},
      );
      expect(
        chartData(tester).lineBarsData.single.spots.map((spot) => spot.x),
        [2, 6],
      );
      expect(find.textContaining('Calories (kcal):'), findsNothing);

      await pumpChart(
        tester,
        weight: [],
        calories: calories,
        startOffset: 2,
        endOffset: 6,
      );
      expect(
        chartData(tester).lineBarsData.single.spots.map((spot) => spot.x),
        [0, 2, 4],
      );
      expect(find.textContaining('Calories (kcal):'), findsNothing);
      await mouse.removePointer();
    },
  );

  testWidgets('tooltip values belong to the selected date', (tester) async {
    await pumpChart(
      tester,
      weight: [point(30, 80), point(31, 80)],
      calories: [point(31, 2200)],
      endOffset: 60,
    );
    final rect = tester.getRect(find.byType(LineChart));
    Offset position(int x) =>
        Offset(rect.left + rect.width * x / 60, rect.center.dy);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: position(30));
    await mouse.moveTo(position(30));
    await tester.pumpAndSettle();

    expect(find.text('Weight (kg): 80.0 kg'), findsOneWidget);
    expect(find.text('Calories (kcal): 2,200 kcal'), findsNothing);

    await mouse.moveTo(position(31));
    await tester.pumpAndSettle();
    expect(find.text('Weight (kg): 80.0 kg'), findsOneWidget);
    expect(find.text('Calories (kcal): 2,200 kcal'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets(
    'a mobile long press tracks recorded points and clears on release',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pumpChart(
        tester,
        weight: [point(4, 80)],
        calories: [point(4, 2200), point(6, 2400)],
        incompleteDays: {day(5)},
      );
      final rect = tester.getRect(find.byType(LineChart));
      Offset position(int x) =>
          Offset(rect.left + rect.width * x / 8, rect.center.dy);
      final touch = await tester.startGesture(position(4));
      await tester.pump(kLongPressTimeout);
      expect(find.text('Calories (kcal): 2,200 kcal'), findsOneWidget);
      expect(find.text('Weight (kg): 80.0 kg'), findsOneWidget);

      await touch.moveTo(position(5));
      await tester.pump();
      expect(find.textContaining('Calories (kcal):'), findsNothing);

      await touch.moveTo(position(6));
      await tester.pump();
      expect(find.text('Calories (kcal): 2,400 kcal'), findsOneWidget);
      expect(find.textContaining('Weight (kg):'), findsNothing);

      await touch.up();
      await tester.pumpAndSettle();
      expect(find.textContaining('Calories (kcal):'), findsNothing);
    },
  );
}
