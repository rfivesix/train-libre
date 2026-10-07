import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/widgets/common/platform_adaptive_pickers.dart';

void main() {
  testWidgets('clear duration returns zero to the caller', (tester) async {
    Duration? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showAdaptiveDurationPicker(
                  context: context,
                  initialDuration: const Duration(seconds: 75),
                  title: AppLocalizations.of(context)!.durationLabel,
                  allowClear: true,
                );
              },
              child: const Text('Open duration'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open duration'));
    await tester.pumpAndSettle();

    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Clear duration'), findsOneWidget);

    await tester.tap(find.text('Clear duration'));
    await tester.pumpAndSettle();

    expect(result, Duration.zero);
  });
}
