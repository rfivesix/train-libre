import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/progression/progression_v15.dart';
import 'package:train_libre/features/workout/presentation/widgets/progression_details.dart';
import 'package:train_libre/widgets/common/platform_adaptive_dropdown.dart';

void main() {
  testWidgets('trial exposes explicit accept and decline, no automatic action',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final units = UnitService();
    await units.setUnitSystem(UnitSystem.metric);
    ReviewAction? decision;
    SetCompletion? completion;
    const review = ProgressionReview(
        kind: ReviewKind.largeStepTrial,
        position: '0',
        policy: ProgressionPolicy.independentWorkingSets,
        ladderSource: LoadLadderSource.user,
        reason: 'largeStepTrial',
        currentLoad: 8,
        targetLoad: 10,
        relativeJump: 0.25);
    await tester.pumpWidget(ChangeNotifierProvider<UnitService>.value(
        value: units,
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ProgressionDetails(
              log: SetLog(
                  workoutLogId: 1,
                  exerciseName: 'Press',
                  setType: 'normal',
                  progressionData: const ProgressionConfig(
                          policy: ProgressionPolicy.independentWorkingSets)
                      .encode()),
              reviews: const [review],
              showCompletionPicker: true,
              onCompletion: (value) => completion = value,
              onDecision: (r, a, {chosenLoad}) async {
                decision = a;
              },
            ))))));
    expect(decision, isNull);
    expect(find.byType(PlatformAdaptiveDropdownFormField<SetCompletion>),
        findsOneWidget);
    expect(find.text('Progression and equipment'), findsNothing);
    expect(find.textContaining('25.0%'), findsOneWidget);
    await tester.tap(find.text('Confirm target'));
    await tester.pump();
    expect(decision, ReviewAction.accepted);
    await tester.tap(find.text('Keep current load'));
    await tester.pump();
    expect(decision, ReviewAction.rejected);
    expect(find.text('Dismiss hint'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(decision, ReviewAction.dismissed);

    await tester.tap(find.text('Completed normally'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ended early').last);
    await tester.pumpAndSettle();
    expect(completion, SetCompletion.abandoned);
  });

  testWidgets('completion-only control has no progression review card',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final units = UnitService();
    await units.setUnitSystem(UnitSystem.metric);
    await tester.pumpWidget(ChangeNotifierProvider<UnitService>.value(
      value: units,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ProgressionDetails(
            log: SetLog(
              workoutLogId: 1,
              exerciseName: 'Press',
              setType: 'normal',
            ),
            showCompletionPicker: true,
            onCompletion: (_) {},
          ),
        ),
      ),
    ));

    expect(find.byType(PlatformAdaptiveDropdownFormField<SetCompletion>),
        findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('progression_review_');
      }),
      findsNothing,
    );
  });
}
