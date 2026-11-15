import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/util/glass_preferences.dart';
import 'package:train_libre/widgets/common/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('glass settings survive a service restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = ThemeService();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.setGlassBlur(0.4);
    await service.setGlassOpacity(1.5);
    await service.setLiquidGlassEnabled(false);
    await service.setGlassBorderRemoved(true);

    final restored = ThemeService();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(restored.glassBlur, 0.4);
    expect(restored.glassOpacity, 1.5);
    expect(restored.liquidGlassEnabled, isFalse);
    expect(restored.glassBorderRemoved, isTrue);
    service.dispose();
    restored.dispose();
  });

  test('an early edit does not discard other saved glass settings', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'glass_blur': 0.4,
      'glass_opacity': 1.5,
      'liquid_glass_enabled': false,
      'glass_border_removed': true,
    });
    final service = ThemeService();
    await service.setGlassBlur(0.8);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(service.glassBlur, 0.8);
    expect(service.glassOpacity, 1.5);
    expect(service.liquidGlassEnabled, isFalse);
    expect(service.glassBorderRemoved, isTrue);
    service.dispose();
  });

  test('preferences adjust the surface without losing its base color', () {
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
      borderRemoved: true,
    ).apply(base);
    expect(adjusted.blur, 5);
    expect(adjusted.glassColor.a, closeTo(base.glassColor.a * 1.5, 0.001));
    expect(adjusted.glassColor.r, base.glassColor.r);
    expect(adjusted.thickness, base.thickness);
    expect(adjusted.ambientRim, 0);
    expect(adjusted.lightIntensity, 0);

    final disabled = const GlassPreferences(liquidEnabled: false).apply(base);
    expect(disabled.thickness, 0);
    expect(disabled.refractiveIndex, 1);
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
    await service.setGlassBlur(0.5);
    await tester.pump();
    final after = tester
        .widget<AdaptiveGlass>(find.byType(AdaptiveGlass))
        .settings;
    expect(after.blur, closeTo(before.blur * 0.5, 0.001));
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
