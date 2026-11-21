import 'package:material_ui/material_ui.dart';
import 'package:flutter/cupertino.dart' as cupertino;
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

    testWidgets('glass theme preserves app icon color in $appBrightness', (
      tester,
    ) async {
      final iconColor = appBrightness == Brightness.dark
          ? Colors.white
          : Colors.black;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: appBrightness,
            iconTheme: IconThemeData(color: iconColor),
          ),
          builder: (context, child) => AppGlassTheme(child: child!),
          home: const Scaffold(body: Icon(Icons.more_vert)),
        ),
      );

      final iconContext = tester.element(find.byIcon(Icons.more_vert));
      expect(IconTheme.of(iconContext).color, iconColor);
    });

    testWidgets('Cupertino controls use the app accent in $appBrightness', (
      tester,
    ) async {
      const accent = Color(0xFFAA3366);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            cupertino.DefaultCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: appBrightness,
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              brightness: appBrightness,
            ).copyWith(primary: accent),
          ),
          builder: (context, child) => AppGlassTheme(child: child!),
          home: Scaffold(
            body: cupertino.CupertinoNavigationBarBackButton(onPressed: () {}),
          ),
        ),
      );

      final context = tester.element(
        find.byType(cupertino.CupertinoNavigationBarBackButton),
      );
      expect(cupertino.CupertinoTheme.of(context).primaryColor, accent);
      expect(
        cupertino.CupertinoTheme.of(context).textTheme.navActionTextStyle.color,
        accent,
      );
    });
  }
}
