import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/presentation/widgets/recommendation_banner.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Upgraded RecommendationBanner Widget Tests', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late RecommendationRepository repository;
    late AdaptiveNutritionRecommendationService recommendationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      repository = RecommendationRepository();
      recommendationService = AdaptiveNutritionRecommendationService(
        repository: repository,
        databaseHelper: dbHelper,
      );
      
      // Save user profile first so saveUserGoals doesn't return early
      await dbHelper.saveUserProfile(
        name: 'Jordan',
        birthday: DateTime(1994, 5, 12),
        height: 178,
        gender: 'male',
      );

      // Seed default goals in test database helper
      await dbHelper.saveUserGoals(
        calories: 2400,
        protein: 170,
        carbs: 260,
        fat: 75,
        water: 3000,
        steps: 8000,
      );
    });

    tearDown(() async {
      await database.close();
      await repository.clearForTesting();
    });

    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: child,
        ),
      );
    }

    NutritionRecommendation createRecommendation({required int calories, required String dueWeekKey}) {
      return NutritionRecommendation(
        recommendedCalories: calories,
        recommendedProteinGrams: 180,
        recommendedCarbsGrams: 280,
        recommendedFatGrams: 75,
        estimatedMaintenanceCalories: 2500,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        confidence: RecommendationConfidence.medium,
        warningState: RecommendationWarningState.none,
        generatedAt: DateTime.now(),
        windowStart: DateTime.now().subtract(const Duration(days: 7)),
        windowEnd: DateTime.now(),
        algorithmVersion: 'test',
        inputSummary: const RecommendationInputSummary(
          windowDays: 7,
          weightLogCount: 5,
          intakeLoggedDays: 7,
          smoothedWeightSlopeKgPerWeek: 0,
          avgLoggedCalories: 2500,
        ),
        baselineCalories: 2400,
        dueWeekKey: dueWeekKey,
      );
    }

    BayesianMaintenanceEstimate createEstimate({required String dueWeekKey}) {
      return BayesianMaintenanceEstimate(
        posteriorMaintenanceCalories: 2500,
        posteriorStdDevCalories: 150,
        profilePriorMaintenanceCalories: 2400,
        priorMeanUsedCalories: 2400,
        priorStdDevUsedCalories: 200,
        priorSource: BayesianPriorSource.profilePriorBootstrap,
        observedIntakeCalories: 2500,
        observedWeightSlopeKgPerWeek: 0,
        observationImpliedMaintenanceCalories: 2500,
        effectiveSampleSize: 7,
        confidence: RecommendationConfidence.medium,
        qualityFlags: const [],
        debugInfo: const {},
        dueWeekKey: dueWeekKey,
      );
    }

    testWidgets('does not render if no recommendation exists', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(RecommendationBanner(
          currentCalories: 2400,
          recommendationService: recommendationService,
        )),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RecommendationBanner), findsOneWidget);
      expect(find.byIcon(LucideIcons.lightbulb), findsNothing);
    });

    testWidgets('renders positive calorie delta correctly', (tester) async {
      final rec = createRecommendation(calories: 2600, dueWeekKey: '2026-W22');
      final est = createEstimate(dueWeekKey: '2026-W22');
      
      await repository.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: rec,
          maintenanceEstimate: est,
          dueWeekKey: '2026-W22',
          algorithmVersion: 'test',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(RecommendationBanner(
          currentCalories: 2400,
          recommendationService: recommendationService,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.lightbulb), findsOneWidget);
      expect(find.textContaining('New targets available (+200 kcal).'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('renders negative calorie delta correctly', (tester) async {
      final rec = createRecommendation(calories: 2280, dueWeekKey: '2026-W22');
      final est = createEstimate(dueWeekKey: '2026-W22');
      
      await repository.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: rec,
          maintenanceEstimate: est,
          dueWeekKey: '2026-W22',
          algorithmVersion: 'test',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(RecommendationBanner(
          currentCalories: 2400,
          recommendationService: recommendationService,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.lightbulb), findsOneWidget);
      expect(find.textContaining('New targets available (-120 kcal).'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('Apply button updates database targets and collapses banner', (tester) async {
      final rec = createRecommendation(calories: 2600, dueWeekKey: '2026-W22');
      final est = createEstimate(dueWeekKey: '2026-W22');
      
      await repository.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: rec,
          maintenanceEstimate: est,
          dueWeekKey: '2026-W22',
          algorithmVersion: 'test',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(RecommendationBanner(
          currentCalories: 2400,
          recommendationService: recommendationService,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final applyButton = find.text('Apply');
      expect(applyButton, findsOneWidget);

      // Delay briefly to ensure the system clock ticks forward, preventing identical timestamps
      await tester.pump(const Duration(milliseconds: 10));

      await tester.tap(applyButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Banner should disappear
      expect(find.byIcon(LucideIcons.lightbulb), findsNothing);

      // Verify SQLite goals have been updated
      final activeGoals = await dbHelper.getGoalsForDate(DateTime.now());
      expect(activeGoals?.targetCalories, 2600);
      expect(activeGoals?.targetProtein, 180);
      expect(activeGoals?.targetCarbs, 280);
      expect(activeGoals?.targetFat, 75);
    });

    testWidgets('dismissal is version-locked to recommendation dueWeekKey', (tester) async {
      final rec22 = createRecommendation(calories: 2600, dueWeekKey: '2026-W22');
      final est22 = createEstimate(dueWeekKey: '2026-W22');
      
      await repository.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: rec22,
          maintenanceEstimate: est22,
          dueWeekKey: '2026-W22',
          algorithmVersion: 'test',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(RecommendationBanner(
          key: const ValueKey('2026-W22'),
          currentCalories: 2400,
          recommendationService: recommendationService,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final closeButton = find.byIcon(LucideIcons.x);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Banner for W22 is now dismissed
      expect(find.byIcon(LucideIcons.lightbulb), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dismissed_tdee_banner_2026-W22'), isTrue);

      // Save a new recommendation for W23
      final rec23 = createRecommendation(calories: 2700, dueWeekKey: '2026-W23');
      final est23 = createEstimate(dueWeekKey: '2026-W23');
      
      await repository.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: rec23,
          maintenanceEstimate: est23,
          dueWeekKey: '2026-W23',
          algorithmVersion: 'test',
        ),
      );

      // Rebuild banner. Since W23 is a new key, it MUST show up again!
      await tester.pumpWidget(
        buildTestableWidget(RecommendationBanner(
          key: const ValueKey('2026-W23'),
          currentCalories: 2400,
          recommendationService: recommendationService,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.lightbulb), findsOneWidget);
      expect(find.textContaining('New targets available (+300 kcal).'), findsOneWidget);
    });
  });
}
