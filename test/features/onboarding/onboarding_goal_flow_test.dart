import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:train_libre/features/onboarding/presentation/onboarding_screen.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/domain/repositories/goal_repository.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

Widget _buildOnboardingTestApp({
  IGoalRepository? goalRepository,
  DatabaseHelper? databaseHelper,
  AdaptiveNutritionRecommendationService? recommendationService,
  Locale locale = const Locale('de'),
  VoidCallback? onFinish,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<UnitService>(
      create: (_) => UnitService(),
      child: OnboardingScreen(
        goalRepository: goalRepository,
        databaseHelper: databaseHelper,
        recommendationService: recommendationService,
        onFinish: onFinish,
      ),
    ),
  );
}

Future<void> _advanceToMeasurements(WidgetTester tester) async {
  // Page 0: Welcome
  final startButton = find.byKey(const Key('onboarding_continue_setup_button'));
  expect(startButton, findsOneWidget);
  await tester.tap(startButton);
  await tester.pumpAndSettle();

  // Page 1: Unit system - select metric
  await tester.tap(find.byIcon(LucideIcons.ruler));
  await tester.pumpAndSettle();
  final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
  await tester.tap(nextButton);
  await tester.pumpAndSettle();

  // Page 2: Region selection
  await tester.tap(nextButton);
  await tester.pumpAndSettle();

  // Page 3: Name
  await tester.enterText(
    find.byKey(const Key('onboarding_name_text_field')),
    'Alex',
  );
  await tester.tap(nextButton);
  await tester.pumpAndSettle();

  // Page 4: Age and gender
  // Pick gender Male
  final genderDropdown = find.byKey(const Key('onboarding_gender_dropdown'));
  await tester.tap(genderDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Männlich').last);
  await tester.pumpAndSettle();

  // Pick DOB
  final dobField = find.byIcon(LucideIcons.cake);
  await tester.tap(dobField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(nextButton);
  await tester.pumpAndSettle();

  // Page 5: Height (the vertical ruler has a sensible default).
  await tester.tap(nextButton);
  await tester.pumpAndSettle();

  // Page 6: Measurements
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('onboarding_measurements_page')), findsOneWidget);
}

