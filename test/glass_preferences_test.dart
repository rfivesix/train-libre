import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/util/design_constants.dart';
import 'package:train_libre/util/glass_preferences.dart';
import 'package:train_libre/widgets/common/app_button.dart';
import 'package:train_libre/widgets/common/glass_pill_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('glass settings survive a service restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.setGlassAppearance(0.8);

    final restored = ThemeService();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(restored.glassAppearance, 0.8);
    expect(restored.glassBlur, closeTo(0.08 + 1.42 / 9, 0.0001));
    expect(restored.glassOpacity, closeTo(1.26, 0.0001));
    service.dispose();
    restored.dispose();
  });

  test('an early edit wins over asynchronous preference loading', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'glass_blur': 0.4,
      'glass_opacity': 1.5,
      'liquid_glass_enabled': false,
      'glass_border_removed': true,
    });
    final service = ThemeService();
    await service.setGlassAppearance(0.8);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(service.glassAppearance, 0.8);
    service.dispose();
  });

  test('old independent preferences migrate to the combined slider', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'glass_blur': 0.6,
      'glass_opacity': 1.0,
    });
    final service = ThemeService();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(service.glassAppearance, closeTo(0.3, 0.0001));
    expect(service.glassBlur, ThemeService.defaultGlassBlur);
    expect(service.glassOpacity, closeTo(0.66, 0.0001));
    service.dispose();
  });

  test('extra blur is reserved for the strongest glass settings', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    await service.setGlassAppearance(0.5);
    expect(service.glassBlur, ThemeService.defaultGlassBlur);
    await service.setGlassAppearance(0.7);
    expect(service.glassBlur, ThemeService.defaultGlassBlur);
    await service.setGlassAppearance(0.85);
    expect(service.glassBlur, closeTo(0.435, 0.0001));
    await service.setGlassAppearance(1);
    expect(service.glassBlur, closeTo(1.5, 0.0001));
    service.dispose();
  });

  test('premium glass retains its color and adjusts the diffusion layer', () {
    const base = LiquidGlassSettings(
      blur: 10,
      thickness: 20,
      glassColor: Color(0x804080C0),
      ambientRim: 0.3,
      lightIntensity: 0.5,
    );
    final adjusted = const GlassPreferences(
      blur: 0.5,
      opacity: 1.5,
    ).apply(base, premium: true);
    expect(adjusted.blur, 5);
    expect(adjusted.glassColor, base.glassColor);
    expect(adjusted.frost, 14);
    expect(adjusted.frostOpacity, closeTo(0.96, 0.001));
    expect(adjusted.thickness, base.thickness);
    expect(adjusted.ambientRim, base.ambientRim);
    expect(adjusted.lightIntensity, base.lightIntensity);
  });

  test(
    'navigation glass preserves color and sharp blur while detail fades',
    () {
      final base = DesignConstants.liquidGlassSettings(true);
      final clear = const GlassPreferences(opacity: 0.3)
          .apply(base, premium: true);
      final middle = const GlassPreferences(opacity: 0.9)
          .apply(base, premium: true);
      final tinted = const GlassPreferences(opacity: 1.5)
          .apply(base, premium: true);
      expect(base.glassColor.r, closeTo(base.glassColor.g, 0.01));
      expect(clear.glassColor.a, greaterThan(0));
      expect(clear.glassColor, middle.glassColor);
      expect(tinted.glassColor, middle.glassColor);
      expect(clear.blur, middle.blur);
      expect(tinted.blur, middle.blur);
      expect(clear.frost, 14);
      expect(tinted.frost, clear.frost);
      expect(clear.frostOpacity, lessThan(middle.frostOpacity));
      expect(middle.frostOpacity, lessThan(tinted.frostOpacity));
      // A uniformly coloured background is unchanged by the cloud/ghost mix,
      // while dark text is replaced progressively by the coloured cloud.
      double mix(double ghost, double cloud, double opacity) =>
          ghost * (1 - opacity) + cloud * opacity;
      expect(mix(1, 1, clear.frostOpacity), closeTo(1, 0.001));
      expect(mix(1, 1, tinted.frostOpacity), closeTo(1, 0.001));
      expect(
        mix(0, 1, tinted.frostOpacity),
        greaterThan(mix(0, 1, clear.frostOpacity)),
      );
      expect(tinted.thickness, clear.thickness);
      expect(tinted.refractiveIndex, clear.refractiveIndex);
    },
  );

  test('fallback renderer still responds to the glass slider', () {
    final base = DesignConstants.liquidGlassSettings(true);
    final clear = const GlassPreferences(
      opacity: 0.3,
      supportsFrost: false,
    ).apply(base, premium: true);
    final tinted = const GlassPreferences(
      opacity: 1.5,
      supportsFrost: false,
    ).apply(base, premium: true);
    expect(clear.blur, tinted.blur);
    expect(clear.glassColor.a, lessThan(tinted.glassColor.a));
    final standard = const GlassPreferences().apply(base);
    expect(standard.frost, 0);
  });

  testWidgets('removed switches no longer affect saved glass preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'liquid_glass_enabled': false,
      'glass_border_removed': true,
    });
    final service = ThemeService();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeService>.value(
        value: service,
        child: const MaterialApp(
          home: Scaffold(body: GlassPillButton(child: Text('Glass'))),
        ),
      ),
    );
    final glass = tester.widget<AdaptiveGlass>(find.byType(AdaptiveGlass));
    expect(glass.settings.thickness, greaterThan(0));
    final borderedContainer = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(GlassPillButton),
            matching: find.byType(Container),
          ),
        )
        .where((container) => container.foregroundDecoration is BoxDecoration);
    expect(borderedContainer, isNotEmpty);
    expect(
      (borderedContainer.first.foregroundDecoration! as BoxDecoration).border,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });

  testWidgets('an existing app button updates when glass preferences change', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeService>.value(
        value: service,
        child: MaterialApp(
          home: Scaffold(
            body: AppButton.primary(label: 'Save', onPressed: () {}),
          ),
        ),
      ),
    );
    final before = tester
        .widget<AdaptiveGlass>(find.byType(AdaptiveGlass))
        .settings;
    await service.setGlassAppearance(0);
    await tester.pump();
    final after = tester
        .widget<AdaptiveGlass>(find.byType(AdaptiveGlass))
        .settings;
    expect(after.blur, before.blur);
    expect(after.glassColor.a, lessThan(before.glassColor.a));
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
