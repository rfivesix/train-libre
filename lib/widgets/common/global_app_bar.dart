// lib/widgets/global_app_bar.dart

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

/// A standardized AppBar for the application with a top-to-bottom
/// [ProgressiveBlur] and soft fade vignette.
///
/// Implements [PreferredSizeWidget] and provides a consistent look across screens.
class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Maximum blur sigma at the very top edge, easing to sharp at the bottom.
  static const double _topBlurMaxSigma = 18.0;

  /// Curve shaping how quickly the progressive blur eases toward the bottom.
  static const double _topBlurFalloff = 1.4;

  /// Slight downward extension past the bar bounds so the blur and scrim finish
  /// fading just below the title/action buttons.
  static const double _fadeBottomExtension = 8.0;

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

  /// Keeps the Scaffold's app-bar geometry while allowing an overlay to cover
  /// it visually and receive its pointer events.
  final bool hidden;

  /// Space between the leading widget and the title.
  final double? titleSpacing;

  /// Optional content painted as an extension of the same app bar.
  /// Its height is included in the app bar's layout and hit-test area.
  final Widget? bottom;

  final double bottomHeight;

  const GlobalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.hidden = false,
    this.titleSpacing,
    this.bottom,
    this.bottomHeight = 56,
  }) : assert(
         title == null || titleWidget == null,
         'Cannot provide both a title and a titleWidget',
       );

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom == null ? 0 : bottomHeight));

  @override
  Widget build(BuildContext context) {
    if (hidden) return SizedBox(height: preferredSize.height);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final vignetteBase = isDark ? Colors.black : scaffoldBg;

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
      title:
          titleWidget ??
          Text(
            title ?? '',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
      actions: actions,
    );

    // Scaffold reserves the toolbar height separately from the system inset.
    // Include that inset in the painted area so SafeArea still has room for
    // the toolbar and optional extension below it.
    final glassHeight =
        MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        (bottom == null ? 0 : bottomHeight);
    final fadeHeight = glassHeight + _fadeBottomExtension;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: fadeHeight,
          child: ClipRect(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ProgressiveBlur(
                      maxSigma: _topBlurMaxSigma,
                      direction: ProgressiveBlurDirection.topToBottom,
                      falloff: _topBlurFalloff,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            vignetteBase.withValues(alpha: isDark ? 0.38 : 0.54),
                            vignetteBase.withValues(alpha: isDark ? 0.20 : 0.28),
                            vignetteBase.withValues(alpha: isDark ? 0.06 : 0.08),
                            vignetteBase.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.44, 0.80, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: glassHeight,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: kToolbarHeight, child: appBarContent),
                if (bottom != null)
                  SizedBox(height: bottomHeight, child: bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
