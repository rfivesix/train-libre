import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';
import 'package:train_libre/features/profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:train_libre/generated/app_localizations.dart';

/// fl_chart materialises one widget per step between minX and maxX. The chart
/// used to pin `interval: 1`, so a `time`-mode axis asked for a widget per
/// minute — a month-wide range built tens of thousands of them on every frame
/// and blocked the UI isolate for seconds.
void main() {
  Future<void> pumpChart(
    WidgetTester tester, {
    required List<ChartDataPoint> points,
    required MeasurementChartAxisMode axisMode,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MeasurementChartWidget.fromData(
          dataPoints: points,
          unit: '%',
          axisMode: axisMode,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a month-wide time axis stays at a handful of labels',
      (tester) async {
    final start = DateTime(2024, 1, 1);
    final points = List.generate(
      4,
      (i) => ChartDataPoint(
        date: start.add(Duration(days: i * 10)),
        value: 15.0 + i,
      ),
    );

    await pumpChart(tester,
        points: points, axisMode: MeasurementChartAxisMode.time);

    // Every axis step becomes a widget — a drawn `SideTitleWidget` or the
    // `SizedBox.shrink()` the builder returns for a skipped step. With
    // `interval: 1` this range produced ~43k of the latter.
    expect(find.byType(SideTitleWidget), findsAtLeastNWidgets(1));
    expect(tester.widgetList(find.byType(SizedBox)).length, lessThan(100));
  });

  testWidgets('a multi-year day axis stays at a handful of labels',
      (tester) async {
    final start = DateTime(2020, 1, 1);
    final points = List.generate(
      6,
      (i) => ChartDataPoint(
        date: start.add(Duration(days: i * 200)),
        value: 80.0 - i,
      ),
    );

    await pumpChart(tester,
        points: points, axisMode: MeasurementChartAxisMode.day);

    expect(find.byType(SideTitleWidget), findsAtLeastNWidgets(1));
    expect(tester.widgetList(find.byType(SizedBox)).length, lessThan(100));
  });
}
