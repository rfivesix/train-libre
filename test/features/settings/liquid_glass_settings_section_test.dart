import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/app/presentation/widgets/main_navigation_bar.dart';
import 'package:train_libre/features/settings/presentation/liquid_glass_settings_section.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/theme_service.dart';

void main() {
  testWidgets('glass controls update the service and live preview', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeService>.value(
        value: service,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: LiquidGlassSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final preview = find.byType(MainNavigationBar);
    expect(preview, findsOneWidget);
    final glass = find.descendant(
      of: preview,
      matching: find.byType(GlassTabBar),
    );
    final initialBlur = tester.widget<GlassTabBar>(glass).settings!.blur;

    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(2));
    final blurBounds = tester.getRect(sliders.at(0));
    await tester.tapAt(
      Offset(blurBounds.left + blurBounds.width * 0.8, blurBounds.center.dy),
    );
    await tester.pump();
    expect(service.glassBlur, greaterThan(1));
    expect(
      tester.widget<GlassTabBar>(glass).settings!.blur,
      greaterThan(initialBlur),
    );

    final opacityBounds = tester.getRect(sliders.at(1));
    await tester.tapAt(
      Offset(
        opacityBounds.left + opacityBounds.width * 0.2,
        opacityBounds.center.dy,
      ),
    );
    await tester.pump();
    expect(service.glassOpacity, lessThan(1));

    await tester.tap(find.text('Reset').first);
    await tester.tap(find.text('Reset').last);
    await tester.pump();
    expect(service.glassBlur, 1);
    expect(service.glassOpacity, 1);
    expect(tester.widget<GlassTabBar>(glass).settings!.blur, initialBlur);

    await tester.tap(find.text('Liquid Glass'));
    await tester.tap(find.text('Remove border'));
    await tester.pump();
    expect(service.liquidGlassEnabled, isFalse);
    expect(service.glassBorderRemoved, isTrue);
    final configuredBar = tester.widget<GlassTabBar>(glass);
    expect(configuredBar.settings!.lightIntensity, 0);
    expect(configuredBar.settings!.thickness, 0);
    expect(configuredBar.indicatorSettings, isNotNull);
    expect(configuredBar.indicatorSettings!.rimLight, lessThan(0.001));
    expect(configuredBar.indicatorSettings!.rimShade, lessThan(0.001));

    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
