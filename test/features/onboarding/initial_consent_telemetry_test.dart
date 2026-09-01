// The initial consent screen carries only the consent the user must give to
// use the app at all. The optional telemetry question is asked separately,
// right afterwards, so that agreeing to the obligatory part cannot be read as
// agreeing to the optional one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/onboarding/data/telemetry_consent_prompt.dart';
import 'package:train_libre/features/onboarding/presentation/initial_consent_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/telemetry/telemetry_service.dart';
import 'package:train_libre/services/telemetry/telemetry_service_noop.dart';

/// Records the opt-in calls the screen makes, and nothing else.
class _RecordingTelemetry extends NoOpTelemetryService {
  final List<bool> calls = [];

  @override
  Future<void> optIn() async => calls.add(true);

  @override
  Future<void> optOut() async => calls.add(false);

  @override
  Future<bool> isOptedIn() async => calls.isNotEmpty && calls.last;
}

void main() {
  late _RecordingTelemetry telemetry;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    telemetry = _RecordingTelemetry();
    TelemetryService.instance = telemetry;
  });

  tearDown(() => TelemetryConsentPrompt.instance.resetForTesting());

  Future<AppLocalizations> pumpConsent(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const InitialConsentScreen(
        nextScreen: Scaffold(body: Text('next')),
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(InitialConsentScreen)))!;
  }

  /// Ticks the mandatory consent and taps through.
  Future<void> accept(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.text(l10n.i_agree_to_privacy_policy));
    await tester.pump();
    await tester.tap(find.text(l10n.accept_and_get_started));
    await tester.pumpAndSettle();
  }

  testWidgets('does not bundle the telemetry question into the consent',
      (tester) async {
    final l10n = await pumpConsent(tester);

    expect(find.text(l10n.i_agree_to_optional_telemetry), findsNothing);
    expect(find.text(l10n.i_agree_to_privacy_policy), findsOneWidget);
  });

  testWidgets('asks separately, right after the consent is given',
      (tester) async {
    final l10n = await pumpConsent(tester);
    await accept(tester, l10n);

    expect(find.text(l10n.telemetryConsentTitle), findsOneWidget);
    // Telemetry is off while the question is still open, so a force-quit
    // mid-question cannot leave it silently enabled.
    expect(telemetry.calls, [false]);
  });

  testWidgets('declining leaves telemetry off and starts the waiting period',
      (tester) async {
    final l10n = await pumpConsent(tester);
    await accept(tester, l10n);

    await tester.tap(find.byKey(const Key('telemetry_consent_decline')));
    await tester.pumpAndSettle();

    expect(telemetry.calls, [false], reason: 'never opted in');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(TelemetryConsentPrompt.anchorKey), isNotNull);
    expect(prefs.getBool(TelemetryConsentPrompt.followUpDoneKey), isNot(true));
    expect(find.text('next'), findsOneWidget, reason: 'proceeds either way');
  });

  testWidgets('accepting opts in and closes the subject for good',
      (tester) async {
    final l10n = await pumpConsent(tester);
    await accept(tester, l10n);

    await tester.tap(find.byKey(const Key('telemetry_consent_accept')));
    await tester.pumpAndSettle();

    expect(telemetry.calls, [false, true]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TelemetryConsentPrompt.followUpDoneKey), isTrue);
    expect(find.text('next'), findsOneWidget);
  });
}
