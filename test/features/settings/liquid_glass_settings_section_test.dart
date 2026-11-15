import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/app/presentation/widgets/main_navigation_bar.dart';
import 'package:train_libre/features/settings/presentation/liquid_glass_settings_section.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/l10n/app_localization_delegates.dart';
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
          theme: ThemeData.dark(),
          localizationsDelegates: appLocalizationDelegates,
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
    expect(find.text('Start Workout'), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(
      find.byKey(const ValueKey('glass-preview-food-accent')),
      findsOneWidget,
    );
    final accent = tester.getRect(
      find.byKey(const ValueKey('glass-preview-food-accent')),
    );
    final navigation = tester.getRect(preview);
    expect(accent.top, lessThan(navigation.top));
    expect(accent.bottom, greaterThan(navigation.bottom));
    final glass = find.descendant(
      of: preview,
      matching: find.byType(GlassTabBar),
    );
    final initialSettings = tester.widget<GlassTabBar>(glass).settings!;
    final initialBlur = initialSettings.blur;
    final initialFrostOpacity = initialSettings.frostOpacity;
    final initialAlpha = tester
        .widget<GlassTabBar>(glass)
        .settings!
        .glassColor
        .a;

    final sliders = find.byType(Slider);
    expect(sliders, findsOneWidget);
    final blurBounds = tester.getRect(sliders.at(0));
    await tester.tapAt(
      Offset(blurBounds.left + blurBounds.width * 0.8, blurBounds.center.dy),
    );
    await tester.pump();
    expect(service.glassBlur, greaterThan(ThemeService.defaultGlassBlur));
    expect(
      tester.widget<GlassTabBar>(glass).settings!.blur,
      greaterThan(initialBlur),
    );
    expect(
      tester.widget<GlassTabBar>(glass).settings!.glassColor.a,
      greaterThan(initialAlpha),
    );
    expect(tester.widget<GlassTabBar>(glass).settings!.frost, 6);
    expect(
      tester.widget<GlassTabBar>(glass).settings!.frostOpacity,
      greaterThan(initialFrostOpacity),
    );
    expect(tester.widget<GlassTabBar>(glass).indicatorSettings, isNull);
    expect(
      tester.widget<GlassTabBar>(glass).settings!.thickness,
      initialSettings.thickness,
    );
    expect(
      tester.widget<GlassTabBar>(glass).settings!.refractiveIndex,
      initialSettings.refractiveIndex,
    );
    await tester.tapAt(Offset(blurBounds.left + 1, blurBounds.center.dy));
    await tester.pump();
    expect(
      tester.widget<GlassTabBar>(glass).settings!.glassColor.a,
      greaterThan(0),
    );
    expect(tester.widget<GlassTabBar>(glass).settings!.blur, initialBlur);
    expect(
      tester.widget<GlassTabBar>(glass).settings!.frostOpacity,
      lessThan(initialFrostOpacity),
    );
    expect(tester.widget<GlassTabBar>(glass).indicatorSettings, isNull);
    await tester.tapAt(Offset(blurBounds.right - 1, blurBounds.center.dy));
    await tester.pump();
    expect(
      tester.widget<GlassTabBar>(glass).settings!.blur,
      greaterThan(initialBlur * 8),
    );
    expect(
      tester.widget<GlassTabBar>(glass).settings!.frostOpacity,
      greaterThan(0.95),
    );
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(service.glassBlur, closeTo(ThemeService.defaultGlassBlur, 0.0001));
    expect(
      service.glassOpacity,
      closeTo(ThemeService.defaultGlassOpacity, 0.0001),
    );
    expect(tester.widget<GlassTabBar>(glass).settings!.blur, initialBlur);

    expect(find.text('Liquid Glass'), findsNothing);
    expect(find.text('Remove border'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });

  testWidgets('glass preview fits a narrow screen in light and dark themes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final theme in [ThemeData.light(), ThemeData.dark()]) {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: service,
          child: MaterialApp(
            locale: const Locale('de'),
            theme: theme,
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LiquidGlassSettingsSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(MainNavigationBar), findsOneWidget);
      expect(
        find.byKey(const ValueKey('glass-preview-food-accent')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });

  testWidgets('glass appearance changes through the iOS glass slider', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeService>.value(
        value: service,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: LiquidGlassSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final slider = find.byType(GlassSlider);
    expect(slider, findsOneWidget);
    final bounds = tester.getRect(slider);
    await tester.tapAt(Offset(bounds.right - 16, bounds.center.dy));
    await tester.pump();
    expect(service.glassAppearance, greaterThan(0.95));
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
