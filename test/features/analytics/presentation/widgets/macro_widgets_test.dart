import 'package:material_ui/material_ui.dart';
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

  testWidgets(
    'MacroHistoryStackedBarChart triggers onDaySelected when bar tapped',
    (tester) async {
      final now = DateTime(2026, 4, 10);
      DailyMacroIntake? selected;
      final days = [
        DailyMacroIntake(
          date: now,
          calories: 2000,
          proteinGrams: 150,
          carbsGrams: 200,
          fatGrams: 60,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MacroHistoryStackedBarChart(
              dailyIntakes: days,
              range: DateTimeRange(start: now, end: now),
              onDaySelected: (day) => selected = day,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gestureFinder = find.byType(GestureDetector);
      expect(gestureFinder, findsWidgets);
      await tester.tap(gestureFinder.first);
      expect(selected, isNotNull);
      expect(selected?.calories, 2000);
    },
  );

  testWidgets('MacroSectionCard renders with empty data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: MacroSectionCard())),
      ),
    );

    await tester.pump();

    expect(find.byType(MacroSectionCard), findsOneWidget);
  });

  testWidgets(
    'MacroHistoryStackedBarChart renders visible bars for 1Y (365 days) timeframe',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final start = DateTime(2026, 1, 1);
      final days = List.generate(365, (i) {
        final date = DateTime(start.year, start.month, start.day + i);
        // Simulate 4 tracked days around May/June
        final isTracked = date.month == 6 && date.day >= 1 && date.day <= 4;
        return DailyMacroIntake(
          date: date,
          calories: isTracked ? 2800 : 0,
          proteinGrams: isTracked ? 180.0 : 0.0,
          carbsGrams: isTracked ? 300.0 : 0.0,
          fatGrams: isTracked ? 90.0 : 0.0,
        );
      });

      DailyMacroIntake? selected;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MacroHistoryStackedBarChart(
              dailyIntakes: days,
              range: DateTimeRange(start: start, end: DateTime(2026, 12, 31)),
              is7Days: false,
              selectedDay: selected,
              onDaySelected: (day) => selected = day,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final barFinder = find.byType(ClipRRect);
      expect(barFinder, findsAtLeastNWidgets(1));
      final barSize = tester.getSize(barFinder.first);
      expect(barSize.width, greaterThan(2.0));
      expect(barSize.height, greaterThan(10.0));

      // Tapping the tracked bar triggers selection
      await tester.tap(barFinder.first);
      await tester.pumpAndSettle();
      expect(selected, isNotNull);
      expect(selected!.calories, 2800);
    },
  );

  testWidgets(
    'MacroHistoryStackedBarChart renders visible bars for multi-year MAX timeframe',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final start = DateTime(2023, 1, 1);
      final days = List.generate(1200, (i) {
        final date = DateTime(start.year, start.month, start.day + i);
        final isTracked = i % 3 == 0;
        return DailyMacroIntake(
          date: date,
          calories: isTracked ? 2500 : 0,
          proteinGrams: isTracked ? 160.0 : 0.0,
          carbsGrams: isTracked ? 260.0 : 0.0,
          fatGrams: isTracked ? 80.0 : 0.0,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MacroHistoryStackedBarChart(
              dailyIntakes: days,
              range: DateTimeRange(start: start, end: days.last.date),
              is7Days: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final barFinder = find.byType(ClipRRect);
      expect(barFinder, findsAtLeastNWidgets(10));
      final barSize = tester.getSize(barFinder.first);
      expect(barSize.width, greaterThan(2.0));
      expect(barSize.height, greaterThan(10.0));
    },
  );

  testWidgets(
    'MacroHistoryStackedBarChart handles single day with is7Days false',
    (tester) async {
      final day = DateTime(2026, 6, 1);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MacroHistoryStackedBarChart(
              dailyIntakes: [
                DailyMacroIntake(
                  date: day,
                  calories: 2200,
                  proteinGrams: 150,
                  carbsGrams: 220,
                  fatGrams: 70,
                ),
              ],
              range: DateTimeRange(start: day, end: day),
              is7Days: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ClipRRect), findsOneWidget);
    },
  );
}
