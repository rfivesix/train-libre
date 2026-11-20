// Glass widgets use Flutter's Cupertino theme to resolve dynamic colors.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Keeps glass widgets and Cupertino dynamic colors aligned with the app theme.
class AppGlassTheme extends StatelessWidget {
  const AppGlassTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GlassTheme(
      data: GlassThemeData.ios27(brightness: brightness),
      child: CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(brightness: brightness),
        child: child,
      ),
    );
  }
}
