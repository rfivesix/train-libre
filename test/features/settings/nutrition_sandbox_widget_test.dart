import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/canonical_scenarios.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/nutrition_sandbox_state.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/nutrition_sandbox_widget.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  testWidgets('screen preview follows sandbox changes and stays read-only',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sandbox = NutritionSandboxState();
    final unitService = UnitService();
    await tester.pumpWidget(
      ChangeNotifierProvider<UnitService>.value(
        value: unitService,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: NutritionSandboxWidget(
                state: sandbox,
                showControls: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Review-Screen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review-Screen öffnen'));
    await tester.pumpAndSettle();

    final plateau = CanonicalNutritionScenarios.all
        .firstWhere((scenario) => scenario.id == 'behind_plateau');
    plateau.applyToSandbox(sandbox);
    await tester.pumpAndSettle();

    expect(find.text('Behind plan'), findsWidgets);
    expect(find.text('2,100 kcal'), findsOneWidget);
    expect(find.text('1,950 kcal'), findsOneWidget);
    expect(find.text('-150 kcal/day'), findsOneWidget);
    expect(find.text('Apply targets'), findsOneWidget);

    await tester.tap(find.text('Apply targets'));
    await tester.pumpAndSettle();
    expect(
        find.text('Sandbox preview: no changes were saved.'), findsOneWidget);
    expect(sandbox.currentCalories, 2100);

    await tester.tap(find.text('Adjust weekly rate'));
    await tester.pumpAndSettle();
    expect(
        find.text('Sandbox preview: no changes were saved.'), findsOneWidget);
    expect(sandbox.currentCalories, 2100);

    await tester.tap(find.text('Change target date'));
    await tester.pumpAndSettle();
    expect(
        find.text('Sandbox preview: no changes were saved.'), findsOneWidget);
    expect(sandbox.currentCalories, 2100);
  });
}
