import 'package:flutter/material.dart';
import '../../util/design_constants.dart';

/// A standardized section header enforcing the perfected diary screen style:
/// muted, uppercase, bold text with 1.0 letter spacing.
///
/// This replaces the duplicated `_buildSectionTitle` methods scattered across
/// 20+ screen files, ensuring consistent visual hierarchy app-wide.
///
/// By default, the text is automatically uppercased. Set [autoUpperCase] to
/// `false` if the label string is already uppercased (e.g. from a localization
/// key ending in `CL` / `CAPSLOCK`).
class AppSectionHeader extends StatelessWidget {
  /// The section title text.
  final String title;

  /// Whether to automatically uppercase the title. Defaults to `true`.
  final bool autoUpperCase;

  /// Optional padding override. Defaults to [DesignConstants.sectionHeaderPadding].
  final EdgeInsetsGeometry? padding;

  /// If true, reduces the top padding to tight spacing (e.g., for the very first section in a screen).
  final bool isFirst;

  /// Optional trailing action widget (e.g. info button or action link).
  final Widget? action;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.autoUpperCase = true,
    this.padding,
    this.isFirst = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = autoUpperCase ? title.toUpperCase() : title;

    final resolvedPadding = padding ??
        (isFirst
            ? EdgeInsets.only(
                top: 4.0,
                bottom: DesignConstants.sectionHeaderPadding.bottom,
                left: DesignConstants.sectionHeaderPadding.left,
                right: DesignConstants.sectionHeaderPadding.right,
              )
            : DesignConstants.sectionHeaderPadding);

    final titleTextWidget = Text(
      displayText,
      style: theme.textTheme.labelMedium?.copyWith(
        fontSize: 14.0,
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: DesignConstants.sectionHeaderLetterSpacing,
      ),
    );

    return Padding(
      padding: resolvedPadding,
      child: action == null
          ? titleTextWidget
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleTextWidget),
                action!,
              ],
            ),
    );
  }
}
