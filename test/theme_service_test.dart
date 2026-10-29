import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/theme/app_color_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitForThemeServiceInit() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService defaults and persistence', () {
    test('loads defaults when no preferences are saved', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final service = ThemeService();
      await _waitForThemeServiceInit();

      expect(service.themeMode, ThemeMode.dark);
      expect(service.visualStyle, 1);
      expect(service.isAiEnabled, true);
      expect(service.appColorChoice, AppColorChoice.trainLibre);
      expect(service.materialColorsEnabled, false);
      expect(service.hapticsEnabled, true);
    });

    test('migrates the previous Android system color preference', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': ThemeMode.dark.index,
        'visual_style': 1,
        'ai_enabled': true,
        'material_colors_enabled': true,
        'haptics_enabled': false,
      });

      final service = ThemeService();
      await _waitForThemeServiceInit();

      expect(service.themeMode, ThemeMode.dark);
      expect(service.visualStyle, 1);
      expect(service.isAiEnabled, true);
      expect(service.appColorChoice, AppColorChoice.system);
      expect(service.materialColorsEnabled, true);
      expect(service.hapticsEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_color_choice'), 'system');
    });

    test('setters persist changed values and update observable state',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ThemeService();
      await _waitForThemeServiceInit();

      await service.setThemeMode(ThemeMode.light);
      await service.setVisualStyle(1); // Test writing style 1
      await service.setAiEnabled(false);
      await service.setAppColorChoice(AppColorChoice.blue);
      await service.setCustomAppColor(const Color(0xFF7952B3));
      await service.setHapticsEnabled(false);

      final prefs = await SharedPreferences.getInstance();
      expect(service.themeMode, ThemeMode.light);
      expect(service.visualStyle, 1);
      expect(service.isAiEnabled, false);
      expect(service.appColorChoice, AppColorChoice.custom);
      expect(service.customAppColor, const Color(0xFF7952B3));
      expect(service.materialColorsEnabled, false);
      expect(service.hapticsEnabled, false);
      expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
      expect(prefs.getInt('visual_style'), 1);
      expect(prefs.getBool('ai_enabled'), false);
      expect(prefs.getString('app_color_choice'), 'custom');
      expect(prefs.getInt('custom_app_color'), 0xFF7952B3);
      expect(prefs.getBool('material_colors_enabled'), isNull);
      expect(prefs.getBool('haptics_enabled'), false);

      final reloadedService = ThemeService();
      await _waitForThemeServiceInit();
      expect(reloadedService.appColorChoice, AppColorChoice.custom);
      expect(reloadedService.customAppColor, const Color(0xFF7952B3));
    });

    test('setters are no-ops when assigning existing values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': ThemeMode.dark.index,
        'visual_style': 1,
        'ai_enabled': true,
        'app_color_choice': 'system',
        'material_colors_enabled': true,
        'haptics_enabled': true,
      });

      final service = ThemeService();
      await _waitForThemeServiceInit();
      var notifications = 0;
      service.addListener(() {
        notifications++;
      });

      await service.setThemeMode(ThemeMode.dark);
      await service.setVisualStyle(1);
      await service.setAiEnabled(true);
      await service.setMaterialColorsEnabled(true);
      await service.setAppColorChoice(AppColorChoice.system);
      await service.setHapticsEnabled(true);

      expect(notifications, 0);
    });
  });
}
