// lib/widgets/global_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// A standardized AppBar for the application with a frosted glass background.
///
/// Implements [PreferredSizeWidget] and provides a consistent look across screens.
class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Simple text title.
  final String? title;

  /// Custom widget for the title area; takes precedence over [title].
  final Widget? titleWidget;

  /// List of actions to display at the end of the bar.
  final List<Widget>? actions;

  /// Custom leading widget; usually a back button or menu icon.
  final Widget? leading;

  /// Whether to automatically show a back button if the route allows it.
  final bool automaticallyImplyLeading;

  /// Space between the leading widget and the title.
  final double? titleSpacing;

  const GlobalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
  }) : assert(
          title == null || titleWidget == null,
          'Cannot provide both a title and a titleWidget',
        );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Visible AppBar content (title, icons, etc.)
    final appBarContent = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: theme.colorScheme.onSurface,
      centerTitle: false,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      title: titleWidget ??
          Text(
            title ?? '',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
      actions: actions,
    );

    // Color for the translucent glass
    final Color glassColor = isDark
        ? Colors.black.withValues(alpha: 0.50)
        : const Color(0xFFF2F2F7).withValues(alpha: 0.70);

    // Final structure with static blur (blur sigma preserved at 14 as requested)
    return Stack(
      children: [
        // Soft top fade-out vignette shadow underneath the bar (does not affect glass blur optics)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFFF2F2F7).withValues(alpha: 0.50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: glassColor,
                ),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(height: kToolbarHeight, child: appBarContent),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
