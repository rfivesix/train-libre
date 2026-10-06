import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:train_libre/features/onboarding/presentation/onboarding_screen.dart';
import 'package:train_libre/features/onboarding/presentation/widgets/profile_slide.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

Widget _buildOnboardingTestApp({
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<UnitService>(
      create: (_) => UnitService(),
      child: const OnboardingScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Onboarding blocks user under 16 years old and shows underage error',
      (tester) async {
    await tester.pumpWidget(_buildOnboardingTestApp());
    await tester.pumpAndSettle();

    // Page 0: Welcome
    final startButton =
        find.byKey(const Key('onboarding_continue_setup_button'));
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    final nextButton = find.byKey(const Key('onboarding_bottom_next_button'));

    // Page 1: Unit system
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Page 2: Region selection
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Page 3: Experience level
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Page 4: Name
    await tester.enterText(
      find.byKey(const Key('onboarding_name_text_field')),
      'Junior',
    );
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Page 5: BioData (Age & Gender)
    expect(find.byKey(const Key('onboarding_bio_data_page')), findsOneWidget);

    // Try tapping Next without selecting a birthday -> field cannot be empty
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('This field cannot be empty.'), findsOneWidget);

    // Simulate entering a date for a 14-year-old
    final now = DateTime.now();
    final underageDate = DateTime(now.year - 14, now.month, now.day);

    // Find BioDataSlide and verify callback triggers age validation
    final bioDataSlideFinder = find.byType(BioDataSlide);
    expect(bioDataSlideFinder, findsOneWidget);
    final bioDataSlide = tester.widget<BioDataSlide>(bioDataSlideFinder);

    // Invoke onSelectDate with underage date
    bioDataSlide.onSelectDate(underageDate);
    await tester.pumpAndSettle();

    // Underage error must be displayed
    expect(
      find.text('You must be at least 16 years old to use Train Libre.'),
      findsOneWidget,
    );

    // Attempting to advance must remain on the bio data page
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_bio_data_page')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_height_page')), findsNothing);

    // Now change to a valid age (20 years old)
    final validDate = DateTime(now.year - 20, now.month, now.day);
    bioDataSlide.onSelectDate(validDate);
    await tester.pumpAndSettle();

    // Underage error is cleared
    expect(
      find.text('You must be at least 16 years old to use Train Libre.'),
      findsNothing,
    );

    // Now Next button successfully advances to height page
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_height_page')), findsOneWidget);
  });
}
