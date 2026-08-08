import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/onboarding/presentation/initial_consent_screen.dart';
import 'package:train_libre/widgets/common/app_button.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'InitialConsentScreen button remains disabled until GDPR consent checkbox is checked',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const InitialConsentScreen(nextScreen: Text('Next Screen')),
      ),
    );
    await tester.pumpAndSettle();

    final nextButtonFinder = find.byType(AppButton);
    expect(nextButtonFinder, findsAtLeastNWidgets(1));

    // Check if button is disabled initially
    var button = tester.widgetList<AppButton>(nextButtonFinder).first;
    expect(button.onPressed, isNull);

    // Find and tap the GDPR health data consent tile (circle icon)
    final consentIcon = find.byIcon(LucideIcons.circle).first;
    await tester.tap(consentIcon);
    await tester.pumpAndSettle();

    // Now enabled
    button = tester.widgetList<AppButton>(nextButtonFinder).first;
    expect(button.onPressed, isNotNull);
  });
}
