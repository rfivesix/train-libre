import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/settings/presentation/app_color_settings_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/theme/app_color_choice.dart';

Future<ThemeService> _pumpColorSettings(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool showSystemColors = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final service = ThemeService();
  await tester.pumpWidget(
    ChangeNotifierProvider<ThemeService>.value(
      value: service,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: AppColorSettingsScreen(showSystemColors: showSystemColors),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return service;
}

Future<void> _tapChoice(WidgetTester tester, String label) async {
  final choice = find.text(label);
  await tester.ensureVisible(choice);
  await tester.pump();
  await tester.tap(choice);
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows presets and omits system colors outside Android',
      (tester) async {
    await _pumpColorSettings(tester);

    expect(find.text('Train Libre'), findsOneWidget);
    expect(find.text('Black & white'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Teal'), findsOneWidget);
    expect(find.text('Purple'), findsOneWidget);
    expect(find.text('Orange'), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('System colors'), findsNothing);
  });

  testWidgets('selects Android system colors as an exclusive mode',
      (tester) async {
    final service = await _pumpColorSettings(
      tester,
      showSystemColors: true,
    );

    expect(find.text('System colors'), findsOneWidget);
    await _tapChoice(tester, 'System colors');

    expect(service.appColorChoice, AppColorChoice.system);
  });

  testWidgets('saves a custom hex color from the picker', (tester) async {
    final service = await _pumpColorSettings(tester);

    await _tapChoice(tester, 'Custom');
    await tester.pumpAndSettle();
    expect(find.text('Choose a color'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '#7952B3');
    await tester.pump();
    await tester.ensureVisible(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(service.appColorChoice, AppColorChoice.custom);
    expect(service.customAppColor, const Color(0xFF7952B3));
  });

  testWidgets('shows localized labels in German', (tester) async {
    await _pumpColorSettings(tester, locale: const Locale('de'));

    expect(find.text('App-Farbe'), findsOneWidget);
    expect(find.text('Schwarz-Weiß'), findsOneWidget);
    expect(find.text('Eigene Farbe'), findsOneWidget);
  });
}
