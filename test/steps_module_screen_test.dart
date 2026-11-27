import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:train_libre/features/steps/data/steps_aggregation_repository.dart';
import 'package:train_libre/features/steps/presentation/statistics_steps_card.dart';
import 'package:train_libre/features/steps/presentation/steps_module_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets(
    'shows one total for the selected period without the entry card',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const repository = InMemoryStepsAggregationRepository();
      final date = DateTime(2026, 11, 16);
      final format = NumberFormat.decimalPattern('en');
      final day = await repository.getDayAggregation(date);
      final week = await repository.getWeekAggregation(date);
      final month = await repository.getMonthAggregation(date);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StepsModuleScreen(repository: repository, initialDate: date),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hourly Timeline'), findsOneWidget);
      expect(find.text(format.format(day.totalSteps)), findsOneWidget);
      expect(find.text('Total Steps'), findsOneWidget);
      expect(find.byType(StatisticsStepsCard), findsNothing);

      await tester.ensureVisible(find.text('7D'));
      await tester.tap(find.text('7D'));
      await tester.pumpAndSettle();

      expect(find.text('Hourly Timeline'), findsNothing);
      expect(find.text(format.format(week.totalSteps)), findsOneWidget);
      expect(find.text('Total Steps'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.byType(StatisticsStepsCard), findsNothing);

      await tester.ensureVisible(find.text('1M'));
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      expect(find.text(format.format(month.totalSteps)), findsOneWidget);
      expect(find.text('Total Steps'), findsOneWidget);
      expect(find.byType(StatisticsStepsCard), findsNothing);
      expect(
        find.descendant(of: find.byType(GridView), matching: find.text('16')),
        findsOneWidget,
      );
    },
  );
}
