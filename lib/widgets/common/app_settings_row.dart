import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'platform_adaptive_switch.dart';

/// A standardized row widget for settings screens.
///
/// Features:
/// - Clean title and optional subtitle.
/// - Optional leading widget (e.g. for tests or rare custom badges, omitted by default).
/// - Trailing action or status indicator (chevron, switch, icon, or custom widget).
/// - Consistent padding matching `AppLinkRow` (horizontal: 16, vertical: 12).
class AppSettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool isDestructive;

  const AppSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.isDestructive = false,
  });

  /// Factory constructor for a navigation link row (showing a trailing chevron by default).
  factory AppSettingsRow.navigation({
    Key? key,
    required String title,
    String? subtitle,
    Widget? leading,
    VoidCallback? onTap,
    IconData trailingIcon = LucideIcons.chevron_right,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12.0)),
  }) {
    return AppSettingsRow(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: onTap,
      padding: padding,
      borderRadius: borderRadius,
      trailing: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Icon(
            trailingIcon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          );
        },
      ),
    );
  }

  /// Factory constructor for a switch toggle row.
  factory AppSettingsRow.switchTile({
    Key? key,
    required String title,
    String? subtitle,
    Widget? leading,
    required bool value,
    required ValueChanged<bool>? onChanged,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12.0)),
  }) {
    return AppSettingsRow(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: leading,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onChanged != null ? () => onChanged(!value) : null,
      trailing: PlatformAdaptiveSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Factory constructor for a radio selection row with the radio in the leading slot.
  factory AppSettingsRow.radioTile({
    Key? key,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback? onTap,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12.0)),
  }) {
    return AppSettingsRow(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Icon(
            selected
                ? LucideIcons.circle_dot
                : LucideIcons.circle,
            size: 20,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          );
        },
      ),
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            SizedBox(
              width: 32.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconTheme(
                  data: IconThemeData(
                    color: isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                  child: leading!,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? theme.colorScheme.error : null,
                  ),
                ),
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 2),
                  subtitleWidget!,
                ] else if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12.0),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Semantics(
          button: true,
          label: title,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: content,
    );
  }
}
