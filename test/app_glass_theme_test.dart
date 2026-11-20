import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:train_libre/theme/app_glass_theme.dart';

void main() {
  for (final appBrightness in Brightness.values) {
    testWidgets('glass menu follows $appBrightness against device brightness', (
      tester,
    ) async {
      final deviceBrightness = appBrightness == Brightness.light
          ? Brightness.dark
          : Brightness.light;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(platformBrightness: deviceBrightness),
          child: MaterialApp(
            theme: ThemeData(brightness: appBrightness),
            builder: (context, child) => AppGlassTheme(child: child!),
            home: Scaffold(
              body: GlassMenuItem(title: 'Option', onTap: () {}),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Option'));
      final color = text.style!.color!;
      expect(
        color.computeLuminance(),
        appBrightness == Brightness.dark ? greaterThan(0.8) : lessThan(0.2),
      );
    });
  }
}
