import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A simple tappable text row for navigating to another screen.
class AppLinkRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final IconData trailingIcon;

  const AppLinkRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.trailingIcon = LucideIcons.chevron_right,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                trailingIcon,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
