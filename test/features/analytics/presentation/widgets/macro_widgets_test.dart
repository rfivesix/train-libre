import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/analytics/presentation/widgets/macro_history_stacked_bar_chart.dart';
import 'package:train_libre/features/analytics/presentation/widgets/macro_section_card.dart';
import 'package:train_libre/features/statistics/data/macro_analytics_data_adapter.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets('MacroHistoryStackedBarChart renders properly', (tester) async {
    final now = DateTime(2026, 4, 10);
    final days = List.generate(5, (i) {
      final date = now.subtract(Duration(days: 4 - i));
      return DailyMacroIntake(
        date: date,
        calories: 1800 + (i * 100),
        proteinGrams: 140.0,
        carbsGrams: 180.0,
        fatGrams: 50.0,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MacroHistoryStackedBarChart(
              dailyIntakes: days,
              range: DateTimeRange(
                start: now.subtract(const Duration(days: 4)),
                end: now,
              ),
              chartHeight: 250,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MacroHistoryStackedBarChart), findsOneWidget);
  });

  testWidgets('MacroSectionCard renders with empty data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MacroSectionCard(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MacroSectionCard), findsOneWidget);
  });
}
