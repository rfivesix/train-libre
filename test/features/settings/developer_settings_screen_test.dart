import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/settings/presentation/developer_settings_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';

void main() {
  testWidgets('developer tools include the performance log', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeveloperSettingsScreen(),
      ),
    );
    expect(find.byKey(const Key('developer_performance_log')), findsOneWidget);
  });
}