Future<void> _setOnboardingWeight(WidgetTester tester, String value) async {
  await tester.tap(find.byKey(const Key('onboarding_weight_edit_button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('onboarding_weight_text_field')),
    value,
  );
  await tester.tap(find.byKey(const Key('onboarding_weight_edit_button')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseHelper dbHelper;
  late AdaptiveNutritionRecommendationService recommendationService;
  late IGoalRepository goalRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'unit_system': 'metric',
    });
    database = AppDatabase(NativeDatabase.memory());
    dbHelper = DatabaseHelper.forTesting(database);
    recommendationService = AdaptiveNutritionRecommendationService(
      repository: RecommendationRepository(),
      databaseHelper: dbHelper,
    );
    goalRepository = GoalRepositoryImpl(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets(
      'Onboarding order asks Activity before Goal Decision, and no training plan exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp(
      goalRepository: goalRepository,
      databaseHelper: dbHelper,
      recommendationService: recommendationService,
    ));
    await tester.pumpAndSettle();

    await _advanceToMeasurements(tester);

    // Enter weight
    await _setOnboardingWeight(tester, '80');

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Verify Page 5: Activity comes before goal decision
    expect(find.byKey(const Key('onboarding_activity_page')), findsOneWidget);
    expect(find.text('Wie aktiv bist du aktuell?'), findsOneWidget);
    expect(find.byKey(const Key('onboarding_prior_activity_dropdown')),
        findsOneWidget);
    expect(find.byKey(const Key('onboarding_extra_cardio_dropdown')),
        findsOneWidget);

    // Verify no training plan UI in onboarding
    expect(find.text('Trainingsplan'), findsNothing);
    expect(find.text('Trainingspläne'), findsNothing);

    // Advance to Page 6: Goal Decision
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('onboarding_goal_decision_page')), findsOneWidget);
    expect(find.text('Möchtest du ein persönliches Ernährungsziel verfolgen?'),
        findsOneWidget);
    expect(find.byKey(const Key('onboarding_goal_decision_now_button')),
        findsOneWidget);
    expect(find.byKey(const Key('onboarding_goal_decision_later_button')),
        findsOneWidget);
  });

  testWidgets(
      'Goal decision "Später einrichten" skips directly to Nutrition Review with neutral defaults',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp(
      goalRepository: goalRepository,
      databaseHelper: dbHelper,
      recommendationService: recommendationService,
    ));
    await tester.pumpAndSettle();

    await _advanceToMeasurements(tester);

    await _setOnboardingWeight(tester, '75');

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    await tester.tap(nextButton); // to Activity
    await tester.pumpAndSettle();

    await tester.tap(nextButton); // to Goal Decision
    await tester.pumpAndSettle();

    final laterFinder =
        find.byKey(const Key('onboarding_goal_decision_later_button'));
    await tester.ensureVisible(laterFinder);
    await tester.pumpAndSettle();
    await tester.tap(laterFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Directly in Nutrition Review (Page 11)
    expect(find.byKey(const Key('onboarding_nutrition_page')), findsOneWidget);
    expect(find.text('Deine Ernährungsziele'), findsOneWidget);

    // Goal steps (Preset, Target, Pace, Motivation) were skipped
    expect(find.text('Was möchtest du erreichen?'), findsNothing);
    expect(find.byKey(const Key('goal_duration_dropdown')), findsNothing);

    // Tapping back returns to Goal Decision
    final backButton = find.byIcon(LucideIcons.arrow_left);
    await tester.tap(backButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
        find.byKey(const Key('onboarding_goal_decision_page')), findsOneWidget);
  });

  testWidgets(
      'Goal decision "Jetzt einrichten" walks through Preset, Target, Pace, Motivation to Review',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp(
      goalRepository: goalRepository,
      databaseHelper: dbHelper,
      recommendationService: recommendationService,
    ));
    await tester.pumpAndSettle();

    await _advanceToMeasurements(tester);

    await _setOnboardingWeight(tester, '85');

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    await tester.tap(nextButton); // to Activity
    await tester.pumpAndSettle();

    await tester.tap(nextButton); // to Goal Decision
    await tester.pumpAndSettle();

    // Tap "Jetzt einrichten"
    await tester
        .tap(find.byKey(const Key('onboarding_goal_decision_now_button')));
    await tester.pumpAndSettle();

    // Page 7: Goal Preset
    expect(find.text('Was möchtest du erreichen?'), findsOneWidget);
    expect(find.text('Gewicht reduzieren'), findsOneWidget);
    expect(find.text('Gewicht halten'), findsOneWidget);

    // Select "Gewicht reduzieren"
    await tester.tap(find.byKey(const Key('goal_preset_loseWeight')));
    await tester.pumpAndSettle();

    // Advance to Page 8: Goal Target
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Was ist dein Zielgewicht?'), findsOneWidget);

    // Verify baseline was populated from measurements (85 kg)
    expect(find.text('85.0 kg'), findsWidgets);

    // Advance to Page 9: Pace & Timeline
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Tempo & Zieldatum planen'), findsOneWidget);
    expect(find.text('Geplante Wochenrate'), findsOneWidget);

    // Advance to Page 10: Motivation
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Warum ist dir das wichtig?'), findsOneWidget);
    expect(find.byKey(const ValueKey('reason_text_field')), findsOneWidget);

    // Advance to Page 11: Nutrition Review
    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('onboarding_nutrition_page')), findsOneWidget);

    // Only 1 LinearProgressIndicator exists (no nested progress bars)
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'Target weight validation prevents advancing when lose target >= baseline',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp(
      goalRepository: goalRepository,
      databaseHelper: dbHelper,
      recommendationService: recommendationService,
    ));
    await tester.pumpAndSettle();

    await _advanceToMeasurements(tester);

    await _setOnboardingWeight(tester, '80');

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    await tester.tap(nextButton); // to Activity
    await tester.pumpAndSettle();
    await tester.tap(nextButton); // to Goal Decision
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const Key('onboarding_goal_decision_now_button')));
    await tester.pumpAndSettle();

    // Page 7: Select "Gewicht reduzieren" (Lose Weight)
    await tester.tap(find.byKey(const Key('goal_preset_loseWeight')));
    await tester.pumpAndSettle();

    await tester.tap(nextButton); // to Target Weight
    await tester.pumpAndSettle();

    // Switch to manual input and enter 85 kg (greater than baseline 80 kg)
    final editButton = find.byIcon(LucideIcons.pencil);
    if (editButton.evaluate().isNotEmpty) {
      await tester.tap(editButton.first);
      await tester.pumpAndSettle();
      final targetInput = find.byKey(const Key('goal_target_weight_input'));
      if (targetInput.evaluate().isNotEmpty) {
        await tester.enterText(targetInput, '85');
        await tester.pumpAndSettle();
      }
    }

    // Try to advance: validation error should prevent it
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Still on Target Weight step
    expect(find.text('Was ist dein Zielgewicht?'), findsOneWidget);
    expect(find.text('Tempo & Zieldatum planen'), findsNothing);
  });

  testWidgets(
      'Completing onboarding creates exactly one active goal without duplicates from LegacyGoalMigration',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp(
      goalRepository: goalRepository,
      databaseHelper: dbHelper,
      recommendationService: recommendationService,
      onFinish: () {},
    ));
    await tester.pumpAndSettle();

    await _advanceToMeasurements(tester);

    await _setOnboardingWeight(tester, '80');

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    await tester.tap(nextButton); // to Activity
    await tester.pumpAndSettle();

    await tester.tap(nextButton); // to Goal Decision
    await tester.pumpAndSettle();

    // Setup later (neutral maintain default)
    final laterFinder =
        find.byKey(const Key('onboarding_goal_decision_later_button'));
    await tester.ensureVisible(laterFinder);
    await tester.pumpAndSettle();
    await tester.tap(laterFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Page 11: Nutrition Review
    expect(find.byKey(const Key('onboarding_nutrition_page')), findsOneWidget);

    // Wait for recommendation computation to finish so next button is enabled
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Advance to Page 12: Permissions (AI Health)
    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('onboarding_ai_health_page')), findsOneWidget);

    // On Page 12: Tap "LOSLEGEN" (Finish)
    await tester.tap(nextButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify exactly 1 goal was created and is active
    final activeGoal = await goalRepository.getActiveNutritionGoal();
    expect(activeGoal, isNotNull);
    expect(activeGoal!.isNutritionDriver, isTrue);

    final allGoals = await database.select(database.userGoals).get();
    expect(allGoals.length, 1);
    expect(allGoals.first.status, 'active');
    expect(allGoals.first.isNutritionDriver, isTrue);
  });

  testWidgets('Baseline weight edit in goal flow syncs with onboarding state',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp(
      goalRepository: goalRepository,
      databaseHelper: dbHelper,
      recommendationService: recommendationService,
    ));
    await tester.pumpAndSettle();

    await _advanceToMeasurements(tester);

    await _setOnboardingWeight(tester, '80');

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    await tester.tap(nextButton); // to Activity
    await tester.pumpAndSettle();

    await tester.tap(nextButton); // to Goal Decision
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const Key('onboarding_goal_decision_now_button')));
    await tester.pumpAndSettle();

    // Page 7: Select "Gewicht reduzieren"
    await tester.tap(find.byKey(const Key('goal_preset_loseWeight')));
    await tester.pumpAndSettle();

    await tester.tap(nextButton); // to Target Weight
    await tester.pumpAndSettle();

    // Tap baseline card to enable inline editing
    final baselineCard = find.byKey(const Key('goal_baseline_card'));
    await tester.ensureVisible(baselineCard);
    await tester.pumpAndSettle();
    await tester.tap(baselineCard);
    await tester.pumpAndSettle();

    final baselineInput = find.byKey(const Key('goal_inline_baseline_input'));
    expect(baselineInput, findsOneWidget);
    await tester.enterText(baselineInput, '82.5');
    await tester.pumpAndSettle();

    // Go back to Measurements step (Page 4) to verify weightController synced to 82.5
    final backButton = find.byIcon(LucideIcons.arrow_left);
    await tester.tap(backButton); // to Preset (Page 7)
    await tester.pumpAndSettle();
    await tester.tap(backButton); // to Goal Decision (Page 6)
    await tester.pumpAndSettle();
    await tester.tap(backButton); // to Activity (Page 5)
    await tester.pumpAndSettle();
    await tester.tap(backButton); // to Measurements (Page 4)
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('onboarding_measurements_page')), findsOneWidget);
    expect(find.text('82.5 kg'), findsOneWidget);
  });
}
