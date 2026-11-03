import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/theme/app_color_choice.dart';
import 'package:train_libre/util/design_constants.dart';

void main() {
  group('AppColorChoice', () {
    test(
      'keeps the Train Libre light and dark brand colors as the default',
      () {
        expect(
          AppColorChoice.trainLibre.primary(
            brightness: Brightness.light,
            customColor: Colors.blue,
          ),
          DesignConstants.brandAccentColorLightMode,
        );
        expect(
          AppColorChoice.trainLibre.primary(
            brightness: Brightness.dark,
            customColor: Colors.blue,
          ),
          DesignConstants.brandAccentColor,
        );
      },
    );

    test('uses contrasting black and white monochrome colors', () {
      final lightPrimary = AppColorChoice.monochrome.primary(
        brightness: Brightness.light,
        customColor: Colors.blue,
      );
      final darkPrimary = AppColorChoice.monochrome.primary(
        brightness: Brightness.dark,
        customColor: Colors.blue,
      );

      expect(lightPrimary, Colors.black);
      expect(darkPrimary, Colors.white);
      expect(
        AppColorChoice.monochrome.onPrimary(
          brightness: Brightness.light,
          primary: lightPrimary,
        ),
        Colors.white,
      );
      expect(
        AppColorChoice.monochrome.onPrimary(
          brightness: Brightness.dark,
          primary: darkPrimary,
        ),
        Colors.black,
      );
    });

    test('derives light and dark variants from the selected custom color', () {
      const custom = Color(0xFF7952B3);
      final light = AppColorChoice.custom.primary(
        brightness: Brightness.light,
        customColor: custom,
      );
      final dark = AppColorChoice.custom.primary(
        brightness: Brightness.dark,
        customColor: custom,
      );

      expect(
        light,
        ColorScheme.fromSeed(
          seedColor: custom,
          brightness: Brightness.light,
        ).primary,
      );
      expect(
        dark,
        ColorScheme.fromSeed(
          seedColor: custom,
          brightness: Brightness.dark,
        ).primary,
      );
      expect(light, isNot(dark));
    });

    test('uses an Android system color when available', () {
      const systemColor = Color(0xFF335577);
      expect(
        AppColorChoice.system.primary(
          brightness: Brightness.light,
          customColor: Colors.blue,
          systemColor: systemColor,
        ),
        systemColor,
      );
    });
  });
}
