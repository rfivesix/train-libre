import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:drift/native.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/manual_training_plan_repository.dart';
import 'package:train_libre/features/workout/domain/models/manual_training_plan.dart';
import 'package:train_libre/features/workout/presentation/manual_plan_editor_screen.dart';
import 'package:train_libre/features/workout/presentation/manual_plan_screen.dart';
import 'package:train_libre/features/workout/presentation/widgets/manual_plan_ui.dart';
import 'package:train_libre/widgets/common/empty_states/cold_start_empty_state.dart';
import 'package:train_libre/widgets/common/glass_fab.dart';
import 'package:train_libre/widgets/common/summary_card.dart';
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

    expect(find.text('Push Pull Legs'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.byIcon(LucideIcons.play), findsNothing);
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

  testWidgets('plan overview shows the complete sequence and active step',
      (tester) async {
    final plan = ManualTrainingPlan(
      id: 'plan',
      name: 'Four day sequence',
      kind: TrainingPlanKind.sequence,
      days: const [
        TrainingPlanDay(routineSnapshot: {'name': 'Upper'}),
        TrainingPlanDay(),
        TrainingPlanDay(routineSnapshot: {'name': 'Lower'}),
        TrainingPlanDay(),
      ],
      revisionId: 'revision',
      revisionNumber: 1,
      active: true,
    );
    await tester.pumpWidget(_app(
      Padding(
        padding: const EdgeInsets.all(16),
        child: PlanScheduleOverviewGrid(
          plan: plan,
          activeSlotIndex: 2,
        ),
      ),
    ));

    expect(
        find.byKey(const Key('plan_schedule_overview_grid')), findsOneWidget);
    expect(find.text('Tag 1'), findsOneWidget);
    expect(find.text('Tag 4'), findsOneWidget);
    expect(find.text('Upper'), findsOneWidget);
    expect(find.text('Lower'), findsOneWidget);
    expect(find.text('Ruhetag'), findsNWidgets(2));
    expect(
      tester.getSemantics(find.text('Lower')).label,
      contains('Als Nächstes'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('plan overview renders every weekday for weekly plans',
      (tester) async {
    final plan = ManualTrainingPlan(
      id: 'plan',
      name: 'Week',
      kind: TrainingPlanKind.week,
      days: const [
        TrainingPlanDay(routineSnapshot: {'name': 'Push'}),
        TrainingPlanDay(),
        TrainingPlanDay(routineSnapshot: {'name': 'Pull'}),
        TrainingPlanDay(),
        TrainingPlanDay(routineSnapshot: {'name': 'Legs'}),
        TrainingPlanDay(),
        TrainingPlanDay(),
      ],
      revisionId: 'revision',
      revisionNumber: 1,
      active: true,
    );

    await tester.pumpWidget(_app(
      PlanScheduleOverviewGrid(
        plan: plan,
        activeSlotIndex: 0,
      ),
    ));

    expect(
      find.text(DateFormat.E('de').format(DateTime(2026, 9, 21))),
      findsOneWidget,
    );
    expect(
      find.text(DateFormat.E('de').format(DateTime(2026, 9, 27))),
      findsOneWidget,
    );
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed plan days expose their saved workout details',
      (tester) async {
    final plan = ManualTrainingPlan(
      id: 'plan',
      name: 'Plan',
      kind: TrainingPlanKind.sequence,
      days: const [
        TrainingPlanDay(routineSnapshot: {
          'name': 'Upper',
          'exercises': [],
        }),
      ],
      revisionId: 'revision',
      revisionNumber: 1,
      active: true,
    );
    var viewed = 0;

    await tester.pumpWidget(_app(
      PlanDayDetailCard(
        plan: plan,
        day: PlannedCalendarDay(
          date: DateTime(2026, 9, 26),
          slotIndex: 0,
          day: TrainingPlanDay(routineSnapshot: {
            'name': 'Upper',
            'exercises': [],
          }),
          status: PlannedDayStatus.completed,
          workoutLogId: 42,
        ),
        onViewWorkout: () => viewed++,
      ),
    ));

    expect(find.text('Workout ansehen'), findsOneWidget);
    expect(find.textContaining('This session is planned'), findsNothing);
    await tester.tap(find.text('Workout ansehen'));
    expect(viewed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'PlanOverviewCard renders directly on background and triggers onEdit on tile tap',
      (tester) async {
    final plan = ManualTrainingPlan(
      id: 'plan',
      name: 'Upper Lower Sequence',
      kind: TrainingPlanKind.sequence,
      days: const [
        TrainingPlanDay(routineSnapshot: {'name': 'Upper'}),
        TrainingPlanDay(),
        TrainingPlanDay(routineSnapshot: {'name': 'Lower'}),
        TrainingPlanDay(),
      ],
      revisionId: 'revision',
      revisionNumber: 1,
      active: true,
    );

    var editTriggered = false;

    await tester.pumpWidget(_app(
      Padding(
        padding: const EdgeInsets.all(16),
        child: PlanOverviewCard(
          plan: plan,
          activeSlotIndex: 0,
          onEdit: (ctx) => editTriggered = true,
        ),
      ),
    ));

    expect(find.byKey(const Key('manual_plan_overview_card')), findsOneWidget);
    // Overview is rendered directly on background without title or separate pencil button:
    expect(find.text('Planübersicht'), findsNothing);
    expect(find.byKey(const Key('manual_plan_overview_edit_button')),
        findsNothing);
    expect(find.text('Upper'), findsOneWidget);
    expect(find.text('Ruhetag'), findsNWidgets(2));

    await tester.tap(find.text('Upper'));
    await tester.pump();
    expect(editTriggered, isTrue);
  });

  testWidgets(
      'ManualPlanScreen displays ColdStartEmptyState with GlassFab when no plans exist',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ManualTrainingPlanRepository(database: db);

    await tester.pumpWidget(_app(ManualPlanScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.byType(ColdStartEmptyState), findsOneWidget);
    expect(find.byType(GlassFab), findsOneWidget);
    // When empty, top app bar actions (+ button) should be omitted
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  testWidgets(
      'hero card eyebrow uses muted onSurfaceVariant without green accent',
      (tester) async {
    await tester.pumpWidget(_app(
      Padding(
        padding: const EdgeInsets.all(16),
        child: WorkoutPlanHeroCard(
          eyebrow: 'Hypertrophy Focus',
          title: 'Upper Body',
          subtitle: '4 Übungen',
        ),
      ),
    ));

    final textWidget = tester.widget<Text>(find.text('Hypertrophy Focus'));
    expect(textWidget.style?.color, isNot(equals(Colors.green)));
    expect(find.text('HYPERTROPHY FOCUS'), findsNothing);
  });

  testWidgets(
      'plan version history sheet cards render with uniform full width',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ManualTrainingPlanRepository(database: db);

    const workoutA = TrainingPlanDay(routineSnapshot: {
      'id': 1,
      'name': 'Long Routine Name That Wraps Multiple Times',
      'exercises': [],
    });
    const workoutB = TrainingPlanDay(routineSnapshot: {
      'id': 2,
      'name': 'B',
      'exercises': [],
    });

    final id = await repo.createPlan(
      name: 'Plan With Revisions',
      kind: TrainingPlanKind.week,
      days: [
        workoutB,
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
      ],
    );
    await repo.revisePlan(
      planId: id,
      name: 'Plan With Revisions',
      kind: TrainingPlanKind.week,
      days: [
        workoutA,
        workoutB,
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
        const TrainingPlanDay(),
      ],
      nextCycle: false,
    );

    await tester.pumpWidget(_app(ManualPlanScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.ellipsis), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Versionen'));
    await tester.pumpAndSettle();

    expect(find.text('Version 2'), findsOneWidget);
    expect(find.text('Version 1'), findsOneWidget);

    final v2Rect =
        tester.getRect(find.widgetWithText(SummaryCard, 'Version 2'));
    final v1Rect =
        tester.getRect(find.widgetWithText(SummaryCard, 'Version 1'));

    expect(v1Rect.width, equals(v2Rect.width));
  });
}
