import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/canonical_scenarios.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/nutrition_sandbox_state.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/profile/presentation/weekly_goal_review_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/widgets/common/value_summary_card.dart';

final _start = DateTime(2026, 9, 27);
final _end = DateTime(2026, 10, 4);

Goal _goal() => Goal(
      id: 'sandbox-goal',
      preset: GoalPreset.loseWeight,
      title: 'Sandbox goal',
      status: GoalStatus.active,
      startDate: DateTime(2026, 1, 1),
      targetDate: DateTime(2026, 12, 1),
      targetMetric: 'weight',
      targetValue: 75,
      targetUnit: 'kg',
      desiredWeeklyRateKg: -0.5,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

GoalReviewRecord _review({
  required String action,
  String status = 'behind',
  String momentum = 'unclear',
  int weighIns = 1,
  int loggedDays = 2,
  int currentCalories = 2100,
  int? recommendedCalories,
}) {
  return GoalReviewRecord(
    id: 'sandbox-review',
    goalId: 'sandbox-goal',
    windowStart: _start,
    windowEnd: _end,
    trajectoryStatus: status,
    observedRateKgPerWeek: -0.2,
    recommendedCalories: recommendedCalories,
    recommendedProtein: recommendedCalories == null ? null : 150,
    recommendedCarbs: recommendedCalories == null ? null : 180,
    recommendedFat: recommendedCalories == null ? null : 60,
    algorithmVersion: 'test',
    assessment: GoalReviewAssessment(
      overallStatus: status,
      recentMomentumStatus: momentum,
      expectedValue: 80,
      currentSmoothedValue: 81,
      trajectoryGap: 1,
      plannedRateKgPerWeek: -0.5,
      requiredRemainingRateKgPerWeek: -0.7,
      weightObservationCount: weighIns,
      nutritionLoggedDays: loggedDays,
      currentCalories: currentCalories,
      dataQuality:
          action == 'insufficient_data' ? 'insufficient' : 'sufficient',
      nutritionAction: action,
    ),
    createdAt: _end,
  );
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required GoalReviewRecord review,
}) async {
  final unitService = UnitService();
  await tester.pumpWidget(
    ChangeNotifierProvider<UnitService>.value(
      value: unitService,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WeeklyGoalReviewScreen(
          goal: _goal(),
          review: review,
          previewOnly: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows both primary outcomes; details stay collapsed',
      (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPreview(
      tester,
      review: _review(
        action: 'adjust_targets',
        weighIns: 5,
        loggedDays: 7,
        recommendedCalories: 1950,
      ),
    );
    expect(tester.takeException(), isNull);

    expect(find.text('DAILY CALORIE TARGET'), findsOneWidget);
    expect(find.text('2,100 kcal'), findsOneWidget);
    expect(find.text('1,950 kcal'), findsOneWidget);
    expect(find.text('-150 kcal/day'), findsOneWidget);
    expect(find.text('WEIGHT GOAL PROGRESS'), findsOneWidget);
    expect(find.text('Planned by now'), findsOneWidget);
    expect(find.text('Recent trend'), findsOneWidget);
    expect(find.text('Adjust weekly rate'), findsOneWidget);
    expect(find.text('Change target date'), findsOneWidget);
    expect(find.text('PROGRESS DETAILS'), findsOneWidget);
    expect(find.text('Plan vs. reality'), findsNothing);
    expect(find.text('Apply targets'), findsOneWidget);
    expect(find.text('Keep goal'), findsOneWidget);
    expect(find.byType(ValueSummaryCard), findsNWidgets(4));

    final recommendedCard =
        find.widgetWithText(ValueSummaryCard, 'Recommended');
    expect(recommendedCard, findsOneWidget);
    expect(
      find.descendant(
        of: recommendedCard,
        matching: find.text('-150 kcal/day'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<ValueSummaryCard>(recommendedCard).borderColor,
      isNotNull,
    );

    final caloriesY = tester.getTopLeft(find.text('DAILY CALORIE TARGET')).dy;
    final progressY = tester.getTopLeft(find.text('WEIGHT GOAL PROGRESS')).dy;
    final detailsY = tester.getTopLeft(find.text('PROGRESS DETAILS')).dy;
    expect(progressY, lessThan(caloriesY));
    expect(caloriesY, lessThan(detailsY));

    await tester.tap(find.text('PROGRESS DETAILS'));
    await tester.pumpAndSettle();
    expect(find.text('Plan vs. reality'), findsOneWidget);
  });

  testWidgets('insufficient data offers continue logging without applying',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPreview(
      tester,
      review: _review(
        action: 'insufficient_data',
        recommendedCalories: 1800,
      ),
    );

    expect(find.text('Continue logging'), findsOneWidget);
    expect(find.text('DAILY CALORIE TARGET'), findsOneWidget);
    expect(find.text('2,100 kcal'), findsOneWidget);
    expect(find.text('1,800 kcal'), findsNothing);
    expect(find.text('Apply targets'), findsNothing);
    expect(find.text('Keep goal'), findsNothing);
    expect(find.text('1 / 3'), findsNothing);

    await tester.tap(find.text('Continue logging'));
    await tester.pumpAndSettle();
    expect(
        find.text('Sandbox preview: no changes were saved.'), findsOneWidget);
  });

  for (final scenario in CanonicalNutritionScenarios.all) {
    testWidgets('renders ${scenario.id} with its matching decision',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sandbox = NutritionSandboxState();
      scenario.applyToSandbox(sandbox);
      final review = sandbox.buildSyntheticReviewRecord();
      await _pumpPreview(tester, review: review);

      expect(find.text('DAILY CALORIE TARGET'), findsOneWidget);
      expect(find.text('WEIGHT GOAL PROGRESS'), findsOneWidget);
      expect(find.text('PROGRESS DETAILS'), findsOneWidget);
      expect(find.text('Plan vs. reality'), findsNothing);

      switch (scenario.expectedAction) {
        case 'insufficient_data':
          expect(find.text('Continue logging'), findsOneWidget);
          expect(find.text('Apply targets'), findsNothing);
          break;
        case 'trajectory_change_needed':
          expect(find.text('Adjust weekly rate'), findsOneWidget);
          expect(find.text('Change target date'), findsOneWidget);
          expect(find.text('Apply targets'), findsNothing);
          break;
        case 'adjust_targets':
          expect(find.text('Apply targets'), findsOneWidget);
          break;
        default:
          expect(find.text('Keep goal'), findsOneWidget);
          break;
      }

      await tester.tap(find.text('PROGRESS DETAILS'));
      await tester.pumpAndSettle();
      expect(find.text('Plan vs. reality'), findsOneWidget);
    });
  }
}
