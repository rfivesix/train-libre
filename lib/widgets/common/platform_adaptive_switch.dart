import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class PlatformAdaptiveSwitch extends StatelessWidget {
  const PlatformAdaptiveSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
    this.inactiveColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;

    if (isIOS) {
      return GlassSwitch(
        value: value,
        onChanged: onChanged ?? (val) {},
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      );
    } else {
      return Theme(
        data: Theme.of(context).copyWith(useMaterial3: true),
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
          inactiveTrackColor: inactiveColor,
        ),
      );
    }
  }
}
