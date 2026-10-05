import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';
import 'package:train_libre/features/profile/presentation/widgets/measurement_chart_widget.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  testWidgets(
      'renders ghost line and smoothed line when smoothWeightTrend is enabled',
      (tester) async {
    final start = DateTime(2026, 1, 1);
    final points = [
      ChartDataPoint(date: start, value: 85.0),
      ChartDataPoint(date: start.add(const Duration(days: 1)), value: 84.0),
      ChartDataPoint(date: start.add(const Duration(days: 2)), value: 86.0),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<UnitService>.value(
        value: UnitService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MeasurementChartWidget.fromData(
              dataPoints: points,
              unit: 'kg',
              axisMode: MeasurementChartAxisMode.day,
              smoothWeightTrend: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lineChart = tester.widget<LineChart>(find.byType(LineChart));
    // 2 lines: ghost line (index 0) + smoothed line (index 1)
    expect(lineChart.data.lineBarsData.length, 2);

    final rawLine = lineChart.data.lineBarsData[0];
    final smoothedLine = lineChart.data.lineBarsData[1];

    expect(rawLine.barWidth, smoothedLine.barWidth);
    expect(rawLine.isCurved, true);
    // Dots are hidden when untouched
    expect(rawLine.dotData.checkToShowDot(rawLine.spots[0], rawLine), false);

    expect(smoothedLine.isCurved, true);
    expect(smoothedLine.belowBarData.show, true);
    // Header shows latest raw measured value
    expect(find.text('86.0 kg'), findsOneWidget);
  });

  testWidgets(
      'renders single line when smoothing is disabled or only 1 point exists',
      (tester) async {
    final start = DateTime(2026, 1, 1);
    final points = [
      ChartDataPoint(date: start, value: 85.0),
      ChartDataPoint(date: start.add(const Duration(days: 1)), value: 84.0),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<UnitService>.value(
        value: UnitService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MeasurementChartWidget.fromData(
              dataPoints: points,
              unit: 'kg',
              axisMode: MeasurementChartAxisMode.day,
              smoothWeightTrend: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lineChart = tester.widget<LineChart>(find.byType(LineChart));
    expect(lineChart.data.lineBarsData.length, 1);
  });
}
