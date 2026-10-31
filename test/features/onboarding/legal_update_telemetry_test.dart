import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/app/presentation/legal_screen.dart';
import 'package:train_libre/features/onboarding/data/telemetry_consent_prompt.dart';
import 'package:train_libre/features/onboarding/presentation/legal_update_consent_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/telemetry/telemetry_service.dart';
import 'package:train_libre/services/telemetry/telemetry_service_noop.dart';

class _Telemetry extends NoOpTelemetryService {
  _Telemetry(this.enabled);
  bool enabled;
  int optInCalls = 0;
  int optOutCalls = 0;

  @override
  Future<bool> isOptedIn() async => enabled;
  @override
  Future<void> optIn() async {
    enabled = true;
    optInCalls++;
  }

  @override
  Future<void> optOut() async {
    enabled = false;
    optOutCalls++;
  }
}

void main() {
  Future<AppLocalizations> showScreen(WidgetTester tester, bool enabled) async {
    SharedPreferences.setMockInitialValues({
      'acceptedLegalVersion': '1.8',
      TelemetryConsentPrompt.followUpDoneKey: true,
    });
    TelemetryService.instance = _Telemetry(enabled);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: LegalUpdateConsentScreen(
          nextScreen: Scaffold(body: Text('next')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(LegalUpdateConsentScreen)),
    )!;
  }

  Future<void> acceptLegal(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(
      find.text(l10n.i_agree_to_updated_privacy_policy(kCurrentLegalVersion)),
    );
    await tester.pump();
    await tester.tap(find.text(l10n.accept_and_continue));
    await tester.pumpAndSettle();
  }

  testWidgets('asks opted-out users separately and preserves a decline', (
    tester,
  ) async {
    final l10n = await showScreen(tester, false);
    final telemetry = TelemetryService.instance as _Telemetry;
    expect(find.text(l10n.i_agree_to_optional_telemetry), findsNothing);
    await acceptLegal(tester, l10n);
    expect(find.text(l10n.telemetryConsentTitle), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('acceptedLegalVersion'),
      '1.8',
    );
    await tester.ensureVisible(
      find.byKey(const Key('telemetry_consent_decline')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('telemetry_consent_decline')));
    await tester.pumpAndSettle();
    expect(telemetry.enabled, isFalse);
    expect(telemetry.optInCalls, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('acceptedLegalVersion'), kCurrentLegalVersion);
    expect(prefs.getBool(TelemetryConsentPrompt.followUpDoneKey), isTrue);
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('accepting the optional prompt enables telemetry', (
    tester,
  ) async {
    final l10n = await showScreen(tester, false);
    final telemetry = TelemetryService.instance as _Telemetry;
    await acceptLegal(tester, l10n);
    await tester.ensureVisible(
      find.byKey(const Key('telemetry_consent_accept')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('telemetry_consent_accept')));
    await tester.pumpAndSettle();
    expect(telemetry.enabled, isTrue);
    expect(telemetry.optInCalls, 1);
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('already opted-in users proceed without another prompt', (
    tester,
  ) async {
    final l10n = await showScreen(tester, true);
    final telemetry = TelemetryService.instance as _Telemetry;
    await acceptLegal(tester, l10n);
    expect(find.text(l10n.telemetryConsentTitle), findsNothing);
    expect(telemetry.enabled, isTrue);
    expect(telemetry.optInCalls, 0);
    expect(telemetry.optOutCalls, 0);
    expect(
      (await SharedPreferences.getInstance()).getString('acceptedLegalVersion'),
      kCurrentLegalVersion,
    );
    expect(find.text('next'), findsOneWidget);
  });
}
