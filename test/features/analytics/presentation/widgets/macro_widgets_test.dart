import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/analytics/presentation/macro_statistics_screen.dart';
import 'package:train_libre/features/analytics/presentation/widgets/macro_history_stacked_bar_chart.dart';
import 'package:train_libre/features/analytics/presentation/widgets/macro_section_card.dart';
import 'package:train_libre/features/statistics/data/macro_analytics_data_adapter.dart';
import 'package:train_libre/features/statistics/domain/timeframe_block.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
import 'package:train_libre/services/haptic_feedback_service.dart';

class _FakeMacroAnalyticsDataAdapter extends MacroAnalyticsDataAdapter {
  const _FakeMacroAnalyticsDataAdapter(this.summary);

  final MacroPeriodSummary summary;

  @override
  Future<MacroPeriodSummary> fetchSummary({required DateTimeRange range}) async {
    return summary;
  }
}

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

  testWidgets(
    'MacroHistoryStackedBarChart emits lightImpact haptics when scrubbing across valid bars and respects haptic setting',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final hapticCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add('${call.arguments}');
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        HapticFeedbackService.instance.setEnabled(true);
      });

      HapticFeedbackService.instance.setEnabled(true);

      final start = DateTime(2026, 6, 1);
      final days = [
        DailyMacroIntake(
          date: start,
          calories: 2100,
          proteinGrams: 150,
          carbsGrams: 200,
          fatGrams: 70,
        ),
        DailyMacroIntake(
          date: start.add(const Duration(days: 1)),
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          isIncomplete: true,
        ),
        DailyMacroIntake(
          date: start.add(const Duration(days: 2)),
          calories: 2450,
          proteinGrams: 165,
          carbsGrams: 250,
          fatGrams: 80,
        ),
        DailyMacroIntake(
          date: start.add(const Duration(days: 3)),
          calories: 1850,
          proteinGrams: 130,
          carbsGrams: 180,
          fatGrams: 60,
        ),
      ];

      DailyMacroIntake? selected;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MacroHistoryStackedBarChart(
                  dailyIntakes: days,
                  range: DateTimeRange(start: start, end: days.last.date),
                  is7Days: false,
                  selectedDay: selected,
                  onDaySelected: (day) => setState(() => selected = day),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gestureFinder = find.byType(GestureDetector);
      final rect = tester.getRect(gestureFinder.first);
      final barWidth = rect.width / days.length;
      final centerY = rect.center.dy;

      // Start long-press on bar 0 -> 1 haptic
      final gesture = await tester.startGesture(
        Offset(rect.left + barWidth * 0.5, centerY),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(hapticCalls, ['HapticFeedbackType.lightImpact']);
      expect(selected?.calories, 2100);

      // Slight move inside bar 0 -> no extra haptic
      await gesture.moveTo(Offset(rect.left + barWidth * 0.6, centerY));
      await tester.pump();
      expect(hapticCalls.length, 1);

      // Move onto incomplete bar 1 -> no haptic, selection cleared
      await gesture.moveTo(Offset(rect.left + barWidth * 1.5, centerY));
      await tester.pump();
      expect(hapticCalls.length, 1);
      expect(selected, isNull);

      // Move onto valid bar 2 -> 1 more haptic
      await gesture.moveTo(Offset(rect.left + barWidth * 2.5, centerY));
      await tester.pump();
      expect(hapticCalls.length, 2);
      expect(selected?.calories, 2450);

      // Move onto valid bar 3 -> 1 more haptic
      await gesture.moveTo(Offset(rect.left + barWidth * 3.5, centerY));
      await tester.pump();
      expect(hapticCalls.length, 3);
      expect(selected?.calories, 1850);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, isNull);

      // Respect disabled haptics setting
      hapticCalls.clear();
      HapticFeedbackService.instance.setEnabled(false);
      await tester.tapAt(Offset(rect.left + barWidth * 0.5, centerY));
      await tester.pumpAndSettle();
      expect(selected?.calories, 2100);
      expect(hapticCalls, isEmpty);
    },
  );

  testWidgets(
    'MacroStatisticsScreen keeps Calories KPI card height constant when scrubbing across varying digit lengths',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final start = DateTime(2026, 6, 1);
      final caloriesByIndex = [0, 850, 2450, 12450, 500, 3100];
      final days = List.generate(30, (i) {
        final cals = caloriesByIndex[i % caloriesByIndex.length];
        return DailyMacroIntake(
          date: start.add(Duration(days: i)),
          calories: cals,
          proteinGrams: cals > 0 ? 150.0 : 0.0,
          carbsGrams: cals > 0 ? 220.0 : 0.0,
          fatGrams: cals > 0 ? 70.0 : 0.0,
        );
      });
      final summary = MacroPeriodSummary(
        range: DateTimeRange(start: start, end: days.last.date),
        dailyIntakes: days,
        avgCalories: 2350,
        avgProtein: 145,
        avgCarbs: 210,
        avgFat: 68,
        totalDays: 30,
        trackedDays: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MacroStatisticsScreen(
            initialBlock: TimeframeBlock.month,
            adapter: _FakeMacroAnalyticsDataAdapter(summary),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Finder caloriesCardFinder() => find.ancestor(
        of: find.text('kcal'),
        matching: find.byType(Container),
      ).first;

      final baselineHeight = tester.getSize(caloriesCardFinder()).height;

      final chartGesture = find.descendant(
        of: find.byType(MacroHistoryStackedBarChart),
        matching: find.byType(GestureDetector),
      );
      final rect = tester.getRect(chartGesture.first);
      final barWidth = rect.width / days.length;
      final centerY = rect.center.dy;

      // Scrub across bars with 0, 850, 2450, 12450 kcal
      final gesture = await tester.startGesture(
        Offset(rect.left + barWidth * 0.5, centerY),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getSize(caloriesCardFinder()).height, baselineHeight);

      for (int i = 1; i < 6; i++) {
        await gesture.moveTo(Offset(rect.left + barWidth * (i + 0.5), centerY));
        await tester.pump();
        expect(
          tester.getSize(caloriesCardFinder()).height,
          baselineHeight,
          reason: 'Calories card height shifted at bar index $i (${caloriesByIndex[i]} kcal)',
        );
      }

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(caloriesCardFinder()).height, baselineHeight);
    },
  );
}
