import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/nutrition_recommendation/presentation/widgets/weekly_intake_vs_target_chart.dart';
import 'package:train_libre/features/statistics/data/macro_analytics_data_adapter.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets('renders WeeklyIntakeVsTargetChart with 7 days and target bar',
      (tester) async {
    final now = DateTime(2026, 4, 10);
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DailyMacroIntake(
        date: date,
        calories: 2000 + (i * 50),
        proteinGrams: 150.0,
        carbsGrams: 200.0,
        fatGrams: 60.0,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeeklyIntakeVsTargetChart(
              dailyIntakes: days,
              targetCalories: 2750,
              targetProtein: 160,
              targetCarbs: 220,
              targetFat: 65,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widget builds without crashing
    expect(find.byType(WeeklyIntakeVsTargetChart), findsOneWidget);

    // Verify Target bar label text is displayed (Ziel)
    expect(find.text('Ziel'), findsOneWidget);

    // Verify target calorie badge is displayed
    expect(find.text('2750'), findsOneWidget);
  });

  testWidgets('handles empty or fewer than 7 days gracefully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeeklyIntakeVsTargetChart(
              dailyIntakes: [],
              targetCalories: 2000,
              targetProtein: 150,
              targetCarbs: 200,
              targetFat: 60,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(WeeklyIntakeVsTargetChart), findsOneWidget);
    expect(find.text('Ziel'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
  });
}
