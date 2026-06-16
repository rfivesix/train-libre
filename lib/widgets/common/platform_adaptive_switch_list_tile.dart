import 'package:flutter/material.dart';
import 'platform_adaptive_switch.dart';

class PlatformAdaptiveSwitchListTile extends StatelessWidget {
  const PlatformAdaptiveSwitchListTile({
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.contentPadding,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: contentPadding,
        leading: secondary,
        title: title,
        subtitle: subtitle,
        trailing: PlatformAdaptiveSwitch(
          value: value,
          onChanged: onChanged,
        ),
        onTap: onChanged != null ? () => onChanged!(!value) : null,
      ),
    );
  }
}
