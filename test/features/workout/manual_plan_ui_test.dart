import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/models/manual_training_plan.dart';
import 'package:train_libre/features/workout/presentation/manual_plan_editor_screen.dart';
import 'package:train_libre/features/workout/presentation/widgets/manual_plan_ui.dart';
import 'package:train_libre/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('de')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('week strip focuses a day without duplicating day content',
      (tester) async {
    final start = DateTime(2026, 9, 21);
    final dates = List.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
    final days = <DateTime, PlannedCalendarDay>{
      for (var index = 0; index < dates.length; index++)
        dates[index]: PlannedCalendarDay(
          date: dates[index],
          slotIndex: index,
          day: const TrainingPlanDay(),
          status: PlannedDayStatus.rest,
        ),
    };
    DateTime? selected;

    await tester.pumpWidget(_app(
      Padding(
        padding: const EdgeInsets.all(16),
        child: PlanWeekStrip(
          dates: dates,
          days: days,
          selectedDate: dates.first,
          nextDate: dates[3],
          onSelected: (date) => selected = date,
        ),
      ),
    ));

    expect(find.byType(PlanWeekStrip), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);

    await tester.tap(find.text('24'));
    expect(selected, dates[3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero keeps the primary workout action explicit', (tester) async {
    var starts = 0;
    await tester.pumpWidget(_app(
      Padding(
        padding: const EdgeInsets.all(16),
        child: WorkoutPlanHeroCard(
          eyebrow: 'Push Pull Legs',
          title: 'Push',
          subtitle: '5 Übungen • 17 Sätze',
          status: PlannedDayStatus.planned,
          actionLabel: 'Workout starten',
          onAction: () => starts++,
        ),
      ),
    ));

    expect(find.text('PUSH PULL LEGS'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    await tester.tap(find.text('Workout starten'));
    await tester.pump();
    expect(starts, 1);
  });

  testWidgets('plan editor exposes direct sequence building controls',
      (tester) async {
    await tester.pumpWidget(_app(const ManualPlanEditorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Wochenplan'), findsOneWidget);
    expect(find.text('Sequenz'), findsOneWidget);
    expect(find.text('Speichern und aktivieren'), findsOneWidget);

    await tester.tap(find.text('Sequenz'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tag hinzufügen'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Tag hinzufügen'), findsOneWidget);
    expect(find.text('3/14 Tage'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsOneWidget);

    await tester.tap(find.text('Tag hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('4/14 Tage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact plan card tolerates large accessibility text',
      (tester) async {
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: WorkoutPlanHeroCard(
              compact: true,
              eyebrow: 'Sehr langer Name eines Trainingsplans',
              title: 'Sehr lange benannte Oberkörpereinheit',
              subtitle: 'Viele Übungen und Sätze in dieser Einheit',
              status: PlannedDayStatus.partial,
            ),
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });
}
