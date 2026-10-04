import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/profile/presentation/widgets/adaptive_review_card.dart';
import 'package:train_libre/generated/app_localizations.dart';

Goal _goal() => Goal(
      id: 'goal-1',
      preset: GoalPreset.loseWeight,
      title: 'Weight goal',
      status: GoalStatus.active,
      startDate: DateTime(2026, 1, 1),
      targetDate: DateTime(2026, 6, 1),
      targetMetric: 'weight',
      targetValue: 75,
      targetUnit: 'kg',
      desiredWeeklyRateKg: -0.5,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

GoalReviewRecord _review({
  required String status,
  required String momentum,
  int? recommendedCalories,
}) {
  final assessment = GoalReviewAssessment(
    overallStatus: status,
    recentMomentumStatus: momentum,
    currentSmoothedValue: 80,
    expectedValue: 79.5,
    trajectoryGap: 0.5,
    weightObservationCount: 5,
    nutritionLoggedDays: 7,
    currentCalories: recommendedCalories == null ? null : 2100,
    dataQuality: 'sufficient',
    nutritionAction:
        recommendedCalories == null ? 'keep_targets' : 'adjust_targets',
  );
  return GoalReviewRecord(
    id: 'review-1',
    goalId: 'goal-1',
    windowStart: DateTime(2026, 9, 27),
    windowEnd: DateTime(2026, 10, 4),
    trajectoryStatus: status,
    observedRateKgPerWeek: -0.5,
    recommendedCalories: recommendedCalories,
    algorithmVersion: 'test',
    assessment: assessment,
    createdAt: DateTime(2026, 10, 4),
  );
}

Widget _testApp({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [child],
      ),
    ),
  );
}

void main() {
  testWidgets('shows progress and the calorie change with one review action',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('de'),
        child: AdaptiveReviewCard(
          activeGoal: _goal(),
          pendingReview: _review(
            status: 'behind',
            momentum: 'matching_plan',
            recommendedCalories: 1950,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hinter dem Plan'), findsOneWidget);
    expect(find.text('Aktuell'), findsOneWidget);
    expect(find.text('Empfohlen'), findsOneWidget);
    expect(find.text('2.100 kcal'), findsOneWidget);
    expect(find.text('1.950 kcal'), findsOneWidget);
    expect(find.text('-150 kcal pro Tag'), findsOneWidget);
    expect(find.text('Review ansehen'), findsOneWidget);
    expect(find.text('Empfohlene Tageswerte übernehmen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the longer English status on a narrow viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('en'),
        child: AdaptiveReviewCard(
          activeGoal: _goal(),
          pendingReview: _review(
            status: 'target_date_needs_review',
            momentum: 'moving_slower',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Target date needs review'), findsOneWidget);
    expect(find.text('View Review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
