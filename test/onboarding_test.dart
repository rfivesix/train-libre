import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/onboarding/presentation/onboarding_screen.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

void main() {
  testWidgets('OnboardingScreen flow validation and physiological bounds check',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<UnitService>(
          create: (_) => UnitService(),
          child: const OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Welcome Screen
    final startButton =
        find.byKey(const Key('onboarding_continue_setup_button'));
    expect(startButton, findsOneWidget);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // 2. Unit System Selection Screen
    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // 3. Region Selection Screen
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // 4. Name screen
    expect(find.text('This field cannot be empty.'), findsNothing);

    await tester.enterText(
        find.byKey(const Key('onboarding_name_text_field')), 'John Doe');
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // 5. Age and gender screen: gender defaults to Male, DOB is required.
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('This field cannot be empty.'), findsOneWidget);

    // Choose Sex/Gender 'Male'
    final genderDropdown = find.byKey(const Key('onboarding_gender_dropdown'));
    expect(genderDropdown, findsOneWidget);
    await tester.tap(genderDropdown);
    await tester.pumpAndSettle();

    final maleItem = find.text('Male').last;
    await tester.tap(maleItem);
    await tester.pumpAndSettle();

    // Select DOB
    final dobField = find.byIcon(LucideIcons.cake);
    expect(dobField, findsOneWidget);
    await tester.tap(dobField);
    await tester.pumpAndSettle();

    // Tap 'OK' button inside the bottom sheet
    final okButton = find.text('OK');
    expect(okButton, findsOneWidget);
    await tester.tap(okButton);
    await tester.pumpAndSettle();

    // Advance to the dedicated vertical height ruler and then measurements.
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // 6. Measurements screen
    final weightEditButton =
        find.byKey(const Key('onboarding_weight_edit_button'));
    expect(weightEditButton, findsOneWidget);

    // Tap Next with empty weight field
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Verify empty field validation error
    expect(find.text('This field cannot be empty.'), findsOneWidget);

    // Enter weight out of bounds (> 250 kg / lbs)
    await tester.tap(weightEditButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('onboarding_weight_text_field')),
      '1000',
    );
    await tester.tap(weightEditButton);
    await tester.pumpAndSettle();

    // Tap Next -> should show physiological warning intercept
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('expected physiological range'), findsOneWidget);

    // Tap Next again -> should bypass warning and advance to Goals page
    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 5. Nutrition Goals Screen (Page 4)
    expect(find.byKey(const Key('onboarding_nutrition_page')), findsNothing);
    // Wait, let's verify which page we transitioned to. On page 4 it should be the AdaptiveGoalSlide
    expect(find.byKey(const Key('onboarding_measurements_page')), findsNothing);
  });

  testWidgets(
      'OnboardingScreen presents UnitSystemSlide and updates unit system',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final unitService = UnitService();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<UnitService>.value(
          value: unitService,
          child: const OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final startButton =
        find.byKey(const Key('onboarding_continue_setup_button'));
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Verify UnitSystemSlide is displayed
    final l10n =
        AppLocalizations.of(tester.element(find.byType(OnboardingScreen)))!;
    expect(find.text(l10n.onboardingUnitSystemTitle), findsOneWidget);
    expect(find.text(l10n.onboardingUnitImperial), findsOneWidget);

    // Tap Imperial system option
    await tester.tap(find.text(l10n.onboardingUnitImperial));
    await tester.pumpAndSettle();

    expect(unitService.isImperial, isTrue);
  });
}
