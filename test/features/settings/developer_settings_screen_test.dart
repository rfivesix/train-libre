import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/settings/presentation/developer_settings_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/experience_level_service.dart';

/// Settings used to link straight to the performance log. Both tools now sit
/// behind one "Developer" entry, and the lab is the only place the experience
/// level can be changed at all — so the route to it is worth asserting.
Future<void> _pumpDeveloperScreen(
  WidgetTester tester,
  ExperienceLevelService service,
) async {
  // Above the MaterialApp, as in main.dart — a provider below it would be out
  // of reach of the route the developer screen pushes.
  await tester.pumpWidget(
    ChangeNotifierProvider<ExperienceLevelService>.value(
      value: service,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeveloperSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lists the lab and the performance log', (tester) async {
    await _pumpDeveloperScreen(tester, ExperienceLevelService());

    expect(find.byKey(const Key('developer_lab')), findsOneWidget);
    expect(find.byKey(const Key('developer_performance_log')), findsOneWidget);
  });

  testWidgets('the lab opens on the level the service holds', (tester) async {
    final service = ExperienceLevelService();
    await service.setLevel(ExperienceLevel.beginner);
    await _pumpDeveloperScreen(tester, service);

    await tester.tap(find.byKey(const Key('developer_lab')));
    await tester.pumpAndSettle();

    expect(find.text('Beginner'), findsOneWidget);
    // The description tells the tester what the level actually changes.
    expect(find.textContaining('No RIR'), findsOneWidget);
  });

  testWidgets('choosing a level writes it through', (tester) async {
    final service = ExperienceLevelService();
    await _pumpDeveloperScreen(tester, service);

    await tester.tap(find.byKey(const Key('developer_lab')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beginner').last);
    await tester.pumpAndSettle();

    expect(service.level, ExperienceLevel.beginner);
  });
}
