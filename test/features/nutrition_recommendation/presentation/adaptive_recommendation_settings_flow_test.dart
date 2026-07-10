import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/features/profile/data/profile_repository.dart';
import 'package:train_libre/features/profile/data/sources/profile_local_data_source.dart';
import 'package:train_libre/features/profile/presentation/goals_screen.dart';
import 'package:train_libre/features/onboarding/presentation/onboarding_screen.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('adaptive recommendation settings flows', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late AdaptiveNutritionRecommendationService recommendationService;

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
    });

    Widget wrapWithProviders(Widget child) {
      return ChangeNotifierProvider<UnitService>(
        create: (_) => UnitService(),
        child: child,
      );
    }

    Future<void> fillProfileSlide(WidgetTester tester,
        {String name = 'Alex', String height = '180'}) async {
      await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')),
        name,
      );
      await tester.pumpAndSettle();

      final genderDropdown =
          find.byKey(const Key('onboarding_gender_dropdown'));
      await tester.tap(genderDropdown);
      await tester.pumpAndSettle();
      final maleItem = find.text('Male').last;
      await tester.tap(maleItem);
      await tester.pumpAndSettle();

      final dobField = find.byIcon(LucideIcons.cake);
      await tester.tap(dobField);
      await tester.pumpAndSettle();
      final okButton = find.text('OK');
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_height_text_field')),
        height,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('goals screen keeps adaptive sections above daily goals',
        (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GoalsScreen(
              recommendationService: recommendationService,
              repository: ProfileRepository(
                localDataSource: ProfileLocalDataSource(database),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final adaptiveSection =
          find.byKey(const Key('goals_adaptive_section_title'));
      final personalSection =
          find.byKey(const Key('goals_personal_section_title'));
      final recommendationSettingsSection = find.byKey(
        const Key('goals_recommendation_settings_section_title'),
      );
      final dailyGoalsSection =
          find.byKey(const Key('goals_daily_section_title'));
      final heightField = find.byKey(const Key('goals_height_field'));

      expect(personalSection, findsOneWidget);
      expect(adaptiveSection, findsOneWidget);
      expect(recommendationSettingsSection, findsOneWidget);
      expect(dailyGoalsSection, findsOneWidget);
      expect(heightField, findsOneWidget);
      expect(find.byKey(const Key('goals_prior_activity_dropdown')),
          findsOneWidget);
      expect(
          find.byKey(const Key('goals_extra_cardio_dropdown')), findsOneWidget);

      final personalTop = tester.getTopLeft(personalSection).dy;
      final heightFieldTop = tester.getTopLeft(heightField).dy;
      final adaptiveTop = tester.getTopLeft(adaptiveSection).dy;
      final settingsTop = tester.getTopLeft(recommendationSettingsSection).dy;
      final dailyTop = tester.getTopLeft(dailyGoalsSection).dy;

      expect(personalTop, lessThan(adaptiveTop));
      expect(heightFieldTop, lessThan(adaptiveTop));
      expect(adaptiveTop, lessThan(settingsTop));
      expect(settingsTop, lessThan(dailyTop));
    });

    testWidgets(
        'onboarding flow includes dedicated body-fat page after bodyweight',
        (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingScreen(
              recommendationService: recommendationService,
              databaseHelper: dbHelper,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();

      // Navigate past region selection slide to profile slide
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      await fillProfileSlide(tester, name: 'Alex');
      // Navigate from profile page to the combined measurements page.
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      // The measurements page (page 2) combines weight and body-fat fields.
      expect(find.byKey(const Key('onboarding_measurements_page')),
          findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_weight_text_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_body_fat_text_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_body_fat_helper_text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_body_fat_help_button')),
        findsOneWidget,
      );

      // Enter weight before advancing
      await tester.enterText(
        find.byKey(const Key('onboarding_weight_text_field')),
        '70',
      );
      await tester.pumpAndSettle();

      // Advance to the adaptive goal page.
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('onboarding_adaptive_goal_page')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_extra_cardio_dropdown')),
        findsOneWidget,
      );
    });

    testWidgets(
        'onboarding body-fat help opens guidance and shows male/female texts',
        (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingScreen(
              recommendationService: recommendationService,
              databaseHelper: dbHelper,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();

      // Navigate past region selection slide to profile slide
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      await fillProfileSlide(tester, name: 'Alex');
      // Navigate to the combined measurements page (page 2) — contains the
      // body-fat help button.
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      final bodyFatHelpButton =
          find.byKey(const Key('onboarding_body_fat_help_button'));
      await tester.tap(bodyFatHelpButton);
      await tester.pumpAndSettle();

      final sheet = find.byKey(const Key('body_fat_guidance_sheet'));
      expect(sheet, findsOneWidget);

      final context = tester.element(sheet);
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.bodyFatGuidanceTitle), findsOneWidget);
      expect(find.text(l10n.bodyFatGuidanceMale10), findsOneWidget);

      await tester.tap(find.byKey(const Key('body_fat_guidance_sex_female')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.bodyFatGuidanceFemale15), findsOneWidget);
    });

    testWidgets(
        'prior activity dropdowns include the very-high activity option',
        (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingScreen(
              recommendationService: recommendationService,
              databaseHelper: dbHelper,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final onboardingContext = tester.element(find.byType(OnboardingScreen));
      final l10n = AppLocalizations.of(onboardingContext)!;

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();

      // Navigate past region selection slide to profile slide
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      await fillProfileSlide(tester, name: 'Alex');
      // Navigate: profile(2) → measurements(3) → adaptive goals(4)
      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_weight_text_field')),
        '70',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_bottom_next_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final onboardingDropdown =
          find.byKey(const Key('onboarding_prior_activity_dropdown'));
      expect(onboardingDropdown, findsOneWidget);
      await tester.ensureVisible(onboardingDropdown);
      await tester.pumpAndSettle();
      await tester.tap(onboardingDropdown);
      await tester.pumpAndSettle();
      expect(find.text(l10n.adaptivePriorActivityVeryHigh), findsOneWidget);
      await tester.tap(find.text(l10n.adaptivePriorActivityVeryHigh).last);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        wrapWithProviders(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GoalsScreen(
              recommendationService: recommendationService,
              repository: ProfileRepository(
                localDataSource: ProfileLocalDataSource(database),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final goalsDropdown =
          find.byKey(const Key('goals_prior_activity_dropdown'));
      expect(goalsDropdown, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(goalsDropdown),
          alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(goalsDropdown);
      await tester.pumpAndSettle();
      expect(find.text(l10n.adaptivePriorActivityVeryHigh), findsOneWidget);
    });

    testWidgets('onboarding final page shows finish action', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingScreen(
              recommendationService: recommendationService,
              databaseHelper: dbHelper,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(OnboardingScreen));
      final l10n = AppLocalizations.of(context)!;
      final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));

      await tester
          .tap(find.byKey(const Key('onboarding_continue_setup_button')));
      await tester.pumpAndSettle();

      // Navigate past region selection slide to profile slide
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      await fillProfileSlide(tester, name: 'Alex');
      // Navigate through the 7-page onboarding flow:
      // profile(2) → measurements(3) → adaptive(4) → nutrition(5) →
      // ai_health(6, last page)
      await tester.tap(nextButton); // profile -> measurements
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_weight_text_field')),
        '70',
      );
      await tester.pumpAndSettle();

      await tester.tap(nextButton); // measurements -> adaptive
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(nextButton); // adaptive -> nutrition
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // nutrition -> ai_health (last page)
      await tester.pumpAndSettle();

      // The bottom button on the last page should display FINISH.
      expect(find.text(l10n.onboardingFinish.toUpperCase()), findsOneWidget);
    });
  });
}
