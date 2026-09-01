// The sheet asks for an optional consent, so how it asks matters as much as
// what it asks: no pre-selection, both answers one tap away, and declining
// must never be the harder path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/onboarding/presentation/telemetry_consent_sheet.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  final accept = find.byKey(const Key('telemetry_consent_accept'));
  final decline = find.byKey(const Key('telemetry_consent_decline'));

  Future<bool?> open(WidgetTester tester) async {
    bool? answer;
    var answered = false;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                answer = await showTelemetryConsentSheet(context);
                answered = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(answered, isFalse, reason: 'sheet should still be open');
    return answer;
  }

  testWidgets('offers both answers, neither pre-selected', (tester) async {
    await open(tester);

    expect(accept, findsOneWidget);
    expect(decline, findsOneWidget);
    // Nothing to tick beforehand: the answer *is* the tap, so there is no
    // default state that could quietly stand in for a consent.
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('gives the decline the same width as the accept',
      (tester) async {
    await open(tester);

    // Equal weight is the point: a decline squeezed into a smaller control, or
    // buried below the fold, would make the choice less than free.
    expect(tester.getSize(accept).width,
        closeTo(tester.getSize(decline).width, 1.0));
    expect(tester.getSize(accept).height,
        closeTo(tester.getSize(decline).height, 1.0));
  });

  testWidgets('returns true when the user opts in', (tester) async {
    bool? answer;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async =>
                  answer = await showTelemetryConsentSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(accept);
    await tester.pumpAndSettle();

    expect(answer, isTrue);
  });

  testWidgets('returns false when the user declines', (tester) async {
    bool? answer;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async =>
                  answer = await showTelemetryConsentSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(decline);
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });
}
